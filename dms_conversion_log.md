# DMS Conversion Log

## Overview

All 7 SQL statements from `DataAccess/ProductRepository.cs` were submitted to the DMS MCP Statement Conversion Tool for conversion from MS SQL Server to PostgreSQL. All attempts failed with the same error. Manual conversion was applied using lowercase schema object names derived from the DMS Schema Mapping Tool.

**DMS Tool:** `dms-mcp___statement_conversion_tool`
**Migration Project:** `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
**Database:** `ProductManagement`
**Schema:** `dbo`
**Region:** `us-east-1`
**Server:** `172.31.83.165`

---

## Statement 1: GetAllProductsAsync

### DMS Tool Invocation
- **Timestamp:** 2026-04-19T06:10:45.114563 (1st attempt), 2026-04-19T06:11:00.913619 (2nd attempt)
- **Parameters:** database_name=ProductManagement, schema_name=dbo, server_name=172.31.83.165
- **Max Poll Attempts:** 15 (1st), 30 (2nd)
- **Poll Interval:** 10s (1st), 15s (2nd)

### DMS Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "workflow_steps": [{"step": "create_metadata_model", "status": "started"}]
}
```

### Original MS SQL Statement
```sql
WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT 
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity,
    p.CreatedDate, p.ModifiedDate,
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END,
    p.Name
```

### Manual Conversion (PostgreSQL)
```sql
WITH productstats_cte AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT 
    p.productid, p.name, p.description, p.price, p.stockquantity,
    p.createddate, p.modifieddate,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END,
    p.name
```

### Manual Intervention Reasoning
- DMS failed; applied lowercase schema mapping from DMS Schema Mapping Tool
- CTE renamed from `ProductStats` to `productstats_cte` to avoid conflict with the `productstats` table
- Window functions, CASE, ROUND are PostgreSQL-compatible

---

## Statement 2: GetProductByIdAsync

### DMS Tool Invocation
- **Timestamp:** 2026-04-19T06:11:34.550708
- **Parameters:** database_name=ProductManagement, schema_name=dbo, server_name=172.31.83.165

### DMS Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
}
```

### Original MS SQL Statement
```sql
WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = @ProductId
)
SELECT 
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity,
    p.CreatedDate, p.ModifiedDate,
    ph.PreviousPrice, ph.PreviousStock,
    CASE 
        WHEN ph.PreviousPrice IS NOT NULL THEN 
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
```

### Manual Conversion (PostgreSQL)
```sql
WITH producthistory_cte AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = @ProductId
)
SELECT 
    p.productid, p.name, p.description, p.price, p.stockquantity,
    p.createddate, p.modifieddate,
    ph.previousprice, ph.previousstock,
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

### Manual Intervention Reasoning
- DMS failed; applied lowercase schema mapping
- CTE renamed from `ProductHistory` to `producthistory_cte` to avoid conflict with the `producthistory` table
- LAG window function is PostgreSQL-compatible

---

## Statement 3: InsertProductAsync

### DMS Tool Invocation
- **Timestamp:** 2026-04-19T06:11:49.140769
- **Parameters:** database_name=ProductManagement, schema_name=dbo, server_name=172.31.83.165

### DMS Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
}
```

### Original MS SQL Statement
```sql
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;
```

### Manual Conversion (PostgreSQL)
```sql
BEGIN;
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (LASTVAL(), 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());
    
    UPDATE productstats
    SET totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1;
COMMIT;

SELECT LASTVAL();
```

### Manual Intervention Reasoning
- DMS failed; applied lowercase schema mapping
- `DECLARE @NewProductId` removed (not needed in PostgreSQL)
- `SCOPE_IDENTITY()` → `LASTVAL()` (PostgreSQL equivalent for last identity value)
- `GETDATE()` → `clock_timestamp()` (per DMS schema mapping default)
- `BEGIN TRANSACTION` → `BEGIN;`
- `SELECT @NewProductId` → `SELECT LASTVAL()`

---

## Statement 4: UpdateProductAsync

### DMS Tool Invocation
- **Timestamp:** 2026-04-19T06:12:03.238987
- **Parameters:** database_name=ProductManagement, schema_name=dbo, server_name=172.31.83.165

### DMS Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
}
```

### Original MS SQL Statement
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products WHERE ProductId = @ProductId;
    
    UPDATE Products
    SET Name = @Name, Description = @Description, Price = @Price,
        StockQuantity = @StockQuantity, ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
```

### Manual Conversion (PostgreSQL)
```sql
BEGIN;
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', price, @Price, stockquantity, @StockQuantity, clock_timestamp()
    FROM products WHERE productid = @ProductId;
    
    UPDATE productstats
    SET averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = clock_timestamp()
    WHERE statid = 1;

    UPDATE products
    SET name = @Name, description = @Description, price = @Price,
        stockquantity = @StockQuantity, modifieddate = clock_timestamp()
    WHERE productid = @ProductId;
COMMIT;
```

### Manual Intervention Reasoning
- DMS failed; applied lowercase schema mapping
- `DECLARE @OldPrice`/`@OldStock` removed (T-SQL variables not supported in PostgreSQL plain SQL)
- Old values captured via `INSERT...SELECT` subquery (captures price/stockquantity before UPDATE)
- Stats update uses subquery `(SELECT price FROM products ...)` for old price
- Operation order changed: history INSERT and stats UPDATE before product UPDATE to capture old values
- `GETDATE()` → `clock_timestamp()`

---

## Statement 5: DeleteProductAsync

### DMS Tool Invocation
- **Timestamp:** 2026-04-19T06:12:16.382494
- **Parameters:** database_name=ProductManagement, schema_name=dbo, server_name=172.31.83.165

### DMS Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
}
```

### Original MS SQL Statement
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
    DELETE FROM Products WHERE ProductId = @ProductId;
    
    UPDATE ProductStats
    SET TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
```

### Manual Conversion (PostgreSQL)
```sql
BEGIN;
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', price, NULL, stockquantity, NULL, clock_timestamp()
    FROM products WHERE productid = @ProductId;
    
    DELETE FROM products WHERE productid = @ProductId;
    
    UPDATE productstats
    SET totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT oldprice FROM producthistory WHERE productid = @ProductId AND action = 'DELETE' ORDER BY actiondate DESC LIMIT 1)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
COMMIT;
```

### Manual Intervention Reasoning
- DMS failed; applied lowercase schema mapping
- `DECLARE @OldPrice`/`@OldStock` removed
- Old values captured via `INSERT...SELECT` from products before DELETE
- Stats update retrieves old price from producthistory (just inserted above)
- `GETDATE()` → `clock_timestamp()`
- CASE expression preserved (compatible)

---

## Statement 6: GetProductsByPriceRangeAsync

### DMS Tool Invocation
- **Timestamp:** 2026-04-19T06:12:30.274731
- **Parameters:** database_name=ProductManagement, schema_name=dbo, server_name=172.31.83.165

### DMS Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
}
```

### Original MS SQL Statement
```sql
WITH RankedProducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.Price) as PriceRank,
           PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*,
    CASE 
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as PriceSegment
FROM RankedProducts rp
ORDER BY rp.PriceRank
```

### Manual Conversion (PostgreSQL)
```sql
WITH rankedproducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.price) as pricerank,
           PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as pricesegment
FROM rankedproducts rp
ORDER BY rp.pricerank
```

### Manual Intervention Reasoning
- DMS failed; applied lowercase schema mapping
- RANK() and PERCENT_RANK() are PostgreSQL-compatible
- BETWEEN clause preserved (compatible)
- All identifiers lowercased

---

## Statement 7: GetLowStockProductsAsync

### DMS Tool Invocation
- **Timestamp:** 2026-04-19T06:12:44.242290
- **Parameters:** database_name=ProductManagement, schema_name=dbo, server_name=172.31.83.165

### DMS Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
}
```

### Original MS SQL Statement
```sql
WITH StockAnalysis AS (
    SELECT p.*, AVG(StockQuantity) OVER() as AvgStock,
           MIN(StockQuantity) OVER() as MinStock,
           MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT sa.*,
    CASE 
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity
```

### Manual Conversion (PostgreSQL)
```sql
WITH stockanalysis AS (
    SELECT p.*, AVG(stockquantity) OVER() as avgstock,
           MIN(stockquantity) OVER() as minstock,
           MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT sa.*,
    CASE 
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity
```

### Manual Intervention Reasoning
- DMS failed; applied lowercase schema mapping
- AVG/MIN/MAX window functions are PostgreSQL-compatible
- Added `CAST(stockquantity AS NUMERIC)` to prevent integer division truncation in ROUND
- CASE expression preserved (compatible)
- All identifiers lowercased
