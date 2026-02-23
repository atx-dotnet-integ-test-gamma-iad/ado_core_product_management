-- ============================================================================
-- PostgreSQL Converted SQL Statements Catalog
-- Purpose: All SQL statements converted from MS SQL Server to PostgreSQL
-- Date: Generated during MS SQL Server to PostgreSQL Migration
-- Conversion Method: Manual conversion due to DMS tool failures
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Original Source: ProductRepository.cs, GetAllProductsAsync()
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
--   - Schema object names converted to lowercase (Products → products, ProductId → productid, etc.)
--   - PostgreSQL CTE and window function syntax (no changes needed, compatible)
--   - ROUND function syntax (no changes needed, compatible)
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
    p.name;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Original Source: ProductRepository.cs, GetProductByIdAsync(int productId)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
--   - Schema object names converted to lowercase
--   - LAG window function (no changes needed, PostgreSQL compatible)
--   - LEFT JOIN syntax (no changes needed, compatible)
--   - Parameter @ProductId retained (Npgsql compatible)
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
WHERE p.productid = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- Original Source: ProductRepository.cs, InsertProductAsync(Product product)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
--   - Schema object names converted to lowercase
--   - Removed DECLARE statement (PostgreSQL uses DO block or functions for variables)
--   - Removed BEGIN TRANSACTION/COMMIT (handled at application level in .NET)
--   - Converted SCOPE_IDENTITY() to RETURNING productid clause
--   - Converted GETDATE() to CURRENT_TIMESTAMP
--   - Restructured as separate statements to be executed in transaction
-- ============================================================================

-- Insert the new product with RETURNING clause
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following statements should be executed within the same transaction
-- using the returned productid from the INSERT above

-- Log the insertion (executed separately with @NewProductId parameter)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics (executed separately)
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- Original Source: ProductRepository.cs, UpdateProductAsync(Product product)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
--   - Schema object names converted to lowercase
--   - Removed BEGIN TRANSACTION/COMMIT (handled at application level)
--   - Removed DECLARE statements (use CTE or subquery instead)
--   - Converted GETDATE() to CURRENT_TIMESTAMP
--   - Restructured to use WITH clause for old values
-- ============================================================================

-- Store old values and update the product
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
    modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId
RETURNING (SELECT oldprice FROM oldvalues) as oldprice, 
          (SELECT oldstock FROM oldvalues) as oldstock;

-- Log the changes (executed separately with old values)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics (executed separately)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- Original Source: ProductRepository.cs, DeleteProductAsync(int productId)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
--   - Schema object names converted to lowercase
--   - Removed BEGIN TRANSACTION/COMMIT (handled at application level)
--   - Removed DECLARE statements (fetch values before delete)
--   - Converted GETDATE() to CURRENT_TIMESTAMP
--   - Restructured to fetch values first, then delete
-- ============================================================================

-- Store product info for history (fetch before delete)
SELECT price as oldprice, stockquantity as oldstock
FROM products
WHERE productid = @ProductId;

-- Log the deletion (executed with fetched values)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Delete the product
DELETE FROM products 
WHERE productid = @ProductId;

-- Update product statistics (executed separately)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Original Source: ProductRepository.cs, GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
--   - Schema object names converted to lowercase
--   - RANK() and PERCENT_RANK() functions (no changes needed, PostgreSQL compatible)
--   - BETWEEN operator (no changes needed, compatible)
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
ORDER BY rp.pricerank;

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Original Source: ProductRepository.cs, GetLowStockProductsAsync(int threshold)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
--   - Schema object names converted to lowercase
--   - AVG/MIN/MAX window functions (no changes needed, PostgreSQL compatible)
--   - ROUND function (no changes needed, compatible)
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
ORDER BY stockquantity;

-- ============================================================================
-- END OF CONVERTED STATEMENTS
-- Total Statements Converted: 7
-- Conversion Method: All statements manually converted due to DMS tool failures
-- 
-- Key PostgreSQL Conversions Applied:
-- 1. All schema object names converted to lowercase
-- 2. SCOPE_IDENTITY() → RETURNING clause
-- 3. GETDATE() → CURRENT_TIMESTAMP
-- 4. BEGIN TRANSACTION/COMMIT removed (handled at application level)
-- 5. DECLARE statements removed (restructured using CTEs or separate fetches)
-- 6. Transaction blocks decomposed into separate statements
-- 
-- PostgreSQL Compatible Features (no conversion needed):
-- - CTEs (WITH clause)
-- - Window functions (AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK, MIN OVER, MAX OVER)
-- - CASE expressions
-- - ROUND function
-- - JOIN operations
-- ============================================================================
