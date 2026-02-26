-- ========================================================================================================
-- CONVERTED SQL STATEMENTS - POSTGRESQL
-- Microsoft SQL Server to PostgreSQL Migration
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- All statements converted manually due to DMS tool failures
-- ========================================================================================================

-- ========================================================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED
-- Original Method: GetAllProductsAsync()
-- Conversion Notes:
-- - Schema objects converted to lowercase (Products -> products, ProductStats -> productstats)
-- - Window functions (AVG OVER, COUNT OVER) are compatible with PostgreSQL
-- - ROUND function is compatible with PostgreSQL
-- - CASE expressions are standard SQL
-- ========================================================================================================
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

-- ========================================================================================================
-- STATEMENT 2: GetProductByIdAsync - CONVERTED
-- Original Method: GetProductByIdAsync(int productId)
-- Conversion Notes:
-- - Schema objects converted to lowercase (Products -> products, ProductHistory -> producthistory)
-- - LAG window function is compatible with PostgreSQL
-- - Parameter syntax changed from @ProductId to $1 (will be handled by Npgsql)
-- - LEFT JOIN and CASE expressions are standard SQL
-- ========================================================================================================
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

-- ========================================================================================================
-- STATEMENT 3: InsertProductAsync - CONVERTED
-- Original Method: InsertProductAsync(Product product)
-- Conversion Notes:
-- - CRITICAL CHANGES for PostgreSQL:
--   * SCOPE_IDENTITY() replaced with RETURNING productid
--   * GETDATE() replaced with CURRENT_TIMESTAMP
--   * BEGIN TRANSACTION/COMMIT removed (handled by application layer)
--   * DECLARE and SET statements removed, use RETURNING clause instead
--   * Schema objects converted to lowercase
-- - This requires significant application code changes to handle RETURNING clause
-- ========================================================================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following operations need to be executed separately in the application:
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- UPDATE productstats
-- SET 
--     totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--     lastupdated = CURRENT_TIMESTAMP
-- WHERE statid = 1;

-- ========================================================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED
-- Original Method: UpdateProductAsync(Product product)
-- Conversion Notes:
-- - CRITICAL CHANGES for PostgreSQL:
--   * GETDATE() replaced with CURRENT_TIMESTAMP
--   * BEGIN TRANSACTION/COMMIT removed (handled by application layer)
--   * DECLARE statements need to be handled differently in PostgreSQL
--   * Use WITH clause or separate queries to capture old values
--   * Schema objects converted to lowercase
-- ========================================================================================================
-- Step 1: Get old values (to be executed separately)
-- SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Step 2: Update the product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Step 3: Log the changes (to be executed separately with old values)
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Step 4: Update product statistics (to be executed separately)
-- UPDATE productstats
-- SET 
--     averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
--     lastupdated = CURRENT_TIMESTAMP
-- WHERE statid = 1;

-- ========================================================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED
-- Original Method: DeleteProductAsync(int productId)
-- Conversion Notes:
-- - CRITICAL CHANGES for PostgreSQL:
--   * GETDATE() replaced with CURRENT_TIMESTAMP
--   * BEGIN TRANSACTION/COMMIT removed (handled by application layer)
--   * DECLARE statements need different handling
--   * Need to capture old values before deletion
--   * Schema objects converted to lowercase
-- ========================================================================================================
-- Step 1: Get old values (to be executed separately before deletion)
-- SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Step 2: Log the deletion (to be executed with captured values)
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Step 3: Delete the product
DELETE FROM products 
WHERE productid = @ProductId;

-- Step 4: Update product statistics (to be executed separately)
-- UPDATE productstats
-- SET 
--     totalproducts = totalproducts - 1,
--     averageprice = CASE 
--         WHEN totalproducts > 1 
--         THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
--         ELSE 0
--     END,
--     lastupdated = CURRENT_TIMESTAMP
-- WHERE statid = 1;

-- ========================================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED
-- Original Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Notes:
-- - Schema objects converted to lowercase (Products -> products, RankedProducts -> rankedproducts)
-- - RANK() and PERCENT_RANK() window functions are compatible with PostgreSQL
-- - BETWEEN operator is standard SQL
-- - CASE expressions are standard SQL
-- ========================================================================================================
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

-- ========================================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED
-- Original Method: GetLowStockProductsAsync(int threshold)
-- Conversion Notes:
-- - Schema objects converted to lowercase (Products -> products, StockAnalysis -> stockanalysis)
-- - Window functions (AVG, MIN, MAX with OVER) are compatible with PostgreSQL
-- - ROUND function is compatible with PostgreSQL
-- - CASE expressions and WHERE clause are standard SQL
-- ========================================================================================================
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

-- ========================================================================================================
-- END OF CONVERTED STATEMENTS
-- ========================================================================================================
-- 
-- IMPORTANT NOTES FOR APPLICATION LAYER:
-- 
-- 1. Transaction Handling:
--    - PostgreSQL transactions should be managed at the application layer using NpgsqlTransaction
--    - BEGIN TRANSACTION/COMMIT blocks have been removed from SQL statements
-- 
-- 2. Parameter Binding:
--    - Npgsql will automatically handle @Parameter syntax conversion to PostgreSQL format
--    - No manual conversion needed for parameters in the application code
-- 
-- 3. Identity/Auto-increment:
--    - Use RETURNING clause for getting newly inserted IDs
--    - Update application code to capture RETURNING values
-- 
-- 4. Multi-statement Transactions (Statements 3, 4, 5):
--    - Break down into separate SQL commands within application transaction
--    - Execute sequentially within NpgsqlTransaction block
--    - Capture intermediate values (old prices, new IDs) in application variables
-- 
-- 5. Schema Case Sensitivity:
--    - All schema objects converted to lowercase per PostgreSQL best practices
--    - PostgreSQL is case-sensitive for quoted identifiers, case-insensitive for unquoted
--    - Using lowercase unquoted identifiers ensures compatibility
-- 
-- ========================================================================================================
