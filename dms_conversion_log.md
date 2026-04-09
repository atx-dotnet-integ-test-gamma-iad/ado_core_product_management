# DMS Conversion Log

## Migration Details
- **Source Database**: Microsoft SQL Server 2019 (ProductManagement)
- **Target Database**: PostgreSQL 13
- **DMS Migration Project ARN**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Conversion Date**: 2026-04-09

## Summary
- **Total Statements**: 7
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7
- **Manual Conversions (DMS Failure)**: 7

## DMS Error Details
All 7 statements failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```
The DMS service was unable to create the metadata model required for SQL statement conversion. This is a service-level issue that affected all conversion attempts.

---

## Statement 1: GetAllProductsAsync

### DMS Tool Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-04-09T08:04:22.239945"
}
```

### Original MS SQL Statement
```sql
WITH ProductStats AS (
    SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average' WHEN p.Price < ps.AvgPrice THEN 'Below Average' ELSE 'Average' END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name
```

### Manual PostgreSQL Conversion
```sql
WITH productstats AS (
    SELECT productid, AVG(price) OVER() as avgprice, COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE WHEN p.price > ps.avgprice THEN 'Above Average' WHEN p.price < ps.avgprice THEN 'Below Average' ELSE 'Average' END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END, p.name
```

### Conversion Notes
- All schema object names converted to lowercase
- SQL syntax is compatible between MS SQL and PostgreSQL (CTE, window functions, CASE, ROUND, INNER JOIN)

---

## Statement 2: GetProductByIdAsync

### DMS Tool Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-04-09T08:05:13.262837"
}
```

### Original MS SQL Statement
```sql
WITH ProductHistory AS (
    SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice, LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products WHERE ProductId = @ProductId
)
SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, ph.PreviousPrice, ph.PreviousStock,
    CASE WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2) ELSE NULL END as PriceChangePercentage
FROM Products p LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId WHERE p.ProductId = @ProductId
```

### Manual PostgreSQL Conversion
```sql
WITH producthistory AS (
    SELECT productid, LAG(price) OVER (ORDER BY modifieddate) as previousprice, LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products WHERE productid = @ProductId
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2) ELSE NULL END as pricechangepercentage
FROM products p LEFT JOIN producthistory ph ON p.productid = ph.productid WHERE p.productid = @ProductId
```

### Conversion Notes
- All schema object names converted to lowercase
- LAG() window function is supported in PostgreSQL
- Parameter syntax @ProductId preserved for Npgsql compatibility

---

## Statement 3: InsertProductAsync

### DMS Tool Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-04-09T08:05:30.415709"
}
```

### Original MS SQL Statement
```sql
DECLARE @NewProductId INT;
BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity) VALUES (@Name, @Description, @Price, @StockQuantity);
    SET @NewProductId = SCOPE_IDENTITY();
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    UPDATE ProductStats SET TotalProducts = TotalProducts + 1, AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1), LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
SELECT @NewProductId;
```

### Manual PostgreSQL Conversion
```sql
BEGIN TRANSACTION;
    INSERT INTO products (name, description, price, stockquantity) VALUES (@Name, @Description, @Price, @StockQuantity);
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    UPDATE productstats SET totalproducts = totalproducts + 1, averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1), lastupdated = NOW() WHERE statid = 1;
COMMIT;
SELECT lastval();
```

### Conversion Notes
- SCOPE_IDENTITY() → lastval() (PostgreSQL equivalent for getting last inserted serial value)
- GETDATE() → NOW() (PostgreSQL equivalent)
- DECLARE @NewProductId removed (using lastval() directly instead of variable assignment)
- All schema object names converted to lowercase

---

## Statement 4: UpdateProductAsync

### DMS Tool Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-04-09T08:05:50.427659"
}
```

### Original MS SQL Statement
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
    UPDATE Products SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE() WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    UPDATE ProductStats SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts, LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

### Manual PostgreSQL Conversion
```sql
BEGIN TRANSACTION;
    UPDATE products SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = NOW() WHERE productid = @ProductId;
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (@ProductId, 'UPDATE', (SELECT price FROM products WHERE productid = @ProductId), @Price, (SELECT stockquantity FROM products WHERE productid = @ProductId), @StockQuantity, NOW());
    UPDATE productstats SET averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts, lastupdated = NOW() WHERE statid = 1;
COMMIT;
```

### Conversion Notes
- DECLARE/SET @variable pattern replaced with subqueries (PostgreSQL doesn't support T-SQL variable declarations in plain SQL)
- GETDATE() → NOW()
- All schema object names converted to lowercase

---

## Statement 5: DeleteProductAsync

### DMS Tool Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-04-09T08:06:07.208200"
}
```

### Original MS SQL Statement
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    DELETE FROM Products WHERE ProductId = @ProductId;
    UPDATE ProductStats SET TotalProducts = TotalProducts - 1, AveragePrice = CASE WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END, LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

### Manual PostgreSQL Conversion
```sql
BEGIN TRANSACTION;
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (@ProductId, 'DELETE', (SELECT price FROM products WHERE productid = @ProductId), NULL, (SELECT stockquantity FROM products WHERE productid = @ProductId), NULL, NOW());
    DELETE FROM products WHERE productid = @ProductId;
    UPDATE productstats SET totalproducts = totalproducts - 1, averageprice = CASE WHEN totalproducts > 1 THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId)) / (totalproducts - 1) ELSE 0 END, lastupdated = NOW() WHERE statid = 1;
COMMIT;
```

### Conversion Notes
- DECLARE/SET @variable pattern replaced with subqueries
- GETDATE() → NOW()
- All schema object names converted to lowercase

---

## Statement 6: GetProductsByPriceRangeAsync

### DMS Tool Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-04-09T08:06:23.106914"
}
```

### Original MS SQL Statement
```sql
WITH RankedProducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.Price) as PriceRank, PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*, CASE WHEN rp.PricePercentile <= 0.25 THEN 'Budget' WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END as PriceSegment
FROM RankedProducts rp ORDER BY rp.PriceRank
```

### Manual PostgreSQL Conversion
```sql
WITH rankedproducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.price) as pricerank, PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*, CASE WHEN rp.pricepercentile <= 0.25 THEN 'Budget' WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END as pricesegment
FROM rankedproducts rp ORDER BY rp.pricerank
```

### Conversion Notes
- All schema object names converted to lowercase
- RANK(), PERCENT_RANK() window functions supported in PostgreSQL
- BETWEEN, CASE supported identically

---

## Statement 7: GetLowStockProductsAsync

### DMS Tool Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-04-09T08:06:39.036984"
}
```

### Original MS SQL Statement
```sql
WITH StockAnalysis AS (
    SELECT p.*, AVG(StockQuantity) OVER() as AvgStock, MIN(StockQuantity) OVER() as MinStock, MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT sa.*, CASE WHEN StockQuantity <= @Threshold THEN 'Critical' WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low' ELSE 'Adequate' END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity
```

### Manual PostgreSQL Conversion
```sql
WITH stockanalysis AS (
    SELECT p.*, AVG(stockquantity) OVER() as avgstock, MIN(stockquantity) OVER() as minstock, MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT sa.*, CASE WHEN stockquantity <= @Threshold THEN 'Critical' WHEN stockquantity <= avgstock * 0.5 THEN 'Low' ELSE 'Adequate' END as stockstatus,
    ROUND((CAST(stockquantity AS DECIMAL) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa WHERE stockquantity <= @Threshold ORDER BY stockquantity
```

### Conversion Notes
- All schema object names converted to lowercase
- Added CAST(stockquantity AS DECIMAL) to ensure proper decimal division in PostgreSQL (integer/integer gives integer in PostgreSQL)
- GETDATE() not used in this statement
