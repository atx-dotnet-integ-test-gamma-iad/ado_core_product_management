# Migration Report: MS SQL Server to PostgreSQL

## Project: AdoCore
## Date: 2026-05-06

---

## Executive Summary

This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating database access code, and modifying configuration settings to use PostgreSQL.

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention (DMS failed) | 7 |
| Validated as equivalent (by SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| With equivalency validation errors | 7 |

### DMS Tool Status
- **Tool**: dms-mcp___statement_conversion_tool
- **Error**: All 7 statements failed with: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Fallback**: Manual conversion applied using `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` methodology

### SQL Equivalency Tool Status
- **Tool**: sql-equivalency___validate_sql_equivalence
- **Error**: All 7 statement pairs returned ERROR with: `'uniqueID'`
- **Note**: Per transformation rules, all equivalency statuses marked as ERROR since the tool returned errors

---

## Statements Requiring Manual Review

All 7 statements require manual review due to both DMS conversion failure and SQL Equivalency tool errors:

### Statement 1: GetAllProductsAsync
- **Source**: DataAccess/ProductRepository.cs
- **Type**: CTE with AVG/COUNT window functions
- **Conversion**: Straightforward lowercase conversion, window functions compatible
- **Risk**: Low - PostgreSQL supports same window function syntax

### Statement 2: GetProductByIdAsync
- **Source**: DataAccess/ProductRepository.cs
- **Type**: CTE with LAG window function
- **Conversion**: Straightforward lowercase conversion
- **Risk**: Low - PostgreSQL supports LAG() identically

### Statement 3: InsertProductAsync
- **Source**: DataAccess/ProductRepository.cs
- **Type**: Transaction block with SCOPE_IDENTITY()
- **Conversion**: Restructured to writable CTE with RETURNING clause
- **Risk**: Medium - Significant structural change from transaction block to writable CTE

### Statement 4: UpdateProductAsync
- **Source**: DataAccess/ProductRepository.cs
- **Type**: Transaction block with DECLARE variables
- **Conversion**: Restructured to writable CTE with old_values subquery
- **Risk**: Medium - Variable declarations replaced with CTE-based approach

### Statement 5: DeleteProductAsync
- **Source**: DataAccess/ProductRepository.cs
- **Type**: Transaction block with DECLARE variables
- **Conversion**: Restructured to writable CTE with old_values subquery
- **Risk**: Medium - Variable declarations replaced with CTE-based approach

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: DataAccess/ProductRepository.cs
- **Type**: CTE with RANK/PERCENT_RANK window functions
- **Conversion**: Straightforward lowercase conversion
- **Risk**: Low - PostgreSQL supports same window function syntax

### Statement 7: GetLowStockProductsAsync
- **Source**: DataAccess/ProductRepository.cs
- **Type**: CTE with AVG/MIN/MAX window functions
- **Conversion**: Lowercase + CAST for integer division fix
- **Risk**: Low - Added explicit CAST for correct numeric division

---

## Code Changes Summary

### Package References (AdoCore.csproj)
| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.0 |

### Import Directives (DataAccess/ProductRepository.cs)
| Before | After |
|--------|-------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |

### Class Replacements (DataAccess/ProductRepository.cs)
| SQL Server Class | PostgreSQL (Npgsql) Class | Occurrences |
|------------------|---------------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 (field, method return, constructor) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per SQL method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader) |

### Connection Strings (appsettings.json)
| Parameter | Before | After |
|-----------|--------|-------|
| Server identifier | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `True` | Removed (not applicable) |
| TrustServerCertificate | `True` | Removed (not applicable) |

### SQL Syntax Conversions
| MS SQL Feature | PostgreSQL Equivalent |
|----------------|---------------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` (in writable CTE) |
| `GETDATE()` | `NOW()` |
| `BEGIN TRANSACTION/COMMIT` | Writable CTEs (single statement) |
| `DECLARE @var / SET @var` | CTE subqueries (old_values pattern) |
| PascalCase schema objects | lowercase schema objects |
| Integer division | `CAST(column AS NUMERIC)` for correct results |

---

## Validation/Exit Criteria Checklist

| Criterion | Status |
|-----------|--------|
| All SQL Server packages replaced with PostgreSQL equivalents | ✅ DONE |
| All SqlConnection/SqlCommand/SqlDataReader replaced with Npgsql | ✅ DONE |
| All SQL statements processed through DMS MCP tool | ✅ DONE (all 7 attempted, all failed) |
| Comprehensive statement catalog exists | ✅ DONE (extracted_statements.sql, converted_statements.sql) |
| All statement pairs validated through SQL Equivalency tool | ✅ DONE (all 7 attempted, all returned ERROR) |
| Comprehensive equivalency report generated | ✅ DONE (sql_equivalency_validation_report.json) |
| No agent judgment used for equivalency determination | ✅ DONE (all marked as ERROR per tool output) |
| DMS failures documented with manual conversion | ✅ DONE (lowercase schema mapping applied) |
| Connection strings updated to PostgreSQL format | ✅ DONE |
| Transaction handling updated for PostgreSQL | ✅ DONE (writable CTEs) |
| Application compiles without errors | ✅ DONE (0 errors, warnings only) |

---

## Artifacts Generated

1. **extracted_statements.sql** - Complete catalog of all 7 original MS SQL statements with source annotations
2. **converted_statements.sql** - Complete catalog of all 7 converted PostgreSQL statements with conversion method
3. **sql_equivalency_validation_report.json** - JSON report with all 7 statement pairs and ERROR status
4. **migration_report.md** - This comprehensive final report

---

## Build Verification

```
Build succeeded.
    10 Warning(s)
    0 Error(s)
```

All warnings are pre-existing nullable reference warnings, not related to the migration.

---

## Recommendations for Manual Testing

1. **Statement 3 (InsertProductAsync)**: The writable CTE approach should be tested to confirm all three operations (INSERT, log history, update stats) execute atomically
2. **Statement 4 (UpdateProductAsync)**: Test that the old_values CTE correctly captures pre-update values
3. **Statement 5 (DeleteProductAsync)**: Test that deletion cascade and stats update work correctly
4. **General**: Verify PostgreSQL connection works with the configured credentials
5. **Performance**: Monitor query execution plans for the CTE-based transactions vs the original transaction block approach
