# DMS Conversion Failure Summary

## DMS Tool Error
All 7 SQL statements failed with the same error when passed through the DMS MCP tool (dms-mcp___statement_conversion_tool):

**Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

**Migration Project**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
**Database**: `ProductManagement`
**Schema**: `dbo`
**Region**: `us-east-1`

## Manual Conversion Applied
Since DMS failed for all statements, manual conversion was applied with the following rules:
- **Reason**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- All schema object names (tables, columns, aliases) converted to lowercase
- `SCOPE_IDENTITY()` → `RETURNING productid` clause with CTE
- `GETDATE()` → `NOW()`
- `DECLARE`/`SET` variable patterns → PostgreSQL CTE-based approach
- `BEGIN TRANSACTION`/`COMMIT` → Managed at application level (Npgsql transaction)
- Window functions (AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK) → Compatible, only lowercase applied
- `ROUND`, `CASE`, `BETWEEN` → Compatible, only lowercase applied
- Integer division in ROUND → Added CAST to numeric for proper behavior

## Statements Processed

| # | Method | DMS Status | Manual Conversion | Key Changes |
|---|--------|-----------|-------------------|-------------|
| 1 | GetAllProductsAsync | FAILED | YES | Lowercase schema objects |
| 2 | GetProductByIdAsync | FAILED | YES | Lowercase schema objects |
| 3 | InsertProductAsync | FAILED | YES | SCOPE_IDENTITY→RETURNING, GETDATE→NOW(), CTE approach |
| 4 | UpdateProductAsync | FAILED | YES | DECLARE/SET→CTE, GETDATE→NOW() |
| 5 | DeleteProductAsync | FAILED | YES | DECLARE/SET→CTE, GETDATE→NOW() |
| 6 | GetProductsByPriceRangeAsync | FAILED | YES | Lowercase schema objects |
| 7 | GetLowStockProductsAsync | FAILED | YES | Lowercase schema objects, CAST for integer division |
