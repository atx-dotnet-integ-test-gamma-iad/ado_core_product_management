-- ============================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Target: PostgreSQL
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Schema mappings obtained from DMS schema_mapping_tool:
--   dbo.Products -> productmanagement_dbo.products
--   dbo.ProductHistory -> productmanagement_dbo.producthistory
--   dbo.ProductStats -> productmanagement_dbo.productstats
-- ============================================

-- ============================================
-- Statement 1: GetAllProductsAsync (converted)
-- ============================================
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

-- ============================================
-- Statement 2: GetProductByIdAsync (converted)
-- ============================================
WITH producthistory_cte AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM productmanagement_dbo.products
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
FROM productmanagement_dbo.products p
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================
-- Statement 3: InsertProductAsync (converted)
-- ============================================
WITH new_product AS (
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
log_insert AS (
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp()
    FROM new_product
)
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

SELECT currval(pg_get_serial_sequence('productmanagement_dbo.products', 'productid'));

-- ============================================
-- Statement 4: UpdateProductAsync (converted)
-- ============================================
DO $$
DECLARE
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

    UPDATE productmanagement_dbo.products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = clock_timestamp()
    WHERE productid = @ProductId;

    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', v_oldprice, @Price, v_oldstock, @StockQuantity, clock_timestamp());

    UPDATE productmanagement_dbo.productstats
    SET 
        averageprice = (averageprice * totalproducts - v_oldprice + @Price) / totalproducts,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- ============================================
-- Statement 5: DeleteProductAsync (converted)
-- ============================================
DO $$
DECLARE
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, clock_timestamp());

    DELETE FROM productmanagement_dbo.products 
    WHERE productid = @ProductId;

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

-- ============================================
-- Statement 6: GetProductsByPriceRangeAsync (converted)
-- ============================================
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM productmanagement_dbo.products p
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

-- ============================================
-- Statement 7: GetLowStockProductsAsync (converted)
-- ============================================
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
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;

-- ============================================
-- SCRIPT STATEMENTS (converted)
-- ============================================

-- ============================================
-- Statement 8: CREATE TABLE products (extended, converted)
-- ============================================
CREATE TABLE productmanagement_dbo.products(
    productid INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    categoryid INTEGER,
    supplierid INTEGER,
    sku VARCHAR(50),
    weight NUMERIC(10, 2),
    dimensions VARCHAR(50),
    isdiscontinued NUMERIC(1,0) NOT NULL DEFAULT 0,
    reorderlevel INTEGER NOT NULL DEFAULT 10,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE,
    CONSTRAINT fk_products_categories FOREIGN KEY (categoryid)
        REFERENCES productmanagement_dbo.categories (categoryid),
    CONSTRAINT fk_products_suppliers FOREIGN KEY (supplierid)
        REFERENCES productmanagement_dbo.suppliers (supplierid)
);

-- ============================================
-- Statement 9: sp_getallproducts (converted)
-- ============================================
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getallproducts()
RETURNS TABLE (
    productid INTEGER, name VARCHAR(100), description VARCHAR(500),
    price NUMERIC(18,2), stockquantity INTEGER,
    createddate TIMESTAMP WITHOUT TIME ZONE, modifieddate TIMESTAMP WITHOUT TIME ZONE
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM productmanagement_dbo.products p ORDER BY p.name;
END; $$;

-- ============================================
-- Statement 10: sp_getproductbyid (converted)
-- ============================================
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getproductbyid(p_productid INTEGER)
RETURNS TABLE (
    productid INTEGER, name VARCHAR(100), description VARCHAR(500),
    price NUMERIC(18,2), stockquantity INTEGER,
    createddate TIMESTAMP WITHOUT TIME ZONE, modifieddate TIMESTAMP WITHOUT TIME ZONE
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM productmanagement_dbo.products p WHERE p.productid = p_productid;
END; $$;

-- ============================================
-- Statement 11: sp_insertproduct (converted)
-- ============================================
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_insertproduct(
    p_name VARCHAR(100), p_description VARCHAR(500),
    p_price NUMERIC(18,2), p_stockquantity INTEGER
) RETURNS INTEGER LANGUAGE plpgsql AS $$
DECLARE v_productid INTEGER;
BEGIN
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING products.productid INTO v_productid;
    RETURN v_productid;
END; $$;

-- ============================================
-- Statement 12: sp_updateproduct (converted)
-- ============================================
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_updateproduct(
    p_productid INTEGER, p_name VARCHAR(100), p_description VARCHAR(500),
    p_price NUMERIC(18,2), p_stockquantity INTEGER
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE productmanagement_dbo.products
    SET name = p_name, description = p_description, price = p_price,
        stockquantity = p_stockquantity, modifieddate = clock_timestamp()
    WHERE productid = p_productid;
END; $$;

-- ============================================
-- Statement 13: sp_deleteproduct (converted)
-- ============================================
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_deleteproduct(p_productid INTEGER)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM productmanagement_dbo.products WHERE productid = p_productid;
END; $$;

-- ============================================
-- Statement 14: trg_products_history (converted)
-- ============================================
CREATE OR REPLACE FUNCTION productmanagement_dbo.trg_products_history_func()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO productmanagement_dbo.producthistory (productid, action, newprice, newstock, modifiedby)
        VALUES (NEW.productid, 'INSERT', NEW.price, NEW.stockquantity, current_user);
        RETURN NEW;
    END IF;
    IF TG_OP = 'UPDATE' THEN
        IF NEW.price <> OLD.price OR NEW.stockquantity <> OLD.stockquantity THEN
            INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, modifiedby)
            VALUES (NEW.productid, 'UPDATE', OLD.price, NEW.price, OLD.stockquantity, NEW.stockquantity, current_user);
        END IF;
        RETURN NEW;
    END IF;
    IF TG_OP = 'DELETE' THEN
        INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, oldstock, modifiedby)
        VALUES (OLD.productid, 'DELETE', OLD.price, OLD.stockquantity, current_user);
        RETURN OLD;
    END IF;
    RETURN NULL;
END; $$;

CREATE TRIGGER trg_products_history
AFTER INSERT OR UPDATE OR DELETE ON productmanagement_dbo.products
FOR EACH ROW EXECUTE FUNCTION productmanagement_dbo.trg_products_history_func();

-- ============================================
-- Statement 15: UPDATE productstats initial statistics (converted)
-- ============================================
UPDATE productmanagement_dbo.productstats
SET
    totalproducts = (SELECT COUNT(*) FROM productmanagement_dbo.products),
    averageprice = (SELECT AVG(price) FROM productmanagement_dbo.products),
    totalstockvalue = (SELECT SUM(price * stockquantity) FROM productmanagement_dbo.products),
    lowstockcount = (SELECT COUNT(*) FROM productmanagement_dbo.products WHERE stockquantity <= reorderlevel),
    discontinuedcount = (SELECT COUNT(*) FROM productmanagement_dbo.products WHERE isdiscontinued = 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

