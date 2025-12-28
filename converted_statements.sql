-- ============================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- Purpose: PostgreSQL-compatible versions of all SQL statements
-- Conversion Method: DMS MCP Tool (Statements 1, 2, 6, 7) + Manual (Statements 3, 4, 5)
-- Target Database: PostgreSQL 13
-- Schema: productmanagement_dbo
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED BY DMS TOOL)
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Notable Conversions: Column names lowercase, NULLS FIRST added to ORDER BY
-- ============================================================================
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
-- STATEMENT 2: GetProductByIdAsync (CONVERTED BY DMS TOOL)
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Notable Conversions: lag() function, LEFT JOIN → LEFT OUTER JOIN, parameter kept as @ProductId
-- ============================================================================
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
-- STATEMENT 3: InsertProductAsync (MANUAL CONVERSION AFTER DMS FAILURE)
-- Conversion Status: MANUAL (DMS Error: Statement definition is not valid)
-- DMS Error: Multi-statement transaction blocks not supported by DMS converter
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Notable Conversions:
--   - DECLARE removed (using DO block or handling in application code)
--   - SCOPE_IDENTITY() → RETURNING clause
--   - GETDATE() → CURRENT_TIMESTAMP or NOW()
--   - BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT
--   - Parameters: @Name, @Description, @Price, @StockQuantity
-- PostgreSQL Approach: Use RETURNING clause to get new ID, then use it in subsequent statements
-- ============================================================================
DO $$
DECLARE
    v_newproductid INT;
BEGIN
    -- Insert the new product and return the ID
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO v_newproductid;
    
    -- Log the insertion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (v_newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
    
    -- Return the new product ID
    RAISE NOTICE 'New Product ID: %', v_newproductid;
END $$;

-- Simplified single-statement version for application use (recommended):
-- Note: Application code should handle this in a transaction block
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (MANUAL CONVERSION AFTER DMS FAILURE)
-- Conversion Status: MANUAL (DMS Error expected - similar to Statement 3)
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Notable Conversions:
--   - GETDATE() → CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION/COMMIT → handled by application transaction
--   - DECLARE → local variables in DO block
--   - Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- ============================================================================
DO $$
DECLARE
    v_oldprice DECIMAL(18,2);
    v_oldstock INT;
BEGIN
    -- Store old values for history
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;
    
    -- Update the product
    UPDATE productmanagement_dbo.products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = @ProductId;
    
    -- Log the changes
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', v_oldprice, @Price, v_oldstock, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        averageprice = (averageprice * totalproducts - v_oldprice + @Price) / totalproducts,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
END $$;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (MANUAL CONVERSION AFTER DMS FAILURE)
-- Conversion Status: MANUAL (DMS Error expected - similar to Statement 3)
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Notable Conversions:
--   - GETDATE() → CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION/COMMIT → handled by application transaction
--   - CASE expression preserved
--   - Parameter: @ProductId
-- ============================================================================
DO $$
DECLARE
    v_oldprice DECIMAL(18,2);
    v_oldstock INT;
BEGIN
    -- Store product info for history
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;
    
    -- Log the deletion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM productmanagement_dbo.products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - v_oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
END $$;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED BY DMS TOOL)
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Notable Conversions: Column names lowercase, percent_rank() function, NULLS FIRST added
-- Parameters: @MinPrice, @MaxPrice
-- ============================================================================
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
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED BY DMS TOOL)
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Notable Conversions: Column names lowercase, window functions preserved, NULLS FIRST added
-- Parameter: @Threshold
-- ============================================================================
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

-- ============================================================================
-- END OF CONVERTED STATEMENTS
-- ============================================================================
