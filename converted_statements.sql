-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Source: DataAccess/ProductRepository.cs
-- Date: 2026-03-21
-- Purpose: All 7 SQL statements converted from MS SQL Server to PostgreSQL
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (all 7)
-- DMS Tool Status: ALL 7 statements submitted to DMS MCP tool; ALL FAILED
-- ============================================================================

-- ============================================================================
-- DMS FAILURE SUMMARY:
--   Statement 1 (GetAllProducts): Error - "Metadata model conversion did not complete after 15 attempts"
--   Statement 2 (GetProductById): Error - "Metadata model conversion did not complete after 15 attempts"
--   Statement 3 (InsertProduct): Error - "Metadata model creation failed: Statement definition is not valid."
--   Statement 4 (UpdateProduct): Error - "Metadata model conversion did not complete after 15 attempts"
--   Statement 5 (DeleteProduct): Error - "Metadata model conversion did not complete after 15 attempts"
--   Statement 6 (GetProductsByPriceRange): Error - "Metadata model conversion did not complete after 15 attempts"
--   Statement 7 (GetLowStockProducts): Error - "Metadata model conversion did not complete after 15 attempts"
--
-- Manual Conversion Rules Applied (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA):
--   1. All schema object names converted to lowercase
--   2. [dbo].[Products] -> productmanagement_dbo.products
--   3. [dbo].[ProductHistory] -> productmanagement_dbo.producthistory
--   4. [dbo].[ProductStats] -> productmanagement_dbo.productstats
--   5. GETDATE() -> clock_timestamp()
--   6. SCOPE_IDENTITY() -> currval(pg_get_serial_sequence('productmanagement_dbo.products', 'productid'))
--   7. DECIMAL -> NUMERIC
--   8. BEGIN TRANSACTION/COMMIT TRANSACTION -> DO $$ BEGIN...END $$
--   9. SELECT @var = col -> SELECT col INTO var
--  10. Added NULLS FIRST to ORDER BY clauses for PostgreSQL compatibility
--  11. CAST(x AS DECIMAL) -> CAST(x AS NUMERIC)
-- ============================================================================


-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- DMS Status: FAILED - "Metadata model conversion did not complete after 15 attempts"
-- DMS Timestamp: 2026-03-21T04:50:25
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================

-- ORIGINAL MS SQL SERVER:
/*
WITH ProductStats_CTE
AS (SELECT
    ProductId, AVG(Price) OVER () AS AvgPrice, COUNT(*) OVER () AS TotalProducts
    FROM [dbo].[Products])
SELECT
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    CASE
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END AS PriceCategory, ROUND((p.Price / ps.AvgPrice), 2) AS PricePercentageOfAverage
    FROM [dbo].[Products] AS p
    INNER JOIN ProductStats_CTE AS ps
        ON p.ProductId = ps.ProductId
    ORDER BY
    CASE
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END, p.Name
*/

-- CONVERTED POSTGRESQL:
/*
WITH productstats_cte
AS (SELECT
    productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM productmanagement_dbo.products)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END AS pricecategory, ROUND((p.price / ps.avgprice), 2) AS pricepercentageofaverage
    FROM productmanagement_dbo.products AS p
    INNER JOIN productstats_cte AS ps
        ON p.productid = ps.productid
    ORDER BY
    CASE
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END NULLS FIRST, p.name NULLS FIRST
*/


-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync
-- DMS Status: FAILED - "Metadata model conversion did not complete after 15 attempts"
-- DMS Timestamp: 2026-03-21T05:13:33
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================

-- ORIGINAL MS SQL SERVER:
/*
WITH ProductHistory_CTE
AS (SELECT
    ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) AS PreviousPrice, LAG(StockQuantity) OVER (ORDER BY ModifiedDate) AS PreviousStock
    FROM [dbo].[Products]
    WHERE ProductId = @ProductId)
SELECT
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, ph.PreviousPrice, ph.PreviousStock,
    CASE
        WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice), 2)
        ELSE NULL
    END AS PriceChangePercentage
    FROM [dbo].[Products] AS p
    LEFT OUTER JOIN ProductHistory_CTE AS ph
        ON p.ProductId = ph.ProductId
    WHERE p.ProductId = @ProductId
*/

-- CONVERTED POSTGRESQL:
/*
WITH producthistory_cte
AS (SELECT
    productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE
        WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice), 2)
        ELSE NULL
    END AS pricechangepercentage
    FROM productmanagement_dbo.products AS p
    LEFT OUTER JOIN producthistory_cte AS ph
        ON p.productid = ph.productid
    WHERE p.productid = @ProductId
*/


-- ============================================================================
-- STATEMENT 3: InsertProductAsync
-- DMS Status: FAILED - "Metadata model creation failed: Statement definition is not valid."
-- DMS Timestamp: 2026-03-21T05:18:33
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================

-- ORIGINAL MS SQL SERVER:
/*
BEGIN TRANSACTION;
    DECLARE @NewProductId INT;
    INSERT INTO [dbo].[Products] (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    SET @NewProductId = SCOPE_IDENTITY();
    INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    UPDATE [dbo].[ProductStats]
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT TRANSACTION;
SELECT SCOPE_IDENTITY();
*/

-- CONVERTED POSTGRESQL:
/*
DO $$
DECLARE
    var_NewProductId INTEGER;
BEGIN
    -- Insert the new product
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);

    var_NewProductId := currval(pg_get_serial_sequence('productmanagement_dbo.products', 'productid'));

    -- Log the insertion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (var_NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

SELECT currval(pg_get_serial_sequence('productmanagement_dbo.products', 'productid'));
*/


-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- DMS Status: FAILED - "Metadata model conversion did not complete after 15 attempts"
-- DMS Timestamp: 2026-03-21T05:20:58
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================

-- ORIGINAL MS SQL SERVER:
/*
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18, 2);
    DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity
        FROM [dbo].[Products]
        WHERE ProductId = @ProductId;
    UPDATE [dbo].[Products]
    SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE()
        WHERE ProductId = @ProductId;
    INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    UPDATE [dbo].[ProductStats]
    SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts, LastUpdated = GETDATE()
        WHERE StatId = 1;
COMMIT TRANSACTION;
*/

-- CONVERTED POSTGRESQL:
/*
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', var_OldPrice, @Price, var_OldStock, @StockQuantity, clock_timestamp());
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - var_OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
        WHERE statid = 1;
END $$;
*/


-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- DMS Status: FAILED - "Metadata model conversion did not complete after 15 attempts"
-- DMS Timestamp: 2026-03-21T05:24:29
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================

-- ORIGINAL MS SQL SERVER:
/*
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18, 2);
    DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity
        FROM [dbo].[Products]
        WHERE ProductId = @ProductId;
    INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    DELETE FROM [dbo].[Products]
    WHERE ProductId = @ProductId;
    UPDATE [dbo].[ProductStats]
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT TRANSACTION;
*/

-- CONVERTED POSTGRESQL:
/*
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;

    -- Log the deletion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', var_OldPrice, NULL, var_OldStock, NULL, clock_timestamp());

    -- Delete the product
    DELETE FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - var_OldPrice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;
*/


-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- DMS Status: FAILED - "Metadata model conversion did not complete after 15 attempts"
-- DMS Timestamp: 2026-03-21T05:29:36
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================

-- ORIGINAL MS SQL SERVER:
/*
WITH RankedProducts
AS (SELECT
    p.*, RANK() OVER (ORDER BY p.Price) AS PriceRank, PERCENT_RANK() OVER (ORDER BY p.Price) AS PricePercentile
    FROM [dbo].[Products] AS p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice)
SELECT
    rp.*,
    CASE
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS PriceSegment
    FROM RankedProducts AS rp
    ORDER BY rp.PriceRank
*/

-- CONVERTED POSTGRESQL:
/*
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
    ORDER BY rp.pricerank NULLS FIRST
*/


-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- DMS Status: FAILED - "Metadata model conversion did not complete after 15 attempts"
-- DMS Timestamp: 2026-03-21T05:34:43
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================

-- ORIGINAL MS SQL SERVER:
/*
WITH StockAnalysis
AS (SELECT p.*,
        AVG(StockQuantity) OVER () AS AvgStock,
        MIN(StockQuantity) OVER () AS MinStock,
        MAX(StockQuantity) OVER () AS MaxStock
    FROM [dbo].[Products] AS p)
SELECT sa.*,
        CASE
            WHEN StockQuantity <= @Threshold THEN 'Critical'
            WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
            ELSE 'Adequate'
        END AS StockStatus,
        ROUND((CAST(StockQuantity AS DECIMAL) / AvgStock) * 100, 2) AS StockPercentageOfAverage
    FROM StockAnalysis AS sa
    WHERE StockQuantity <= @Threshold
    ORDER BY StockQuantity
*/

-- CONVERTED POSTGRESQL:
/*
WITH stockanalysis
AS (SELECT p.*,
        AVG(stockquantity) OVER () AS avgstock,
        MIN(stockquantity) OVER () AS minstock,
        MAX(stockquantity) OVER () AS maxstock
    FROM productmanagement_dbo.products AS p)
SELECT sa.*,
        CASE
            WHEN stockquantity <= @Threshold THEN 'Critical'
            WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
            ELSE 'Adequate'
        END AS stockstatus,
        ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) AS stockpercentageofaverage
    FROM stockanalysis AS sa
    WHERE stockquantity <= @Threshold
    ORDER BY stockquantity NULLS FIRST
*/

-- ============================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total: 7 statements converted
-- DMS Tool Success: 0/7
-- DMS Tool Failures: 7/7
-- Manual Conversions: 7/7 (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
-- ============================================================================
