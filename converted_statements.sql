-- ============================================================
-- COMPLETE CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: Manual conversion (DMS FAILED for all statements)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Total Statements: 26 (7 from C# code + 19 from SQL scripts)
-- ============================================================

-- ############################################################
-- SECTION A: Converted Statements from ProductRepository.cs (7)
-- ############################################################

-- Statement 1: GetAllProductsAsync
WITH productstats AS (
    SELECT productid, AVG(price) OVER() as avgprice, COUNT(*) OVER() as totalproducts FROM products
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE WHEN p.price > ps.avgprice THEN 'Above Average' WHEN p.price < ps.avgprice THEN 'Below Average' ELSE 'Average' END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END, p.name;

-- Statement 2: GetProductByIdAsync
WITH producthistory AS (
    SELECT productid, LAG(price) OVER (ORDER BY modifieddate) as previousprice, LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products WHERE productid = @ProductId
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2) ELSE NULL END as pricechangepercentage
FROM products p LEFT JOIN producthistory ph ON p.productid = ph.productid WHERE p.productid = @ProductId;

-- Statement 3: InsertProductAsync (split into individual statements for ADO.NET)
INSERT INTO products (name, description, price, stockquantity) VALUES (@Name, @Description, @Price, @StockQuantity) RETURNING productid;
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
UPDATE productstats SET totalproducts = totalproducts + 1, averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1), lastupdated = NOW() WHERE statid = 1;

-- Statement 4: UpdateProductAsync (split into individual statements for ADO.NET)
SELECT price, stockquantity FROM products WHERE productid = @ProductId;
UPDATE products SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = NOW() WHERE productid = @ProductId;
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());
UPDATE productstats SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = NOW() WHERE statid = 1;

-- Statement 5: DeleteProductAsync (split into individual statements for ADO.NET)
SELECT price, stockquantity FROM products WHERE productid = @ProductId;
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());
DELETE FROM products WHERE productid = @ProductId;
UPDATE productstats SET totalproducts = totalproducts - 1, averageprice = CASE WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1) ELSE 0 END, lastupdated = NOW() WHERE statid = 1;

-- Statement 6: GetProductsByPriceRangeAsync
WITH rankedproducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.price) as pricerank, PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*, CASE WHEN rp.pricepercentile <= 0.25 THEN 'Budget' WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END as pricesegment
FROM rankedproducts rp ORDER BY rp.pricerank;

-- Statement 7: GetLowStockProductsAsync
WITH stockanalysis AS (
    SELECT p.*, AVG(stockquantity) OVER() as avgstock, MIN(stockquantity) OVER() as minstock, MAX(stockquantity) OVER() as maxstock FROM products p
)
SELECT sa.*, CASE WHEN stockquantity <= @Threshold THEN 'Critical' WHEN stockquantity <= avgstock * 0.5 THEN 'Low' ELSE 'Adequate' END as stockstatus,
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa WHERE stockquantity <= @Threshold ORDER BY stockquantity;

-- ############################################################
-- SECTION B: Converted Statements from Database/Scripts/01_InitialSetup.sql (14)
-- ############################################################

-- Statement 8: CREATE TABLE categories
CREATE TABLE categories (categoryid SERIAL PRIMARY KEY, name VARCHAR(50) NOT NULL, description VARCHAR(200) NULL, parentcategoryid INT NULL, createddate TIMESTAMP NOT NULL DEFAULT NOW());

-- Statement 9: CREATE TABLE suppliers
CREATE TABLE suppliers (supplierid SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL, contactname VARCHAR(100) NULL, email VARCHAR(100) NULL, phone VARCHAR(20) NULL, address VARCHAR(200) NULL, country VARCHAR(50) NULL, isactive BOOLEAN NOT NULL DEFAULT TRUE, createddate TIMESTAMP NOT NULL DEFAULT NOW());

-- Statement 10: CREATE TABLE products
CREATE TABLE products (productid SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL, description VARCHAR(500) NULL, price DECIMAL(18, 2) NOT NULL, stockquantity INT NOT NULL, categoryid INT NULL, supplierid INT NULL, sku VARCHAR(50) NULL, weight DECIMAL(10, 2) NULL, dimensions VARCHAR(50) NULL, isdiscontinued BOOLEAN NOT NULL DEFAULT FALSE, reorderlevel INT NOT NULL DEFAULT 10, createddate TIMESTAMP NOT NULL DEFAULT NOW(), modifieddate TIMESTAMP NULL);

-- Statement 11: CREATE TABLE producthistory
CREATE TABLE producthistory (historyid SERIAL PRIMARY KEY, productid INT NOT NULL, action VARCHAR(10) NOT NULL, oldprice DECIMAL(18, 2) NULL, newprice DECIMAL(18, 2) NULL, oldstock INT NULL, newstock INT NULL, actiondate TIMESTAMP NOT NULL DEFAULT NOW(), modifiedby VARCHAR(100) NULL);

-- Statement 12: CREATE TABLE productstats
CREATE TABLE productstats (statid INT PRIMARY KEY DEFAULT 1, totalproducts INT NOT NULL DEFAULT 0, averageprice DECIMAL(18, 2) NOT NULL DEFAULT 0, totalstockvalue DECIMAL(18, 2) NOT NULL DEFAULT 0, lowstockcount INT NOT NULL DEFAULT 0, discontinuedcount INT NOT NULL DEFAULT 0, lastupdated TIMESTAMP NOT NULL DEFAULT NOW());

-- Statement 13: INSERT categories
INSERT INTO categories (name, description, parentcategoryid) VALUES ('Electronics', 'Electronic devices and accessories', NULL), ('Computers', 'Computers and related equipment', 1);

-- Statement 14: INSERT suppliers
INSERT INTO suppliers (name, contactname, email, phone, address, country) VALUES ('TechGlobal Inc.', 'John Smith', 'john@techglobal.com', '+1-555-0101', '123 Tech Street, Silicon Valley, CA', 'USA');

-- Statement 15: INSERT products
INSERT INTO products (name, description, price, stockquantity, categoryid, supplierid, sku, weight, dimensions, reorderlevel) VALUES ('ProBook X1', 'High-performance business laptop with 16GB RAM', 1299.99, 15, 9, 1, 'LAP-X1-001', 1.8, '14" x 9" x 0.7"', 5);

-- Statement 16: INSERT productstats
INSERT INTO productstats (statid, totalproducts, averageprice, totalstockvalue, lowstockcount, discontinuedcount, lastupdated) VALUES (1, 0, 0, 0, 0, 0, NOW());

-- Statement 17: UPDATE productstats
UPDATE productstats SET totalproducts = (SELECT COUNT(*) FROM products), averageprice = (SELECT AVG(price) FROM products), totalstockvalue = (SELECT SUM(price * stockquantity) FROM products), lowstockcount = (SELECT COUNT(*) FROM products WHERE stockquantity <= reorderlevel), discontinuedcount = (SELECT COUNT(*) FROM products WHERE isdiscontinued = TRUE), lastupdated = NOW() WHERE statid = 1;

-- Statement 18: CREATE TRIGGER (function + trigger)
CREATE OR REPLACE FUNCTION trg_products_history_func() RETURNS TRIGGER AS $$ BEGIN IF TG_OP = 'INSERT' THEN INSERT INTO producthistory (productid, action, newprice, newstock, modifiedby) VALUES (NEW.productid, 'INSERT', NEW.price, NEW.stockquantity, current_user); RETURN NEW; END IF; IF TG_OP = 'UPDATE' THEN IF NEW.price <> OLD.price OR NEW.stockquantity <> OLD.stockquantity THEN INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, modifiedby) VALUES (NEW.productid, 'UPDATE', OLD.price, NEW.price, OLD.stockquantity, NEW.stockquantity, current_user); END IF; RETURN NEW; END IF; IF TG_OP = 'DELETE' THEN INSERT INTO producthistory (productid, action, oldprice, oldstock, modifiedby) VALUES (OLD.productid, 'DELETE', OLD.price, OLD.stockquantity, current_user); RETURN OLD; END IF; RETURN NULL; END; $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_products_history AFTER INSERT OR UPDATE OR DELETE ON products FOR EACH ROW EXECUTE FUNCTION trg_products_history_func();

-- Statement 19: CREATE FUNCTION sp_getallproducts
CREATE OR REPLACE FUNCTION sp_getallproducts() RETURNS TABLE (productid INT, name VARCHAR(100), description VARCHAR(500), price DECIMAL(18,2), stockquantity INT, createddate TIMESTAMP, modifieddate TIMESTAMP) AS $$ BEGIN RETURN QUERY SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate FROM products p ORDER BY p.name; END; $$ LANGUAGE plpgsql;

-- Statement 20: CREATE FUNCTION sp_getproductbyid
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INT) RETURNS TABLE (productid INT, name VARCHAR(100), description VARCHAR(500), price DECIMAL(18,2), stockquantity INT, createddate TIMESTAMP, modifieddate TIMESTAMP) AS $$ BEGIN RETURN QUERY SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate FROM products p WHERE p.productid = p_productid; END; $$ LANGUAGE plpgsql;

-- Statement 21: CREATE FUNCTION sp_insertproduct
CREATE OR REPLACE FUNCTION sp_insertproduct(p_name VARCHAR(100), p_description VARCHAR(500), p_price DECIMAL(18,2), p_stockquantity INT) RETURNS INT AS $$ DECLARE v_productid INT; BEGIN INSERT INTO products (name, description, price, stockquantity) VALUES (p_name, p_description, p_price, p_stockquantity) RETURNING products.productid INTO v_productid; RETURN v_productid; END; $$ LANGUAGE plpgsql;

-- ############################################################
-- SECTION C: Converted Statements from Scripts/01_InitialSetup.sql (5)
-- ############################################################

-- Statement 22: CREATE TABLE IF NOT EXISTS products
CREATE TABLE IF NOT EXISTS products (productid SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL, description VARCHAR(500) NULL, price DECIMAL(18, 2) NOT NULL, stockquantity INT NOT NULL, createddate TIMESTAMP NOT NULL DEFAULT NOW(), modifieddate TIMESTAMP NULL);

-- Statement 23: CREATE FUNCTION sp_updateproduct
CREATE OR REPLACE FUNCTION sp_updateproduct(p_productid INT, p_name VARCHAR(100), p_description VARCHAR(500), p_price DECIMAL(18,2), p_stockquantity INT) RETURNS VOID AS $$ BEGIN UPDATE products SET name = p_name, description = p_description, price = p_price, stockquantity = p_stockquantity, modifieddate = NOW() WHERE productid = p_productid; END; $$ LANGUAGE plpgsql;

-- Statement 24: CREATE FUNCTION sp_deleteproduct
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid INT) RETURNS VOID AS $$ BEGIN DELETE FROM products WHERE productid = p_productid; END; $$ LANGUAGE plpgsql;

-- Statement 25: INSERT Sample Data
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM products LIMIT 1) THEN PERFORM sp_insertproduct('Laptop', 'High-performance laptop', 999.99, 10); PERFORM sp_insertproduct('Mouse', 'Wireless gaming mouse', 49.99, 20); PERFORM sp_insertproduct('Keyboard', 'Mechanical keyboard', 129.99, 15); END IF; END $$;

-- Statement 26: ALTER TABLE categories FK
ALTER TABLE categories ADD CONSTRAINT fk_categories_categories FOREIGN KEY (parentcategoryid) REFERENCES categories (categoryid);
