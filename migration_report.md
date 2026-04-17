# Migration Report: SQL Server to PostgreSQL

## 1. Migration Overview

| Property | Source | Target |
|----------|--------|--------|
| **Database** | SQL Server 2019 | PostgreSQL 13 |
| **ADO.NET Driver** | Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |
| **Application** | AdoCore (.NET 9.0 Console Application) | AdoCore (.NET 9.0 Console Application) |
| **Migration Date** | 2026-04-17 | |

## 2. Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL, ADO.NET classes replaced with Npgsql equivalents |
| `AdoCore.csproj` | Package reference updated from Microsoft.Data.SqlClient to Npgsql |
| `appsettings.json` | Connection strings updated from SQL Server to PostgreSQL format |

## 3. SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total statements processed** | 7 |
| **Statements converted by DMS** | 0 |
| **Statements requiring manual conversion** | 7 |

### DMS Tool Status

All 7 SQL statements were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`) as required. All 7 calls failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**DMS Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

Since DMS failed for all statements, manual conversion was performed with lowercase schema object names per the transformation plan's instructions (`DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`).

### Conversion Details by Statement

| # | Method | Statement Type | Key Conversions |
|---|--------|---------------|-----------------|
| 1 | GetAllProductsAsync | SELECT with CTE, window functions | Lowercased schema objects |
| 2 | GetProductByIdAsync | SELECT with CTE, LAG window function | Lowercased schema objects |
| 3 | InsertProductAsync | Transaction block with INSERT | SCOPE_IDENTITY() → currval(), GETDATE() → NOW(), BEGIN TRANSACTION → BEGIN |
| 4 | UpdateProductAsync | Transaction block with UPDATE | DECLARE/@var → subqueries, GETDATE() → NOW(), BEGIN TRANSACTION → BEGIN |
| 5 | DeleteProductAsync | Transaction block with DELETE | DECLARE/@var → subqueries, GETDATE() → NOW(), BEGIN TRANSACTION → BEGIN |
| 6 | GetProductsByPriceRangeAsync | CTE with RANK, PERCENT_RANK | Lowercased schema objects |
| 7 | GetLowStockProductsAsync | CTE with AVG, MIN, MAX | Lowercased schema objects, added ::numeric cast |

See `extracted_statements.sql` for original statements and `converted_statements.sql` for converted statements.

## 4. Equivalency Validation Summary

| Metric | Count |
|--------|-------|
| **Total pairs validated** | 7 |
| **Equivalent** | 0 |
| **Not Equivalent** | 0 |
| **Errors** | 7 |

All 7 statement pairs were passed through the SQL Equivalency MCP tool (`sql-equivalency___validate_sql_equivalence`). All 7 calls returned ERROR with the error `'uniqueID'`, indicating an infrastructure issue with the validation tool. Per the transformation plan: "If the SQL Equivalency tool fails, mark the pair as ERROR."

See `sql_equivalency_validation_report.json` for the complete detailed report.

## 5. Static Code Changes

### Using Directive
```csharp
// Before
using Microsoft.Data.SqlClient;

// After
using Npgsql;
```

### ADO.NET Class Replacements
| SQL Server Class | PostgreSQL Equivalent |
|-----------------|---------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

### Package Reference
```xml
<!-- Before -->
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />

<!-- After -->
<PackageReference Include="Npgsql" Version="8.0.6" />
```

### Connection Strings
```json
// Before (SQL Server)
"Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True"

// After (PostgreSQL)
"Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres"
```

### Parameter Mapping
| SQL Server | PostgreSQL |
|-----------|-----------|
| `Server=` | `Host=` |
| `Database=` | `Database=` (unchanged) |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | Removed (not applicable) |
| `TrustServerCertificate=True` | Removed (not applicable) |

## 6. Manual Review Items

### DMS Tool Failures
All 7 SQL statements failed DMS conversion due to metadata model creation issues. Manual conversion was applied with lowercase schema object names. The following SQL Server-specific syntax was manually converted:

1. **SCOPE_IDENTITY()** → `currval(pg_get_serial_sequence('products', 'productid'))` (Statement 3)
2. **GETDATE()** → `NOW()` (Statements 3, 4, 5)
3. **BEGIN TRANSACTION** → `BEGIN` (Statements 3, 4, 5)
4. **DECLARE @var / SET @var** → Subqueries or direct SQL operations (Statements 3, 4, 5)
5. **Integer division in ROUND** → Added `::numeric` cast for PostgreSQL (Statement 7)

### Equivalency Validation Errors
All 7 statement pairs returned ERROR from the SQL Equivalency tool due to infrastructure issues (`'uniqueID'` error). These pairs should be manually reviewed for correctness:

1. GetAllProductsAsync - SELECT with CTE and window functions
2. GetProductByIdAsync - SELECT with CTE and LAG
3. InsertProductAsync - Transaction block with INSERT
4. UpdateProductAsync - Transaction block with UPDATE
5. DeleteProductAsync - Transaction block with DELETE
6. GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
7. GetLowStockProductsAsync - CTE with AVG, MIN, MAX

## 7. Build Status

The application compiles successfully after all changes with 0 errors.

## 8. Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | Project root | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Project root | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Project root | Comprehensive equivalency validation report for all 7 pairs |
| `migration_report.md` | Project root | This migration summary report |
