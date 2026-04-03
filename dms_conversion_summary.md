# DMS Conversion Summary Report

## DMS Tool Status
- **Tool**: dms-mcp___statement_conversion_tool
- **Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Database**: ProductManagement
- **Schema**: dbo
- **Region**: us-east-1

## DMS Failure Details
All 7 SQL statements failed DMS conversion with the same error:
- **Error**: "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}"
- **Attempts**: Multiple attempts were made with varying poll_interval_seconds (10, 15) and max_poll_attempts (15, 25, 30)
- **Statements tested**: Both complex (CTE with window functions) and simple (SELECT ProductId FROM Products) statements failed identically

## Conversion Method Applied
All statements converted using: **DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA**

### Conversion Rules Applied:
1. All schema object names (tables, columns, aliases) converted to lowercase
2. SCOPE_IDENTITY() → RETURNING clause
3. GETDATE() → NOW()
4. DECLARE @variable → Restructured as separate SQL commands with application-level variable handling
5. BEGIN TRANSACTION/COMMIT → Managed via NpgsqlTransaction at the C# application level
6. ROUND() syntax preserved (compatible)
7. CTE syntax preserved (compatible)
8. Window functions (LAG, RANK, PERCENT_RANK, AVG, MIN, MAX OVER()) preserved (compatible)
9. CASE expressions preserved (compatible)
10. Integer division fix: CAST to numeric for proper division in PostgreSQL

## Statement-by-Statement Details

### Statement 1: GetAllProductsAsync
- **Original**: CTE with AVG/COUNT window functions, ROUND, CASE, ORDER BY
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Lowercased all schema objects. ROUND and window functions are PostgreSQL-compatible.

### Statement 2: GetProductByIdAsync
- **Original**: CTE with LAG window functions, ROUND, CASE
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Lowercased all schema objects. LAG window function is PostgreSQL-compatible.

### Statement 3: InsertProductAsync
- **Original**: DECLARE, BEGIN TRANSACTION, INSERT with SCOPE_IDENTITY(), GETDATE(), COMMIT
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Replaced SCOPE_IDENTITY() with RETURNING clause. Replaced GETDATE() with NOW(). Restructured single transaction block into separate commands managed by C# NpgsqlTransaction. Lowercased all schema objects.

### Statement 4: UpdateProductAsync
- **Original**: BEGIN TRANSACTION, DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE(), COMMIT
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Replaced DECLARE with application-level variable reading. Replaced GETDATE() with NOW(). Restructured into separate commands. Lowercased all schema objects.

### Statement 5: DeleteProductAsync
- **Original**: BEGIN TRANSACTION, DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE, GETDATE(), COMMIT
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Replaced DECLARE with application-level variable reading. Replaced GETDATE() with NOW(). Restructured into separate commands. Lowercased all schema objects.

### Statement 6: GetProductsByPriceRangeAsync
- **Original**: CTE with RANK/PERCENT_RANK window functions, BETWEEN, CASE
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Lowercased all schema objects. RANK/PERCENT_RANK window functions are PostgreSQL-compatible.

### Statement 7: GetLowStockProductsAsync
- **Original**: CTE with AVG/MIN/MAX window functions, CASE, ROUND with integer division
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Lowercased all schema objects. Added CAST(stockquantity AS numeric) to fix integer division in ROUND. Window functions are PostgreSQL-compatible.
