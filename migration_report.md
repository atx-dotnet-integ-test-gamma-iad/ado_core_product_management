# SQL Server to PostgreSQL Migration Report

## Migration Overview

| Metric | Value |
|--------|-------|
| Migration Date | 2026-04-07 |
| Source Database | Microsoft SQL Server |
| Target Database | PostgreSQL |
| Application Framework | .NET 9.0 / ADO.NET |
| Source File | DataAccess/ProductRepository.cs |

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Statements Successfully Converted by DMS MCP Tool | 0 |
| Statements Requiring Manual Intervention (DMS Failed) | 7 |
| Statements Validated as Equivalent (SQL Equivalency Tool) | 0 |
| Statements Validated as Non-Equivalent | 0 |
| Statements with Equivalency Validation Errors | 7 |

### DMS Tool Status
- **DMS Migration Project**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **DMS Status**: All 7 statements attempted; all failed with metadata model creation timeout
- **DMS Error**: `Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}`
- **Total DMS Attempts**: 9 (7 statements + 2 additional test queries)

### SQL Equivalency Tool Status
- All 7 statement pairs submitted to `sql-equivalency___validate_sql_equivalence`
- All 7 returned ERROR status with error: `'uniqueID'`
- No agent judgment used for equivalency - all statuses come from tool output

---

## Detailed Statement Transformations

### Statement 1: GetAllProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetAllProductsAsync()`
- **Type**: CTE with AVG/COUNT window functions, CASE, ROUND, INNER JOIN
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**:
  - Schema objects lowercased: Products→products, ProductId→productid, etc.
  - CTE alias lowercased: ProductStats→productstats
  - Column aliases lowercased: AvgPrice→avgprice, PriceCategory→pricecategory

### Statement 2: GetProductByIdAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetProductByIdAsync(int productId)`
- **Type**: CTE with LAG window function, CASE, ROUND, LEFT JOIN
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**:
  - Schema objects lowercased
  - LAG window function preserved (PostgreSQL compatible)
  - Parameter @ProductId preserved (Npgsql compatible)

### Statement 3: InsertProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `InsertProductAsync(Product product)`
- **Type**: Transaction block with SCOPE_IDENTITY/GETDATE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**:
  - SCOPE_IDENTITY() → INSERT ... RETURNING productid (via writable CTE)
  - GETDATE() → NOW()
  - BEGIN TRANSACTION/COMMIT → Single statement using writable CTEs
  - DECLARE @NewProductId → Eliminated via RETURNING clause
  - Schema objects lowercased

### Statement 4: UpdateProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `UpdateProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, SELECT INTO variables, GETDATE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**:
  - DECLARE @OldPrice/@OldStock → CTE (old_values) capturing previous values
  - GETDATE() → NOW()
  - BEGIN TRANSACTION/COMMIT → Single statement using writable CTEs
  - Schema objects lowercased

### Statement 5: DeleteProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `DeleteProductAsync(int productId)`
- **Type**: Transaction block with DECLARE, DELETE, CASE, GETDATE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**:
  - DECLARE @OldPrice/@OldStock → CTE (old_values) capturing previous values
  - GETDATE() → NOW()
  - CASE expression preserved (PostgreSQL compatible)
  - BEGIN TRANSACTION/COMMIT → Single statement using writable CTEs
  - Schema objects lowercased

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type**: CTE with RANK/PERCENT_RANK, BETWEEN, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**:
  - Schema objects lowercased
  - RANK()/PERCENT_RANK() preserved (PostgreSQL compatible)
  - BETWEEN preserved (PostgreSQL compatible)

### Statement 7: GetLowStockProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**:
  - Schema objects lowercased
  - Window functions AVG/MIN/MAX preserved (PostgreSQL compatible)
  - ROUND preserved (PostgreSQL compatible)

---

## Package Dependency Changes

| Component | Before | After |
|-----------|--------|-------|
| Database Client Package | Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |

**Note**: Initially targeted Npgsql 8.0.0 per plan, upgraded to 8.0.6 due to known high-severity vulnerability (GHSA-x9vc-6hfv-hg8c) in 8.0.0.

---

## ADO.NET Class Replacements

| Original (SQL Server) | Replacement (PostgreSQL) | Locations |
|------------------------|--------------------------|-----------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | Line 5 |
| `SqlConnection` | `NpgsqlConnection` | Field declaration, GetConnectionAsync() |
| `new SqlConnection(...)` | `new NpgsqlConnection(...)` | GetConnectionAsync() |
| `SqlCommand` | `NpgsqlCommand` | All 7 query methods |
| `SqlDataReader` | `NpgsqlDataReader` | MapProductFromReader() |

---

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server specifier | `Server=localhost` | `Host=localhost` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| Multiple result sets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| Certificate | `TrustServerCertificate=True` | Removed (not applicable) |

### Connection Strings (DevConnection and ProdConnection)
- **Before**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After**: `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`

---

## Reader Column Name Changes

Due to PostgreSQL lowercase convention, all reader column references were updated:

| SQL Server | PostgreSQL |
|-----------|------------|
| `reader["ProductId"]` | `reader["productid"]` |
| `reader["Name"]` | `reader["name"]` |
| `reader["Description"]` | `reader["description"]` |
| `reader["Price"]` | `reader["price"]` |
| `reader["StockQuantity"]` | `reader["stockquantity"]` |
| `reader["CreatedDate"]` | `reader["createddate"]` |
| `reader["ModifiedDate"]` | `reader["modifieddate"]` |

---

## Statements Requiring Manual Review

All 7 statements require manual review because:
1. DMS MCP tool was unavailable (metadata model creation timeout on all attempts)
2. SQL Equivalency tool returned ERROR for all 7 pairs (error: 'uniqueID')
3. Manual conversion was applied with lowercase schema mapping

**Recommendation**: Test all 7 SQL statements against a real PostgreSQL database to verify:
- Window functions (LAG, RANK, PERCENT_RANK, AVG, COUNT, MIN, MAX) execute correctly
- Writable CTEs (INSERT RETURNING, UPDATE, DELETE within CTEs) work as expected
- Parameter binding with Npgsql works correctly for all @-prefixed parameters
- Transaction semantics are maintained (especially for Insert/Update/Delete operations)

---

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | Complete catalog of all 7 original MS SQL statements |
| converted_statements.sql | sourceCode/ | Complete catalog of all 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | sourceCode/ | Comprehensive equivalency report with all 7 statement pairs |
| dms_failure_summary.md | sourceCode/ | Detailed DMS failure documentation |
| migration_report.md | sourceCode/ | This report |

---

## Build Verification

- **Final Build Status**: ✅ **BUILD SUCCEEDED**
- **Errors**: 0
- **Warnings**: 10 (all pre-existing nullable reference type warnings)
- **No SQL Server-specific code remaining** (verified via grep)

---

## Post-Migration Checklist

- [x] All SQL Server packages replaced with PostgreSQL equivalents
- [x] All SqlConnection/SqlCommand/SqlDataReader replaced with Npgsql equivalents
- [x] All SQL statements processed through DMS MCP tool (all failed, manual conversion applied)
- [x] Comprehensive statement catalog created (extracted_statements.sql, converted_statements.sql)
- [x] All statement pairs validated through SQL Equivalency tool (all returned ERROR)
- [x] Equivalency validation report generated (sql_equivalency_validation_report.json)
- [x] No agent judgment used for equivalency determination
- [x] DMS failures documented with original statements and manual conversion rationale
- [x] Connection strings updated to PostgreSQL format
- [x] Application compiles without errors
- [ ] Integration testing against PostgreSQL database (requires running PostgreSQL instance)
- [ ] Unit test execution (requires test framework setup)
