-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs (converted from MS SQL Server)
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (converted to PostgreSQL)
-- Original Method: GetAllProductsAsync()
-- Conversion Notes: 
--   - Table/column names lowercased
--   - CTE name changed to avoid conflict with table name productstats
--   - ROUND compatible with PostgreSQL decimal division
-- ============================================================================
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

-- ============================================================================
-- Statement 2: GetProductByIdAsync (converted to PostgreSQL)
-- Original Method: GetProductByIdAsync(int productId)
-- Conversion Notes:
--   - Table/column names lowercased
--   - CTE name changed to avoid conflict with table name producthistory
--   - LAG window function is PostgreSQL compatible
--   - @ProductId parameter kept (Npgsql supports @ prefix)
-- ============================================================================
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

-- ============================================================================
-- Statement 3: InsertProductAsync (converted to PostgreSQL)
-- Original Method: InsertProductAsync(Product product)
-- Conversion Notes:
--   - SCOPE_IDENTITY() replaced with RETURNING clause via CTE chain
--   - GETDATE() replaced with NOW()
--   - DECLARE/@var pattern replaced with CTE+RETURNING pattern
--   - Transaction uses BEGIN/COMMIT
-- ============================================================================
WITH new_product AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM new_product
    RETURNING productid
)
SELECT productid FROM new_product;

-- ============================================================================
-- Statement 3b: InsertProductAsync - Stats Update (separate statement)
-- ============================================================================
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- Statement 4: UpdateProductAsync (converted to PostgreSQL)
-- Original Method: UpdateProductAsync(Product product)
-- Conversion Notes:
--   - DECLARE/SET variables replaced with CTE+subquery pattern
--   - GETDATE() replaced with NOW()
--   - Table/column names lowercased
-- ============================================================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
),
do_update AS (
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId
    RETURNING productid
)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
SELECT @ProductId, 'UPDATE', ov.oldprice, @Price, ov.oldstock, @StockQuantity, NOW()
FROM old_values ov;

-- ============================================================================
-- Statement 4b: UpdateProductAsync - Stats Update (separate statement)
-- ============================================================================
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- Statement 5: DeleteProductAsync (converted to PostgreSQL)
-- Original Method: DeleteProductAsync(int productId)
-- Conversion Notes:
--   - DECLARE/SET variables replaced with CTE pattern
--   - GETDATE() replaced with NOW()
--   - Table/column names lowercased
--   - Restructured: capture old values, log history, then delete
-- ============================================================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', ov.oldprice, NULL, ov.oldstock, NULL, NOW()
    FROM old_values ov
    RETURNING productid
)
DELETE FROM products 
WHERE productid = @ProductId;

-- ============================================================================
-- Statement 5b: DeleteProductAsync - Stats Update (separate statement)
-- ============================================================================
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

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (converted to PostgreSQL)
-- Original Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Notes:
--   - Table/column names lowercased
--   - RANK() and PERCENT_RANK() are PostgreSQL compatible
--   - BETWEEN is PostgreSQL compatible
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
-- Statement 7: GetLowStockProductsAsync (converted to PostgreSQL)
-- Original Method: GetLowStockProductsAsync(int threshold)
-- Conversion Notes:
--   - Table/column names lowercased
--   - AVG/MIN/MAX OVER() are PostgreSQL compatible
--   - ROUND needs CAST for integer division
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
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
