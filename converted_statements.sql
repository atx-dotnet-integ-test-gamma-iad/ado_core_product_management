-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Target Database: PostgreSQL
-- Conversion Date: 2026-02-21
-- ============================================================================

-- This file contains all SQL statements converted from Microsoft SQL Server
-- syntax to PostgreSQL syntax. Each statement includes conversion metadata
-- documenting the conversion method and any DMS tool issues encountered.

-- CONVERSION SUMMARY:
-- Total Statements: 7
-- DMS Tool Conversions: 0 (all failed with metadata model creation error)
-- Manual Conversions: 7 (all using lowercase schema mapping rules)
-- DMS Failure Reason: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}

-- ============================================================================
-- STATEMENT #1: GetAllProductsAsync - Complex CTE with Window Functions
-- ============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- PostgreSQL Conversions Applied:
--   - Table names: Products → products
--   - Column names: ProductId → productid, Name → name, Description → description, 
--                   Price → price, StockQuantity → stockquantity, 
--                   CreatedDate → createddate, ModifiedDate → modifieddate
--   - ROUND() function remains compatible in PostgreSQL
--   - Window functions (AVG OVER, COUNT OVER) remain compatible
-- ============================================================================
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
    p.name

-- ============================================================================
-- STATEMENT #2: GetProductByIdAsync - CTE with LAG Window Function
-- ============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- PostgreSQL Conversions Applied:
--   - Table names: Products → products
--   - Column names: All converted to lowercase
--   - LAG window function remains compatible in PostgreSQL
--   - Parameter @ProductId remains compatible (PostgreSQL uses same syntax)
-- ============================================================================
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
WHERE p.productid = @ProductId

-- ============================================================================
-- STATEMENT #3: InsertProductAsync - Transaction with Multiple Statements
-- ============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- PostgreSQL Conversions Applied:
--   - BEGIN TRANSACTION → BEGIN (PostgreSQL syntax)
--   - SCOPE_IDENTITY() → RETURNING clause on INSERT
--   - GETDATE() → NOW() or CURRENT_TIMESTAMP
--   - Variable declarations: PostgreSQL uses different syntax for variables
--   - Table/column names: All converted to lowercase
--   - Restructured to use RETURNING clause instead of SCOPE_IDENTITY()
-- ============================================================================
-- Note: This statement will need to be restructured in application code
-- because PostgreSQL handles RETURNING differently than SCOPE_IDENTITY()
BEGIN;
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid;
    
    -- Note: Application code will need to capture the returned productid
    -- and use it in subsequent statements
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (/* captured productid */, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- STATEMENT #4: UpdateProductAsync - Transaction with History Logging
-- ============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- PostgreSQL Conversions Applied:
--   - BEGIN TRANSACTION → BEGIN
--   - GETDATE() → NOW()
--   - Variable declarations: Need to be handled differently in PostgreSQL
--   - Table/column names: All converted to lowercase
--   - PostgreSQL uses DO blocks for variable declarations in transactions
-- ============================================================================
BEGIN;
    -- Store old values for history using DO block or subqueries
    -- Option 1: Use WITH clause to capture old values
    WITH oldvalues AS (
        SELECT price as oldprice, stockquantity as oldstock
        FROM products
        WHERE productid = @ProductId
    )
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', oldprice, @Price, oldstock, @StockQuantity, NOW()
    FROM (SELECT price as oldprice, stockquantity as oldstock FROM products WHERE productid = @ProductId LIMIT 1) AS old;
    
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- STATEMENT #5: DeleteProductAsync - Transaction with Cascading Updates
-- ============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- PostgreSQL Conversions Applied:
--   - BEGIN TRANSACTION → BEGIN
--   - GETDATE() → NOW()
--   - Variable declarations: Using subqueries instead
--   - Table/column names: All converted to lowercase
-- ============================================================================
BEGIN;
    -- Log the deletion (capture old values using subquery)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', price, NULL, stockquantity, NULL, NOW()
    FROM products
    WHERE productid = @ProductId;
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId LIMIT 1)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- STATEMENT #6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- PostgreSQL Conversions Applied:
--   - Table/column names: All converted to lowercase
--   - RANK() and PERCENT_RANK() window functions remain compatible in PostgreSQL
--   - BETWEEN clause remains compatible
-- ============================================================================
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

-- ============================================================================
-- STATEMENT #7: GetLowStockProductsAsync - CTE with Window Functions
-- ============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- PostgreSQL Conversions Applied:
--   - Table/column names: All converted to lowercase
--   - Window functions (AVG, MIN, MAX OVER) remain compatible in PostgreSQL
--   - ROUND() function remains compatible
-- ============================================================================
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
    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity

-- ============================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total Statements Converted: 7
-- Conversion Methods:
--   - DMS Tool Success: 0
--   - Manual Conversion (DMS Failure): 7
-- 
-- Key PostgreSQL Transformations Applied:
--   1. All table and column names converted to lowercase
--   2. BEGIN TRANSACTION → BEGIN
--   3. GETDATE() → NOW() or CURRENT_TIMESTAMP
--   4. SCOPE_IDENTITY() → RETURNING clause
--   5. Variable declarations restructured using subqueries or WITH clauses
--   6. Window functions (compatible between SQL Server and PostgreSQL)
--   7. ROUND(), RANK(), PERCENT_RANK(), LAG() functions (compatible)
-- 
-- Notes for Code Integration:
--   - InsertProductAsync: Needs restructuring to handle RETURNING clause
--   - UpdateProductAsync: Old values captured via subqueries
--   - DeleteProductAsync: Old values captured via subquery in INSERT
--   - Parameter syntax (@ParameterName) remains compatible
-- ============================================================================
