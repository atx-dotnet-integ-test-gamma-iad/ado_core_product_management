# Migration Report: SQL Server to PostgreSQL

## Summary
This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-03-23  
**Source Database:** Microsoft SQL Server 2019 (ProductManagement)  
**Target Database:** PostgreSQL 13 (postgres)  
**Application Framework:** .NET 9.0 with ADO.NET  

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention after DMS failure | 7 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| Equivalency validation errors | 7 |

### DMS MCP Tool Results
All 7 SQL statements were submitted to the DMS MCP statement conversion tool (`dms-mcp___statement_conversion_tool`). All 7 failed with timeout errors:
- **Error:** "Metadata model creation/conversion failed: Metadata model creation/conversion did not complete after 15 attempts"
- **Root Cause:** DMS infrastructure timeout - the metadata model creation/conversion step consistently exceeded the maximum poll attempts

### Manual Conversion Applied
Since DMS failed for all statements, manual conversion was applied using the rule: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

Key conversions applied:
- `SCOPE_IDENTITY()` → `lastval()`
- `GETDATE()` → `NOW()`
- `BEGIN TRANSACTION` → `BEGIN;`
- `DECLARE @variable` patterns → Replaced with subqueries (PostgreSQL doesn't support inline DECLARE outside DO blocks)
- All schema object names (tables, columns, aliases) → lowercase
- Integer division in `ROUND()` → Added `CAST(... AS NUMERIC)` for PostgreSQL

### SQL Equivalency Validation Results
All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All 7 returned ERROR status:
- **Error:** "'uniqueID'" (infrastructure error in the equivalency tool)
- **Note:** Per the transformation definition, these errors are reported as-is. Agent judgment was NOT used to determine equivalency.

---

## Detailed Statement Inventory

### Statement 1: GetAllProductsAsync
- **Source:** CTE with ProductStats, AVG/COUNT OVER(), INNER JOIN, CASE WHEN, ROUND
- **DMS Status:** FAILED (timeout)
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 2: GetProductByIdAsync
- **Source:** CTE with ProductHistory, LAG OVER(ORDER BY), LEFT JOIN, CASE WHEN, ROUND
- **DMS Status:** FAILED (timeout)
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 3: InsertProductAsync
- **Source:** Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), INSERT into ProductHistory, UPDATE ProductStats, GETDATE()
- **DMS Status:** FAILED (timeout)
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** SCOPE_IDENTITY() → lastval(), GETDATE() → NOW(), BEGIN TRANSACTION → BEGIN;
- **Equivalency Status:** ERROR

### Statement 4: UpdateProductAsync
- **Source:** Transaction block with DECLARE variables, SELECT INTO variables, UPDATE, INSERT into ProductHistory, GETDATE()
- **DMS Status:** FAILED (timeout)
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** DECLARE eliminated (used subqueries), GETDATE() → NOW(), BEGIN TRANSACTION → BEGIN;
- **Equivalency Status:** ERROR

### Statement 5: DeleteProductAsync
- **Source:** Transaction block with DECLARE variables, SELECT INTO variables, INSERT into ProductHistory, DELETE, CASE WHEN, GETDATE()
- **DMS Status:** FAILED (timeout)
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** DECLARE eliminated (used subqueries), GETDATE() → NOW(), BEGIN TRANSACTION → BEGIN;
- **Equivalency Status:** ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Source:** CTE with RankedProducts, RANK/PERCENT_RANK OVER(), BETWEEN, CASE WHEN
- **DMS Status:** FAILED (timeout)
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 7: GetLowStockProductsAsync
- **Source:** CTE with StockAnalysis, AVG/MIN/MAX OVER(), CASE WHEN, ROUND with integer division
- **DMS Status:** FAILED (timeout)
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Added CAST(stockquantity AS NUMERIC) for integer division in ROUND
- **Equivalency Status:** ERROR

---

## File Changes Summary

### Modified Files
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL; SqlClient → Npgsql classes |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | Connection strings: SQL Server → PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Full PostgreSQL conversion (tables, functions, data) |
| `Database/Scripts/01_InitialSetup.sql` | Full PostgreSQL conversion (tables, triggers, functions, indexes, data) |

### New Files (Artifacts)
| File | Description |
|------|-------------|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency report for all 7 statement pairs |
| `dms_failure_summary.sql` | DMS tool failure documentation |
| `migration_report.md` | This report |

---

## Exit Criteria Verification

| Criteria | Status |
|----------|--------|
| All SQL Server packages replaced with PostgreSQL equivalents | ✅ Microsoft.Data.SqlClient → Npgsql |
| All SqlConnection/SqlCommand/SqlDataReader replaced with Npgsql equivalents | ✅ NpgsqlConnection/NpgsqlCommand/NpgsqlDataReader |
| All SQL statements processed through DMS MCP tool | ✅ All 7 submitted (all failed, manual conversion applied) |
| Comprehensive catalog of all SQL statements exists | ✅ extracted_statements.sql + converted_statements.sql |
| All statement pairs validated through SQL Equivalency tool | ✅ All 7 submitted (all returned ERROR due to tool issue) |
| Comprehensive equivalency report generated | ✅ sql_equivalency_validation_report.json |
| No agent judgment used for equivalency | ✅ All statuses from tool output only |
| DMS failures documented | ✅ dms_failure_summary.sql + report details |
| Connection strings updated to PostgreSQL format | ✅ Host/Port/Username/Password format |
| Transaction handling PostgreSQL-compatible | ✅ BEGIN;/COMMIT; syntax |
| Application compiles without errors | ✅ 0 errors, 10 warnings (pre-existing) |

---

## Build Results

```
Build succeeded.
    10 Warning(s)
    0 Error(s)
```

All 10 warnings are pre-existing nullable reference warnings unrelated to the migration.

---

## Statements Requiring Manual Review

All 7 statements should be reviewed for functional correctness since:
1. DMS tool was unavailable for automated conversion verification
2. SQL Equivalency tool returned errors for all pairs
3. Manual conversion was applied based on known MS SQL → PostgreSQL mapping rules

**Priority items for review:**
- **Statements 3, 4, 5** (InsertProductAsync, UpdateProductAsync, DeleteProductAsync): These involved structural changes (DECLARE variables eliminated, replaced with subqueries). The ordering of operations within transactions was adjusted to ensure old values are captured before modifications.
- **Statement 7** (GetLowStockProductsAsync): Added explicit CAST for integer division in PostgreSQL's stricter type system.
