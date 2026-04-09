# SQL Server to PostgreSQL Migration Report

## Migration Summary
- **Date**: 2026-04-09
- **Source Database**: Microsoft SQL Server 2019 (ProductManagement)
- **Target Database**: PostgreSQL 13 (postgres)
- **Application**: AdoCore (.NET 9.0 ADO.NET Application)
- **Migration Project ARN**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

---

## SQL Statement Conversion Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Manual conversion after DMS failure | 7 |
| Validated as EQUIVALENT (by SQL Equivalency tool) | 0 |
| Validated as NOT_EQUIVALENT (by SQL Equivalency tool) | 0 |
| Equivalency validation ERROR (by SQL Equivalency tool) | 7 |

### DMS Tool Status
All 7 DMS conversion attempts failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```
All statements were manually converted using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` approach with lowercase schema object naming for PostgreSQL compatibility.

### SQL Equivalency Tool Status
All 7 equivalency validation attempts returned ERROR:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```
This appears to be an infrastructure-level issue with the SQL Equivalency tool. All 7 statement pairs require manual review.

---

## Statements Requiring Manual Review

All 7 statements require manual review due to both DMS tool failure and SQL Equivalency tool errors:

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, AVG/COUNT window functions, INNER JOIN, ORDER BY with CASE, ROUND
- **Key Changes**: Lowercase schema objects only (SQL syntax is PostgreSQL-compatible)
- **Risk**: Low - only identifier casing changes

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG window functions, LEFT JOIN, ROUND, CASE
- **Key Changes**: Lowercase schema objects only
- **Risk**: Low - only identifier casing changes

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), history logging, stats update
- **Key Changes**: 
  - SCOPE_IDENTITY() → data-modifying CTE with RETURNING clause
  - GETDATE() → NOW()
  - DECLARE/SET variables → CTE approach
  - BEGIN TRANSACTION/COMMIT → removed (single CTE statement)
- **Risk**: Medium - significant structural changes to use data-modifying CTEs

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE variables, UPDATE, history logging, stats update
- **Key Changes**:
  - DECLARE @var → CTE with old_values subquery
  - GETDATE() → NOW()
  - Multi-statement transaction → data-modifying CTE chain
- **Risk**: Medium - structural changes to eliminate variable declarations

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE variables, DELETE, history logging, stats update with CASE
- **Key Changes**:
  - DECLARE @var → CTE with old_values subquery
  - GETDATE() → NOW()
  - Multi-statement transaction → data-modifying CTE chain
- **Risk**: Medium - structural changes to eliminate variable declarations

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK/PERCENT_RANK window functions, BETWEEN, CASE
- **Key Changes**: Lowercase schema objects only
- **Risk**: Low - only identifier casing changes

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND
- **Key Changes**: Lowercase schema objects, added ::numeric cast for integer division in ROUND
- **Risk**: Low - minor changes

---

## Code Changes Summary

### 1. Package References (AdoCore.csproj)
- **Removed**: `Microsoft.Data.SqlClient` v5.1.4
- **Added**: `Npgsql` v8.0.6 (patched version to avoid GHSA-x9vc-6hfv-hg8c vulnerability in v8.0.0)

### 2. ADO.NET Class Replacements (DataAccess/ProductRepository.cs)
| Original (SqlClient) | Replacement (Npgsql) | Occurrences |
|----------------------|---------------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 (field, method return, constructor) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per SQL method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader) |

### 3. SQL Statement Conversions (DataAccess/ProductRepository.cs)
- 7 SQL statements converted from MS SQL Server to PostgreSQL syntax
- All schema objects converted to lowercase
- Transaction patterns restructured using data-modifying CTEs
- SQL Server functions replaced: SCOPE_IDENTITY() → RETURNING, GETDATE() → NOW()
- Added ::numeric cast for integer division compatibility

### 4. Connection Strings (appsettings.json)
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | Server=localhost | Host=localhost |
| Database | Database=ProductManagement | Database=postgres |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets | true | (removed - N/A) |
| TrustServerCertificate | True | (removed - N/A) |

---

## Artifacts

| Artifact | Location | Status |
|----------|----------|--------|
| extracted_statements.sql | sourceCode/extracted_statements.sql | ✅ Complete (7 statements) |
| converted_statements.sql | sourceCode/converted_statements.sql | ✅ Complete (7 statements) |
| sql_equivalency_validation_report.json | sourceCode/sql_equivalency_validation_report.json | ✅ Complete (7 entries) |
| Migration Report | sourceCode/migration_report.md | ✅ This file |

---

## Build Status
- **Final Build**: ✅ SUCCESS (0 errors, 10 warnings - all pre-existing nullable reference warnings)
- **Target Framework**: .NET 9.0
- **Output**: AdoCore.dll

---

## Recommendations for Manual Review
1. **All 7 SQL statements** should be tested against the target PostgreSQL database to verify correctness
2. **Statements 3, 4, 5** (Insert/Update/Delete) have significant structural changes and should receive priority testing
3. The data-modifying CTE approach used for Insert/Update/Delete should be validated for transaction atomicity
4. Connection string credentials should be updated to production values before deployment
5. Consider running the SQL Equivalency tool again once the infrastructure issue is resolved
