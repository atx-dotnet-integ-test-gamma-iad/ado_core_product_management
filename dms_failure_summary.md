# DMS Conversion Failure Summary
## Date: 2026-02-27

## DMS Error
All 7 SQL statements from ProductRepository.cs failed DMS conversion with the same error:
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Database**: `ProductManagement`
- **Schema**: `dbo`

## Resolution
All statements were manually converted using lowercase schema object names for PostgreSQL compatibility.
Conversion method: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

## Key Conversions Applied
| MS SQL Construct | PostgreSQL Equivalent |
|---|---|
| SCOPE_IDENTITY() | RETURNING clause |
| GETDATE() | NOW() |
| DECLARE @var / SET @var | DO $$ DECLARE v_var ... BEGIN ... END $$ |
| BEGIN TRANSACTION / COMMIT | DO $$ block (implicit transaction) |
| Schema objects (PascalCase) | Lowercase names |
| ROUND with int division | Cast to ::numeric for proper division |
| NVARCHAR | VARCHAR |
| IDENTITY(1,1) | SERIAL |

## SQL Equivalency Results
All 7 statement pairs returned ERROR from the SQL Equivalency tool.
Error: `'uniqueID'` - The tool encountered an internal error during validation.

## Statements Processed
1. GetAllProductsAsync - CTE with AVG/COUNT OVER window functions
2. GetProductByIdAsync - CTE with LAG window function
3. InsertProductAsync - Transaction block with SCOPE_IDENTITY(), GETDATE()
4. UpdateProductAsync - Transaction block with DECLARE, GETDATE()
5. DeleteProductAsync - Transaction block with DECLARE, GETDATE(), CASE
6. GetProductsByPriceRangeAsync - CTE with RANK/PERCENT_RANK window functions
7. GetLowStockProductsAsync - CTE with AVG/MIN/MAX window functions
