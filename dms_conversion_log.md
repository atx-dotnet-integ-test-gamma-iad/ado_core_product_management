# DMS Conversion Log

## Overview

All 7 SQL statements from `DataAccess/ProductRepository.cs` were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`).

**Tool Configuration:**
- migration_project_identifier: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- schema_name: `dbo`
- database_name: `ProductManagement`
- region: `us-east-1`

**Result: ALL 7 calls FAILED with the same error.**

---

## Statement 1: GetAllProductsAsync

**Source File:** `DataAccess/ProductRepository.cs`
**Method:** `GetAllProductsAsync()`

**Original SQL:**
```sql
WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name
```

**DMS Output:**
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-04-30T02:09:27.573761"
}
```

**Manual Conversion (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA):**
```sql
WITH productstats AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory,
    ROUND(CAST(p.price AS numeric) / CAST(ps.avgprice AS numeric) * 100, 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name
```

**Conversion Notes:** Added CAST to numeric for ROUND division. Lowercase all schema objects.

---

## Statement 2: GetProductByIdAsync

**Source File:** `DataAccess/ProductRepository.cs`
**Method:** `GetProductByIdAsync()`

**Original SQL:**
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
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    ph.PreviousPrice,
    ph.PreviousStock,
    CASE 
        WHEN ph.PreviousPrice IS NOT NULL THEN 
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
```

**DMS Output:**
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-04-30T02:10:30.039889"
}
```

**Manual Conversion (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA):**
```sql
WITH producthistory AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = @ProductId
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    ph.previousprice,
    ph.previousstock,
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(CAST((p.price - ph.previousprice) AS numeric) / CAST(ph.previousprice AS numeric) * 100, 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

**Conversion Notes:** Added CAST to numeric for ROUND division. Lowercase all schema objects.

---

## Statement 3: InsertProductAsync

**Source File:** `DataAccess/ProductRepository.cs`
**Method:** `InsertProductAsync()`

**Original SQL:**
```sql
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;
```

**DMS Output:**
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-04-30T02:10:44.201757"
}
```

**Manual Conversion (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA):**
```sql
BEGIN;
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (currval(pg_get_serial_sequence('products', 'productid')), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

SELECT currval(pg_get_serial_sequence('products', 'productid'));
```

**Conversion Notes:** SCOPE_IDENTITY() → currval(pg_get_serial_sequence()). GETDATE() → NOW(). DECLARE/SET eliminated. BEGIN TRANSACTION → BEGIN.

---

## Statement 4: UpdateProductAsync

**Source File:** `DataAccess/ProductRepository.cs`
**Method:** `UpdateProductAsync()`

**Original SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
```

**DMS Output:**
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-04-30T02:10:57.809471"
}
```

**Manual Conversion (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA):**
```sql
BEGIN;
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'UPDATE', price, @Price, stockquantity, @StockQuantity, NOW()
    FROM products
    WHERE productid = @ProductId;
    
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;

    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
COMMIT;
```

**Conversion Notes:** DECLARE variables eliminated. Operations reordered: INSERT history first (using SELECT to capture old values), then UPDATE stats, then UPDATE product. GETDATE() → NOW().

---

## Statement 5: DeleteProductAsync

**Source File:** `DataAccess/ProductRepository.cs`
**Method:** `DeleteProductAsync()`

**Original SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
```

**DMS Output:**
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-04-30T02:11:11.158678"
}
```

**Manual Conversion (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA):**
```sql
BEGIN;
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, NOW()
    FROM products
    WHERE productid = @ProductId;
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;

    DELETE FROM products 
    WHERE productid = @ProductId;
COMMIT;
```

**Conversion Notes:** DECLARE variables eliminated. Operations reordered: INSERT history first, UPDATE stats second, DELETE last. GETDATE() → NOW().

---

## Statement 6: GetProductsByPriceRangeAsync

**Source File:** `DataAccess/ProductRepository.cs`
**Method:** `GetProductsByPriceRangeAsync()`

**Original SQL:**
```sql
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as PriceSegment
FROM RankedProducts rp
ORDER BY rp.PriceRank
```

**DMS Output:**
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-04-30T02:11:26.148989"
}
```

**Manual Conversion (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA):**
```sql
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as pricesegment
FROM rankedproducts rp
ORDER BY rp.pricerank
```

**Conversion Notes:** Lowercase schema objects only. RANK(), PERCENT_RANK(), BETWEEN syntax compatible with PostgreSQL.

---

## Statement 7: GetLowStockProductsAsync

**Source File:** `DataAccess/ProductRepository.cs`
**Method:** `GetLowStockProductsAsync()`

**Original SQL:**
```sql
WITH StockAnalysis AS (
    SELECT 
        p.*,
        AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock,
        MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT 
    sa.*,
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

**DMS Output:**
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-04-30T02:11:41.488777"
}
```

**Manual Conversion (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA):**
```sql
WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT 
    sa.*,
    CASE 
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND(CAST(stockquantity AS numeric) / CAST(avgstock AS numeric) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity
```

**Conversion Notes:** Added CAST to numeric for ROUND division (integer division in PostgreSQL would truncate). Lowercase all schema objects.
