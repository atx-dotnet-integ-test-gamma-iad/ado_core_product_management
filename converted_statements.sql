-- ============================================================
-- Converted PostgreSQL Statements from ProductRepository.cs
-- Source: DataAccess/ProductRepository.cs
-- Conversion Date: 2026-03-28
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Schema mappings obtained from DMS schema_mapping_tool
-- Total Statements: 7
-- DMS statement_conversion_tool status: FAILED (timeout errors on all attempts)
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Conversion: Lowercase schema objects per DMS schema mapping
-- Changes: Products->products, ProductId->productid, Name->name, etc.
-- ROUND and CASE and window functions are compatible with PostgreSQL
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
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Conversion: Lowercase schema objects per DMS schema mapping
-- Changes: Products->products, LAG window function compatible
-- Parameters: @ProductId -> @productid
-- ============================================================
WITH producthistory_cte AS (
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
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @productid;

-- ============================================================
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Conversion: SCOPE_IDENTITY()->RETURNING, GETDATE()->NOW(),
--   DECLARE/SET->DO block or RETURNING clause, transaction syntax
-- Parameters: @Name->@name, @Description->@description, etc.
-- ============================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@name, @description, @price, @stockquantity)
RETURNING productid;

-- Note: The original transaction block with ProductHistory and ProductStats
-- updates is converted to individual statements managed by ADO.NET transaction.
-- The RETURNING clause replaces SCOPE_IDENTITY().
-- ProductHistory insert and ProductStats update are handled separately below.

-- ProductHistory insert (part of InsertProductAsync transaction):
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@newproductid, 'INSERT', NULL, @price, NULL, @stockquantity, NOW());

-- ProductStats update (part of InsertProductAsync transaction):
-- UPDATE productstats
-- SET 
--     totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @price) / (totalproducts + 1),
--     lastupdated = NOW()
-- WHERE statid = 1;

-- ============================================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Conversion: DECLARE->subquery or separate SELECT, GETDATE()->NOW()
-- Parameters: @ProductId->@productid, etc.
-- ============================================================
DO $$
DECLARE
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
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
    VALUES (@productid, 'UPDATE', v_oldprice, @price, v_oldstock, @stockquantity, NOW());
    
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - v_oldprice + @price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- ============================================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Conversion: DECLARE->subquery or separate SELECT, GETDATE()->NOW()
-- Parameters: @ProductId->@productid
-- ============================================================
DO $$
DECLARE
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @productid;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@productid, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, NOW());
    
    DELETE FROM products 
    WHERE productid = @productid;
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - v_oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Conversion: Lowercase schema objects per DMS schema mapping
-- RANK, PERCENT_RANK, BETWEEN, CASE are compatible
-- Parameters: @MinPrice->@minprice, @MaxPrice->@maxprice
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
-- Conversion: Lowercase schema objects per DMS schema mapping
-- AVG/MIN/MAX window functions, CASE, ROUND compatible
-- Parameters: @Threshold->@threshold
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
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @threshold
ORDER BY stockquantity;
