-- Converted SQL Statements Catalog (PostgreSQL)
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Total statements: 7
-- Conversion method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (all statements)
-- DMS failure reason: Metadata model creation failed after 15 attempts

-- ============================================================
-- Statement 1: GetAllProductsAsync()
-- ============================================================
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

-- ============================================================
-- Statement 2: GetProductByIdAsync(int productId)
-- ============================================================
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

-- ============================================================
-- Statement 3: InsertProductAsync(Product product)
-- Conversion: SCOPE_IDENTITY() replaced with RETURNING clause via writeable CTE
-- GETDATE() replaced with NOW()
-- Transaction handled implicitly by single-statement CTE
-- ============================================================
WITH inserted AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM inserted
),
stats_update AS (
    UPDATE productstats
    SET totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1
)
SELECT productid FROM inserted;

-- ============================================================
-- Statement 4: UpdateProductAsync(Product product)
-- Conversion: DECLARE/SET replaced with writeable CTE to capture old values
-- GETDATE() replaced with NOW()
-- Transaction handled implicitly by single-statement CTE
-- ============================================================
WITH old_values AS (
    SELECT price, stockquantity FROM products WHERE productid = @ProductId
),
product_update AS (
    UPDATE products
    SET name = @Name, description = @Description, price = @Price,
        stockquantity = @StockQuantity, modifieddate = NOW()
    WHERE productid = @ProductId
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', ov.price, @Price, ov.stockquantity, @StockQuantity, NOW()
    FROM old_values ov
)
UPDATE productstats
SET averageprice = (averageprice * totalproducts - (SELECT price FROM old_values) + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================
-- Statement 5: DeleteProductAsync(int productId)
-- Conversion: DECLARE/SET replaced with writeable CTE to capture old values
-- GETDATE() replaced with NOW()
-- Transaction handled implicitly by single-statement CTE
-- ============================================================
WITH old_values AS (
    SELECT price, stockquantity FROM products WHERE productid = @ProductId
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', ov.price, NULL, ov.stockquantity, NULL, NOW()
    FROM old_values ov
),
product_delete AS (
    DELETE FROM products WHERE productid = @ProductId
)
UPDATE productstats
SET totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT price FROM old_values)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
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
-- Statement 7: GetLowStockProductsAsync(int threshold)
-- Conversion: Added ::numeric cast for integer division fix
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
        WHEN sa.stockquantity <= @Threshold THEN 'Critical'
        WHEN sa.stockquantity <= sa.avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((sa.stockquantity::numeric / sa.avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE sa.stockquantity <= @Threshold
ORDER BY sa.stockquantity;
