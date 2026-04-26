# DMS Conversion Failure Summary
# ================================
# All 7 SQL statements failed DMS conversion with the same error.
# Manual conversion was applied using lowercase schema object naming for PostgreSQL compatibility.

## DMS Error (consistent across all 7 statements):
- Status: error
- Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- Migration Project: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- Schema: dbo
- Database: ProductManagement

## Statements Affected:
1. GetAllProductsAsync - CTE with window functions, INNER JOIN
2. GetProductByIdAsync - CTE with LAG window functions, LEFT JOIN
3. InsertProductAsync - Transaction block with SCOPE_IDENTITY(), GETDATE()
4. UpdateProductAsync - Transaction block with DECLARE, GETDATE()
5. DeleteProductAsync - Transaction block with DECLARE, GETDATE(), CASE/WHEN
6. GetProductsByPriceRangeAsync - CTE with RANK/PERCENT_RANK, BETWEEN
7. GetLowStockProductsAsync - CTE with AVG/MIN/MAX window functions

## Manual Conversion Rules Applied:
- All schema object names (tables, columns, aliases) converted to lowercase
- SCOPE_IDENTITY() → RETURNING clause
- GETDATE() → NOW()
- DECLARE @var / SET @var → Application-level variable management or restructured queries
- BEGIN TRANSACTION / COMMIT → Application-level transaction management (NpgsqlTransaction)
- Integer division fix: added ::numeric cast for ROUND operations on integer columns
- SQL Server parameter syntax (@param) preserved as Npgsql supports this syntax

## Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
