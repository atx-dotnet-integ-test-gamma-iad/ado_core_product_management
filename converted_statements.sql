-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Equivalents
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Conversion: Lowercase schema objects, syntax is PostgreSQL-compatible
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
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Conversion: Lowercase schema objects, syntax is PostgreSQL-compatible
-- ============================================================================
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

-- ============================================================================
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Conversion: SCOPE_IDENTITY() -> RETURNING productid + CTE chain
--             GETDATE() -> NOW()
--             DECLARE/SET -> use WITH (CTE) and subquery
--             Restructured as DO block with variables
-- ============================================================================
DO $$
DECLARE
    v_newproductid INT;
BEGIN
    -- Insert the new product
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@name, @description, @price, @stockquantity)
    RETURNING productid INTO v_newproductid;
    
    -- Log the insertion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (v_newproductid, 'INSERT', NULL, @price, NULL, @stockquantity, NOW());
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- ============================================================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Conversion: DECLARE -> DO block DECLARE
--             GETDATE() -> NOW()
--             SELECT INTO variables -> SELECT INTO
-- ============================================================================
DO $$
DECLARE
    v_oldprice DECIMAL(18,2);
    v_oldstock INT;
BEGIN
    -- Store old values for history
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @productid;
    
    -- Update the product
    UPDATE products
    SET 
        name = @name,
        description = @description,
        price = @price,
        stockquantity = @stockquantity,
        modifieddate = NOW()
    WHERE productid = @productid;
    
    -- Log the changes
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@productid, 'UPDATE', v_oldprice, @price, v_oldstock, @stockquantity, NOW());
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - v_oldprice + @price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- ============================================================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Conversion: DECLARE -> DO block DECLARE
--             GETDATE() -> NOW()
--             SELECT INTO variables -> SELECT INTO
-- ============================================================================
DO $$
DECLARE
    v_oldprice DECIMAL(18,2);
    v_oldstock INT;
BEGIN
    -- Store product info for history
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @productid;
    
    -- Log the deletion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@productid, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, NOW());
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = @productid;
    
    -- Update product statistics
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

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Conversion: Lowercase schema objects, syntax is PostgreSQL-compatible
-- ============================================================================
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

-- ============================================================================
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Conversion: Lowercase schema objects, syntax is PostgreSQL-compatible
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
        WHEN stockquantity <= @threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((CAST(stockquantity AS DECIMAL) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @threshold
ORDER BY stockquantity;
