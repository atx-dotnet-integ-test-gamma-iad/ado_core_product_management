-- ============================================================================
-- Converted SQL Statements - PostgreSQL (from MS SQL Server)
-- Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync
-- Conversion: Lowercase schema objects. ROUND numeric cast for PostgreSQL.
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
-- Statement 2: GetProductByIdAsync
-- Conversion: Lowercase schema objects. LAG window function compatible.
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
-- Statement 3: InsertProductAsync
-- Conversion: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> NOW(),
--             DECLARE/SET -> PostgreSQL DO block with RETURNING clause,
--             Transaction handled by application code in PostgreSQL.
-- NOTE: For Npgsql, the transaction block (BEGIN/COMMIT) is handled by the
--       application code. The SQL is restructured to use RETURNING and
--       separate statements executed within an application-level transaction.
-- ============================================================================

INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- (Executed separately within application-managed transaction):
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
--
-- UPDATE productstats
-- SET totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--     lastupdated = NOW()
-- WHERE statid = 1;

-- ============================================================================
-- Statement 4: UpdateProductAsync
-- Conversion: GETDATE() -> NOW(), DECLARE -> PostgreSQL variables in DO block,
--             Transaction handled by application code.
-- NOTE: Since Npgsql does not support T-SQL variables in inline SQL,
--       we restructure to use multiple statements in application-level transaction.
-- ============================================================================

SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- (Then in application code, capture OldPrice/OldStock and execute):
-- UPDATE products
-- SET name = @Name, description = @Description, price = @Price,
--     stockquantity = @StockQuantity, modifieddate = NOW()
-- WHERE productid = @ProductId;
--
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());
--
-- UPDATE productstats
-- SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
--     lastupdated = NOW()
-- WHERE statid = 1;

-- ============================================================================
-- Statement 5: DeleteProductAsync
-- Conversion: GETDATE() -> NOW(), DECLARE -> handled in application code,
--             Transaction handled by application code.
-- ============================================================================

SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- (Then in application code, capture OldPrice/OldStock and execute):
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());
--
-- DELETE FROM products WHERE productid = @ProductId;
--
-- UPDATE productstats
-- SET totalproducts = totalproducts - 1,
--     averageprice = CASE
--         WHEN totalproducts > 1
--         THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
--         ELSE 0
--     END,
--     lastupdated = NOW()
-- WHERE statid = 1;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Conversion: Lowercase schema objects. RANK/PERCENT_RANK compatible.
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
-- Statement 7: GetLowStockProductsAsync
-- Conversion: Lowercase schema objects. Added ::numeric cast for integer division.
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
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
