# DMS Conversion Log

## Summary
- **Total Statements Attempted**: 7
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7
- **Manual Conversions Required**: 7
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

## DMS Failure Details
All 7 statements failed with the same error. The DMS service metadata model creation is stuck in "RECEIVED" status, preventing any SQL conversion. Multiple retry attempts with increased poll intervals (up to 50 attempts at 20s intervals) did not resolve the issue.

---

## Statement 1: GetAllProductsAsync

### DMS Attempt
- **Timestamp**: 2026-04-29T13:57:07
- **Schema**: dbo
- **Status**: ERROR
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

### Manual Conversion
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - All table names lowercased: `Products` → `products`
  - All column names lowercased: `ProductId` → `productid`, `Price` → `price`, etc.
  - CTE alias lowercased: `ProductStats` → `productstats`
  - Window functions (AVG OVER, COUNT OVER) - no syntax change needed for PostgreSQL
  - CASE expressions - no syntax change needed for PostgreSQL
  - ROUND function - no syntax change needed for PostgreSQL
  - INNER JOIN syntax - no change needed

---

## Statement 2: GetProductByIdAsync

### DMS Attempt
- **Timestamp**: 2026-04-29T13:57:58
- **Schema**: dbo
- **Status**: ERROR
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

### Manual Conversion
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - All table names lowercased: `Products` → `products`
  - All column names lowercased: `ProductId` → `productid`, `ModifiedDate` → `modifieddate`, etc.
  - CTE alias lowercased: `ProductHistory` → `producthistory`
  - LAG window function - no syntax change needed for PostgreSQL
  - CASE expressions - no syntax change needed for PostgreSQL
  - ROUND function - no syntax change needed for PostgreSQL
  - LEFT JOIN syntax - no change needed
  - Parameter `@ProductId` preserved for C# parameterization

---

## Statement 3: InsertProductAsync

### DMS Attempt
- **Timestamp**: 2026-04-29T13:58:12
- **Schema**: dbo
- **Status**: ERROR
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

### Manual Conversion
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - All table names lowercased: `Products` → `products`, `ProductHistory` → `producthistory`, `ProductStats` → `productstats`
  - All column names lowercased
  - `SCOPE_IDENTITY()` → `RETURNING productid` clause on INSERT
  - `GETDATE()` → `NOW()`
  - `DECLARE @NewProductId INT` → removed (handled by RETURNING in C#)
  - `SET @NewProductId = SCOPE_IDENTITY()` → removed (replaced by RETURNING)
  - `BEGIN TRANSACTION`/`COMMIT` → Managed via C# NpgsqlTransaction
  - Restructured into separate SQL commands for C# execution within a transaction

---

## Statement 4: UpdateProductAsync

### DMS Attempt
- **Timestamp**: 2026-04-29T13:58:28
- **Schema**: dbo
- **Status**: ERROR
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

### Manual Conversion
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - All table names lowercased: `Products` → `products`, `ProductHistory` → `producthistory`, `ProductStats` → `productstats`
  - All column names lowercased
  - `DECLARE @OldPrice DECIMAL(18,2)` / `DECLARE @OldStock INT` → Handled in C# with separate SELECT
  - `SELECT @OldPrice = Price, @OldStock = StockQuantity` → `SELECT price, stockquantity` (values read in C#)
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION`/`COMMIT` → Managed via C# NpgsqlTransaction
  - Restructured into separate SQL commands for C# execution within a transaction

---

## Statement 5: DeleteProductAsync

### DMS Attempt
- **Timestamp**: 2026-04-29T13:58:41
- **Schema**: dbo
- **Status**: ERROR
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

### Manual Conversion
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - All table names lowercased: `Products` → `products`, `ProductHistory` → `producthistory`, `ProductStats` → `productstats`
  - All column names lowercased
  - `DECLARE @OldPrice DECIMAL(18,2)` / `DECLARE @OldStock INT` → Handled in C# with separate SELECT
  - `SELECT @OldPrice = Price, @OldStock = StockQuantity` → `SELECT price, stockquantity` (values read in C#)
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION`/`COMMIT` → Managed via C# NpgsqlTransaction
  - CASE expression in UPDATE - no syntax change needed for PostgreSQL
  - Restructured into separate SQL commands for C# execution within a transaction

---

## Statement 6: GetProductsByPriceRangeAsync

### DMS Attempt
- **Timestamp**: 2026-04-29T13:58:56
- **Schema**: dbo
- **Status**: ERROR
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

### Manual Conversion
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - All table names lowercased: `Products` → `products`
  - All column names lowercased: `Price` → `price`, etc.
  - CTE alias lowercased: `RankedProducts` → `rankedproducts`
  - RANK(), PERCENT_RANK() window functions - no syntax change needed for PostgreSQL
  - BETWEEN - no syntax change needed
  - CASE expression - no syntax change needed
  - Parameters `@MinPrice`, `@MaxPrice` preserved for C# parameterization

---

## Statement 7: GetLowStockProductsAsync

### DMS Attempt
- **Timestamp**: 2026-04-29T13:59:11
- **Schema**: dbo
- **Status**: ERROR
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

### Manual Conversion
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - All table names lowercased: `Products` → `products`
  - All column names lowercased: `StockQuantity` → `stockquantity`, etc.
  - CTE alias lowercased: `StockAnalysis` → `stockanalysis`
  - AVG/MIN/MAX window functions - no syntax change needed for PostgreSQL
  - CASE expression - no syntax change needed
  - ROUND function - added explicit `CAST(stockquantity AS DECIMAL)` to prevent integer division truncation
  - Parameter `@Threshold` preserved for C# parameterization
