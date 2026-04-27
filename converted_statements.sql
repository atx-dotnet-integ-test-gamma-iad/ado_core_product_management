-- ============================================================
-- Converted SQL Statements for PostgreSQL
-- Target: PostgreSQL 13
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (converted)
-- Conversion: Lowercase schema objects, ROUND with numeric cast
-- ============================================================
WITH productstats_cte AS (
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
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================================
-- Statement 2: GetProductByIdAsync (converted)
-- Conversion: Lowercase schema objects, LAG window function compatible
-- ============================================================
WITH producthistory_cte AS (
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
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================================
-- Statement 3: InsertProductAsync (converted)
-- Conversion: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> now(), 
--             DECLARE @var -> PostgreSQL DO block with variables,
--             Transaction restructured for PostgreSQL compatibility
-- ============================================================
-- Note: For ADO.NET integration, the transaction block is restructured.
-- The INSERT with RETURNING replaces SCOPE_IDENTITY().
-- The application code handles the transaction via ADO.NET BeginTransaction.
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Separate statements executed within same ADO.NET transaction:
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, now());
-- 
-- UPDATE productstats
-- SET 
--     totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--     lastupdated = now()
-- WHERE statid = 1;

-- ============================================================
-- Statement 4: UpdateProductAsync (converted)
-- Conversion: DECLARE -> DO block, GETDATE() -> now(), lowercase schema
-- ============================================================
-- Note: For ADO.NET integration, restructured as sequential statements
-- within a single ADO.NET transaction.
-- SELECT price, stockquantity FROM products WHERE productid = @ProductId;
-- UPDATE products SET ... WHERE productid = @ProductId;
-- INSERT INTO producthistory ...;
-- UPDATE productstats ...;

-- ============================================================
-- Statement 5: DeleteProductAsync (converted)
-- Conversion: DECLARE -> DO block, GETDATE() -> now(), lowercase schema
-- ============================================================
-- Note: For ADO.NET integration, restructured as sequential statements
-- within a single ADO.NET transaction.
-- SELECT price, stockquantity FROM products WHERE productid = @ProductId;
-- INSERT INTO producthistory ...;
-- DELETE FROM products WHERE productid = @ProductId;
-- UPDATE productstats ...;

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync (converted)
-- Conversion: Lowercase schema objects, window functions compatible
-- ============================================================
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

-- ============================================================
-- Statement 7: GetLowStockProductsAsync (converted)
-- Conversion: Lowercase schema objects, numeric cast for ROUND
-- ============================================================
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
