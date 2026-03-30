# SQL Server to PostgreSQL Migration Report

## Overview
- **Application:** AdoCore - .NET ADO.NET Product Management Application
- **Source Database:** Microsoft SQL Server
- **Target Database:** PostgreSQL
- **Migration Date:** 2026-03-30
- **Framework:** .NET 9.0

---

## SQL Statement Conversion Summary

| Metric | Count |
|---|---|
| Total SQL statements processed | 7 |
| Statements converted by DMS MCP tool | 0 |
| Statements requiring manual conversion (DMS failure) | 7 |
| Conversion method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |

### DMS Tool Failure Details
The DMS MCP tool (dms-mcp___statement_conversion_tool) was attempted for all 7 statements but failed consistently with:
- **Error:** "Metadata model creation/conversion failed: Metadata model creation/conversion did not complete after 15 attempts"
- **Additional attempts:** Timed out after 300 seconds
- **Root cause:** DMS service metadata model creation was unable to complete within the allowed timeouts

### Manual Conversion Rules Applied
Since DMS failed, manual conversion was applied per the transformation definition guidelines:
1. All schema object names converted to lowercase (tables, columns, aliases)
2. `SCOPE_IDENTITY()` → `lastval()`
3. `GETDATE()` → `NOW()`
4. `BEGIN TRANSACTION` → `BEGIN`
5. `DECLARE`/`SET` variable blocks → reordered operations with subqueries (for ADO.NET parameter compatibility)
6. Integer division → `::numeric` cast for `ROUND` operations

---

## SQL Equivalency Validation Summary

| Metric | Count |
|---|---|
| Total statement pairs validated | 7 |
| Equivalent (tool-verified) | 0 |
| Not Equivalent (tool-verified) | 0 |
| Errors (tool failure) | 7 |

### Equivalency Tool Failure Details
The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) was called for all 7 statement pairs but returned ERROR for every call:
- **Error:** `'uniqueID'`
- **Behavior:** Even the simplest query (`SELECT 1`) returned the same error
- **Root cause:** Systematic service-side failure
- **Note:** All equivalency statuses are from tool output, not agent judgment

---

## Statements Detail

### Statement 1: GetAllProductsAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** CTE with window functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN, ORDER BY with CASE
- **Conversion:** Lowercase schema objects, window functions compatible
- **Equivalency:** ERROR (tool failure)

### Statement 2: GetProductByIdAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** CTE with LAG window function, LEFT JOIN, CASE with NULL handling, ROUND
- **Conversion:** Lowercase schema objects, LAG function compatible
- **Equivalency:** ERROR (tool failure)

### Statement 3: InsertProductAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), INSERT into ProductHistory, UPDATE ProductStats, GETDATE()
- **Conversion:** SCOPE_IDENTITY()→lastval(), GETDATE()→NOW(), BEGIN TRANSACTION→BEGIN, removed DECLARE/SET
- **Equivalency:** ERROR (tool failure)

### Statement 4: UpdateProductAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT into ProductHistory, UPDATE ProductStats
- **Conversion:** Reordered operations to capture old values via subquery before UPDATE, GETDATE()→NOW()
- **Equivalency:** ERROR (tool failure)

### Statement 5: DeleteProductAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** Transaction block with DECLARE, SELECT INTO variables, INSERT into ProductHistory, DELETE, UPDATE ProductStats with CASE
- **Conversion:** Reordered operations to capture values before DELETE via subquery, GETDATE()→NOW()
- **Equivalency:** ERROR (tool failure)

### Statement 6: GetProductsByPriceRangeAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** CTE with RANK, PERCENT_RANK window functions, BETWEEN, CASE with percentile thresholds
- **Conversion:** Lowercase schema objects, window functions compatible
- **Equivalency:** ERROR (tool failure)

### Statement 7: GetLowStockProductsAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** CTE with AVG/MIN/MAX window functions, CASE, ROUND, ORDER BY
- **Conversion:** Lowercase schema objects, added ::numeric cast for integer division in ROUND
- **Equivalency:** ERROR (tool failure)

---

## Package Changes

| Component | Before | After |
|---|---|---|
| Database driver package | Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |
| Using statement | `using Microsoft.Data.SqlClient;` | `using Npgsql;` |

### Class Replacements

| SQL Server Class | Npgsql Equivalent | Occurrences |
|---|---|---|
| SqlConnection | NpgsqlConnection | 3 (field, return type, constructor) |
| SqlCommand | NpgsqlCommand | 7 (all method usages) |
| SqlDataReader | NpgsqlDataReader | 1 (MapProductFromReader parameter) |

---

## Connection String Changes

### Original (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### Converted (PostgreSQL)
```
Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres
```

### Parameter Mapping
| SQL Server Parameter | PostgreSQL Parameter |
|---|---|
| Server=localhost | Host=localhost |
| Database=ProductManagement | Database=ProductManagement (unchanged) |
| Trusted_Connection=True | Removed (use Username/Password) |
| MultipleActiveResultSets=true | Removed (not applicable) |
| TrustServerCertificate=True | Removed |
| N/A | Port=5432 (added) |
| N/A | Username=postgres (added) |
| N/A | Password=postgres (added) |

---

## Files Modified

| File | Changes |
|---|---|
| DataAccess/ProductRepository.cs | SQL statements converted, ADO.NET classes replaced with Npgsql |
| AdoCore.csproj | Microsoft.Data.SqlClient → Npgsql 8.0.6 |
| appsettings.json | Connection strings updated to PostgreSQL format |

---

## Artifact Files

| Artifact | Description |
|---|---|
| extracted_statements.sql | Complete catalog of all 7 original MS SQL statements |
| converted_statements.sql | Complete catalog of all 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | Comprehensive equivalency validation report for all 7 pairs |
| dms_failure_log.sql | DMS tool failure documentation |
| migration_report.md | This report |

---

## Build Status
- **Final build:** ✅ Succeeded
- **Build command:** `dotnet build sourceCode/AdoCore.csproj`
- **Errors:** 0
- **Warnings:** Pre-existing nullable reference warnings only (not migration-related)

---

## Statements Requiring Manual Review

All 7 statements should be reviewed due to:
1. **DMS conversion failure** - All statements were manually converted (DMS tool timed out)
2. **Equivalency validation failure** - All equivalency checks failed with tool error ('uniqueID')
3. **Transaction reordering** - Statements 4 (UpdateProductAsync) and 5 (DeleteProductAsync) had their operation order modified to capture old values before UPDATE/DELETE operations, replacing the DECLARE/SET variable pattern used in SQL Server

### Specific items to review:
- **InsertProductAsync:** Uses `lastval()` instead of `SCOPE_IDENTITY()` - ensure the products table has a SERIAL/IDENTITY column in PostgreSQL
- **UpdateProductAsync:** Operations reordered - history INSERT and stats UPDATE happen before the product UPDATE to capture old values via subquery
- **DeleteProductAsync:** Operations reordered - history INSERT and stats UPDATE happen before the product DELETE to capture old values via subquery
- **GetLowStockProductsAsync:** Added `::numeric` cast to prevent integer division truncation in PostgreSQL
