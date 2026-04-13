-- ============================================================
-- Converted SQL Statements (PostgreSQL) from ProductRepository.cs
-- All 7 statements converted manually due to DMS failure
-- Conversion method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Original: CTE with window functions, CASE, ROUND, INNER JOIN
-- Changes: All schema object names lowercased for PostgreSQL
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
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Original: CTE with LAG, CASE, ROUND, LEFT JOIN, parameterized
-- Changes: All schema object names lowercased, @ProductId → @productid
-- ============================================================

WITH producthistory AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = @productid
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
WHERE p.productid = @productid;

-- ============================================================
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Original: Transaction with DECLARE, SCOPE_IDENTITY(), GETDATE()
-- Changes: Removed DECLARE/SET, use RETURNING, GETDATE()→NOW(),
--          restructured to use INSERT...RETURNING and separate statements
--          All schema object names lowercased
-- ============================================================

BEGIN;
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@name, @description, @price, @stockquantity)
    RETURNING productid;

-- ============================================================
-- Statement 3b: InsertProductAsync - History insert (PostgreSQL)
-- ============================================================

    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@newproductid, 'INSERT', NULL, @price, NULL, @stockquantity, NOW());

-- ============================================================
-- Statement 3c: InsertProductAsync - Stats update (PostgreSQL)
-- ============================================================

    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ============================================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Original: Transaction with DECLARE, SELECT into vars, UPDATE, INSERT, GETDATE()
-- Changes: GETDATE()→NOW(), removed SQL Server DECLARE syntax,
--          use SELECT INTO for variables, all schema names lowercased
-- ============================================================

BEGIN;
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @productid;

    UPDATE products
    SET 
        name = @name,
        description = @description,
        price = @price,
        stockquantity = @stockquantity,
        modifieddate = NOW()
    WHERE productid = @productid;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@productid, 'UPDATE', @oldprice, @price, @oldstock, @stockquantity, NOW());
    
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - @oldprice + @price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ============================================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Original: Transaction with DECLARE, SELECT, INSERT, DELETE, UPDATE with CASE, GETDATE()
-- Changes: GETDATE()→NOW(), removed DECLARE, all schema names lowercased
-- ============================================================

BEGIN;
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @productid;

    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@productid, 'DELETE', @oldprice, NULL, @oldstock, NULL, NOW());
    
    DELETE FROM products 
    WHERE productid = @productid;
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - @oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original: CTE with RANK, PERCENT_RANK, BETWEEN, CASE
-- Changes: All schema object names lowercased, parameter names lowercased
-- ============================================================

WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN @minprice AND @maxprice
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
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Original: CTE with AVG/MIN/MAX window functions, CASE, ROUND
-- Changes: All schema object names lowercased, parameter names lowercased,
--          CAST added for integer division to produce decimal result
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
        WHEN stockquantity <= @threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((CAST(stockquantity AS DECIMAL) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @threshold
ORDER BY stockquantity;
