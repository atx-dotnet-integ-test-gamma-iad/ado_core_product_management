-- ============================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Purpose: PostgreSQL-converted statements from SQL Server
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Conversion Date: 2025-02-26
-- Note: All DMS tool invocations failed with metadata model creation error
--       Manual conversion applied following PostgreSQL syntax with lowercase schema objects
-- ============================================

-- ============================================
-- STATEMENT #1: GetAllProductsAsync (PostgreSQL)
-- ============================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
--   - Lowercase schema objects: Products → products, ProductId → productid, etc.
--   - Window functions (AVG, COUNT OVER) compatible - no changes
--   - CASE expressions compatible - no changes
-- ============================================
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

-- ============================================
-- STATEMENT #2: GetProductByIdAsync (PostgreSQL)
-- ============================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
--   - Lowercase schema objects
--   - LAG window function compatible - no changes
--   - Parameter @ProductId remains (PostgreSQL compatible)
-- ============================================
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

-- ============================================
-- STATEMENT #3: InsertProductAsync (PostgreSQL)
-- ============================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
--   - Lowercase schema objects
--   - SCOPE_IDENTITY() → RETURNING productid on first INSERT
--   - GETDATE() → NOW()
--   - Removed DECLARE/SET (handled in code layer)
--   - BEGIN TRANSACTION → BEGIN
--   - Restructured to use RETURNING instead of SCOPE_IDENTITY()
-- Note: This will be split into multiple statements in code to handle RETURNING value
-- ============================================
-- Statement 3a: Insert product and get ID via RETURNING
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Log the insertion (executed after getting productid from RETURNING)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Statement 3c: Update product statistics
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================
-- STATEMENT #4: UpdateProductAsync (PostgreSQL)
-- ============================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
--   - Lowercase schema objects
--   - GETDATE() → NOW()
--   - Transaction will be handled at code level
--   - Removed DECLARE (will use CTEs or separate statements)
-- Note: Will be executed as separate statements within a transaction
-- ============================================
-- Statement 4a: Store old values (using CTE in subsequent UPDATE or separate SELECT)
-- This will be handled in code by doing a SELECT first

-- Statement 4b: Update the product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- Statement 4c: Log the changes (old values passed as parameters from code)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Statement 4d: Update product statistics
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================
-- STATEMENT #5: DeleteProductAsync (PostgreSQL)
-- ============================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
--   - Lowercase schema objects
--   - GETDATE() → NOW()
--   - CASE expression compatible
--   - Transaction will be handled at code level
-- Note: Will be executed as separate statements within a transaction
-- ============================================
-- Statement 5a: Store product info for history (handled in code with SELECT first)

-- Statement 5b: Log the deletion (old values passed as parameters from code)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Statement 5c: Delete the product
DELETE FROM products 
WHERE productid = @ProductId;

-- Statement 5d: Update product statistics
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================
-- STATEMENT #6: GetProductsByPriceRangeAsync (PostgreSQL)
-- ============================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
--   - Lowercase schema objects
--   - RANK() and PERCENT_RANK() compatible - no changes
--   - CASE expression compatible
-- ============================================
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

-- ============================================
-- STATEMENT #7: GetLowStockProductsAsync (PostgreSQL)
-- ============================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
--   - Lowercase schema objects
--   - AVG(), MIN(), MAX() window functions compatible - no changes
--   - CASE expression compatible
--   - ROUND function compatible
-- ============================================
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

-- ============================================
-- END OF CONVERTED STATEMENTS
-- Total Statements: 7
-- Conversion Method: All manually converted due to DMS tool failures
-- ============================================
