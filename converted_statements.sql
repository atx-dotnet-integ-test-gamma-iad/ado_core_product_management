-- ============================================================================
-- Converted SQL Statements for PostgreSQL
-- Target: PostgreSQL (productmanagement_dbo schema)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation did not complete after 15 attempts
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
-- Date: 2026-04-04
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync
-- Conversion: Table/column names lowercased, schema prefixed with productmanagement_dbo
-- ============================================================================
WITH productstats_cte AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM productmanagement_dbo.products
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
FROM productmanagement_dbo.products p
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================================================
-- Statement 2: GetProductByIdAsync
-- Conversion: Table/column names lowercased, schema prefixed, LAG supported in PostgreSQL
-- ============================================================================
WITH producthistory_cte AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM productmanagement_dbo.products
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
FROM productmanagement_dbo.products p
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @productid;

-- ============================================================================
-- Statement 3: InsertProductAsync
-- Conversion: SCOPE_IDENTITY() -> lastval() or RETURNING, GETDATE() -> clock_timestamp()
-- Transaction block converted to PostgreSQL DO block style
-- ============================================================================
DO $$
DECLARE
    v_newproductid INTEGER;
BEGIN
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@name, @description, @price, @stockquantity)
    RETURNING productid INTO v_newproductid;
    
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (v_newproductid, 'INSERT', NULL, @price, NULL, @stockquantity, clock_timestamp());
    
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

SELECT lastval();

-- ============================================================================
-- Statement 4: UpdateProductAsync
-- Conversion: DECLARE/SELECT INTO variables -> PostgreSQL DO block, GETDATE() -> clock_timestamp()
-- ============================================================================
DO $$
DECLARE
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM productmanagement_dbo.products
    WHERE productid = @productid;
    
    UPDATE productmanagement_dbo.products
    SET 
        name = @name,
        description = @description,
        price = @price,
        stockquantity = @stockquantity,
        modifieddate = clock_timestamp()
    WHERE productid = @productid;
    
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@productid, 'UPDATE', v_oldprice, @price, v_oldstock, @stockquantity, clock_timestamp());
    
    UPDATE productmanagement_dbo.productstats
    SET 
        averageprice = (averageprice * totalproducts - v_oldprice + @price) / totalproducts,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- ============================================================================
-- Statement 5: DeleteProductAsync
-- Conversion: DECLARE/SELECT INTO -> PostgreSQL DO block, GETDATE() -> clock_timestamp(), CASE preserved
-- ============================================================================
DO $$
DECLARE
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM productmanagement_dbo.products
    WHERE productid = @productid;
    
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@productid, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, clock_timestamp());
    
    DELETE FROM productmanagement_dbo.products 
    WHERE productid = @productid;
    
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - v_oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Conversion: Table/column names lowercased, RANK()/PERCENT_RANK() supported in PostgreSQL
-- ============================================================================
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM productmanagement_dbo.products p
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

-- ============================================================================
-- Statement 7: GetLowStockProductsAsync
-- Conversion: Table/column names lowercased, AVG/MIN/MAX OVER supported in PostgreSQL
-- ============================================================================
WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM productmanagement_dbo.products p
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
