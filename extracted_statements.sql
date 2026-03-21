-- ============================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: DataAccess/ProductRepository.cs
-- Date: 2026-03-21
-- Description: All 7 SQL statements extracted from ProductRepository.cs
-- Note: The codebase already uses PostgreSQL syntax (Npgsql).
--       Original MS SQL Server equivalents are reconstructed for DMS processing.
-- ============================================================

-- ============================================================
-- STATEMENT 1: GetAllProductsAsync
-- Method: GetAllProductsAsync()
-- Location: ProductRepository.cs (lines ~46-63)
-- Type: SELECT with CTE and window functions (AVG, COUNT OVER)
-- Parameters: None
-- ============================================================
-- Current PostgreSQL statement in code:
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

-- Reconstructed MS SQL Server equivalent:
-- WITH ProductStats
-- AS (SELECT
--     ProductId, AVG(Price) OVER () AS AvgPrice, COUNT(*) OVER () AS TotalProducts
--     FROM dbo.Products)
-- SELECT
--     p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
--     CASE
--         WHEN p.Price > ps.AvgPrice THEN 'Above Average'
--         WHEN p.Price < ps.AvgPrice THEN 'Below Average'
--         ELSE 'Average'
--     END AS PriceCategory, ROUND((p.Price / ps.AvgPrice) * 100, 2) AS PricePercentageOfAverage
--     FROM dbo.Products AS p
--     INNER JOIN ProductStats AS ps
--         ON p.ProductId = ps.ProductId
--     ORDER BY
--     CASE
--         WHEN p.Price > ps.AvgPrice THEN 1
--         ELSE 2
--     END, p.Name

-- ============================================================
-- STATEMENT 2: GetProductByIdAsync
-- Method: GetProductByIdAsync(int productId)
-- Location: ProductRepository.cs (lines ~74-91)
-- Type: SELECT with CTE and LAG window function
-- Parameters: @ProductId
-- ============================================================
-- Current PostgreSQL statement in code:
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

-- Reconstructed MS SQL Server equivalent:
-- WITH ProductHistory
-- AS (SELECT
--     ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) AS PreviousPrice, LAG(StockQuantity) OVER (ORDER BY ModifiedDate) AS PreviousStock
--     FROM dbo.Products
--     WHERE ProductId = @ProductId)
-- SELECT
--     p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, ph.PreviousPrice, ph.PreviousStock,
--     CASE
--         WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
--         ELSE NULL
--     END AS PriceChangePercentage
--     FROM dbo.Products AS p
--     LEFT OUTER JOIN ProductHistory AS ph
--         ON p.ProductId = ph.ProductId
--     WHERE p.ProductId = @ProductId

-- ============================================================
-- STATEMENT 3: InsertProductAsync
-- Method: InsertProductAsync(Product product)
-- Location: ProductRepository.cs (lines ~100-120)
-- Type: DO $$ block with INSERT, INSERT, UPDATE + SELECT currval()
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- ============================================================
-- Current PostgreSQL statement in code:
DO $$
DECLARE
    var_NewProductId INTEGER;
BEGIN
    -- Insert the new product
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO var_NewProductId;

    -- Log the insertion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (var_NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

SELECT currval(pg_get_serial_sequence('productmanagement_dbo.products', 'productid'));

-- Reconstructed MS SQL Server equivalent:
-- DECLARE @NewProductId INT;
-- INSERT INTO dbo.Products (Name, Description, Price, StockQuantity)
-- VALUES (@Name, @Description, @Price, @StockQuantity);
-- SET @NewProductId = SCOPE_IDENTITY();
-- INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
-- UPDATE dbo.ProductStats
-- SET TotalProducts = TotalProducts + 1,
--     AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
--     LastUpdated = GETDATE()
-- WHERE StatId = 1;
-- SELECT @NewProductId;

-- ============================================================
-- STATEMENT 4: UpdateProductAsync
-- Method: UpdateProductAsync(Product product)
-- Location: ProductRepository.cs (lines ~133-155)
-- Type: DO $$ block with SELECT INTO, UPDATE, INSERT, UPDATE
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- ============================================================
-- Current PostgreSQL statement in code:
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store old values for history */
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update the product */
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId;
    /* Log the changes */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', var_OldPrice, @Price, var_OldStock, @StockQuantity, clock_timestamp());
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - var_OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
        WHERE statid = 1;
END $$;

-- Reconstructed MS SQL Server equivalent:
-- DECLARE @OldPrice DECIMAL(18, 2);
-- DECLARE @OldStock INT;
-- SELECT @OldPrice = Price, @OldStock = StockQuantity
-- FROM dbo.Products WHERE ProductId = @ProductId;
-- UPDATE dbo.Products
-- SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE()
-- WHERE ProductId = @ProductId;
-- INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
-- UPDATE dbo.ProductStats
-- SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts, LastUpdated = GETDATE()
-- WHERE StatId = 1;

-- ============================================================
-- STATEMENT 5: DeleteProductAsync
-- Method: DeleteProductAsync(int productId)
-- Location: ProductRepository.cs (lines ~168-192)
-- Type: DO $$ block with SELECT INTO, INSERT, DELETE, UPDATE
-- Parameters: @ProductId
-- ============================================================
-- Current PostgreSQL statement in code:
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store product info for history */
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Log the deletion */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', var_OldPrice, NULL, var_OldStock, NULL, clock_timestamp());
    /* Delete the product */
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - var_OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = clock_timestamp()
        WHERE statid = 1;
END $$;

-- Reconstructed MS SQL Server equivalent:
-- DECLARE @OldPrice DECIMAL(18, 2);
-- DECLARE @OldStock INT;
-- SELECT @OldPrice = Price, @OldStock = StockQuantity
-- FROM dbo.Products WHERE ProductId = @ProductId;
-- INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
-- DELETE FROM dbo.Products WHERE ProductId = @ProductId;
-- UPDATE dbo.ProductStats
-- SET TotalProducts = TotalProducts - 1,
--     AveragePrice = CASE WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END,
--     LastUpdated = GETDATE()
-- WHERE StatId = 1;

-- ============================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Location: ProductRepository.cs (lines ~203-222)
-- Type: SELECT with CTE, RANK, PERCENT_RANK window functions
-- Parameters: @MinPrice, @MaxPrice
-- ============================================================
-- Current PostgreSQL statement in code:
WITH rankedproducts
AS (SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products AS p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice)
SELECT
    rp.productid, rp.name, rp.description, rp.price, rp.stockquantity, rp.createddate, rp.modifieddate, rp.pricerank, rp.pricepercentile,
    CASE
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS pricesegment
    FROM rankedproducts AS rp
    ORDER BY rp.pricerank NULLS FIRST;

-- Reconstructed MS SQL Server equivalent:
-- WITH RankedProducts
-- AS (SELECT
--     p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, RANK() OVER (ORDER BY p.Price) AS PriceRank, PERCENT_RANK() OVER (ORDER BY p.Price) AS PricePercentile
--     FROM dbo.Products AS p
--     WHERE p.Price BETWEEN @MinPrice AND @MaxPrice)
-- SELECT
--     rp.ProductId, rp.Name, rp.Description, rp.Price, rp.StockQuantity, rp.CreatedDate, rp.ModifiedDate, rp.PriceRank, rp.PricePercentile,
--     CASE
--         WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
--         WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
--         ELSE 'Premium'
--     END AS PriceSegment
--     FROM RankedProducts AS rp
--     ORDER BY rp.PriceRank

-- ============================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Method: GetLowStockProductsAsync(int threshold)
-- Location: ProductRepository.cs (lines ~235-253)
-- Type: SELECT with CTE and aggregate window functions (AVG, MIN, MAX)
-- Parameters: @Threshold
-- ============================================================
-- Current PostgreSQL statement in code:
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

-- Reconstructed MS SQL Server equivalent:
-- WITH StockAnalysis
-- AS (SELECT
--     p.*, AVG(StockQuantity) OVER () AS AvgStock, MIN(StockQuantity) OVER () AS MinStock, MAX(StockQuantity) OVER () AS MaxStock
--     FROM dbo.Products AS p)
-- SELECT
--     sa.*,
--     CASE
--         WHEN StockQuantity <= @Threshold THEN 'Critical'
--         WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
--         ELSE 'Adequate'
--     END AS StockStatus, ROUND((CAST(StockQuantity AS DECIMAL) / AvgStock) * 100, 2) AS StockPercentageOfAverage
--     FROM StockAnalysis AS sa
--     WHERE StockQuantity <= @Threshold
--     ORDER BY StockQuantity

-- ============================================================
-- END OF EXTRACTED STATEMENTS CATALOG
-- Total: 7 SQL statements extracted
-- ============================================================
