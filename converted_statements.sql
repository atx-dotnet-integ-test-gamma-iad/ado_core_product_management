-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Migration: Microsoft SQL Server to PostgreSQL
-- Project: AdoCore - .NET ADO Application
-- Date: 2024-11-22
-- Tool: AWS DMS MCP Statement Conversion Tool
-- ============================================================================

-- STATEMENT ID: SQL_001
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Transformation: dbo.Products -> productmanagement_dbo.products
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

-- STATEMENT ID: SQL_002
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Transformation: dbo.Products -> productmanagement_dbo.products
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

-- STATEMENT ID: SQL_003
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: DMS_PARTIAL_SUCCESS
-- DMS Error: Metadata model creation failed - Statement definition is not valid (transaction block not supported)
-- Manual Conversion Rationale: DMS tool cannot process complex transaction blocks with DECLARE, 
-- SCOPE_IDENTITY(), and multiple statements. Used DMS conversion for individual INSERT component
-- and applied PostgreSQL transaction patterns for transaction control.
-- Schema Transformation: dbo.Products -> productmanagement_dbo.products
-- Key Changes: 
--   1. BEGIN TRANSACTION -> BEGIN
--   2. SCOPE_IDENTITY() -> RETURNING clause
--   3. GETDATE() -> CURRENT_TIMESTAMP  
--   4. Variable handling with PostgreSQL patterns
-- ============================================================================
-- Note: This needs to be executed as a stored procedure or split into separate statements
-- For ADO.NET integration, this will be split and RETURNING used in C# code
BEGIN;
    -- Insert the new product and return the ID
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid;
    
    -- The returned ID will be captured in application code
    -- Log the insertion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
COMMIT;

-- STATEMENT ID: SQL_004
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: DMS_PARTIAL_SUCCESS
-- DMS Error: Metadata model creation failed - Statement definition is not valid (transaction block not supported)
-- Manual Conversion Rationale: DMS tool cannot process complex transaction blocks with DECLARE variables.
-- Applied PostgreSQL transaction patterns and CURRENT_TIMESTAMP function.
-- Schema Transformation: dbo.Products -> productmanagement_dbo.products
-- Key Changes:
--   1. BEGIN TRANSACTION -> BEGIN
--   2. GETDATE() -> CURRENT_TIMESTAMP
--   3. DECLARE variables removed (handled in application code or stored procedure)
-- ============================================================================
BEGIN;
    -- Store old values for history (handled in application code)
    -- @OldPrice and @OldStock retrieved via SELECT in application before this executes
    
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
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
COMMIT;

-- STATEMENT ID: SQL_005
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: DMS_PARTIAL_SUCCESS
-- DMS Error: Metadata model creation failed - Statement definition is not valid (transaction block not supported)
-- Manual Conversion Rationale: DMS tool cannot process complex transaction blocks with DECLARE variables.
-- Applied PostgreSQL transaction patterns and CURRENT_TIMESTAMP function.
-- Schema Transformation: dbo.Products -> productmanagement_dbo.products
-- Key Changes:
--   1. BEGIN TRANSACTION -> BEGIN
--   2. GETDATE() -> CURRENT_TIMESTAMP
--   3. DECLARE variables removed (handled in application code or stored procedure)
-- ============================================================================
BEGIN;
    -- Store product info for history (handled in application code)
    -- @OldPrice and @OldStock retrieved via SELECT in application before this executes
    
    -- Log the deletion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM productmanagement_dbo.products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
COMMIT;

-- STATEMENT ID: SQL_006
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Transformation: dbo.Products -> productmanagement_dbo.products
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

-- STATEMENT ID: SQL_007
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Transformation: dbo.Products -> productmanagement_dbo.products
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
-- END OF CONVERTED STATEMENTS CATALOG
-- Total Statements: 7
-- DMS Tool Success: 4 (SQL_001, SQL_002, SQL_006, SQL_007)
-- Manual After DMS Failure: 3 (SQL_003, SQL_004, SQL_005)
-- ============================================================================
