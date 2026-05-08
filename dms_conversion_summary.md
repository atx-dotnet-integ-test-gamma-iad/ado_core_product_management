# DMS Conversion Failure Summary Log

## Overview
All 7 SQL statements were submitted to the DMS MCP tool (dms-mcp___statement_conversion_tool) for conversion.
All 7 statements failed with the same error.

## Error Details
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Schema**: dbo
- **All timestamps**: 2026-05-08T10:13:46 through 2026-05-08T10:14:26

## Manual Conversion Applied
Since DMS failed for all statements, manual conversion was applied following the rule:
**DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA**

### Conversion Rules Applied:
1. All schema object names (tables, columns, CTEs, aliases) converted to lowercase
2. `SCOPE_IDENTITY()` → `lastval()` with `RETURNING` clause
3. `GETDATE()` → `NOW()`
4. `BEGIN TRANSACTION` / `COMMIT` → `BEGIN` / `COMMIT` or `DO $$ ... END $$` blocks
5. `DECLARE @Variable TYPE` → PL/pgSQL `DECLARE` block variables
6. `SET @Variable = value` → PL/pgSQL assignment
7. `SELECT @Variable = column` → `SELECT column INTO variable`
8. `NVARCHAR(n)` → `VARCHAR(n)` in schema
9. `NVARCHAR(MAX)` → `TEXT` in schema
10. `DATETIME` → `TIMESTAMP` in schema
11. `INT IDENTITY(1,1)` → `SERIAL` in schema
12. Integer division cast to `::numeric` for ROUND operations where needed

## SQL Equivalency Validation
All 7 statement pairs were submitted to the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence).
All 7 returned ERROR status with error "'uniqueID'".

## Statements Processed

| # | Method | Source File | DMS Status | Equivalency Status |
|---|--------|-------------|------------|-------------------|
| 1 | GetAllProductsAsync | ProductRepository.cs | FAILED | ERROR |
| 2 | GetProductByIdAsync | ProductRepository.cs | FAILED | ERROR |
| 3 | InsertProductAsync | ProductRepository.cs | FAILED | ERROR |
| 4 | UpdateProductAsync | ProductRepository.cs | FAILED | ERROR |
| 5 | DeleteProductAsync | ProductRepository.cs | FAILED | ERROR |
| 6 | GetProductsByPriceRangeAsync | ProductRepository.cs | FAILED | ERROR |
| 7 | GetLowStockProductsAsync | ProductRepository.cs | FAILED | ERROR |
