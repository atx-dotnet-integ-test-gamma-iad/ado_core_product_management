-- ============================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: AdoCore .NET Application
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- All statements attempted through DMS MCP tool first, all failed.
-- Manual conversion applied with lowercase schema object names.
-- ============================================================

-- ============================================================
-- SOURCE FILE: sourceCode/DataAccess/ProductRepository.cs
-- ============================================================

-- -----------------------------------------------------------
-- STATEMENT 1: GetAllProductsAsync (PostgreSQL)
-- -----------------------------------------------------------
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
    ROUND(CAST((p.price / ps.avgprice) * 100 AS NUMERIC), 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- -----------------------------------------------------------
-- STATEMENT 2: GetProductByIdAsync (PostgreSQL)
-- -----------------------------------------------------------
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
            ROUND(CAST(((p.price - ph.previousprice) / ph.previousprice) * 100 AS NUMERIC), 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- -----------------------------------------------------------
-- STATEMENT 3: InsertProductAsync (PostgreSQL)
-- Note: SCOPE_IDENTITY() replaced with INSERT...RETURNING
-- Note: GETDATE() replaced with NOW()
-- Note: BEGIN TRANSACTION replaced with BEGIN
-- -----------------------------------------------------------
DO $$
DECLARE newproductid INT;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO newproductid;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- -----------------------------------------------------------
-- STATEMENT 4: UpdateProductAsync (PostgreSQL)
-- Note: DECLARE syntax changed to PostgreSQL DO block style
-- Note: GETDATE() replaced with NOW()
-- -----------------------------------------------------------
DO $$
DECLARE v_oldprice DECIMAL(18,2);
DECLARE v_oldstock INT;
BEGIN
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
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
    VALUES (@ProductId, 'UPDATE', v_oldprice, @Price, v_oldstock, @StockQuantity, NOW());
    
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - v_oldprice + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- -----------------------------------------------------------
-- STATEMENT 5: DeleteProductAsync (PostgreSQL)
-- -----------------------------------------------------------
DO $$
DECLARE v_oldprice DECIMAL(18,2);
DECLARE v_oldstock INT;
BEGIN
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, NOW());
    
    DELETE FROM products 
    WHERE productid = @ProductId;
    
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

-- -----------------------------------------------------------
-- STATEMENT 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- -----------------------------------------------------------
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

-- -----------------------------------------------------------
-- STATEMENT 7: GetLowStockProductsAsync (PostgreSQL)
-- -----------------------------------------------------------
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
    ROUND(CAST((stockquantity / avgstock) * 100 AS NUMERIC), 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;

-- ============================================================
-- SOURCE FILE: sourceCode/Scripts/01_InitialSetup.sql (PostgreSQL)
-- ============================================================

-- STATEMENT 8: Create Database Check
SELECT 'CREATE DATABASE productmanagement' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'productmanagement');

-- STATEMENT 9: Connect to Database (PostgreSQL equivalent)
\c productmanagement

-- STATEMENT 10: Create Products Table (Scripts version)
CREATE TABLE IF NOT EXISTS products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price DECIMAL(18, 2) NOT NULL,
    stockquantity INT NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT NOW(),
    modifieddate TIMESTAMP NULL
);

-- STATEMENT 11: sp_GetAllProducts (Scripts version)
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE (productid INT, name VARCHAR(100), description VARCHAR(500), price DECIMAL(18,2), stockquantity INT, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    ORDER BY p.name;
END;
$$;

-- STATEMENT 12: sp_GetProductById (Scripts version)
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INT)
RETURNS TABLE (productid INT, name VARCHAR(100), description VARCHAR(500), price DECIMAL(18,2), stockquantity INT, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    WHERE p.productid = p_productid;
END;
$$;

-- STATEMENT 13: sp_InsertProduct (Scripts version)
CREATE OR REPLACE FUNCTION sp_insertproduct(p_name VARCHAR(100), p_description VARCHAR(500), p_price DECIMAL(18,2), p_stockquantity INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_productid INT;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING productid INTO v_productid;
    RETURN v_productid;
END;
$$;

-- STATEMENT 14: sp_UpdateProduct (Scripts version)
CREATE OR REPLACE FUNCTION sp_updateproduct(p_productid INT, p_name VARCHAR(100), p_description VARCHAR(500), p_price DECIMAL(18,2), p_stockquantity INT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stockquantity = p_stockquantity,
        modifieddate = NOW()
    WHERE productid = p_productid;
END;
$$;

-- STATEMENT 15: sp_DeleteProduct (Scripts version)
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid INT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM products
    WHERE productid = p_productid;
END;
$$;

-- STATEMENT 16: Insert Sample Data (Scripts version)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM products LIMIT 1) THEN
        PERFORM sp_insertproduct('Laptop', 'High-performance laptop', 999.99, 10);
        PERFORM sp_insertproduct('Mouse', 'Wireless gaming mouse', 49.99, 20);
        PERFORM sp_insertproduct('Keyboard', 'Mechanical keyboard', 129.99, 15);
    END IF;
END $$;

-- ============================================================
-- SOURCE FILE: sourceCode/Database/Scripts/01_InitialSetup.sql (PostgreSQL)
-- ============================================================

-- STATEMENT 17: Create Database Check (Database version)
SELECT 'CREATE DATABASE productmanagement' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'productmanagement');

-- STATEMENT 18: Connect to Database (Database version)
\c productmanagement

-- STATEMENT 19: Drop Trigger
DROP TRIGGER IF EXISTS trg_products_history ON products;
DROP FUNCTION IF EXISTS trg_products_history_func();

-- STATEMENT 20: Drop ProductHistory Table
DROP TABLE IF EXISTS producthistory CASCADE;

-- STATEMENT 21: Drop Products Table
DROP TABLE IF EXISTS products CASCADE;

-- STATEMENT 22: Drop Categories Table
DROP TABLE IF EXISTS categories CASCADE;

-- STATEMENT 23: Drop Suppliers Table
DROP TABLE IF EXISTS suppliers CASCADE;

-- STATEMENT 24: Drop ProductStats Table
DROP TABLE IF EXISTS productstats CASCADE;

-- STATEMENT 25: Create Categories Table
CREATE TABLE categories (
    categoryid SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200) NULL,
    parentcategoryid INT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT NOW()
);

-- STATEMENT 26: Add Foreign Key to Categories
ALTER TABLE categories
ADD CONSTRAINT fk_categories_categories 
FOREIGN KEY (parentcategoryid) REFERENCES categories (categoryid);

-- STATEMENT 27: Create Suppliers Table
CREATE TABLE suppliers (
    supplierid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contactname VARCHAR(100) NULL,
    email VARCHAR(100) NULL,
    phone VARCHAR(20) NULL,
    address VARCHAR(200) NULL,
    country VARCHAR(50) NULL,
    isactive BOOLEAN NOT NULL DEFAULT TRUE,
    createddate TIMESTAMP NOT NULL DEFAULT NOW()
);

-- STATEMENT 28: Create Products Table (Database version)
CREATE TABLE products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price DECIMAL(18, 2) NOT NULL,
    stockquantity INT NOT NULL,
    categoryid INT NULL,
    supplierid INT NULL,
    sku VARCHAR(50) NULL,
    weight DECIMAL(10, 2) NULL,
    dimensions VARCHAR(50) NULL,
    isdiscontinued BOOLEAN NOT NULL DEFAULT FALSE,
    reorderlevel INT NOT NULL DEFAULT 10,
    createddate TIMESTAMP NOT NULL DEFAULT NOW(),
    modifieddate TIMESTAMP NULL,
    CONSTRAINT fk_products_categories FOREIGN KEY (categoryid) 
        REFERENCES categories (categoryid),
    CONSTRAINT fk_products_suppliers FOREIGN KEY (supplierid) 
        REFERENCES suppliers (supplierid)
);

-- STATEMENT 29: Create ProductHistory Table
CREATE TABLE producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INT NOT NULL,
    action VARCHAR(10) NOT NULL,
    oldprice DECIMAL(18, 2) NULL,
    newprice DECIMAL(18, 2) NULL,
    oldstock INT NULL,
    newstock INT NULL,
    actiondate TIMESTAMP NOT NULL DEFAULT NOW(),
    modifiedby VARCHAR(100) NULL,
    CONSTRAINT fk_producthistory_products FOREIGN KEY (productid) 
        REFERENCES products (productid)
);

-- STATEMENT 30: Create ProductStats Table
CREATE TABLE productstats (
    statid INT PRIMARY KEY DEFAULT 1,
    totalproducts INT NOT NULL DEFAULT 0,
    averageprice DECIMAL(18, 2) NOT NULL DEFAULT 0,
    totalstockvalue DECIMAL(18, 2) NOT NULL DEFAULT 0,
    lowstockcount INT NOT NULL DEFAULT 0,
    discontinuedcount INT NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL DEFAULT NOW()
);

-- STATEMENT 31: Create Index IX_Products_CategoryId
CREATE INDEX ix_products_categoryid ON products (categoryid);

-- STATEMENT 32: Create Index IX_Products_SupplierId
CREATE INDEX ix_products_supplierid ON products (supplierid);

-- STATEMENT 33: Create Unique Index IX_Products_SKU
CREATE UNIQUE INDEX ix_products_sku ON products (sku);

-- STATEMENT 34: Create Index IX_ProductHistory_ProductId
CREATE INDEX ix_producthistory_productid ON producthistory (productid);

-- STATEMENT 35: Create Index IX_ProductHistory_ActionDate
CREATE INDEX ix_producthistory_actiondate ON producthistory (actiondate);

-- STATEMENT 36: Insert Sample Categories
INSERT INTO categories (name, description, parentcategoryid)
VALUES 
    ('Electronics', 'Electronic devices and accessories', NULL),
    ('Computers', 'Computers and related equipment', 1),
    ('Peripherals', 'Computer peripherals and accessories', 1),
    ('Audio', 'Audio equipment and accessories', 1),
    ('Storage', 'Data storage devices', 1),
    ('Gaming', 'Gaming equipment and accessories', NULL),
    ('Office', 'Office equipment and supplies', NULL),
    ('Networking', 'Networking equipment and accessories', 1),
    ('Laptops', 'Portable computers', 2),
    ('Desktops', 'Desktop computers', 2),
    ('Keyboards', 'Computer keyboards', 3),
    ('Mice', 'Computer mice and pointing devices', 3),
    ('Headphones', 'Audio headphones and headsets', 4),
    ('Speakers', 'Audio speakers', 4),
    ('External Drives', 'External storage devices', 5),
    ('Gaming PCs', 'Gaming computers', 6),
    ('Gaming Accessories', 'Gaming peripherals', 6),
    ('Printers', 'Printing devices', 7),
    ('Routers', 'Network routers', 8),
    ('Switches', 'Network switches', 8);

-- STATEMENT 37: Insert Sample Suppliers
INSERT INTO suppliers (name, contactname, email, phone, address, country)
VALUES 
    ('TechGlobal Inc.', 'John Smith', 'john@techglobal.com', '+1-555-0101', '123 Tech Street, Silicon Valley, CA', 'USA'),
    ('ElectroParts Ltd.', 'Sarah Johnson', 'sarah@electroparts.com', '+44-20-7123-4567', '45 Circuit Road, London', 'UK'),
    ('Digital Solutions', 'Michael Chen', 'michael@digitalsolutions.com', '+86-10-1234-5678', '789 Digital Avenue, Beijing', 'China'),
    ('Gaming Gear Co.', 'David Wilson', 'david@gaminggear.com', '+1-555-0202', '456 Game Street, Seattle, WA', 'USA'),
    ('AudioTech Systems', 'Emma Brown', 'emma@audiotech.com', '+1-555-0303', '789 Sound Road, Nashville, TN', 'USA'),
    ('Storage Solutions', 'James Lee', 'james@storagesolutions.com', '+1-555-0404', '321 Data Drive, Austin, TX', 'USA'),
    ('Office Supplies Pro', 'Lisa Anderson', 'lisa@officesupplies.com', '+1-555-0505', '654 Office Park, Chicago, IL', 'USA'),
    ('Network Experts', 'Robert Taylor', 'robert@networkexperts.com', '+1-555-0606', '987 Network Way, Boston, MA', 'USA');

-- STATEMENT 38: Insert Sample Products
INSERT INTO products (name, description, price, stockquantity, categoryid, supplierid, sku, weight, dimensions, reorderlevel)
VALUES 
    ('ProBook X1', 'High-performance business laptop with 16GB RAM', 1299.99, 15, 9, 1, 'LAP-X1-001', 1.8, '14" x 9" x 0.7"', 5),
    ('Gaming Beast', 'Gaming laptop with RTX 3080, 32GB RAM', 2499.99, 8, 9, 4, 'LAP-GB-001', 2.5, '15.6" x 11" x 1"', 3),
    ('UltraBook Air', 'Ultra-thin laptop with 12-hour battery', 999.99, 20, 9, 1, 'LAP-UA-001', 1.2, '13" x 8" x 0.5"', 7),
    ('WorkStation Pro', 'Professional workstation with dual monitors', 1999.99, 10, 10, 1, 'DESK-WP-001', 15.0, '18" x 8" x 16"', 4),
    ('Gaming Tower', 'High-end gaming desktop with liquid cooling', 2999.99, 5, 16, 4, 'DESK-GT-001', 20.0, '20" x 10" x 18"', 2),
    ('Mechanical Pro', 'Mechanical keyboard with RGB lighting', 149.99, 30, 11, 2, 'KB-MP-001', 1.2, '17" x 5" x 1.5"', 10),
    ('Wireless Elite', 'Wireless keyboard with numeric pad', 79.99, 25, 11, 2, 'KB-WE-001', 0.8, '18" x 6" x 1"', 8),
    ('Gaming Mouse Pro', 'High-precision gaming mouse', 89.99, 40, 12, 4, 'M-GP-001', 0.3, '5" x 3" x 1.5"', 15),
    ('Wireless Track', 'Wireless mouse with long battery life', 49.99, 35, 12, 2, 'M-WT-001', 0.2, '4" x 2.5" x 1.2"', 12),
    ('Noise Cancelling Pro', 'Premium noise-cancelling headphones', 299.99, 20, 13, 5, 'HP-NC-001', 0.4, '7" x 6" x 3"', 8),
    ('Gaming Headset', '7.1 surround sound gaming headset', 129.99, 25, 13, 4, 'HP-GH-001', 0.5, '8" x 7" x 4"', 10),
    ('Studio Monitors', 'Professional studio monitors', 399.99, 10, 14, 5, 'SP-SM-001', 8.0, '12" x 8" x 10"', 4),
    ('Bluetooth Soundbar', 'Wireless soundbar with subwoofer', 249.99, 15, 14, 5, 'SP-BS-001', 5.0, '36" x 3" x 4"', 6),
    ('SSD Pro 1TB', '1TB external SSD with USB 3.1', 199.99, 30, 15, 6, 'ED-SP-001', 0.2, '4" x 2" x 0.5"', 12),
    ('HDD Backup 4TB', '4TB external HDD for backup', 129.99, 25, 15, 6, 'ED-HB-001', 0.5, '5" x 3" x 1"', 10),
    ('Laser Pro', 'Business laser printer with duplex', 399.99, 12, 18, 7, 'PR-LP-001', 25.0, '18" x 16" x 12"', 5),
    ('Photo Inkjet', 'Photo-quality inkjet printer', 299.99, 15, 18, 7, 'PR-PI-001', 15.0, '16" x 14" x 8"', 6),
    ('WiFi 6 Router', 'High-speed WiFi 6 router', 199.99, 20, 19, 8, 'NET-WR-001', 1.5, '10" x 7" x 2"', 8),
    ('Gigabit Switch', '24-port gigabit network switch', 299.99, 10, 20, 8, 'NET-GS-001', 3.0, '17" x 10" x 1.5"', 4);

-- STATEMENT 39: Insert Initial Stats Record
INSERT INTO productstats (statid, totalproducts, averageprice, totalstockvalue, lowstockcount, discontinuedcount, lastupdated)
VALUES (1, 0, 0, 0, 0, 0, NOW());

-- STATEMENT 40: Update Initial Statistics
UPDATE productstats
SET 
    totalproducts = (SELECT COUNT(*) FROM products),
    averageprice = (SELECT AVG(price) FROM products),
    totalstockvalue = (SELECT SUM(price * stockquantity) FROM products),
    lowstockcount = (SELECT COUNT(*) FROM products WHERE stockquantity <= reorderlevel),
    discontinuedcount = (SELECT COUNT(*) FROM products WHERE isdiscontinued = TRUE),
    lastupdated = NOW()
WHERE statid = 1;

-- STATEMENT 41: Create Trigger trg_Products_History
CREATE OR REPLACE FUNCTION trg_products_history_func()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO producthistory (productid, action, newprice, newstock, modifiedby)
        VALUES (NEW.productid, 'INSERT', NEW.price, NEW.stockquantity, current_user);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.price <> OLD.price OR NEW.stockquantity <> OLD.stockquantity THEN
            INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, modifiedby)
            VALUES (NEW.productid, 'UPDATE', OLD.price, NEW.price, OLD.stockquantity, NEW.stockquantity, current_user);
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO producthistory (productid, action, oldprice, oldstock, modifiedby)
        VALUES (OLD.productid, 'DELETE', OLD.price, OLD.stockquantity, current_user);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_products_history
AFTER INSERT OR UPDATE OR DELETE ON products
FOR EACH ROW EXECUTE FUNCTION trg_products_history_func();

-- STATEMENT 42: sp_GetAllProducts (Database version) - same as Statement 11
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE (productid INT, name VARCHAR(100), description VARCHAR(500), price DECIMAL(18,2), stockquantity INT, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    ORDER BY p.name;
END;
$$;

-- STATEMENT 43: sp_GetProductById (Database version) - same as Statement 12
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INT)
RETURNS TABLE (productid INT, name VARCHAR(100), description VARCHAR(500), price DECIMAL(18,2), stockquantity INT, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    WHERE p.productid = p_productid;
END;
$$;

-- STATEMENT 44: sp_InsertProduct (Database version) - same as Statement 13
CREATE OR REPLACE FUNCTION sp_insertproduct(p_name VARCHAR(100), p_description VARCHAR(500), p_price DECIMAL(18,2), p_stockquantity INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_productid INT;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING productid INTO v_productid;
    RETURN v_productid;
END;
$$;

-- STATEMENT 45: sp_UpdateProduct (Database version) - same as Statement 14
CREATE OR REPLACE FUNCTION sp_updateproduct(p_productid INT, p_name VARCHAR(100), p_description VARCHAR(500), p_price DECIMAL(18,2), p_stockquantity INT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stockquantity = p_stockquantity,
        modifieddate = NOW()
    WHERE productid = p_productid;
END;
$$;

-- STATEMENT 46: sp_DeleteProduct (Database version) - same as Statement 15
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid INT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM products
    WHERE productid = p_productid;
END;
$$;

-- ============================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total: 46 SQL statements converted
-- Conversion method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed for ALL statements
-- ============================================================
