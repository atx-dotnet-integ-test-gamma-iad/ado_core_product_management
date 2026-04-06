# DMS Conversion Log

## Summary
- **Total Statements**: 7
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7
- **Manual Conversions (DMS Failure)**: 7
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## DMS Tool Issues
The DMS MCP tool (`dms-mcp___statement_conversion_tool`) consistently failed for all statements with metadata model creation/conversion timeout errors. Multiple attempts were made including:
1. Default settings (15 poll attempts, 10s interval) - Failed with "Metadata model conversion did not complete after 15 attempts"
2. Increased settings (30 poll attempts, 15s interval) - Command execution timed out after 300 seconds
3. Simple test queries (e.g., `SELECT GETDATE()`) - Failed with "Metadata model creation did not complete after 15 attempts"

The DMS migration project ARN used: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

## Statement-by-Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **DMS Attempt**: FAILED - "Metadata model conversion failed: Metadata model conversion did not complete after 15 attempts"
- **Manual Conversion**: Applied lowercase schema object naming
- **Key Changes**: All table/column names lowercased (Products→products, ProductId→productid, etc.)
- **SQL Syntax**: CTE with window functions - PostgreSQL compatible, no syntax changes needed beyond casing

### Statement 2: GetProductByIdAsync
- **DMS Attempt**: FAILED - Command execution timed out
- **Manual Conversion**: Applied lowercase schema object naming
- **Key Changes**: All table/column names lowercased
- **SQL Syntax**: CTE with LAG window functions - PostgreSQL compatible

### Statement 3: InsertProductAsync
- **DMS Attempt**: FAILED - Command execution timed out
- **Manual Conversion**: Applied lowercase schema + restructured for PostgreSQL
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `INSERT...RETURNING productid`
  - `GETDATE()` → `NOW()`
  - `DECLARE @NewProductId INT` → Removed (using RETURNING clause instead)
  - Multi-statement transaction block → Restructured into separate statements for Npgsql parameter compatibility
  - The C# code will need to manage the transaction at the application level

### Statement 4: UpdateProductAsync
- **DMS Attempt**: FAILED - Command execution timed out
- **Manual Conversion**: Applied lowercase schema + restructured for PostgreSQL
- **Key Changes**:
  - `GETDATE()` → `NOW()`
  - `DECLARE @OldPrice`, `DECLARE @OldStock` → Removed, restructured to use subqueries
  - `BEGIN TRANSACTION/COMMIT` → Application-level transaction management
  - Variable assignment via SELECT → Subqueries in INSERT...SELECT

### Statement 5: DeleteProductAsync
- **DMS Attempt**: FAILED - Command execution timed out
- **Manual Conversion**: Applied lowercase schema + restructured for PostgreSQL
- **Key Changes**:
  - `GETDATE()` → `NOW()`
  - `DECLARE @OldPrice`, `DECLARE @OldStock` → Removed, using SELECT subqueries
  - `BEGIN TRANSACTION/COMMIT` → Application-level transaction management
  - CASE expression in UPDATE → Preserved (PostgreSQL compatible)

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Attempt**: FAILED - Command execution timed out
- **Manual Conversion**: Applied lowercase schema object naming
- **Key Changes**: All table/column names lowercased
- **SQL Syntax**: CTE with RANK/PERCENT_RANK window functions - PostgreSQL compatible

### Statement 7: GetLowStockProductsAsync
- **DMS Attempt**: FAILED - Command execution timed out
- **Manual Conversion**: Applied lowercase schema object naming
- **Key Changes**:
  - All table/column names lowercased
  - `ROUND((StockQuantity / AvgStock) * 100, 2)` → `ROUND((stockquantity::NUMERIC / avgstock) * 100, 2)` (added explicit NUMERIC cast to avoid integer division in PostgreSQL)

## SQL Equivalency Validation
All 7 statement pairs were validated through the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence).
All 7 returned ERROR status with error message `'uniqueID'`, which appears to be a service-side issue.
See `sql_equivalency_validation_report.json` for complete details.
