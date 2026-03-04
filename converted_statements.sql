-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Source: DMS MCP Tool Conversion Results
-- Migration Project: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
-- Total Statements: 15
-- All conversions: DMS_TOOL (all 15 succeeded)
-- Note: Statement 3 - DMS converted SCOPE_IDENTITY() to SCOPE_IDENTITY (removed parentheses)
--       but did not convert to PostgreSQL RETURNING clause. The DMS output will be used
--       but adapted to use RETURNING for PostgreSQL compatibility during re-integration.
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync - Complex CTE with window functions
-- Method: GetAllProductsAsync()
-- Conversion Method: DMS_TOOL
-- ============================================================================
-- ORIGINAL MS SQL:
-- WITH ProductStats AS (
--     SELECT ProductId, AVG(Price) OVER () AS AvgPrice, COUNT(*) OVER () AS TotalProducts
--     FROM dbo.Products
-- )
-- SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
--     CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average' WHEN p.Price < ps.AvgPrice THEN 'Below Average' ELSE 'Average' END AS PriceCategory,
--     ROUND((p.Price / ps.AvgPrice) * 100, 2) AS PricePercentageOfAverage
-- FROM dbo.Products AS p INNER JOIN ProductStats AS ps ON p.ProductId = ps.ProductId
-- ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name;

-- CONVERTED PostgreSQL (DMS):
WITH productstats
AS (SELECT
    productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM productmanagement_dbo.products)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END AS pricecategory, ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
    FROM productmanagement_dbo.products AS p
    INNER JOIN productstats AS ps
        ON p.productid = ps.productid
    ORDER BY
    CASE
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END NULLS FIRST, p.name NULLS FIRST;

-- ============================================================================
-- Statement 2: GetProductByIdAsync - CTE with LAG window function
-- Method: GetProductByIdAsync(int productId)
-- Conversion Method: DMS_TOOL
-- ============================================================================
-- ORIGINAL MS SQL:
-- WITH ProductHistory AS (
--     SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) AS PreviousPrice,
--         LAG(StockQuantity) OVER (ORDER BY ModifiedDate) AS PreviousStock
--     FROM dbo.Products WHERE ProductId = @ProductId
-- )
-- SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
--     ph.PreviousPrice, ph.PreviousStock,
--     CASE WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2) ELSE NULL END AS PriceChangePercentage
-- FROM dbo.Products AS p LEFT OUTER JOIN ProductHistory AS ph ON p.ProductId = ph.ProductId
-- WHERE p.ProductId = @ProductId;

-- CONVERTED PostgreSQL (DMS):
WITH producthistory
AS (SELECT
    productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE
        WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END AS pricechangepercentage
    FROM productmanagement_dbo.products AS p
    LEFT OUTER JOIN producthistory AS ph
        ON p.productid = ph.productid
    WHERE p.productid = @ProductId;

-- ============================================================================
-- Statement 3: InsertProductAsync - INSERT product with SCOPE_IDENTITY
-- Method: InsertProductAsync(Product product)
-- Variable: sqlInsertProduct
-- Conversion Method: DMS_TOOL
-- Note: DMS converted but left SCOPE_IDENTITY without parentheses.
--       For PostgreSQL, this needs RETURNING productid clause.
--       Will use RETURNING during re-integration.
-- ============================================================================
-- ORIGINAL MS SQL:
-- INSERT INTO dbo.Products (Name, Description, Price, StockQuantity)
-- VALUES (@Name, @Description, @Price, @StockQuantity);
-- SELECT SCOPE_IDENTITY();

-- CONVERTED PostgreSQL (DMS output):
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity);
SELECT
    SCOPE_IDENTITY;

-- ADAPTED PostgreSQL (for re-integration, replacing SCOPE_IDENTITY with RETURNING):
-- INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
-- VALUES (@Name, @Description, @Price, @StockQuantity)
-- RETURNING productid;

-- ============================================================================
-- Statement 4: InsertProductAsync - INSERT into ProductHistory for INSERT action
-- Method: InsertProductAsync(Product product)
-- Variable: sqlLogHistory
-- Conversion Method: DMS_TOOL
-- ============================================================================
-- ORIGINAL MS SQL:
-- INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());

-- CONVERTED PostgreSQL (DMS):
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- ============================================================================
-- Statement 5: InsertProductAsync - UPDATE ProductStats (increment TotalProducts)
-- Method: InsertProductAsync(Product product)
-- Variable: sqlUpdateStats
-- Conversion Method: DMS_TOOL
-- ============================================================================
-- ORIGINAL MS SQL:
-- UPDATE dbo.ProductStats SET TotalProducts = TotalProducts + 1,
--     AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
--     LastUpdated = GETDATE() WHERE StatId = 1;

-- CONVERTED PostgreSQL (DMS):
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts + 1, averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1), lastupdated = clock_timestamp()
    WHERE statid = 1;

-- ============================================================================
-- Statement 6: UpdateProductAsync - SELECT old values from Products
-- Method: UpdateProductAsync(Product product)
-- Variable: sqlGetOldValues
-- Conversion Method: DMS_TOOL
-- ============================================================================
-- ORIGINAL MS SQL:
-- SELECT Price, StockQuantity FROM dbo.Products WHERE ProductId = @ProductId;

-- CONVERTED PostgreSQL (DMS):
SELECT
    price, stockquantity
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

-- ============================================================================
-- Statement 7: UpdateProductAsync - UPDATE product SET with ModifiedDate
-- Method: UpdateProductAsync(Product product)
-- Variable: sqlUpdateProduct
-- Conversion Method: DMS_TOOL
-- ============================================================================
-- ORIGINAL MS SQL:
-- UPDATE dbo.Products SET Name = @Name, Description = @Description, Price = @Price,
--     StockQuantity = @StockQuantity, ModifiedDate = GETDATE() WHERE ProductId = @ProductId;

-- CONVERTED PostgreSQL (DMS):
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
    WHERE productid = @ProductId;

-- ============================================================================
-- Statement 8: UpdateProductAsync - INSERT into ProductHistory for UPDATE action
-- Method: UpdateProductAsync(Product product)
-- Variable: sqlLogHistory
-- Conversion Method: DMS_TOOL
-- ============================================================================
-- ORIGINAL MS SQL:
-- INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());

-- CONVERTED PostgreSQL (DMS):
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- ============================================================================
-- Statement 9: UpdateProductAsync - UPDATE ProductStats (recalculate AveragePrice)
-- Method: UpdateProductAsync(Product product)
-- Variable: sqlUpdateStats
-- Conversion Method: DMS_TOOL
-- ============================================================================
-- ORIGINAL MS SQL:
-- UPDATE dbo.ProductStats SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
--     LastUpdated = GETDATE() WHERE StatId = 1;

-- CONVERTED PostgreSQL (DMS):
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
    WHERE statid = 1;

-- ============================================================================
-- Statement 10: DeleteProductAsync - SELECT old values from Products
-- Method: DeleteProductAsync(int productId)
-- Variable: sqlGetOldValues
-- Conversion Method: DMS_TOOL
-- ============================================================================
-- ORIGINAL MS SQL:
-- SELECT Price, StockQuantity FROM dbo.Products WHERE ProductId = @ProductId;

-- CONVERTED PostgreSQL (DMS):
SELECT
    price, stockquantity
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

-- ============================================================================
-- Statement 11: DeleteProductAsync - INSERT into ProductHistory for DELETE action
-- Method: DeleteProductAsync(int productId)
-- Variable: sqlLogHistory
-- Conversion Method: DMS_TOOL
-- ============================================================================
-- ORIGINAL MS SQL:
-- INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());

-- CONVERTED PostgreSQL (DMS):
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- ============================================================================
-- Statement 12: DeleteProductAsync - DELETE FROM Products
-- Method: DeleteProductAsync(int productId)
-- Variable: sqlDeleteProduct
-- Conversion Method: DMS_TOOL
-- ============================================================================
-- ORIGINAL MS SQL:
-- DELETE FROM dbo.Products WHERE ProductId = @ProductId;

-- CONVERTED PostgreSQL (DMS):
DELETE FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

-- ============================================================================
-- Statement 13: DeleteProductAsync - UPDATE ProductStats (decrement TotalProducts with CASE)
-- Method: DeleteProductAsync(int productId)
-- Variable: sqlUpdateStats
-- Conversion Method: DMS_TOOL
-- ============================================================================
-- ORIGINAL MS SQL:
-- UPDATE dbo.ProductStats SET TotalProducts = TotalProducts - 1,
--     AveragePrice = CASE WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END,
--     LastUpdated = GETDATE() WHERE StatId = 1;

-- CONVERTED PostgreSQL (DMS):
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
    ELSE 0
END, lastupdated = clock_timestamp()
    WHERE statid = 1;

-- ============================================================================
-- Statement 14: GetProductsByPriceRangeAsync - CTE with RANK/PERCENT_RANK
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Method: DMS_TOOL
-- ============================================================================
-- ORIGINAL MS SQL:
-- WITH RankedProducts AS (
--     SELECT p.*, RANK() OVER (ORDER BY p.Price) AS PriceRank,
--         PERCENT_RANK() OVER (ORDER BY p.Price) AS PricePercentile
--     FROM dbo.Products p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
-- )
-- SELECT rp.*, CASE WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
--     WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END AS PriceSegment
-- FROM RankedProducts rp ORDER BY rp.PriceRank;

-- CONVERTED PostgreSQL (DMS):
WITH rankedproducts
AS (SELECT
    p.*, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products AS p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice)
SELECT
    rp.*,
    CASE
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS pricesegment
    FROM rankedproducts AS rp
    ORDER BY rp.pricerank NULLS FIRST;

-- ============================================================================
-- Statement 15: GetLowStockProductsAsync - CTE with AVG/MIN/MAX window functions
-- Method: GetLowStockProductsAsync(int threshold)
-- Conversion Method: DMS_TOOL
-- ============================================================================
-- ORIGINAL MS SQL:
-- WITH StockAnalysis AS (
--     SELECT p.*, AVG(StockQuantity) OVER() AS AvgStock, MIN(StockQuantity) OVER() AS MinStock,
--         MAX(StockQuantity) OVER() AS MaxStock FROM dbo.Products p
-- )
-- SELECT sa.*, CASE WHEN StockQuantity <= @Threshold THEN 'Critical'
--     WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low' ELSE 'Adequate' END AS StockStatus,
--     ROUND((StockQuantity / AvgStock) * 100, 2) AS StockPercentageOfAverage
-- FROM StockAnalysis sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity;

-- CONVERTED PostgreSQL (DMS):
WITH stockanalysis
AS (SELECT
    p.*, AVG(stockquantity) OVER () AS avgstock, MIN(stockquantity) OVER () AS minstock, MAX(stockquantity) OVER () AS maxstock
    FROM productmanagement_dbo.products AS p)
SELECT
    sa.*,
    CASE
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS stockstatus, ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage
    FROM stockanalysis AS sa
    WHERE stockquantity <= @Threshold
    ORDER BY stockquantity NULLS FIRST;
