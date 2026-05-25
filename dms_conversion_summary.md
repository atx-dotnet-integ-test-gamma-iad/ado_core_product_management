# DMS Conversion Summary

## Overview
All 7 SQL statements were submitted to the DMS MCP tool for conversion. All failed with the same error.

## DMS Error
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

## Statements Processed

| # | Method | DMS Status | Manual Conversion Applied |
|---|--------|-----------|--------------------------|
| 1 | GetAllProductsAsync | FAILED | Yes - lowercase schema |
| 2 | GetProductByIdAsync | FAILED | Yes - lowercase schema |
| 3 | InsertProductAsync | FAILED | Yes - lowercase schema + RETURNING/CTE pattern |
| 4 | UpdateProductAsync | FAILED | Yes - lowercase schema + CTE pattern |
| 5 | DeleteProductAsync | FAILED | Yes - lowercase schema + CTE pattern |
| 6 | GetProductsByPriceRangeAsync | FAILED | Yes - lowercase schema |
| 7 | GetLowStockProductsAsync | FAILED | Yes - lowercase schema + numeric cast |

## Manual Conversion Rules Applied (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)

1. All schema object names converted to lowercase (tables, columns, aliases)
2. `SCOPE_IDENTITY()` → `RETURNING productid` with data-modifying CTEs
3. `GETDATE()` → `NOW()`
4. `BEGIN TRANSACTION/COMMIT` with `DECLARE` variables → data-modifying CTEs with subqueries
5. `ROUND(int/int)` → `ROUND(int::numeric / int)` for integer division cases
6. T-SQL transaction blocks restructured as PostgreSQL data-modifying CTEs
