-- ================================================================================
-- SQL SERVER TO POSTGRESQL MIGRATION - CONVERTED SQL STATEMENTS CATALOG
-- ================================================================================
-- This file documents all SQL statements after conversion to PostgreSQL.
-- Each statement includes the original SQL Server syntax, DMS tool output,
-- and the resulting PostgreSQL statement.
--
-- Total Statements: 7
-- DMS Tool Successful Conversions: 6
-- Manual Conversions After DMS Failure: 1 (Statement 3)
-- Source File: DataAccess/ProductRepository.cs
-- ================================================================================

-- ================================================================================
-- STATEMENT 1 of 7 - GetAllProductsAsync
-- ================================================================================
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- DMS Metadata Model: sql-conversion-1767356327
-- Schema Transformation: Products -> productmanagement_dbo.products
-- ================================================================================

-- ORIGINAL SQL SERVER STATEMENT:
-- --------------------------------
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
    p.Name;

-- CONVERTED POSTGRESQL STATEMENT:
-- ---------------------------------
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

-- ================================================================================
-- STATEMENT 2 of 7 - GetProductByIdAsync
-- ================================================================================
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- DMS Metadata Model: sql-conversion-1767356414
-- Schema Transformation: Products -> productmanagement_dbo.products
-- ================================================================================

-- ORIGINAL SQL SERVER STATEMENT:
-- --------------------------------
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
WHERE p.ProductId = @ProductId;

-- CONVERTED POSTGRESQL STATEMENT:
-- ---------------------------------
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

-- ================================================================================
-- STATEMENT 3 of 7 - InsertProductAsync
-- ================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Status: DMS FAILED - Manual conversion required
-- DMS Error: Statement definition is not valid
-- ================================================================================

-- ORIGINAL SQL SERVER STATEMENT:
-- --------------------------------
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    -- Insert the new product
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;

-- DMS ERROR OUTPUT:
-- ---------------------------------
-- Metadata model creation failed: {'error': "Metadata model creation failed: {'default_error_details': {'message': 'Statement definition is not valid.'}}"}

-- MANUALLY CONVERTED POSTGRESQL STATEMENT:
-- ---------------------------------
-- Note: This requires transaction handling at the application level in C#
-- The RETURNING clause replaces SCOPE_IDENTITY()
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Additional statements to be executed in the same transaction:
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ================================================================================
-- STATEMENT 4 of 7 - UpdateProductAsync
-- ================================================================================
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS WITH WARNINGS
-- DMS Metadata Model: sql-conversion-1767356538
-- Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--          transaction management commands such as BEGIN TRAN, SAVE TRAN in 
--          functions. Convert your source code manually.]
-- Schema Transformation: Products -> productmanagement_dbo.products
--                       ProductHistory -> productmanagement_dbo.producthistory
--                       ProductStats -> productmanagement_dbo.productstats
-- Note: Transaction management handled at application level
-- ================================================================================

-- ORIGINAL SQL SERVER STATEMENT:
-- --------------------------------
BEGIN TRANSACTION;
    -- Store old values for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Update the product
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

-- CONVERTED POSTGRESQL STATEMENT (without transaction wrapper):
-- ---------------------------------
-- Note: Transaction management handled at application level in C#
-- Variable declarations removed (handled through separate SELECT)
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ================================================================================
-- STATEMENT 5 of 7 - DeleteProductAsync
-- ================================================================================
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS WITH WARNINGS
-- DMS Metadata Model: sql-conversion-1767356627
-- Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--          transaction management commands such as BEGIN TRAN, SAVE TRAN in 
--          functions. Convert your source code manually.]
-- Schema Transformation: Products -> productmanagement_dbo.products
--                       ProductHistory -> productmanagement_dbo.producthistory
--                       ProductStats -> productmanagement_dbo.productstats
-- Note: Transaction management handled at application level
-- ================================================================================

-- ORIGINAL SQL SERVER STATEMENT:
-- --------------------------------
BEGIN TRANSACTION;
    -- Store product info for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    -- Update product statistics
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

-- CONVERTED POSTGRESQL STATEMENT (without transaction wrapper):
-- ---------------------------------
-- Note: Transaction management handled at application level in C#
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
    ELSE 0
END, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ================================================================================
-- STATEMENT 6 of 7 - GetProductsByPriceRangeAsync
-- ================================================================================
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- DMS Metadata Model: sql-conversion-1767356712
-- Schema Transformation: Products -> productmanagement_dbo.products
-- ================================================================================

-- ORIGINAL SQL SERVER STATEMENT:
-- --------------------------------
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
ORDER BY rp.PriceRank;

-- CONVERTED POSTGRESQL STATEMENT:
-- ---------------------------------
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

-- ================================================================================
-- STATEMENT 7 of 7 - GetLowStockProductsAsync
-- ================================================================================
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- DMS Metadata Model: sql-conversion-1767356799
-- Schema Transformation: Products -> productmanagement_dbo.products
-- ================================================================================

-- ORIGINAL SQL SERVER STATEMENT:
-- --------------------------------
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
ORDER BY StockQuantity;

-- CONVERTED POSTGRESQL STATEMENT:
-- ---------------------------------
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

-- ================================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- ================================================================================
-- Summary:
-- - Total statements processed: 7
-- - DMS tool successful conversions: 6
-- - Manual conversions after DMS failure: 1 (Statement 3 - InsertProductAsync)
-- - Key transformations:
--   * Schema: Products -> productmanagement_dbo.products
--   * Schema: ProductHistory -> productmanagement_dbo.producthistory
--   * Schema: ProductStats -> productmanagement_dbo.productstats
--   * Function: GETDATE() -> CURRENT_TIMESTAMP or clock_timestamp()
--   * Function: SCOPE_IDENTITY() -> RETURNING clause
--   * Transaction: BEGIN TRANSACTION/COMMIT handled at application level
--   * Identifiers: Converted to lowercase by DMS
--   * ORDER BY: Added NULLS FIRST clause
-- ================================================================================
