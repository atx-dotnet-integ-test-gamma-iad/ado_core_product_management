-- ============================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Conversion Date: Migration Phase - Step 2
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================

-- ============================================
-- STATEMENT 1: GetAllProductsAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- Manual Conversion Notes: 
--   - Applied lowercase schema object names (Products -> products, ProductId -> productid, etc.)
--   - No syntax changes needed for CTEs, window functions, CASE, or ROUND in PostgreSQL
--   - PostgreSQL supports same window function and CTE syntax
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
-- STATEMENT 2: GetProductByIdAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- Manual Conversion Notes:
--   - Applied lowercase schema object names
--   - LAG window function is compatible in PostgreSQL
--   - Parameters remain @ProductId (Npgsql driver will handle)
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
-- STATEMENT 3: InsertProductAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- Manual Conversion Notes:
--   - Applied lowercase schema object names
--   - Removed DECLARE (PostgreSQL uses DO blocks or function parameters)
--   - Removed BEGIN TRANSACTION/COMMIT (handled at application level in PostgreSQL)
--   - Changed SCOPE_IDENTITY() to RETURNING clause
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Split into separate statements for application-level transaction control
-- PostgreSQL Transaction Handling Note:
--   These statements should be executed within a single transaction at the application level
--   using NpgsqlTransaction.BeginTransaction()/Commit()
-- ============================================

-- First INSERT with RETURNING
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Second INSERT for history (productid from RETURNING above)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Third UPDATE for statistics
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================
-- STATEMENT 4: UpdateProductAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- Manual Conversion Notes:
--   - Applied lowercase schema object names
--   - Removed BEGIN TRANSACTION/COMMIT (handled at application level)
--   - Variable declarations moved to application code
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Split into separate statements for application-level transaction control
-- PostgreSQL Transaction Handling Note:
--   These statements should be executed within a single transaction at the application level
--   Old values need to be retrieved first in application code before UPDATE
-- ============================================

-- First SELECT to get old values (handled in application code)
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Second UPDATE statement
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Third INSERT for history
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Fourth UPDATE for statistics
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================
-- STATEMENT 5: DeleteProductAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- Manual Conversion Notes:
--   - Applied lowercase schema object names
--   - Removed BEGIN TRANSACTION/COMMIT (handled at application level)
--   - Variable declarations moved to application code
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Split into separate statements for application-level transaction control
-- PostgreSQL Transaction Handling Note:
--   These statements should be executed within a single transaction at the application level
--   Old values need to be retrieved first in application code before DELETE
-- ============================================

-- First SELECT to get old values (handled in application code)
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Second INSERT for history
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Third DELETE statement
DELETE FROM products 
WHERE productid = @ProductId;

-- Fourth UPDATE for statistics
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

-- ============================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- Manual Conversion Notes:
--   - Applied lowercase schema object names
--   - RANK() and PERCENT_RANK() window functions are compatible in PostgreSQL
--   - No syntax changes needed
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
-- STATEMENT 7: GetLowStockProductsAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- Manual Conversion Notes:
--   - Applied lowercase schema object names
--   - Window functions AVG/MIN/MAX are compatible in PostgreSQL
--   - No syntax changes needed
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
-- ============================================

-- ============================================
-- CONVERSION SUMMARY
-- ============================================
-- Total Statements Converted: 7
-- Conversion Method: All statements manually converted due to DMS tool failure
-- DMS Error (all statements): Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- 
-- Key Transformation Rules Applied:
-- 1. Schema object names converted to lowercase (PostgreSQL convention)
-- 2. GETDATE() -> CURRENT_TIMESTAMP
-- 3. SCOPE_IDENTITY() -> RETURNING clause
-- 4. BEGIN TRANSACTION/COMMIT removed (handled at application level with NpgsqlTransaction)
-- 5. DECLARE statements removed (variables handled in application code)
-- 6. Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX) - no changes needed
-- 7. CTEs (WITH clauses) - no changes needed
-- 8. CASE statements - no changes needed
-- 9. ROUND function - no changes needed
-- 10. Parameters (@param) - compatible with Npgsql driver
-- ============================================
