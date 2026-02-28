-- =====================================================
-- Converted SQL Statements for PostgreSQL
-- Target: PostgreSQL 13+
-- Total: 15 individual SQL statements
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- =====================================================

-- Statement 1: GetAllProductsAsync - sql (PostgreSQL)
-- Conversion notes: Schema objects lowercased. ROUND and CASE syntax compatible.
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

-- =====================================================

-- Statement 2: GetProductByIdAsync - sql (PostgreSQL)
-- Conversion notes: Schema objects lowercased. LAG window function compatible.
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

-- =====================================================

-- Statement 3: InsertProductAsync - insertProductSql (PostgreSQL)
-- Conversion notes: SCOPE_IDENTITY() replaced with RETURNING clause.
-- Schema objects lowercased.
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- =====================================================

-- Statement 4: InsertProductAsync - insertHistorySql (PostgreSQL)
-- Conversion notes: GETDATE() replaced with NOW(). Schema objects lowercased.
-- @NewProductId replaced with @ProductId (C# app-level variable).
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- =====================================================

-- Statement 5: InsertProductAsync - updateStatsSql (PostgreSQL)
-- Conversion notes: GETDATE() replaced with NOW(). Schema objects lowercased.
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================

-- Statement 6: UpdateProductAsync - selectOldValuesSql (PostgreSQL)
-- Conversion notes: SELECT @var = col pattern replaced with SELECT col
-- for C# reader pattern. Schema objects lowercased.
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- =====================================================

-- Statement 7: UpdateProductAsync - updateProductSql (PostgreSQL)
-- Conversion notes: GETDATE() replaced with NOW(). Schema objects lowercased.
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- =====================================================

-- Statement 8: UpdateProductAsync - insertHistorySql (PostgreSQL)
-- Conversion notes: GETDATE() replaced with NOW(). Schema objects lowercased.
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- =====================================================

-- Statement 9: UpdateProductAsync - updateStatsSql (PostgreSQL)
-- Conversion notes: GETDATE() replaced with NOW(). Schema objects lowercased.
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================

-- Statement 10: DeleteProductAsync - selectOldValuesSql (PostgreSQL)
-- Conversion notes: SELECT @var = col pattern replaced with SELECT col
-- for C# reader pattern. Schema objects lowercased.
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- =====================================================

-- Statement 11: DeleteProductAsync - insertHistorySql (PostgreSQL)
-- Conversion notes: GETDATE() replaced with NOW(). Schema objects lowercased.
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- =====================================================

-- Statement 12: DeleteProductAsync - deleteProductSql (PostgreSQL)
-- Conversion notes: Schema objects lowercased.
DELETE FROM products 
WHERE productid = @ProductId;

-- =====================================================

-- Statement 13: DeleteProductAsync - updateStatsSql (PostgreSQL)
-- Conversion notes: GETDATE() replaced with NOW(). Schema objects lowercased.
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

-- =====================================================

-- Statement 14: GetProductsByPriceRangeAsync - sql (PostgreSQL)
-- Conversion notes: Schema objects lowercased. RANK(), PERCENT_RANK() compatible.
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

-- =====================================================

-- Statement 15: GetLowStockProductsAsync - sql (PostgreSQL)
-- Conversion notes: Schema objects lowercased. Window functions compatible.
-- CAST added for integer division to produce decimal result.
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
    ROUND((CAST(stockquantity AS DECIMAL) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
