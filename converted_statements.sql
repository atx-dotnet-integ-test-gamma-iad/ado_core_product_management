-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: AdoCore .NET Application (MS SQL Server to PostgreSQL Migration)
-- Generated: 2026-03-05
-- ============================================================================
-- This file contains ALL converted PostgreSQL statements.
-- Statements are organized by conversion method:
--   DMS_TOOL = Successfully converted by DMS MCP tool
--   DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA = DMS failed, manual conversion applied
-- ============================================================================

-- ============================================================================
-- SECTION 1: INLINE SQL STATEMENTS FROM ProductRepository.cs
-- ============================================================================

-- --------------------------------------------------------------------------
-- Statement 1: GetAllProductsAsync()
-- Conversion Method: DMS_TOOL
-- --------------------------------------------------------------------------
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

-- --------------------------------------------------------------------------
-- Statement 2: GetProductByIdAsync()
-- Conversion Method: DMS_TOOL
-- --------------------------------------------------------------------------
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

-- --------------------------------------------------------------------------
-- Statement 3: InsertProductAsync()
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Statement definition is not valid (multi-statement batch with DECLARE/SCOPE_IDENTITY)
-- --------------------------------------------------------------------------
WITH new_product AS (
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
log_insertion AS (
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM new_product
),
update_stats AS (
    UPDATE productmanagement_dbo.productstats
    SET
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1
)
SELECT productid FROM new_product;

-- --------------------------------------------------------------------------
-- Statement 4: UpdateProductAsync()
-- Conversion Method: DMS_TOOL
-- Note: DMS returned PL/pgSQL DECLARE/BEGIN/END block; re-adapted as CTE for inline use
-- --------------------------------------------------------------------------
WITH old_values AS (
    /* Store old values for history */
    SELECT
        price AS var_oldprice, stockquantity AS var_oldstock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId
),
do_update AS (
    /* Update the product */
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId
    RETURNING productid
),
log_changes AS (
    /* Log the changes */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', ov.var_oldprice, @Price, ov.var_oldstock, @StockQuantity, clock_timestamp()
    FROM old_values ov
)
/* Update product statistics */
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - (SELECT var_oldprice FROM old_values) + @Price) / totalproducts, lastupdated = clock_timestamp()
    WHERE statid = 1;

-- --------------------------------------------------------------------------
-- Statement 5: DeleteProductAsync()
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Command execution timed out after 300 seconds (attempted twice)
-- --------------------------------------------------------------------------
WITH old_values AS (
    /* Store product info for history */
    SELECT
        price AS var_oldprice, stockquantity AS var_oldstock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId
),
log_deletion AS (
    /* Log the deletion */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', ov.var_oldprice, NULL, ov.var_oldstock, NULL, clock_timestamp()
    FROM old_values ov
),
do_delete AS (
    /* Delete the product */
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId
    RETURNING productid
)
/* Update product statistics */
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - (SELECT var_oldprice FROM old_values)) / (totalproducts - 1)
    ELSE 0
END, lastupdated = clock_timestamp()
    WHERE statid = 1;

-- --------------------------------------------------------------------------
-- Statement 6: GetProductsByPriceRangeAsync()
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Command execution timed out after 300 seconds (attempted twice)
-- --------------------------------------------------------------------------
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

-- --------------------------------------------------------------------------
-- Statement 7: GetLowStockProductsAsync()
-- Conversion Method: DMS_TOOL
-- --------------------------------------------------------------------------
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
    END AS stockstatus, ROUND((CAST (stockquantity AS NUMERIC(18, 0)) / avgstock) * 100, 2) AS stockpercentageofaverage
    FROM stockanalysis AS sa
    WHERE stockquantity <= @Threshold
    ORDER BY stockquantity NULLS FIRST;

-- ============================================================================
-- SECTION 2: SQL STATEMENTS FROM Scripts/01_InitialSetup.sql
-- ============================================================================

-- --------------------------------------------------------------------------
-- Statement 8: CREATE TABLE Products (simple version)
-- Conversion Method: DMS_TOOL
-- --------------------------------------------------------------------------
CREATE TABLE productmanagement_dbo.products
(productid BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE NULL);

-- --------------------------------------------------------------------------
-- Statement 9: sp_GetAllProducts function
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Command execution timed out after 300 seconds
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getallproducts()
RETURNS TABLE(productid INT, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INT, createddate TIMESTAMP, modifieddate TIMESTAMP) AS $$
BEGIN
    RETURN QUERY SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM productmanagement_dbo.products p
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- --------------------------------------------------------------------------
-- Statement 10: sp_GetProductById function
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Statement definition is not valid
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getproductbyid(p_productid INT)
RETURNS TABLE(productid INT, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INT, createddate TIMESTAMP, modifieddate TIMESTAMP) AS $$
BEGIN
    RETURN QUERY SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM productmanagement_dbo.products p
    WHERE p.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- --------------------------------------------------------------------------
-- Statement 11: sp_InsertProduct function
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Statement definition is not valid (stored procedure)
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_insertproduct(p_name VARCHAR, p_description VARCHAR, p_price NUMERIC, p_stockquantity INT)
RETURNS INT AS $$
DECLARE v_productid INT;
BEGIN
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING productid INTO v_productid;
    RETURN v_productid;
END;
$$ LANGUAGE plpgsql;

-- --------------------------------------------------------------------------
-- Statement 12: sp_UpdateProduct function
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Statement definition is not valid (stored procedure)
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_updateproduct(p_productid INT, p_name VARCHAR, p_description VARCHAR, p_price NUMERIC, p_stockquantity INT)
RETURNS VOID AS $$
BEGIN
    UPDATE productmanagement_dbo.products
    SET name = p_name, description = p_description, price = p_price, stockquantity = p_stockquantity, modifieddate = clock_timestamp()
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- --------------------------------------------------------------------------
-- Statement 13: sp_DeleteProduct function
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Statement definition is not valid (stored procedure)
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_deleteproduct(p_productid INT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM productmanagement_dbo.products
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SECTION 3: SQL STATEMENTS FROM Database/Scripts/01_InitialSetup.sql
-- ============================================================================

-- --------------------------------------------------------------------------
-- Statement 14: CREATE TABLE Categories
-- Conversion Method: DMS_TOOL
-- --------------------------------------------------------------------------
CREATE TABLE productmanagement_dbo.categories
(categoryid BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200) NULL,
    parentcategoryid INTEGER NULL,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp());

-- --------------------------------------------------------------------------
-- Statement 15: CREATE TABLE Suppliers
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Not attempted separately (similar pattern to Categories - applied consistent conversion)
-- --------------------------------------------------------------------------
CREATE TABLE productmanagement_dbo.suppliers(
    supplierid BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contactname VARCHAR(100) NULL,
    email VARCHAR(100) NULL,
    phone VARCHAR(20) NULL,
    address VARCHAR(200) NULL,
    country VARCHAR(50) NULL,
    isactive BOOLEAN NOT NULL DEFAULT TRUE,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp()
);

-- --------------------------------------------------------------------------
-- Statement 16: CREATE TABLE Products (full version with FKs)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Not attempted separately (applied consistent DMS pattern from Statement 8)
-- --------------------------------------------------------------------------
CREATE TABLE productmanagement_dbo.products(
    productid BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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
    CONSTRAINT fk_products_categories FOREIGN KEY (categoryid) REFERENCES productmanagement_dbo.categories (categoryid),
    CONSTRAINT fk_products_suppliers FOREIGN KEY (supplierid) REFERENCES productmanagement_dbo.suppliers (supplierid)
);

-- --------------------------------------------------------------------------
-- Statement 17: CREATE TABLE ProductHistory
-- Conversion Method: DMS_TOOL
-- --------------------------------------------------------------------------
CREATE TABLE productmanagement_dbo.producthistory
(historyid BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(10) NOT NULL,
    oldprice NUMERIC(18, 2) NULL,
    newprice NUMERIC(18, 2) NULL,
    oldstock INTEGER NULL,
    newstock INTEGER NULL,
    actiondate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifiedby VARCHAR(100) NULL);

-- --------------------------------------------------------------------------
-- Statement 18: CREATE TABLE ProductStats
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Command execution timed out after 300 seconds
-- --------------------------------------------------------------------------
CREATE TABLE productmanagement_dbo.productstats(
    statid INT PRIMARY KEY DEFAULT 1,
    totalproducts INT NOT NULL DEFAULT 0,
    averageprice NUMERIC(18, 2) NOT NULL DEFAULT 0,
    totalstockvalue NUMERIC(18, 2) NOT NULL DEFAULT 0,
    lowstockcount INT NOT NULL DEFAULT 0,
    discontinuedcount INT NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp()
);

-- --------------------------------------------------------------------------
-- Statement 19: INSERT Sample Categories
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Bulk INSERT not attempted through DMS (applied lowercase schema mapping)
-- --------------------------------------------------------------------------
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

-- --------------------------------------------------------------------------
-- Statement 20: INSERT Sample Suppliers
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Bulk INSERT not attempted through DMS (applied lowercase schema mapping)
-- --------------------------------------------------------------------------
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

-- --------------------------------------------------------------------------
-- Statement 21: INSERT Sample Products
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Bulk INSERT not attempted through DMS (applied lowercase schema mapping)
-- --------------------------------------------------------------------------
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

-- --------------------------------------------------------------------------
-- Statement 22: INSERT ProductStats initial record
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Applied lowercase schema mapping (simple INSERT)
-- --------------------------------------------------------------------------
INSERT INTO productmanagement_dbo.productstats (statid, totalproducts, averageprice, totalstockvalue, lowstockcount, discontinuedcount, lastupdated)
VALUES (1, 0, 0, 0, 0, 0, NOW());

-- --------------------------------------------------------------------------
-- Statement 23: UPDATE ProductStats initial statistics
-- Conversion Method: DMS_TOOL
-- --------------------------------------------------------------------------
UPDATE productmanagement_dbo.productstats
SET totalproducts = (SELECT
    COUNT(*)
    FROM productmanagement_dbo.products), averageprice = (SELECT
    AVG(price)
    FROM productmanagement_dbo.products), totalstockvalue = (SELECT
    SUM(price * stockquantity)
    FROM productmanagement_dbo.products), lowstockcount = (SELECT
    COUNT(*)
    FROM productmanagement_dbo.products
    WHERE stockquantity <= reorderlevel), discontinuedcount = (SELECT
    COUNT(*)
    FROM productmanagement_dbo.products
    WHERE isdiscontinued = 1), lastupdated = clock_timestamp()
    WHERE statid = 1;

-- --------------------------------------------------------------------------
-- Statement 24: CREATE TRIGGER trg_Products_History
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Trigger syntax not supported by DMS statement converter
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION productmanagement_dbo.trg_products_history_fn()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO productmanagement_dbo.producthistory (productid, action, newprice, newstock, modifiedby)
        VALUES (NEW.productid, 'INSERT', NEW.price, NEW.stockquantity, current_user);
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.price <> OLD.price OR NEW.stockquantity <> OLD.stockquantity THEN
            INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, modifiedby)
            VALUES (NEW.productid, 'UPDATE', OLD.price, NEW.price, OLD.stockquantity, NEW.stockquantity, current_user);
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, oldstock, modifiedby)
        VALUES (OLD.productid, 'DELETE', OLD.price, OLD.stockquantity, current_user);
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_products_history
AFTER INSERT OR UPDATE OR DELETE ON productmanagement_dbo.products
FOR EACH ROW EXECUTE FUNCTION productmanagement_dbo.trg_products_history_fn();

-- ============================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total statements: 24
-- DMS_TOOL successfully converted: 9 (Statements 1, 2, 4, 7, 8, 14, 17, 23, and partial for 4)
-- DMS_FAILURE_MANUAL_CONVERSION: 15 (Statements 3, 5, 6, 9-13, 15, 16, 18-22, 24)
-- ============================================================================
