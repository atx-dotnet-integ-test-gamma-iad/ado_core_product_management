# DMS Conversion Failure Summary

## Overview
All 7 SQL statements failed DMS conversion with the same error.

## DMS Error
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

## Statements Requiring Manual Conversion

All statements were manually converted using the rule: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Conversion Rules Applied:
1. All schema object names (tables, columns, aliases) converted to lowercase
2. SCOPE_IDENTITY() replaced with PostgreSQL RETURNING clause via writable CTEs
3. GETDATE() replaced with NOW()
4. BEGIN TRANSACTION/COMMIT replaced with writable CTEs for atomic operations
5. DECLARE @variable / SET @variable replaced with CTE subqueries
6. Integer division fix: added ::numeric cast where needed (Statement 7)

### Statement Summary:
| # | Method | Key Changes |
|---|--------|-------------|
| 1 | GetAllProductsAsync | Lowercase only - CTE with window functions compatible |
| 2 | GetProductByIdAsync | Lowercase only - LAG window function compatible |
| 3 | InsertProductAsync | SCOPE_IDENTITY() → RETURNING, GETDATE() → NOW(), transaction → writable CTE |
| 4 | UpdateProductAsync | DECLARE/SET → CTE subquery, GETDATE() → NOW(), transaction → writable CTE |
| 5 | DeleteProductAsync | DECLARE/SET → CTE subquery, GETDATE() → NOW(), transaction → writable CTE |
| 6 | GetProductsByPriceRangeAsync | Lowercase only - RANK/PERCENT_RANK compatible |
| 7 | GetLowStockProductsAsync | Lowercase + ::numeric cast for integer division |

## SQL Equivalency Validation
All 7 statement pairs were submitted to the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence).
All 7 returned ERROR status with error: "'uniqueID'"
This appears to be a tool-level issue unrelated to the SQL statements themselves.
