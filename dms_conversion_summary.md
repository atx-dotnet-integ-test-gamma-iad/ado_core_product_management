# DMS Conversion Failure Summary Log

## Tool: dms-mcp___statement_conversion_tool
## Migration Project: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
## Database: ProductManagement
## Schema: dbo
## Region: us-east-1

## Error Details
All 7 SQL statements failed DMS conversion with the same error:
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Workflow Step**: create_metadata_model (started but failed)

## Manual Conversion Applied
All statements were manually converted using the rule: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Conversion Rules Applied:
1. All schema object names (tables, columns, aliases) converted to lowercase
2. `SCOPE_IDENTITY()` replaced with PostgreSQL `RETURNING productid` via writable CTEs
3. `GETDATE()` replaced with `NOW()`
4. `DECLARE @var / SET @var` replaced with CTE-based approach for PostgreSQL compatibility
5. `BEGIN TRANSACTION / COMMIT` replaced with single atomic writable CTE statements
6. String types: NVARCHAR -> VARCHAR (in table definitions)
7. Identity columns: INT IDENTITY(1,1) -> SERIAL
8. DateTime: DATETIME -> TIMESTAMP

## Statements Processed

| # | Method | DMS Timestamp | Conversion Approach |
|---|--------|---------------|---------------------|
| 1 | GetAllProductsAsync | 2026-06-06T21:24:03 | Lowercase schema objects |
| 2 | GetProductByIdAsync | 2026-06-06T21:24:06 | Lowercase schema objects |
| 3 | InsertProductAsync | 2026-06-06T21:24:09 | Writable CTEs + RETURNING + NOW() |
| 4 | UpdateProductAsync | 2026-06-06T21:24:12 | Writable CTEs + NOW() |
| 5 | DeleteProductAsync | 2026-06-06T21:24:14 | Writable CTEs + NOW() |
| 6 | GetProductsByPriceRangeAsync | 2026-06-06T21:24:29 | Lowercase schema objects |
| 7 | GetLowStockProductsAsync | 2026-06-06T21:24:31 | Lowercase schema objects |

## SQL Equivalency Validation
All 7 statement pairs were submitted to the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence).
All returned ERROR with: {'equivalence_status': 'ERROR', 'error': "'uniqueID'"}
Per transformation rules, these are marked as ERROR (not equivalent or non-equivalent by agent judgment).
