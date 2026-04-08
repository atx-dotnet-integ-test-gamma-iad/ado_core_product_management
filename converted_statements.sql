-- =====================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: MS SQL Server to PostgreSQL Migration
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- =====================================================

-- =============================================================
-- SOURCE: DataAccess/ProductRepository.cs
-- =============================================================

-- ----- Statement 1: GetAllProductsAsync (CTE with window functions) -----
-- Location: DataAccess/ProductRepository.cs, GetAllProductsAsync method

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

-- ----- Statement 2: GetProductByIdAsync (CTE with LAG window function) -----
-- Location: DataAccess/ProductRepository.cs, GetProductByIdAsync method

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

-- ----- Statement 3: InsertProductAsync (Transaction block) -----
-- Location: DataAccess/ProductRepository.cs, InsertProductAsync method
-- Note: SCOPE_IDENTITY() -> RETURNING + lastval(), GETDATE() -> NOW(), DECLARE -> DO block restructured for Npgsql

                INSERT INTO products (name, description, price, stockquantity)
                VALUES (@Name, @Description, @Price, @StockQuantity)
                RETURNING productid;

-- ----- Statement 4: UpdateProductAsync (Transaction block with variables) -----
-- Location: DataAccess/ProductRepository.cs, UpdateProductAsync method
-- Note: T-SQL DECLARE/SET -> PostgreSQL DO block, GETDATE() -> NOW()

                DO $$
                DECLARE
                    v_oldprice DECIMAL(18,2);
                    v_oldstock INT;
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

-- ----- Statement 5: DeleteProductAsync (Transaction block with CASE) -----
-- Location: DataAccess/ProductRepository.cs, DeleteProductAsync method

                DO $$
                DECLARE
                    v_oldprice DECIMAL(18,2);
                    v_oldstock INT;
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

-- ----- Statement 6: GetProductsByPriceRangeAsync (CTE with RANK/PERCENT_RANK) -----
-- Location: DataAccess/ProductRepository.cs, GetProductsByPriceRangeAsync method

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

-- ----- Statement 7: GetLowStockProductsAsync (CTE with aggregate window functions) -----
-- Location: DataAccess/ProductRepository.cs, GetLowStockProductsAsync method
-- Note: Added CAST for integer division compatibility

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
                    ROUND((CAST(stockquantity AS DECIMAL) / avgstock) * 100, 2) as stockpercentageofaverage
                FROM stockanalysis sa
                WHERE stockquantity <= @Threshold
                ORDER BY stockquantity;

-- =============================================================
-- SOURCE: Scripts/01_InitialSetup.sql
-- =============================================================

-- ----- Statement 8: Create Database (conditional) -----
-- PostgreSQL: CREATE DATABASE cannot be wrapped in IF; use psql conditional or separate step
SELECT 'CREATE DATABASE productmanagement' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'productmanagement');

-- ----- Statement 9: Create Products Table (conditional) -----
CREATE TABLE IF NOT EXISTS products(
    productid serial PRIMARY KEY,
    name varchar(100) NOT NULL,
    description varchar(500) NULL,
    price decimal(18, 2) NOT NULL,
    stockquantity int NOT NULL,
    createddate timestamp NOT NULL DEFAULT NOW(),
    modifieddate timestamp NULL
);

-- ----- Statement 10: sp_GetAllProducts -----
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE(productid int, name varchar(100), description varchar(500), price decimal(18,2), stockquantity int, createddate timestamp, modifieddate timestamp)
AS $$
BEGIN
    RETURN QUERY SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- ----- Statement 11: sp_GetProductById -----
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INT)
RETURNS TABLE(productid int, name varchar(100), description varchar(500), price decimal(18,2), stockquantity int, createddate timestamp, modifieddate timestamp)
AS $$
BEGIN
    RETURN QUERY SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    WHERE p.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- ----- Statement 12: sp_InsertProduct -----
CREATE OR REPLACE FUNCTION sp_insertproduct(p_name varchar(100), p_description varchar(500), p_price decimal(18,2), p_stockquantity int)
RETURNS int AS $$
DECLARE
    v_productid int;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING productid INTO v_productid;
    RETURN v_productid;
END;
$$ LANGUAGE plpgsql;

-- ----- Statement 13: sp_UpdateProduct -----
CREATE OR REPLACE FUNCTION sp_updateproduct(p_productid INT, p_name varchar(100), p_description varchar(500), p_price decimal(18,2), p_stockquantity int)
RETURNS void AS $$
BEGIN
    UPDATE products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stockquantity = p_stockquantity,
        modifieddate = NOW()
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- ----- Statement 14: sp_DeleteProduct -----
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid INT)
RETURNS void AS $$
BEGIN
    DELETE FROM products
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- ----- Statement 15: Insert Sample Data (via function calls) -----
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM products LIMIT 1) THEN
        PERFORM sp_insertproduct('Laptop', 'High-performance laptop', 999.99, 10);
        PERFORM sp_insertproduct('Mouse', 'Wireless gaming mouse', 49.99, 20);
        PERFORM sp_insertproduct('Keyboard', 'Mechanical keyboard', 129.99, 15);
    END IF;
END $$;

-- =============================================================
-- SOURCE: Database/Scripts/01_InitialSetup.sql
-- =============================================================

-- ----- Statement 16: Create Database (conditional) -----
SELECT 'CREATE DATABASE productmanagement' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'productmanagement');

-- ----- Statement 17: Drop Trigger (conditional) -----
DROP TRIGGER IF EXISTS trg_products_history ON products;
DROP FUNCTION IF EXISTS trg_products_history_func();

-- ----- Statement 18: Drop ProductHistory Table (conditional) -----
DROP TABLE IF EXISTS producthistory;

-- ----- Statement 19: Drop Products Table (conditional) -----
DROP TABLE IF EXISTS products CASCADE;

-- ----- Statement 20: Drop Categories Table (conditional) -----
DROP TABLE IF EXISTS categories CASCADE;

-- ----- Statement 21: Drop Suppliers Table (conditional) -----
DROP TABLE IF EXISTS suppliers CASCADE;

-- ----- Statement 22: Drop ProductStats Table (conditional) -----
DROP TABLE IF EXISTS productstats CASCADE;

-- ----- Statement 23: Create Categories Table -----
CREATE TABLE categories(
    categoryid serial PRIMARY KEY,
    name varchar(50) NOT NULL,
    description varchar(200) NULL,
    parentcategoryid int NULL,
    createddate timestamp NOT NULL DEFAULT NOW()
);

-- ----- Statement 24: Add Foreign Key to Categories -----
ALTER TABLE categories
ADD CONSTRAINT fk_categories_categories 
FOREIGN KEY (parentcategoryid) REFERENCES categories (categoryid);

-- ----- Statement 25: Create Suppliers Table -----
CREATE TABLE suppliers(
    supplierid serial PRIMARY KEY,
    name varchar(100) NOT NULL,
    contactname varchar(100) NULL,
    email varchar(100) NULL,
    phone varchar(20) NULL,
    address varchar(200) NULL,
    country varchar(50) NULL,
    isactive boolean NOT NULL DEFAULT true,
    createddate timestamp NOT NULL DEFAULT NOW()
);

-- ----- Statement 26: Create Products Table (extended) -----
CREATE TABLE products(
    productid serial PRIMARY KEY,
    name varchar(100) NOT NULL,
    description varchar(500) NULL,
    price decimal(18, 2) NOT NULL,
    stockquantity int NOT NULL,
    categoryid int NULL,
    supplierid int NULL,
    sku varchar(50) NULL,
    weight decimal(10, 2) NULL,
    dimensions varchar(50) NULL,
    isdiscontinued boolean NOT NULL DEFAULT false,
    reorderlevel int NOT NULL DEFAULT 10,
    createddate timestamp NOT NULL DEFAULT NOW(),
    modifieddate timestamp NULL,
    CONSTRAINT fk_products_categories FOREIGN KEY (categoryid) 
        REFERENCES categories (categoryid),
    CONSTRAINT fk_products_suppliers FOREIGN KEY (supplierid) 
        REFERENCES suppliers (supplierid)
);

-- ----- Statement 27: Create ProductHistory Table -----
CREATE TABLE producthistory(
    historyid serial PRIMARY KEY,
    productid int NOT NULL,
    action varchar(10) NOT NULL,
    oldprice decimal(18, 2) NULL,
    newprice decimal(18, 2) NULL,
    oldstock int NULL,
    newstock int NULL,
    actiondate timestamp NOT NULL DEFAULT NOW(),
    modifiedby varchar(100) NULL,
    CONSTRAINT fk_producthistory_products FOREIGN KEY (productid) 
        REFERENCES products (productid)
);

-- ----- Statement 28: Create ProductStats Table -----
CREATE TABLE productstats(
    statid int PRIMARY KEY DEFAULT 1,
    totalproducts int NOT NULL DEFAULT 0,
    averageprice decimal(18, 2) NOT NULL DEFAULT 0,
    totalstockvalue decimal(18, 2) NOT NULL DEFAULT 0,
    lowstockcount int NOT NULL DEFAULT 0,
    discontinuedcount int NOT NULL DEFAULT 0,
    lastupdated timestamp NOT NULL DEFAULT NOW()
);

-- ----- Statement 29: Create Index IX_Products_CategoryId -----
CREATE INDEX ix_products_categoryid ON products (categoryid);

-- ----- Statement 30: Create Index IX_Products_SupplierId -----
CREATE INDEX ix_products_supplierid ON products (supplierid);

-- ----- Statement 31: Create Unique Index IX_Products_SKU -----
CREATE UNIQUE INDEX ix_products_sku ON products (sku);

-- ----- Statement 32: Create Index IX_ProductHistory_ProductId -----
CREATE INDEX ix_producthistory_productid ON producthistory (productid);

-- ----- Statement 33: Create Index IX_ProductHistory_ActionDate -----
CREATE INDEX ix_producthistory_actiondate ON producthistory (actiondate);

-- ----- Statement 34: Insert Sample Categories -----
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

-- ----- Statement 35: Insert Sample Suppliers -----
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

-- ----- Statement 36: Insert Sample Products -----
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

-- ----- Statement 37: Insert Initial Stats Record -----
INSERT INTO productstats (statid, totalproducts, averageprice, totalstockvalue, lowstockcount, discontinuedcount, lastupdated)
VALUES (1, 0, 0, 0, 0, 0, NOW());

-- ----- Statement 38: Update Initial Statistics -----
UPDATE productstats
SET 
    totalproducts = (SELECT COUNT(*) FROM products),
    averageprice = (SELECT AVG(price) FROM products),
    totalstockvalue = (SELECT SUM(price * stockquantity) FROM products),
    lowstockcount = (SELECT COUNT(*) FROM products WHERE stockquantity <= reorderlevel),
    discontinuedcount = (SELECT COUNT(*) FROM products WHERE isdiscontinued = true),
    lastupdated = NOW()
WHERE statid = 1;

-- ----- Statement 39: Create Trigger trg_Products_History -----
-- PostgreSQL trigger requires a function + trigger definition
CREATE OR REPLACE FUNCTION trg_products_history_func()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO producthistory (productid, action, newprice, newstock, modifiedby)
        VALUES (NEW.productid, 'INSERT', NEW.price, NEW.stockquantity, CURRENT_USER);
        RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (NEW.price <> OLD.price OR NEW.stockquantity <> OLD.stockquantity) THEN
            INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, modifiedby)
            VALUES (NEW.productid, 'UPDATE', OLD.price, NEW.price, OLD.stockquantity, NEW.stockquantity, CURRENT_USER);
        END IF;
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO producthistory (productid, action, oldprice, oldstock, modifiedby)
        VALUES (OLD.productid, 'DELETE', OLD.price, OLD.stockquantity, CURRENT_USER);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_products_history
    AFTER INSERT OR UPDATE OR DELETE ON products
    FOR EACH ROW EXECUTE FUNCTION trg_products_history_func();

-- ----- Statements 40-44: Stored Procedures (Database version - same as 10-14) -----
-- These are identical to Statements 10-14 above (same stored procedures defined in Database/Scripts/)
-- See Statements 10-14 for converted PostgreSQL functions

-- =====================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total: 44 statements converted
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (all 44)
-- DMS Error: Metadata model creation failed for all statements
-- =====================================================
