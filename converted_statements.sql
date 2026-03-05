-- ====================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Source: AdoCore .NET Application
-- Conversion: MS SQL Server -> PostgreSQL
-- Tool: AWS DMS MCP Statement Conversion Tool
-- ====================================================================

-- ====================================================================
-- SOURCE FILE: sourceCode/DataAccess/ProductRepository.cs
-- ====================================================================

-- STATEMENT 1: GetAllProductsAsync() - CTE with window functions
-- Source: ProductRepository.cs
-- Conversion Method: DMS_TOOL (Success)
-- ====================================================================
-- ORIGINAL (MS SQL):
-- WITH ProductStats AS (
--     SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts FROM Products
-- )
-- SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
--     CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average' WHEN p.Price < ps.AvgPrice THEN 'Below Average' ELSE 'Average' END as PriceCategory,
--     ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
-- FROM Products p INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
-- ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name

-- CONVERTED (PostgreSQL - DMS):
WITH productstats
AS (SELECT
    productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM productmanagement_dbo.products)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END AS pricecategory, ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
    FROM productmanagement_dbo.products AS p
    INNER JOIN productstats AS ps
        ON p.productid = ps.productid
    ORDER BY
    CASE
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END NULLS FIRST, p.name NULLS FIRST;

-- ====================================================================
-- STATEMENT 2: GetProductByIdAsync() - CTE with LAG window functions
-- Source: ProductRepository.cs
-- Conversion Method: DMS_TOOL (Success)
-- ====================================================================
-- CONVERTED (PostgreSQL - DMS):
WITH producthistory
AS (SELECT
    productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE
        WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END AS pricechangepercentage
    FROM productmanagement_dbo.products AS p
    LEFT OUTER JOIN producthistory AS ph
        ON p.productid = ph.productid
    WHERE p.productid = @ProductId;

-- ====================================================================
-- STATEMENT 3: InsertProductAsync() - Transaction block
-- Source: ProductRepository.cs
-- Conversion Method: DMS_TOOL (Success for individual statements; SCOPE_IDENTITY -> RETURNING)
-- ====================================================================
-- Sub-statement 3a: INSERT with RETURNING (DMS converted INSERT, manual RETURNING)
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Sub-statement 3b: History INSERT (DMS Success)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- Sub-statement 3c: Stats UPDATE (DMS Success)
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts + 1, averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1), lastupdated = clock_timestamp()
    WHERE statid = 1;

-- ====================================================================
-- STATEMENT 4: UpdateProductAsync() - Transaction block
-- Source: ProductRepository.cs
-- Conversion Method: DMS_TOOL for SELECT/UPDATE, DMS_FAILURE_MANUAL for history INSERT/stats UPDATE
-- ====================================================================
-- Sub-statement 4a: SELECT old values (DMS Success)
SELECT
    price, stockquantity
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

-- Sub-statement 4b: UPDATE Products (DMS Success)
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
    WHERE productid = @ProductId;

-- Sub-statement 4c: History INSERT (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA - timeout)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- Sub-statement 4d: Stats UPDATE (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA - timeout)
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
    WHERE statid = 1;

-- ====================================================================
-- STATEMENT 5: DeleteProductAsync() - Transaction block
-- Source: ProductRepository.cs
-- Conversion Method: DMS_TOOL for SELECT/DELETE, DMS_FAILURE_MANUAL for history INSERT/stats UPDATE
-- ====================================================================
-- Sub-statement 5a: SELECT old values (DMS Success - same as 4a)
SELECT
    price, stockquantity
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

-- Sub-statement 5b: History INSERT (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA - timeout)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- Sub-statement 5c: DELETE Products (DMS Success)
DELETE FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

-- Sub-statement 5d: Stats UPDATE with CASE (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA - timeout)
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
    ELSE 0
END, lastupdated = clock_timestamp()
    WHERE statid = 1;

-- ====================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync() - CTE with RANK/PERCENT_RANK
-- Source: ProductRepository.cs
-- Conversion Method: DMS_TOOL (Success)
-- ====================================================================
WITH rankedproducts
AS (SELECT
    p.*, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products AS p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice)
SELECT
    rp.*,
    CASE
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS pricesegment
    FROM rankedproducts AS rp
    ORDER BY rp.pricerank NULLS FIRST;

-- ====================================================================
-- STATEMENT 7: GetLowStockProductsAsync() - CTE with AVG/MIN/MAX window functions
-- Source: ProductRepository.cs
-- Conversion Method: DMS_TOOL (Success)
-- ====================================================================
WITH stockanalysis
AS (SELECT
    p.*, AVG(stockquantity) OVER () AS avgstock, MIN(stockquantity) OVER () AS minstock, MAX(stockquantity) OVER () AS maxstock
    FROM productmanagement_dbo.products AS p)
SELECT
    sa.*,
    CASE
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS stockstatus, ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage
    FROM stockanalysis AS sa
    WHERE stockquantity <= @Threshold
    ORDER BY stockquantity NULLS FIRST;

-- ====================================================================
-- SOURCE FILE: sourceCode/Database/Scripts/01_InitialSetup.sql
-- ====================================================================

-- STATEMENT 8: Create Database (conditional)
-- Conversion Method: DMS_TOOL (Success - returned aws_sqlserver_ext pattern, simplified for PG)
-- DMS Output: IF NOT EXISTS (SELECT * FROM aws_sqlserver_ext.SYS_DATABASES WHERE name = 'ProductManagement') THEN CREATE DATABASE WITH ENCODING = 'UTF8'; END IF;
-- Used: CREATE SCHEMA IF NOT EXISTS productmanagement_dbo; (simpler PostgreSQL equivalent)
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;

-- STATEMENT 9: USE Database
-- Conversion Method: DMS_TOOL (Success)
-- DMS Output: SET search_path TO;
-- Used: Schema prefix approach instead (productmanagement_dbo.tablename)
-- No direct equivalent needed in PostgreSQL with schema-qualified names

-- STATEMENT 10: Drop Trigger IF EXISTS
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
DROP TRIGGER IF EXISTS trg_products_history ON productmanagement_dbo.products;

-- STATEMENT 11: Drop ProductHistory IF EXISTS
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
DROP TABLE IF EXISTS productmanagement_dbo.producthistory;

-- STATEMENT 12: Drop Products IF EXISTS
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
DROP TABLE IF EXISTS productmanagement_dbo.products;

-- STATEMENT 13: Drop Categories IF EXISTS
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
DROP TABLE IF EXISTS productmanagement_dbo.categories;

-- STATEMENT 14: Drop Suppliers IF EXISTS
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
DROP TABLE IF EXISTS productmanagement_dbo.suppliers;

-- STATEMENT 15: Drop ProductStats IF EXISTS
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
DROP TABLE IF EXISTS productmanagement_dbo.productstats;

-- STATEMENT 16: Create Categories Table
-- Conversion Method: DMS_TOOL (Success)
CREATE TABLE productmanagement_dbo.categories
(categoryid BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200) NULL,
    parentcategoryid INTEGER NULL,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp());

-- STATEMENT 17: Alter Categories - Self-referencing FK
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
ALTER TABLE productmanagement_dbo.categories
ADD CONSTRAINT fk_categories_categories 
FOREIGN KEY (parentcategoryid) REFERENCES productmanagement_dbo.categories (categoryid);

-- STATEMENT 18: Create Suppliers Table
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
CREATE TABLE productmanagement_dbo.suppliers
(supplierid BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contactname VARCHAR(100) NULL,
    email VARCHAR(100) NULL,
    phone VARCHAR(20) NULL,
    address VARCHAR(200) NULL,
    country VARCHAR(50) NULL,
    isactive BOOLEAN NOT NULL DEFAULT TRUE,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp());

-- STATEMENT 19: Create Products Table
-- Conversion Method: DMS_TOOL (Success)
-- Note: DMS used NUMERIC(1,0) for BIT; file uses BOOLEAN (better PG idiom)
CREATE TABLE productmanagement_dbo.products
(productid BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    categoryid INTEGER NULL,
    supplierid INTEGER NULL,
    sku VARCHAR(50) NULL,
    weight NUMERIC(10, 2) NULL,
    dimensions VARCHAR(50) NULL,
    isdiscontinued BOOLEAN NOT NULL DEFAULT FALSE,
    reorderlevel INTEGER NOT NULL DEFAULT 10,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE NULL,
    CONSTRAINT fk_products_categories FOREIGN KEY (categoryid) 
        REFERENCES productmanagement_dbo.categories (categoryid),
    CONSTRAINT fk_products_suppliers FOREIGN KEY (supplierid) 
        REFERENCES productmanagement_dbo.suppliers (supplierid));

-- STATEMENT 20: Create ProductHistory Table
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
CREATE TABLE productmanagement_dbo.producthistory
(historyid BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(10) NOT NULL,
    oldprice NUMERIC(18, 2) NULL,
    newprice NUMERIC(18, 2) NULL,
    oldstock INTEGER NULL,
    newstock INTEGER NULL,
    actiondate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifiedby VARCHAR(100) NULL,
    CONSTRAINT fk_producthistory_products FOREIGN KEY (productid) 
        REFERENCES productmanagement_dbo.products (productid));

-- STATEMENT 21: Create ProductStats Table
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
CREATE TABLE productmanagement_dbo.productstats
(statid INTEGER PRIMARY KEY DEFAULT 1,
    totalproducts INTEGER NOT NULL DEFAULT 0,
    averageprice NUMERIC(18, 2) NOT NULL DEFAULT 0,
    totalstockvalue NUMERIC(18, 2) NOT NULL DEFAULT 0,
    lowstockcount INTEGER NOT NULL DEFAULT 0,
    discontinuedcount INTEGER NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp());

-- STATEMENT 22: Create Index IX_Products_CategoryId
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
CREATE INDEX ix_products_categoryid ON productmanagement_dbo.products (categoryid);

-- STATEMENT 23: Create Index IX_Products_SupplierId
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
CREATE INDEX ix_products_supplierid ON productmanagement_dbo.products (supplierid);

-- STATEMENT 24: Create Unique Index IX_Products_SKU
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
CREATE UNIQUE INDEX ix_products_sku ON productmanagement_dbo.products (sku);

-- STATEMENT 25: Create Index IX_ProductHistory_ProductId
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
CREATE INDEX ix_producthistory_productid ON productmanagement_dbo.producthistory (productid);

-- STATEMENT 26: Create Index IX_ProductHistory_ActionDate
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
CREATE INDEX ix_producthistory_actiondate ON productmanagement_dbo.producthistory (actiondate);

-- STATEMENT 27: Insert Sample Categories
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
INSERT INTO productmanagement_dbo.categories (name, description, parentcategoryid)
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

-- STATEMENT 28: Insert Sample Suppliers
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
INSERT INTO productmanagement_dbo.suppliers (name, contactname, email, phone, address, country)
VALUES 
    ('TechGlobal Inc.', 'John Smith', 'john@techglobal.com', '+1-555-0101', '123 Tech Street, Silicon Valley, CA', 'USA'),
    ('ElectroParts Ltd.', 'Sarah Johnson', 'sarah@electroparts.com', '+44-20-7123-4567', '45 Circuit Road, London', 'UK'),
    ('Digital Solutions', 'Michael Chen', 'michael@digitalsolutions.com', '+86-10-1234-5678', '789 Digital Avenue, Beijing', 'China'),
    ('Gaming Gear Co.', 'David Wilson', 'david@gaminggear.com', '+1-555-0202', '456 Game Street, Seattle, WA', 'USA'),
    ('AudioTech Systems', 'Emma Brown', 'emma@audiotech.com', '+1-555-0303', '789 Sound Road, Nashville, TN', 'USA'),
    ('Storage Solutions', 'James Lee', 'james@storagesolutions.com', '+1-555-0404', '321 Data Drive, Austin, TX', 'USA'),
    ('Office Supplies Pro', 'Lisa Anderson', 'lisa@officesupplies.com', '+1-555-0505', '654 Office Park, Chicago, IL', 'USA'),
    ('Network Experts', 'Robert Taylor', 'robert@networkexperts.com', '+1-555-0606', '987 Network Way, Boston, MA', 'USA');

-- STATEMENT 29: Insert Sample Products
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity, categoryid, supplierid, sku, weight, dimensions, reorderlevel)
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

-- STATEMENT 30: Insert initial ProductStats record
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
INSERT INTO productmanagement_dbo.productstats (statid, totalproducts, averageprice, totalstockvalue, lowstockcount, discontinuedcount, lastupdated)
VALUES (1, 0, 0, 0, 0, 0, clock_timestamp());

-- STATEMENT 31: Update initial statistics
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = (SELECT COUNT(*) FROM productmanagement_dbo.products),
    averageprice = (SELECT AVG(price) FROM productmanagement_dbo.products),
    totalstockvalue = (SELECT SUM(price * stockquantity) FROM productmanagement_dbo.products),
    lowstockcount = (SELECT COUNT(*) FROM productmanagement_dbo.products WHERE stockquantity <= reorderlevel),
    discontinuedcount = (SELECT COUNT(*) FROM productmanagement_dbo.products WHERE isdiscontinued = TRUE),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- STATEMENT 32: Create Trigger trg_Products_History
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
-- PostgreSQL: Trigger function + trigger
CREATE OR REPLACE FUNCTION productmanagement_dbo.trg_products_history_func()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO productmanagement_dbo.producthistory (productid, action, newprice, newstock, modifiedby)
        VALUES (NEW.productid, 'INSERT', NEW.price, NEW.stockquantity, current_user);
        RETURN NEW;
    END IF;
    IF TG_OP = 'UPDATE' THEN
        IF OLD.price <> NEW.price OR OLD.stockquantity <> NEW.stockquantity THEN
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
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_products_history
AFTER INSERT OR UPDATE OR DELETE ON productmanagement_dbo.products
FOR EACH ROW EXECUTE FUNCTION productmanagement_dbo.trg_products_history_func();

-- STATEMENT 33: Create Function sp_GetAllProducts (replaces stored procedure)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getallproducts()
RETURNS TABLE (productid BIGINT, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP)
AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM productmanagement_dbo.products p
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- STATEMENT 34: Create Function sp_GetProductById (replaces stored procedure)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getproductbyid(p_productid INTEGER)
RETURNS TABLE (productid BIGINT, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP)
AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM productmanagement_dbo.products p
    WHERE p.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- STATEMENT 35: Create Function sp_InsertProduct (replaces stored procedure)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_insertproduct(
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18,2),
    p_stockquantity INTEGER
)
RETURNS BIGINT AS $$
DECLARE
    v_productid BIGINT;
BEGIN
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING productmanagement_dbo.products.productid INTO v_productid;
    RETURN v_productid;
END;
$$ LANGUAGE plpgsql;

-- STATEMENT 36: Create Function sp_UpdateProduct (replaces stored procedure)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_updateproduct(
    p_productid INTEGER,
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18,2),
    p_stockquantity INTEGER
)
RETURNS VOID AS $$
BEGIN
    UPDATE productmanagement_dbo.products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stockquantity = p_stockquantity,
        modifieddate = clock_timestamp()
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- STATEMENT 37: Create Function sp_DeleteProduct (replaces stored procedure)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_deleteproduct(p_productid INTEGER)
RETURNS VOID AS $$
BEGIN
    DELETE FROM productmanagement_dbo.products
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- ====================================================================
-- SOURCE FILE: sourceCode/Scripts/01_InitialSetup.sql
-- ====================================================================

-- STATEMENT 38: Create Database (conditional) - Scripts version
-- Conversion Method: DMS_TOOL (Success - same as Statement 8)
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;

-- STATEMENT 39: USE Database - Scripts version
-- Conversion Method: DMS_TOOL (Success - same as Statement 9)
-- No direct equivalent needed

-- STATEMENT 40: Create Products Table (conditional) - Scripts version
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
CREATE TABLE IF NOT EXISTS productmanagement_dbo.products
(productid BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE NULL);

-- STATEMENT 41: Create Function sp_GetAllProducts - Scripts version
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
-- Same as Statement 33

-- STATEMENT 42: Create Function sp_GetProductById - Scripts version
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
-- Same as Statement 34

-- STATEMENT 43: Create Function sp_InsertProduct - Scripts version
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
-- Same as Statement 35

-- STATEMENT 44: Create Function sp_UpdateProduct - Scripts version
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
-- Same as Statement 36

-- STATEMENT 45: Create Function sp_DeleteProduct - Scripts version
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
-- Same as Statement 37

-- STATEMENT 46: Insert Sample Data (conditional with EXEC) - Scripts version
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (timeout)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM productmanagement_dbo.products LIMIT 1) THEN
        PERFORM productmanagement_dbo.sp_insertproduct('Laptop', 'High-performance laptop', 999.99, 10);
        PERFORM productmanagement_dbo.sp_insertproduct('Mouse', 'Wireless gaming mouse', 49.99, 20);
        PERFORM productmanagement_dbo.sp_insertproduct('Keyboard', 'Mechanical keyboard', 129.99, 15);
    END IF;
END $$;

-- ====================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total Statements: 46
-- DMS Success: 12 (Statements 1, 2, 3a, 3b, 3c, 4a, 4b, 5c, 6, 7, 8, 9, 16, 19)
-- DMS Failed (manual conversion): 34 (remaining - all due to timeout)
-- ====================================================================
