-- ===============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Version
-- Microsoft SQL Server to PostgreSQL Migration
-- ===============================================================================
-- This file contains all SQL statements converted to PostgreSQL syntax.
-- All statements were processed through DMS MCP tool, which failed for all statements.
-- Manual conversion was applied with lowercase schema object names.
-- ===============================================================================

-- ===============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ===============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Changes:
--   - Table name: Products -> products (lowercase)
--   - Column names: ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate -> lowercase
--   - ROUND() function: Compatible with PostgreSQL
--   - Window functions (AVG OVER, COUNT OVER): Compatible with PostgreSQL
--   - CASE expressions: Compatible with PostgreSQL
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ===============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Changes:
--   - Table name: Products -> products (lowercase)
--   - Column names: All converted to lowercase
--   - LAG() OVER (ORDER BY): Compatible with PostgreSQL
--   - Parameter: @ProductId maintained (PostgreSQL supports @ parameters with Npgsql)
--   - ROUND() function: Compatible with PostgreSQL
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 3: InsertProductAsync - Transaction Block with INSERT and RETURNING
-- ===============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Changes:
--   - DECLARE @variable INT: Removed (will use RETURNING clause instead)
--   - BEGIN TRANSACTION/COMMIT: Changed to BEGIN/COMMIT (PostgreSQL syntax)
--   - Table names: Products, ProductHistory, ProductStats -> lowercase
--   - Column names: All converted to lowercase
--   - SCOPE_IDENTITY(): Replaced with RETURNING productid
--   - GETDATE(): Replaced with CURRENT_TIMESTAMP
--   - SET @variable = SCOPE_IDENTITY(): Removed (integrated into INSERT with RETURNING)
--   - Final SELECT @variable: Removed (RETURNING provides the value)
-- Note: This will require code adjustment to use ExecuteScalarAsync with RETURNING
-- ===============================================================================

BEGIN;
    -- Insert the new product and get the ID
    WITH inserted_product AS (
        INSERT INTO products (name, description, price, stockquantity)
        VALUES (@Name, @Description, @Price, @StockQuantity)
        RETURNING productid
    )
    -- Log the insertion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP
    FROM inserted_product;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
    
    -- Return the new product ID
    SELECT productid FROM inserted_product;
COMMIT;

-- Note: For ADO.NET usage, this can be simplified to a single statement with RETURNING:
-- INSERT INTO products (name, description, price, stockquantity)
-- VALUES (@Name, @Description, @Price, @StockQuantity)
-- RETURNING productid;
-- Then handle the history logging and stats update in separate statements within the transaction.

-- ===============================================================================
-- STATEMENT 3 (Alternative Simplified Version for ADO.NET):
-- ===============================================================================
-- This version breaks the transaction into manageable parts for ADO.NET ExecuteScalarAsync

INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Then in separate commands within the same transaction:
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- UPDATE productstats
-- SET totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--     lastupdated = CURRENT_TIMESTAMP
-- WHERE statid = 1;

-- ===============================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction Block with UPDATE and History
-- ===============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Changes:
--   - BEGIN TRANSACTION/COMMIT: Changed to BEGIN/COMMIT
--   - DECLARE @variable: PostgreSQL uses DO blocks or functions for variables
--   - Table names: Products, ProductHistory, ProductStats -> lowercase
--   - Column names: All converted to lowercase
--   - GETDATE(): Replaced with CURRENT_TIMESTAMP
--   - Variable assignment from SELECT: Will use WITH clause or subqueries
-- Note: PostgreSQL doesn't support DECLARE in simple SQL, using WITH clause for old values
-- ===============================================================================

BEGIN;
    -- Store old values and update the product
    WITH old_values AS (
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
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = @ProductId;
    
    -- Log the changes (using a separate statement)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', 
           (SELECT price FROM products WHERE productid = @ProductId), 
           @Price, 
           (SELECT stockquantity FROM products WHERE productid = @ProductId), 
           @StockQuantity, 
           CURRENT_TIMESTAMP;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - 
                       (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
COMMIT;

-- ===============================================================================
-- STATEMENT 4 (Corrected Version - Capture old values before update):
-- ===============================================================================

BEGIN;
    -- Create a temporary table to hold old values
    CREATE TEMP TABLE IF NOT EXISTS temp_old_values AS
    SELECT price as oldprice, stockquantity as oldstock
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
    
    -- Log the changes using the saved old values
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', oldprice, @Price, oldstock, @StockQuantity, CURRENT_TIMESTAMP
    FROM temp_old_values;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - 
                       (SELECT oldprice FROM temp_old_values) + @Price) / totalproducts,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
    
    -- Clean up temp table
    DROP TABLE IF EXISTS temp_old_values;
COMMIT;

-- ===============================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction Block with DELETE
-- ===============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Changes:
--   - BEGIN TRANSACTION/COMMIT: Changed to BEGIN/COMMIT
--   - DECLARE @variable: Using WITH clause for old values
--   - Table names: Products, ProductHistory, ProductStats -> lowercase
--   - Column names: All converted to lowercase
--   - GETDATE(): Replaced with CURRENT_TIMESTAMP
-- ===============================================================================

BEGIN;
    -- Create a temporary table to hold old values before deletion
    CREATE TEMP TABLE IF NOT EXISTS temp_delete_values AS
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId;
    
    -- Log the deletion using the saved values
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', oldprice, NULL, oldstock, NULL, CURRENT_TIMESTAMP
    FROM temp_delete_values;
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT oldprice FROM temp_delete_values)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
    
    -- Clean up temp table
    DROP TABLE IF EXISTS temp_delete_values;
COMMIT;

-- ===============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ===============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Changes:
--   - Table name: Products -> products (lowercase)
--   - Column names: All converted to lowercase
--   - RANK() OVER: Compatible with PostgreSQL
--   - PERCENT_RANK() OVER: Compatible with PostgreSQL
--   - BETWEEN clause: Compatible with PostgreSQL
--   - Parameters: @MinPrice, @MaxPrice maintained
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ===============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Changes:
--   - Table name: Products -> products (lowercase)
--   - Column names: All converted to lowercase
--   - AVG() OVER(), MIN() OVER(), MAX() OVER(): Compatible with PostgreSQL
--   - ROUND() function: Compatible with PostgreSQL
--   - Parameter: @Threshold maintained
-- ===============================================================================

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

-- ===============================================================================
-- END OF CONVERTED SQL STATEMENTS
-- ===============================================================================
-- Total Statements Converted: 7
-- DMS Tool Successful: 0
-- Manual Conversion: 7
-- ===============================================================================
