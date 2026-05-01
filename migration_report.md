# Migration Report: SQL Server to PostgreSQL

## Summary
Migration of AdoCore .NET 9.0 ADO.NET application from Microsoft SQL Server to PostgreSQL.

- **Application**: AdoCore
- **Framework**: .NET 9.0
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Migration Date**: 2026-05-01
- **Migration Method**: DMS MCP Tool (with manual fallback due to DMS failures)

---

## SQL Statement Conversion Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention after DMS failure | 7 |
| Validated as equivalent by SQL Equivalency tool | 0 |
| Validated as non-equivalent | 0 |
| With equivalency validation errors | 7 |

### DMS Tool Status
All 7 DMS tool invocations failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

### SQL Equivalency Tool Status
All 7 equivalency validations returned ERROR status:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

---

## SQL Statements Processed

### Statement 1: GetAllProductsAsync
- **Source**: DataAccess/ProductRepository.cs, `GetAllProductsAsync` method
- **Type**: CTE with window functions (AVG, COUNT OVER), CASE, INNER JOIN
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema naming
- **Equivalency**: ERROR (tool returned error)

### Statement 2: GetProductByIdAsync
- **Source**: DataAccess/ProductRepository.cs, `GetProductByIdAsync` method
- **Type**: CTE with LAG() window function, LEFT JOIN, parameterized
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema naming
- **Equivalency**: ERROR (tool returned error)

### Statement 3: InsertProductAsync
- **Source**: DataAccess/ProductRepository.cs, `InsertProductAsync` method
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), INSERT history, UPDATE stats
- **DMS Status**: FAILED
- **Manual Conversion**: Restructured to CTE with RETURNING clause, GETDATE() → NOW()
- **Equivalency**: ERROR (tool returned error)

### Statement 4: UpdateProductAsync
- **Source**: DataAccess/ProductRepository.cs, `UpdateProductAsync` method
- **Type**: Transaction block with DECLARE variables, SELECT INTO, UPDATE, INSERT history
- **DMS Status**: FAILED
- **Manual Conversion**: Restructured to CTE-based approach, GETDATE() → NOW()
- **Equivalency**: ERROR (tool returned error)

### Statement 5: DeleteProductAsync
- **Source**: DataAccess/ProductRepository.cs, `DeleteProductAsync` method
- **Type**: Transaction block with DECLARE variables, SELECT INTO, INSERT history, DELETE, UPDATE stats
- **DMS Status**: FAILED
- **Manual Conversion**: Restructured to CTE-based approach, GETDATE() → NOW()
- **Equivalency**: ERROR (tool returned error)

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: DataAccess/ProductRepository.cs, `GetProductsByPriceRangeAsync` method
- **Type**: CTE with RANK(), PERCENT_RANK() window functions, BETWEEN
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema naming
- **Equivalency**: ERROR (tool returned error)

### Statement 7: GetLowStockProductsAsync
- **Source**: DataAccess/ProductRepository.cs, `GetLowStockProductsAsync` method
- **Type**: CTE with AVG/MIN/MAX window functions, ROUND with integer division
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema naming, added ::numeric cast
- **Equivalency**: ERROR (tool returned error)

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL; All ADO.NET classes replaced with Npgsql |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | Connection strings updated to PostgreSQL format |

---

## ADO.NET Class Replacements

| Original (SQL Server) | Replacement (PostgreSQL) |
|------------------------|--------------------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

---

## Connection String Transformation

### Before (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL)
```
Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres
```

### Parameter Mapping
| SQL Server Parameter | PostgreSQL Equivalent |
|----------------------|----------------------|
| `Server=` | `Host=` |
| `Database=` | `Database=` (unchanged) |
| `Trusted_Connection=True` | Removed (replaced with Username/Password) |
| `MultipleActiveResultSets=true` | Removed (not applicable) |
| `TrustServerCertificate=True` | Removed (not applicable) |
| N/A | `Username=postgres` (added) |
| N/A | `Password=postgres` (added) |

---

## Package Dependency Changes

| Action | Package | Version |
|--------|---------|---------|
| Removed | Microsoft.Data.SqlClient | 5.1.4 |
| Added | Npgsql | 8.0.6 |
| Unchanged | Microsoft.Extensions.Configuration | 8.0.0 |
| Unchanged | Microsoft.Extensions.Configuration.Json | 8.0.0 |
| Unchanged | Microsoft.Extensions.DependencyInjection | 8.0.0 |

> Note: Npgsql version was upgraded from 8.0.1 (plan specified) to 8.0.6 to resolve known high severity vulnerability (GHSA-x9vc-6hfv-hg8c).

---

## SQL Syntax Conversions Applied

| MS SQL Server | PostgreSQL | Statements Affected |
|---------------|------------|---------------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` (CTE) | Statement 3 |
| `GETDATE()` | `NOW()` | Statements 3, 4, 5 |
| `DECLARE @var TYPE` | Removed (CTE-based approach) | Statements 3, 4, 5 |
| `SET @var = value` | Removed (CTE-based approach) | Statements 3, 4, 5 |
| `BEGIN TRANSACTION / COMMIT` | Removed (CTE handles atomicity) | Statements 3, 4, 5 |
| PascalCase identifiers | lowercase identifiers | All 7 statements |
| `ROUND(int / int)` | `ROUND(int::numeric / int)` | Statement 7 |

---

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS tool failures preventing automated conversion validation
2. SQL Equivalency tool errors preventing automated equivalency verification
3. Manual conversions applied with lowercase schema naming convention

---

## Build Status
- **Final build**: ✅ SUCCESS (0 errors, 10 warnings)
- **Warnings**: All pre-existing nullable reference warnings (CS8601, CS8618, CS8603, CS8600, CS8625)
- **No vulnerability warnings** after Npgsql version upgrade

---

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | All 7 original MS SQL statements |
| converted_statements.sql | sourceCode/ | All 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | sourceCode/ | Equivalency validation results for all 7 pairs |
| dms_conversion_log.md | sourceCode/ | Detailed DMS tool interaction log |
| migration_report.md | sourceCode/ | This report |
