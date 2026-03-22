-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 15
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (all 15)
-- DMS Tool: All 15 statements were passed through DMS MCP tool - all failed
-- DMS failures: Metadata model creation/conversion timeout errors
-- Manual Conversion: All schema object names converted to lowercase for PostgreSQL
-- Key changes: GETDATE() -> NOW(), SCOPE_IDENTITY() -> RETURNING, PascalCase -> lowercase,
--              CAST(x AS DECIMAL) -> CAST(x AS NUMERIC)
-- ============================================================================

-- =============================================================================
-- Statement 1: GetAllProductsAsync - sql
-- Source Method: GetAllProductsAsync()
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- DMS Timestamp: 2026-03-21T23:09:27.308891
-- ORIGINAL MS SQL:
-- WITH ProductStats AS (SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts FROM Products) SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average' WHEN p.Price < ps.AvgPrice THEN 'Below Average' ELSE 'Average' END as PriceCategory, ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage FROM Products p INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name
-- CONVERTED PostgreSQL:
-- =============================================================================
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
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- =============================================================================
-- Statement 2: GetProductByIdAsync - sql
-- Source Method: GetProductByIdAsync(int productId)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation did not complete after 15 attempts
-- DMS Timestamp: 2026-03-21T23:12:12.747720
-- ORIGINAL MS SQL:
-- WITH ProductHistory AS (SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice, LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock FROM Products WHERE ProductId = @ProductId) SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, ph.PreviousPrice, ph.PreviousStock, CASE WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2) ELSE NULL END as PriceChangePercentage FROM Products p LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId WHERE p.ProductId = @ProductId
-- CONVERTED PostgreSQL:
-- =============================================================================
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
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- =============================================================================
-- Statement 3: InsertProductAsync - insertSql
-- Source Method: InsertProductAsync(Product product)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- DMS Timestamp: 2026-03-21T23:16:23.292365
-- Changes: SCOPE_IDENTITY() replaced with RETURNING productid, lowercase schema names
-- ORIGINAL MS SQL:
-- INSERT INTO Products (Name, Description, Price, StockQuantity) VALUES (@Name, @Description, @Price, @StockQuantity); SELECT SCOPE_IDENTITY() AS ProductId
-- CONVERTED PostgreSQL:
-- =============================================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- =============================================================================
-- Statement 4: InsertProductAsync - historySql
-- Source Method: InsertProductAsync(Product product)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation did not complete after 15 attempts
-- DMS Timestamp: 2026-03-21T23:19:08.644620
-- Changes: GETDATE() replaced with NOW(), lowercase schema names
-- ORIGINAL MS SQL:
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE())
-- CONVERTED PostgreSQL:
-- =============================================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- =============================================================================
-- Statement 5: InsertProductAsync - statsSql
-- Source Method: InsertProductAsync(Product product)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- DMS Timestamp: 2026-03-21T23:23:18.761008
-- Changes: GETDATE() replaced with NOW(), lowercase schema names
-- ORIGINAL MS SQL:
-- UPDATE ProductStats SET TotalProducts = TotalProducts + 1, AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1), LastUpdated = GETDATE() WHERE StatId = 1
-- CONVERTED PostgreSQL:
-- =============================================================================
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- =============================================================================
-- Statement 6: UpdateProductAsync - selectSql
-- Source Method: UpdateProductAsync(Product product)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation did not complete after 15 attempts
-- DMS Timestamp: 2026-03-21T23:26:02.129412
-- Changes: Lowercase schema names
-- ORIGINAL MS SQL:
-- SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId
-- CONVERTED PostgreSQL:
-- =============================================================================
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- =============================================================================
-- Statement 7: UpdateProductAsync - updateSql
-- Source Method: UpdateProductAsync(Product product)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- DMS Timestamp: 2026-03-21T23:30:11.923621
-- Changes: GETDATE() replaced with NOW(), lowercase schema names
-- ORIGINAL MS SQL:
-- UPDATE Products SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE() WHERE ProductId = @ProductId
-- CONVERTED PostgreSQL:
-- =============================================================================
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- =============================================================================
-- Statement 8: UpdateProductAsync - historySql
-- Source Method: UpdateProductAsync(Product product)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation did not complete after 15 attempts
-- DMS Timestamp: 2026-03-21T23:32:55.844440
-- Changes: GETDATE() replaced with NOW(), lowercase schema names
-- ORIGINAL MS SQL:
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE())
-- CONVERTED PostgreSQL:
-- =============================================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- =============================================================================
-- Statement 9: UpdateProductAsync - statsSql
-- Source Method: UpdateProductAsync(Product product)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- DMS Timestamp: 2026-03-21T23:37:17.808191
-- Changes: GETDATE() replaced with NOW(), lowercase schema names
-- ORIGINAL MS SQL:
-- UPDATE ProductStats SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts, LastUpdated = GETDATE() WHERE StatId = 1
-- CONVERTED PostgreSQL:
-- =============================================================================
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- =============================================================================
-- Statement 10: DeleteProductAsync - selectSql
-- Source Method: DeleteProductAsync(int productId)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- DMS Timestamp: 2026-03-21T23:58:26.165752
-- Note: Same SQL as Statement 6, both separately attempted through DMS
-- ORIGINAL MS SQL:
-- SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId
-- CONVERTED PostgreSQL:
-- =============================================================================
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- =============================================================================
-- Statement 11: DeleteProductAsync - historySql
-- Source Method: DeleteProductAsync(int productId)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation did not complete after 15 attempts
-- DMS Timestamp: 2026-03-21T23:40:07.801704
-- Changes: GETDATE() replaced with NOW(), lowercase schema names
-- ORIGINAL MS SQL:
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE())
-- CONVERTED PostgreSQL:
-- =============================================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- =============================================================================
-- Statement 12: DeleteProductAsync - deleteSql
-- Source Method: DeleteProductAsync(int productId)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- DMS Timestamp: 2026-03-21T23:44:17.281321
-- Changes: Lowercase schema names
-- ORIGINAL MS SQL:
-- DELETE FROM Products WHERE ProductId = @ProductId
-- CONVERTED PostgreSQL:
-- =============================================================================
DELETE FROM products WHERE productid = @ProductId;

-- =============================================================================
-- Statement 13: DeleteProductAsync - statsSql
-- Source Method: DeleteProductAsync(int productId)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation did not complete after 15 attempts
-- DMS Timestamp: 2026-03-21T23:47:01.665362
-- Changes: GETDATE() replaced with NOW(), lowercase schema names
-- ORIGINAL MS SQL:
-- UPDATE ProductStats SET TotalProducts = TotalProducts - 1, AveragePrice = CASE WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END, LastUpdated = GETDATE() WHERE StatId = 1
-- CONVERTED PostgreSQL:
-- =============================================================================
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = NOW()
WHERE statid = 1;

-- =============================================================================
-- Statement 14: GetProductsByPriceRangeAsync - sql
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- DMS Timestamp: 2026-03-21T23:51:27.238857
-- Changes: Lowercase schema names
-- ORIGINAL MS SQL:
-- WITH RankedProducts AS (SELECT p.*, RANK() OVER (ORDER BY p.Price) as PriceRank, PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile FROM Products p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice) SELECT rp.*, CASE WHEN rp.PricePercentile <= 0.25 THEN 'Budget' WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END as PriceSegment FROM RankedProducts rp ORDER BY rp.PriceRank
-- CONVERTED PostgreSQL:
-- =============================================================================
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
ORDER BY rp.pricerank;

-- =============================================================================
-- Statement 15: GetLowStockProductsAsync - sql
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation did not complete after 15 attempts
-- DMS Timestamp: 2026-03-21T23:54:13.790161
-- Changes: CAST(x AS DECIMAL) -> CAST(x AS NUMERIC), lowercase schema names
-- ORIGINAL MS SQL:
-- WITH StockAnalysis AS (SELECT p.*, AVG(StockQuantity) OVER() as AvgStock, MIN(StockQuantity) OVER() as MinStock, MAX(StockQuantity) OVER() as MaxStock FROM Products p) SELECT sa.*, CASE WHEN StockQuantity <= @Threshold THEN 'Critical' WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low' ELSE 'Adequate' END as StockStatus, ROUND((CAST(StockQuantity AS DECIMAL) / AvgStock) * 100, 2) as StockPercentageOfAverage FROM StockAnalysis sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity
-- CONVERTED PostgreSQL:
-- =============================================================================
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
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
