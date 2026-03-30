-- ============================================================
-- Converted SQL Statements for PostgreSQL
-- Source: DataAccess/ProductRepository.cs
-- Target: PostgreSQL (via DMS schema mapping + manual conversion)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS schema mapping used: dbo.Products -> products, 
--   dbo.ProductHistory -> producthistory, dbo.ProductStats -> productstats
-- All column names converted to lowercase per DMS schema mapping
-- GETDATE() -> clock_timestamp(), SCOPE_IDENTITY() -> RETURNING, 
-- ROUND with integer division -> ROUND with CAST to NUMERIC
-- ============================================================

-- Statement 1: GetAllProductsAsync (Converted to PostgreSQL)
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
-- Statement 2: GetProductByIdAsync (Converted to PostgreSQL)
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
-- Statement 3: InsertProductAsync (Converted to PostgreSQL)
-- Note: PostgreSQL uses DO blocks for variable declarations in anonymous blocks
-- SCOPE_IDENTITY() replaced with RETURNING clause pattern
-- GETDATE() replaced with clock_timestamp()
DO $$
DECLARE
    v_newproductid INTEGER;
BEGIN
    -- Insert the new product
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO v_newproductid;
    
    -- Log the insertion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (v_newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- ============================================================
-- Statement 4: UpdateProductAsync (Converted to PostgreSQL)
-- GETDATE() replaced with clock_timestamp()
DO $$
DECLARE
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    -- Update the product
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = clock_timestamp()
    WHERE productid = @ProductId;
    
    -- Log the changes
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', v_oldprice, @Price, v_oldstock, @StockQuantity, clock_timestamp());
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - v_oldprice + @Price) / totalproducts,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- ============================================================
-- Statement 5: DeleteProductAsync (Converted to PostgreSQL)
-- GETDATE() replaced with clock_timestamp()
DO $$
DECLARE
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    -- Log the deletion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, clock_timestamp());
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productstats
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

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted to PostgreSQL)
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
-- Statement 7: GetLowStockProductsAsync (Converted to PostgreSQL)
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

-- ============================================================
-- SCRIPT STATEMENTS: Converted from Scripts/01_InitialSetup.sql
-- ============================================================

-- Statement 8: CREATE TABLE products (Converted to PostgreSQL)
CREATE TABLE IF NOT EXISTS products(
    productid INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE
);

-- Statement 9: sp_getallproducts function (Converted to PostgreSQL)
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE(
    productid INTEGER, name VARCHAR(100), description VARCHAR(500),
    price NUMERIC(18,2), stockquantity INTEGER,
    createddate TIMESTAMP WITHOUT TIME ZONE, modifieddate TIMESTAMP WITHOUT TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- Statement 10: sp_getproductbyid function (Converted to PostgreSQL)
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INTEGER)
RETURNS TABLE(
    productid INTEGER, name VARCHAR(100), description VARCHAR(500),
    price NUMERIC(18,2), stockquantity INTEGER,
    createddate TIMESTAMP WITHOUT TIME ZONE, modifieddate TIMESTAMP WITHOUT TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p WHERE p.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Statement 11: sp_insertproduct function (Converted to PostgreSQL)
CREATE OR REPLACE FUNCTION sp_insertproduct(
    p_name VARCHAR(100), p_description VARCHAR(500),
    p_price NUMERIC(18,2), p_stockquantity INTEGER
) RETURNS TABLE(productid INTEGER) AS $$
BEGIN
    RETURN QUERY
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING products.productid;
END;
$$ LANGUAGE plpgsql;

-- Statement 12: sp_updateproduct function (Converted to PostgreSQL)
CREATE OR REPLACE FUNCTION sp_updateproduct(
    p_productid INTEGER, p_name VARCHAR(100), p_description VARCHAR(500),
    p_price NUMERIC(18,2), p_stockquantity INTEGER
) RETURNS VOID AS $$
BEGIN
    UPDATE products SET name = p_name, description = p_description,
        price = p_price, stockquantity = p_stockquantity,
        modifieddate = clock_timestamp()
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Statement 13: sp_deleteproduct function (Converted to PostgreSQL)
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid INTEGER)
RETURNS VOID AS $$
BEGIN
    DELETE FROM products WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Statement 14: UPDATE productstats with subqueries (Converted to PostgreSQL)
UPDATE productstats
SET
    totalproducts = (SELECT COUNT(*) FROM products),
    averageprice = (SELECT AVG(price) FROM products),
    totalstockvalue = (SELECT SUM(price * stockquantity) FROM products),
    lowstockcount = (SELECT COUNT(*) FROM products WHERE stockquantity <= reorderlevel),
    discontinuedcount = (SELECT COUNT(*) FROM products WHERE isdiscontinued = 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

