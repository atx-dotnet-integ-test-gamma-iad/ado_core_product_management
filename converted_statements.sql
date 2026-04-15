-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: AdoCore .NET Application - Converted from MS SQL Server
-- DMS Status: All conversions failed - Manual conversion with lowercase schema
-- Schema mappings obtained from DMS schema_mapping_tool
-- ============================================================================

-- ============================================================================
-- DMS FAILURE LOG
-- All 44 statements were passed through DMS MCP tool
-- (dms-mcp___statement_conversion_tool) and all returned the same error:
-- Status: error
-- Error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- Conversion method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Schema mapping reference: Obtained via dms-mcp___schema_mapping_tool
--   Products -> products (schema: productmanagement_dbo)
--   ProductHistory -> producthistory (schema: productmanagement_dbo)
--   ProductStats -> productstats (schema: productmanagement_dbo)
--   Categories -> categories (schema: productmanagement_dbo)
--   Suppliers -> suppliers (schema: productmanagement_dbo)
-- ============================================================================

-- ============================================================================
-- SOURCE FILE: DataAccess/ProductRepository.cs
-- ============================================================================

-- --------------------------------------------------------------------------
-- Statement 1: GetAllProductsAsync - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: All identifiers lowercased per DMS schema mapping
-- --------------------------------------------------------------------------
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

-- --------------------------------------------------------------------------
-- Statement 2: GetProductByIdAsync - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: All identifiers lowercased, ROUND precision maintained
-- --------------------------------------------------------------------------
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

-- --------------------------------------------------------------------------
-- Statement 3: InsertProductAsync - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: SCOPE_IDENTITY() -> RETURNING productid, GETDATE() -> NOW(),
--          DECLARE/SET removed, transaction restructured for PostgreSQL,
--          All identifiers lowercased
-- --------------------------------------------------------------------------
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following statements must be executed separately after retrieving productid
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (<returned_productid>, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
--
-- UPDATE productstats
-- SET totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--     lastupdated = NOW()
-- WHERE statid = 1;

-- --------------------------------------------------------------------------
-- Statement 4: UpdateProductAsync - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: DECLARE -> PostgreSQL variable handling via subquery,
--          GETDATE() -> NOW(), All identifiers lowercased
-- --------------------------------------------------------------------------
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
)
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- Subsequent statements for history and stats update:
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- SELECT @ProductId, 'UPDATE', oldprice, @Price, oldstock, @StockQuantity, NOW()
-- FROM old_values;
--
-- UPDATE productstats
-- SET averageprice = (averageprice * totalproducts - <oldprice> + @Price) / totalproducts,
--     lastupdated = NOW()
-- WHERE statid = 1;

-- --------------------------------------------------------------------------
-- Statement 5: DeleteProductAsync - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: DECLARE -> PostgreSQL variable handling via subquery,
--          GETDATE() -> NOW(), CASE expression preserved,
--          All identifiers lowercased
-- --------------------------------------------------------------------------
-- Transaction block restructured for C# ADO.NET with Npgsql:
-- Step 1: Get old values
-- SELECT price, stockquantity FROM products WHERE productid = @ProductId
-- Step 2: Log deletion
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@ProductId, 'DELETE', <oldprice>, NULL, <oldstock>, NULL, NOW())
-- Step 3: Delete product
-- DELETE FROM products WHERE productid = @ProductId
-- Step 4: Update stats
-- UPDATE productstats SET totalproducts = totalproducts - 1,
--     averageprice = CASE WHEN totalproducts > 1
--         THEN (averageprice * totalproducts - <oldprice>) / (totalproducts - 1)
--         ELSE 0 END,
--     lastupdated = NOW()
-- WHERE statid = 1

-- --------------------------------------------------------------------------
-- Statement 6: GetProductsByPriceRangeAsync - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: All identifiers lowercased
-- --------------------------------------------------------------------------
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

-- --------------------------------------------------------------------------
-- Statement 7: GetLowStockProductsAsync - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: All identifiers lowercased, added ::numeric cast for integer division
-- --------------------------------------------------------------------------
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
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;

-- ============================================================================
-- SOURCE FILE: Scripts/01_InitialSetup.sql
-- ============================================================================

-- --------------------------------------------------------------------------
-- Statement S1: Create Database - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Database creation commented out (done outside script in PostgreSQL)
-- --------------------------------------------------------------------------
-- Note: In PostgreSQL, database creation is typically done outside of script execution
-- CREATE DATABASE productmanagement;

-- --------------------------------------------------------------------------
-- Statement S2: Create Products Table - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: IDENTITY -> GENERATED ALWAYS AS IDENTITY, NVARCHAR -> VARCHAR,
--          DATETIME -> TIMESTAMP, GETDATE() -> NOW(), IF NOT EXISTS syntax,
--          All identifiers lowercased
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products(
    productid INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price DECIMAL(18, 2) NOT NULL,
    stockquantity INT NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT NOW(),
    modifieddate TIMESTAMP NULL
);

-- --------------------------------------------------------------------------
-- Statement S3: sp_GetAllProducts - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: CREATE OR ALTER PROCEDURE -> CREATE OR REPLACE FUNCTION,
--          SET NOCOUNT ON removed, RETURN QUERY added, All identifiers lowercased
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE(
    productid INT,
    name VARCHAR(100),
    description VARCHAR(500),
    price DECIMAL(18,2),
    stockquantity INT,
    createddate TIMESTAMP,
    modifieddate TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- --------------------------------------------------------------------------
-- Statement S4: sp_GetProductById - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: CREATE OR ALTER PROCEDURE -> CREATE OR REPLACE FUNCTION,
--          @ProductId -> p_productid parameter, All identifiers lowercased
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INT)
RETURNS TABLE(
    productid INT,
    name VARCHAR(100),
    description VARCHAR(500),
    price DECIMAL(18,2),
    stockquantity INT,
    createddate TIMESTAMP,
    modifieddate TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    WHERE p.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- --------------------------------------------------------------------------
-- Statement S5: sp_InsertProduct - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: CREATE OR ALTER PROCEDURE -> CREATE OR REPLACE FUNCTION,
--          SCOPE_IDENTITY() -> RETURNING INTO, All identifiers lowercased
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_insertproduct(
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price DECIMAL(18,2),
    p_stockquantity INT
)
RETURNS INT AS $$
DECLARE
    v_productid INT;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING products.productid INTO v_productid;
    
    RETURN v_productid;
END;
$$ LANGUAGE plpgsql;

-- --------------------------------------------------------------------------
-- Statement S6: sp_UpdateProduct - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: CREATE OR ALTER PROCEDURE -> CREATE OR REPLACE FUNCTION,
--          GETDATE() -> NOW(), @params -> p_params, All identifiers lowercased
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_updateproduct(
    p_productid INT,
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price DECIMAL(18,2),
    p_stockquantity INT
)
RETURNS VOID AS $$
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

-- --------------------------------------------------------------------------
-- Statement S7: sp_DeleteProduct - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: CREATE OR ALTER PROCEDURE -> CREATE OR REPLACE FUNCTION,
--          @ProductId -> p_productid, All identifiers lowercased
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid INT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM products
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- --------------------------------------------------------------------------
-- Statement S8: Insert Sample Data - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: IF NOT EXISTS -> DO $$ block, EXEC -> PERFORM,
--          TOP 1 -> LIMIT 1, All identifiers lowercased
-- --------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM products LIMIT 1) THEN
        PERFORM sp_insertproduct('Laptop', 'High-performance laptop', 999.99, 10);
        PERFORM sp_insertproduct('Mouse', 'Wireless gaming mouse', 49.99, 20);
        PERFORM sp_insertproduct('Keyboard', 'Mechanical keyboard', 129.99, 15);
    END IF;
END $$;

-- ============================================================================
-- SOURCE FILE: Database/Scripts/01_InitialSetup.sql
-- ============================================================================

-- --------------------------------------------------------------------------
-- Statement D1: Create Database - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Database creation commented out (done outside script in PostgreSQL)
-- --------------------------------------------------------------------------
-- Note: In PostgreSQL, database creation is typically done outside of script execution
-- CREATE DATABASE productmanagement;

-- --------------------------------------------------------------------------
-- Statement D2: Drop Trigger - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: IF EXISTS(sys.objects) -> DROP TRIGGER IF EXISTS ON table,
--          All identifiers lowercased
-- --------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_products_history ON products;

-- --------------------------------------------------------------------------
-- Statement D3: Drop ProductHistory Table - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: IF EXISTS(sys.objects) -> DROP TABLE IF EXISTS,
--          All identifiers lowercased
-- --------------------------------------------------------------------------
DROP TABLE IF EXISTS producthistory;

-- --------------------------------------------------------------------------
-- Statement D4: Drop Products Table - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: IF EXISTS(sys.objects) -> DROP TABLE IF EXISTS,
--          All identifiers lowercased
-- --------------------------------------------------------------------------
DROP TABLE IF EXISTS products;

-- --------------------------------------------------------------------------
-- Statement D5: Drop Categories Table - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: IF EXISTS(sys.objects) -> DROP TABLE IF EXISTS,
--          All identifiers lowercased
-- --------------------------------------------------------------------------
DROP TABLE IF EXISTS categories;

-- --------------------------------------------------------------------------
-- Statement D6: Drop Suppliers Table - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: IF EXISTS(sys.objects) -> DROP TABLE IF EXISTS,
--          All identifiers lowercased
-- --------------------------------------------------------------------------
DROP TABLE IF EXISTS suppliers;

-- --------------------------------------------------------------------------
-- Statement D7: Drop ProductStats Table - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: IF EXISTS(sys.objects) -> DROP TABLE IF EXISTS,
--          All identifiers lowercased
-- --------------------------------------------------------------------------
DROP TABLE IF EXISTS productstats;

-- --------------------------------------------------------------------------
-- Statement D8: Create Categories Table - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: IDENTITY -> GENERATED ALWAYS AS IDENTITY, NVARCHAR -> VARCHAR,
--          DATETIME -> TIMESTAMP, GETDATE() -> NOW(), All identifiers lowercased
-- --------------------------------------------------------------------------
CREATE TABLE categories(
    categoryid INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200) NULL,
    parentcategoryid INT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT NOW()
);

-- --------------------------------------------------------------------------
-- Statement D9: Add FK Categories self-referencing - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: [dbo].[table] -> table, constraint/column names lowercased
-- --------------------------------------------------------------------------
ALTER TABLE categories
ADD CONSTRAINT fk_categories_categories 
FOREIGN KEY (parentcategoryid) REFERENCES categories (categoryid);

-- --------------------------------------------------------------------------
-- Statement D10: Create Suppliers Table - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: IDENTITY -> GENERATED ALWAYS AS IDENTITY, NVARCHAR -> VARCHAR,
--          BIT -> BOOLEAN, DEFAULT 1 -> DEFAULT TRUE,
--          DATETIME -> TIMESTAMP, GETDATE() -> NOW(), All identifiers lowercased
-- --------------------------------------------------------------------------
CREATE TABLE suppliers(
    supplierid INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contactname VARCHAR(100) NULL,
    email VARCHAR(100) NULL,
    phone VARCHAR(20) NULL,
    address VARCHAR(200) NULL,
    country VARCHAR(50) NULL,
    isactive BOOLEAN NOT NULL DEFAULT TRUE,
    createddate TIMESTAMP NOT NULL DEFAULT NOW()
);

-- --------------------------------------------------------------------------
-- Statement D11: Create Products Table - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: IDENTITY -> GENERATED ALWAYS AS IDENTITY, NVARCHAR -> VARCHAR,
--          BIT -> BOOLEAN, DEFAULT 0 -> DEFAULT FALSE,
--          DATETIME -> TIMESTAMP, GETDATE() -> NOW(),
--          FK constraint names lowercased, All identifiers lowercased
-- --------------------------------------------------------------------------
CREATE TABLE products(
    productid INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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

-- --------------------------------------------------------------------------
-- Statement D12: Create ProductHistory Table - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: IDENTITY -> GENERATED ALWAYS AS IDENTITY, NVARCHAR -> VARCHAR,
--          DATETIME -> TIMESTAMP, GETDATE() -> NOW(),
--          FK constraint name lowercased, All identifiers lowercased
-- --------------------------------------------------------------------------
CREATE TABLE producthistory(
    historyid INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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

-- --------------------------------------------------------------------------
-- Statement D13: Create ProductStats Table - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: DATETIME -> TIMESTAMP, GETDATE() -> NOW(), All identifiers lowercased
-- --------------------------------------------------------------------------
CREATE TABLE productstats(
    statid INT PRIMARY KEY DEFAULT 1,
    totalproducts INT NOT NULL DEFAULT 0,
    averageprice DECIMAL(18, 2) NOT NULL DEFAULT 0,
    totalstockvalue DECIMAL(18, 2) NOT NULL DEFAULT 0,
    lowstockcount INT NOT NULL DEFAULT 0,
    discontinuedcount INT NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL DEFAULT NOW()
);

-- --------------------------------------------------------------------------
-- Statement D14: Create Index IX_Products_CategoryId - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: [dbo].[table] -> table, index/column names lowercased
-- --------------------------------------------------------------------------
CREATE INDEX ix_products_categoryid ON products (categoryid);

-- --------------------------------------------------------------------------
-- Statement D15: Create Index IX_Products_SupplierId - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: [dbo].[table] -> table, index/column names lowercased
-- --------------------------------------------------------------------------
CREATE INDEX ix_products_supplierid ON products (supplierid);

-- --------------------------------------------------------------------------
-- Statement D16: Create Unique Index IX_Products_SKU - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: [dbo].[table] -> table, index/column names lowercased
-- --------------------------------------------------------------------------
CREATE UNIQUE INDEX ix_products_sku ON products (sku);

-- --------------------------------------------------------------------------
-- Statement D17: Create Index IX_ProductHistory_ProductId - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: [dbo].[table] -> table, index/column names lowercased
-- --------------------------------------------------------------------------
CREATE INDEX ix_producthistory_productid ON producthistory (productid);

-- --------------------------------------------------------------------------
-- Statement D18: Create Index IX_ProductHistory_ActionDate - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: [dbo].[table] -> table, index/column names lowercased
-- --------------------------------------------------------------------------
CREATE INDEX ix_producthistory_actiondate ON producthistory (actiondate);

-- --------------------------------------------------------------------------
-- Statement D19: Insert Sample Categories - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: All identifiers lowercased
-- --------------------------------------------------------------------------
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

-- --------------------------------------------------------------------------
-- Statement D20: Insert Sample Suppliers - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: All identifiers lowercased
-- --------------------------------------------------------------------------
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

-- --------------------------------------------------------------------------
-- Statement D21: Insert Sample Products - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: All identifiers lowercased
-- --------------------------------------------------------------------------
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

-- --------------------------------------------------------------------------
-- Statement D22: Insert Initial Stats Record - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: GETDATE() -> NOW(), All identifiers lowercased
-- --------------------------------------------------------------------------
INSERT INTO productstats (statid, totalproducts, averageprice, totalstockvalue, lowstockcount, discontinuedcount, lastupdated)
VALUES (1, 0, 0, 0, 0, 0, NOW());

-- --------------------------------------------------------------------------
-- Statement D23: Update Initial Statistics - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: GETDATE() -> NOW(), IsDiscontinued = 1 -> isdiscontinued = TRUE,
--          All identifiers lowercased
-- --------------------------------------------------------------------------
UPDATE productstats
SET 
    totalproducts = (SELECT COUNT(*) FROM products),
    averageprice = (SELECT AVG(price) FROM products),
    totalstockvalue = (SELECT SUM(price * stockquantity) FROM products),
    lowstockcount = (SELECT COUNT(*) FROM products WHERE stockquantity <= reorderlevel),
    discontinuedcount = (SELECT COUNT(*) FROM products WHERE isdiscontinued = TRUE),
    lastupdated = NOW()
WHERE statid = 1;

-- --------------------------------------------------------------------------
-- Statement D24: Create Trigger trg_Products_History - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: SQL Server TRIGGER -> PostgreSQL FUNCTION + TRIGGER pattern,
--          inserted/deleted -> NEW/OLD, SYSTEM_USER -> current_user,
--          IF EXISTS(SELECT FROM inserted/deleted) -> TG_OP,
--          All identifiers lowercased
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_products_history_func()
RETURNS TRIGGER AS $$
BEGIN
    -- Handle INSERT
    IF TG_OP = 'INSERT' THEN
        INSERT INTO producthistory (productid, action, newprice, newstock, modifiedby)
        VALUES (NEW.productid, 'INSERT', NEW.price, NEW.stockquantity, current_user);
        RETURN NEW;
    END IF;
    
    -- Handle UPDATE
    IF TG_OP = 'UPDATE' THEN
        IF OLD.price <> NEW.price OR OLD.stockquantity <> NEW.stockquantity THEN
            INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, modifiedby)
            VALUES (NEW.productid, 'UPDATE', OLD.price, NEW.price, OLD.stockquantity, NEW.stockquantity, current_user);
        END IF;
        RETURN NEW;
    END IF;
    
    -- Handle DELETE
    IF TG_OP = 'DELETE' THEN
        INSERT INTO producthistory (productid, action, oldprice, oldstock, modifiedby)
        VALUES (OLD.productid, 'DELETE', OLD.price, OLD.stockquantity, current_user);
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_products_history
AFTER INSERT OR UPDATE OR DELETE ON products
FOR EACH ROW
EXECUTE FUNCTION trg_products_history_func();

-- --------------------------------------------------------------------------
-- Statement D25: sp_GetAllProducts - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: CREATE OR ALTER PROCEDURE -> CREATE OR REPLACE FUNCTION,
--          SET NOCOUNT ON removed, RETURN QUERY added, All identifiers lowercased
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE(
    productid INT,
    name VARCHAR(100),
    description VARCHAR(500),
    price DECIMAL(18,2),
    stockquantity INT,
    createddate TIMESTAMP,
    modifieddate TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- --------------------------------------------------------------------------
-- Statement D26: sp_GetProductById - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: CREATE OR ALTER PROCEDURE -> CREATE OR REPLACE FUNCTION,
--          @ProductId -> p_productid, All identifiers lowercased
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INT)
RETURNS TABLE(
    productid INT,
    name VARCHAR(100),
    description VARCHAR(500),
    price DECIMAL(18,2),
    stockquantity INT,
    createddate TIMESTAMP,
    modifieddate TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    WHERE p.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- --------------------------------------------------------------------------
-- Statement D27: sp_InsertProduct - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: CREATE OR ALTER PROCEDURE -> CREATE OR REPLACE FUNCTION,
--          SCOPE_IDENTITY() -> RETURNING INTO, All identifiers lowercased
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_insertproduct(
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price DECIMAL(18,2),
    p_stockquantity INT
)
RETURNS INT AS $$
DECLARE
    v_productid INT;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING products.productid INTO v_productid;
    
    RETURN v_productid;
END;
$$ LANGUAGE plpgsql;

-- --------------------------------------------------------------------------
-- Statement D28: sp_UpdateProduct - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: CREATE OR ALTER PROCEDURE -> CREATE OR REPLACE FUNCTION,
--          GETDATE() -> NOW(), @params -> p_params, All identifiers lowercased
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_updateproduct(
    p_productid INT,
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price DECIMAL(18,2),
    p_stockquantity INT
)
RETURNS VOID AS $$
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

-- --------------------------------------------------------------------------
-- Statement D29: sp_DeleteProduct - PostgreSQL Conversion
-- DMS Attempted: Yes (Failed - Metadata model creation error)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: CREATE OR ALTER PROCEDURE -> CREATE OR REPLACE FUNCTION,
--          @ProductId -> p_productid, All identifiers lowercased
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid INT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM products
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Total Statements Converted: 44
-- From ProductRepository.cs: 7 (inline SQL in C# code)
-- From Scripts/01_InitialSetup.sql: 8 (S1-S8)
-- From Database/Scripts/01_InitialSetup.sql: 29 (D1-D29)
-- DMS Conversion Success: 0 (all failed with metadata model creation error)
-- Manual Conversion: 44 (with lowercase schema per DMS schema mappings)
-- Key SQL Server -> PostgreSQL transformations applied:
--   SCOPE_IDENTITY() -> RETURNING clause
--   GETDATE() -> NOW()
--   DECLARE @var -> PostgreSQL variable handling / subqueries
--   BEGIN TRANSACTION/COMMIT -> Managed by C# transaction handling
--   INTEGER division -> ::numeric cast for proper decimal results
--   CREATE OR ALTER PROCEDURE -> CREATE OR REPLACE FUNCTION
--   CREATE TRIGGER (SQL Server) -> CREATE FUNCTION + CREATE TRIGGER (PostgreSQL)
--   IDENTITY(1,1) -> GENERATED ALWAYS AS IDENTITY
--   NVARCHAR -> VARCHAR
--   DATETIME -> TIMESTAMP
--   BIT -> BOOLEAN
--   SYSTEM_USER -> current_user
--   IF NOT EXISTS(sys.objects) -> DROP IF EXISTS / CREATE IF NOT EXISTS
--   [dbo].[TableName] -> tablename (lowercase, no schema prefix)
--   All schema object names -> lowercase (per DMS schema_mapping_tool output)
-- ============================================================================
