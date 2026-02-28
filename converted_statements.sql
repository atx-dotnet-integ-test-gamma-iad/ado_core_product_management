-- ============================================================
-- Converted SQL Statements (MS SQL Server → PostgreSQL)
-- Source: ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (CONVERTED)
-- Original: CTE with ProductStats, window functions, INNER JOIN, CASE WHEN, ROUND
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
-- Statement 2: GetProductByIdAsync (CONVERTED)
-- Original: CTE with ProductHistory, LAG window function, LEFT JOIN
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
-- Statement 3: InsertProductAsync (CONVERTED)
-- Original: DECLARE, BEGIN TRANSACTION, SCOPE_IDENTITY(), GETDATE()
-- Converted: Uses INSERT...RETURNING, NOW(), DO block for variable
-- Note: For Npgsql integration, the transaction block is simplified.
--       SCOPE_IDENTITY() is replaced with INSERT...RETURNING.
--       GETDATE() is replaced with NOW().
-- ============================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- (The following are executed separately in the transaction context managed by C# code)
-- After obtaining newproductid from RETURNING:
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
--
-- UPDATE productstats
-- SET totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--     lastupdated = NOW()
-- WHERE statid = 1;

-- Full transactional block for reference (DO block approach):
-- DO $$
-- DECLARE
--     newproductid INT;
-- BEGIN
--     INSERT INTO products (name, description, price, stockquantity)
--     VALUES (@Name, @Description, @Price, @StockQuantity)
--     RETURNING productid INTO newproductid;
--
--     INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
--     VALUES (newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
--
--     UPDATE productstats
--     SET totalproducts = totalproducts + 1,
--         averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--         lastupdated = NOW()
--     WHERE statid = 1;
-- END $$;

-- ============================================================
-- Statement 4: UpdateProductAsync (CONVERTED)
-- Original: BEGIN TRANSACTION, DECLARE variables, SELECT INTO vars, UPDATE, INSERT, COMMIT
-- Converted: DO block with PostgreSQL variable syntax, NOW() instead of GETDATE()
-- ============================================================
DO $$
DECLARE
    oldprice DECIMAL(18,2);
    oldstock INT;
BEGIN
    SELECT price, stockquantity INTO oldprice, oldstock
    FROM products
    WHERE productid = @ProductId;
    
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', oldprice, @Price, oldstock, @StockQuantity, NOW());
    
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - oldprice + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- ============================================================
-- Statement 5: DeleteProductAsync (CONVERTED)
-- Original: BEGIN TRANSACTION, DECLARE, SELECT INTO, INSERT, DELETE, UPDATE CASE, COMMIT
-- Converted: DO block with PostgreSQL variable syntax, NOW() instead of GETDATE()
-- ============================================================
DO $$
DECLARE
    oldprice DECIMAL(18,2);
    oldstock INT;
BEGIN
    SELECT price, stockquantity INTO oldprice, oldstock
    FROM products
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', oldprice, NULL, oldstock, NULL, NOW());
    
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Original: CTE with RANK/PERCENT_RANK, BETWEEN, CASE WHEN
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
-- Statement 7: GetLowStockProductsAsync (CONVERTED)
-- Original: CTE with AVG/MIN/MAX OVER, CASE WHEN, ROUND
-- Converted: Added ::numeric cast for integer division in ROUND
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
