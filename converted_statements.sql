-- ================================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Microsoft SQL Server to PostgreSQL Migration
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (All statements)
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Source: extracted_statements.sql - STATEMENT 1
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Tool Status: ERROR
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Applied: 
--   - Table names to lowercase (Products → products, ProductStats → productstats)
--   - Column names to lowercase (ProductId → productid, etc.)
--   - Window functions (AVG OVER, COUNT OVER) - PostgreSQL compatible, no change
--   - CASE statements - PostgreSQL compatible, no change
--   - ROUND function - PostgreSQL compatible, no change
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Source: extracted_statements.sql - STATEMENT 2
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Tool Status: ERROR
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Applied:
--   - Table names to lowercase (Products → products, ProductHistory → producthistory)
--   - Column names to lowercase (ProductId → productid, etc.)
--   - LAG window function - PostgreSQL compatible, no change
--   - Parameter @ProductId - PostgreSQL compatible with @ prefix
--   - CASE statements - PostgreSQL compatible, no change
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 3: InsertProductAsync
-- Source: extracted_statements.sql - STATEMENT 3
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Tool Status: ERROR
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Applied:
--   - Table names to lowercase (Products → products, ProductHistory → producthistory, ProductStats → productstats)
--   - Column names to lowercase (ProductId → productid, Name → name, etc.)
--   - DECLARE @NewProductId INT - Removed (not needed with RETURNING clause)
--   - BEGIN TRANSACTION → BEGIN
--   - SCOPE_IDENTITY() → RETURNING productid (PostgreSQL pattern)
--   - GETDATE() → CURRENT_TIMESTAMP
--   - SET @NewProductId = SCOPE_IDENTITY() - Replaced with RETURNING clause
--   - SELECT @NewProductId - Removed (value returned by RETURNING clause)
--   - Converted to use DO block for complex transaction logic
-- ================================================================================

DO $$
DECLARE
    v_newproductid INT;
    v_totalproducts INT;
    v_avgprice DECIMAL(18,2);
BEGIN
    -- Insert the new product and get the ID
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO v_newproductid;
    
    -- Log the insertion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (v_newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Get current stats
    SELECT totalproducts, averageprice INTO v_totalproducts, v_avgprice
    FROM productstats
    WHERE statid = 1;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = v_totalproducts + 1,
        averageprice = (v_avgprice * v_totalproducts + @Price) / (v_totalproducts + 1),
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
    
    -- Return the new product ID
    RAISE NOTICE 'New Product ID: %', v_newproductid;
END $$;

-- NOTE: For ADO.NET integration, this will need to be restructured as separate statements
-- with RETURNING clause on INSERT to get the new ID

-- ================================================================================
-- STATEMENT 4: UpdateProductAsync
-- Source: extracted_statements.sql - STATEMENT 4
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Tool Status: ERROR
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Applied:
--   - Table names to lowercase (Products → products, ProductHistory → producthistory, ProductStats → productstats)
--   - Column names to lowercase (ProductId → productid, etc.)
--   - BEGIN TRANSACTION → BEGIN
--   - DECLARE @OldPrice → Use subquery or separate SELECT
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Converted to use DO block for complex transaction logic
-- ================================================================================

DO $$
DECLARE
    v_oldprice DECIMAL(18,2);
    v_oldstock INT;
    v_totalproducts INT;
    v_avgprice DECIMAL(18,2);
BEGIN
    -- Store old values for history
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    -- Update the product
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = @ProductId;
    
    -- Log the changes
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', v_oldprice, @Price, v_oldstock, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Get current stats
    SELECT totalproducts, averageprice INTO v_totalproducts, v_avgprice
    FROM productstats
    WHERE statid = 1;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (v_avgprice * v_totalproducts - v_oldprice + @Price) / v_totalproducts,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
END $$;

-- NOTE: For ADO.NET integration, this will be converted to use CTEs or separate statements

-- ================================================================================
-- STATEMENT 5: DeleteProductAsync
-- Source: extracted_statements.sql - STATEMENT 5
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Tool Status: ERROR
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Applied:
--   - Table names to lowercase (Products → products, ProductHistory → producthistory, ProductStats → productstats)
--   - Column names to lowercase (ProductId → productid, etc.)
--   - BEGIN TRANSACTION → BEGIN
--   - DECLARE @OldPrice → Use DO block with variables
--   - GETDATE() → CURRENT_TIMESTAMP
--   - CASE statement - PostgreSQL compatible, no change
-- ================================================================================

DO $$
DECLARE
    v_oldprice DECIMAL(18,2);
    v_oldstock INT;
    v_totalproducts INT;
    v_avgprice DECIMAL(18,2);
BEGIN
    -- Store product info for history
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    -- Log the deletion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    -- Get current stats
    SELECT totalproducts, averageprice INTO v_totalproducts, v_avgprice
    FROM productstats
    WHERE statid = 1;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = v_totalproducts - 1,
        averageprice = CASE 
            WHEN v_totalproducts > 1 
            THEN (v_avgprice * v_totalproducts - v_oldprice) / (v_totalproducts - 1)
            ELSE 0
        END,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
END $$;

-- NOTE: For ADO.NET integration, this will be converted to use CTEs or separate statements

-- ================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Source: extracted_statements.sql - STATEMENT 6
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Tool Status: ERROR
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Applied:
--   - Table names to lowercase (Products → products, RankedProducts → rankedproducts)
--   - Column names to lowercase (ProductId → productid, etc.)
--   - RANK() and PERCENT_RANK() window functions - PostgreSQL compatible, no change
--   - BETWEEN operator - PostgreSQL compatible, no change
--   - Parameters @MinPrice, @MaxPrice - PostgreSQL compatible with @ prefix
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Source: extracted_statements.sql - STATEMENT 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Tool Status: ERROR
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Applied:
--   - Table names to lowercase (Products → products, StockAnalysis → stockanalysis)
--   - Column names to lowercase (StockQuantity → stockquantity, etc.)
--   - AVG(), MIN(), MAX() window functions - PostgreSQL compatible, no change
--   - CASE statement - PostgreSQL compatible, no change
--   - ROUND function - PostgreSQL compatible, no change
--   - Parameter @Threshold - PostgreSQL compatible with @ prefix
-- ================================================================================

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
ORDER BY stockquantity;

-- ================================================================================
-- END OF CONVERTED SQL STATEMENTS
-- 
-- CONVERSION SUMMARY:
-- Total Statements: 7
-- DMS Tool Success: 0
-- Manual Conversion: 7
-- 
-- All statements failed DMS conversion with same error:
-- "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
--
-- Manual conversion applied lowercase schema mapping rules:
-- - All table names converted to lowercase
-- - All column names converted to lowercase
-- - GETDATE() → CURRENT_TIMESTAMP
-- - SCOPE_IDENTITY() → RETURNING clause pattern
-- - BEGIN TRANSACTION → BEGIN (or DO block for complex transactions)
-- - Window functions, CTEs, and CASE statements are PostgreSQL compatible
-- ================================================================================
