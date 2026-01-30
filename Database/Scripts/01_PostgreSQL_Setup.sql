-- ================================================================
-- PostgreSQL Database Setup Script
-- ================================================================
-- This script creates the ProductManagement database and all related objects
-- for the ADO.NET Core PostgreSQL application
--
-- Prerequisites:
--   - PostgreSQL 12 or later installed
--   - psql or pgAdmin 4 available
--   - User has CREATE DATABASE privileges
--
-- Usage:
--   psql -U postgres -f 01_PostgreSQL_Setup.sql
--   Or run in pgAdmin Query Tool
-- ================================================================

-- Create ProductManagement Database
-- Note: You may need to create this separately if not running as superuser
-- CREATE DATABASE "ProductManagement";

-- Connect to the database
\c ProductManagement

-- Drop existing objects in correct order (for clean reinstall)
DROP TRIGGER IF EXISTS trg_products_history ON products CASCADE;
DROP TABLE IF EXISTS product_history CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS product_stats CASCADE;

-- ================================================================
-- Create Categories Table
-- ================================================================
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200),
    parent_category_id INT,
    created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Add self-referencing foreign key for Categories
ALTER TABLE categories
ADD CONSTRAINT fk_categories_categories 
FOREIGN KEY (parent_category_id) REFERENCES categories (category_id);

-- ================================================================
-- Create Suppliers Table
-- ================================================================
CREATE TABLE suppliers (
    supplier_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    address VARCHAR(200),
    country VARCHAR(50),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ================================================================
-- Create Products Table
-- ================================================================
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    price NUMERIC(18, 2) NOT NULL,
    stock_quantity INT NOT NULL,
    category_id INT,
    supplier_id INT,
    sku VARCHAR(50),
    weight NUMERIC(10, 2),
    dimensions VARCHAR(50),
    is_discontinued BOOLEAN NOT NULL DEFAULT FALSE,
    reorder_level INT NOT NULL DEFAULT 10,
    created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_date TIMESTAMP,
    CONSTRAINT fk_products_categories FOREIGN KEY (category_id) 
        REFERENCES categories (category_id),
    CONSTRAINT fk_products_suppliers FOREIGN KEY (supplier_id) 
        REFERENCES suppliers (supplier_id)
);

-- ================================================================
-- Create ProductHistory Table
-- ================================================================
CREATE TABLE product_history (
    history_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL,
    action VARCHAR(10) NOT NULL,
    old_price NUMERIC(18, 2),
    new_price NUMERIC(18, 2),
    old_stock INT,
    new_stock INT,
    action_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_by VARCHAR(100),
    CONSTRAINT fk_product_history_products FOREIGN KEY (product_id) 
        REFERENCES products (product_id)
);

-- ================================================================
-- Create ProductStats Table
-- ================================================================
CREATE TABLE product_stats (
    stat_id INT PRIMARY KEY DEFAULT 1,
    total_products INT NOT NULL DEFAULT 0,
    average_price NUMERIC(18, 2) NOT NULL DEFAULT 0,
    total_stock_value NUMERIC(18, 2) NOT NULL DEFAULT 0,
    low_stock_count INT NOT NULL DEFAULT 0,
    discontinued_count INT NOT NULL DEFAULT 0,
    last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_stat_id CHECK (stat_id = 1)
);

-- ================================================================
-- Create Indexes
-- ================================================================
CREATE INDEX ix_products_category_id ON products (category_id);
CREATE INDEX ix_products_supplier_id ON products (supplier_id);
CREATE UNIQUE INDEX ix_products_sku ON products (sku) WHERE sku IS NOT NULL;
CREATE INDEX ix_product_history_product_id ON product_history (product_id);
CREATE INDEX ix_product_history_action_date ON product_history (action_date);

-- ================================================================
-- Insert Sample Categories
-- ================================================================
INSERT INTO categories (name, description, parent_category_id)
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

-- ================================================================
-- Insert Sample Suppliers
-- ================================================================
INSERT INTO suppliers (name, contact_name, email, phone, address, country)
VALUES 
    ('TechGlobal Inc.', 'John Smith', 'john@techglobal.com', '+1-555-0101', '123 Tech Street, Silicon Valley, CA', 'USA'),
    ('ElectroParts Ltd.', 'Sarah Johnson', 'sarah@electroparts.com', '+44-20-7123-4567', '45 Circuit Road, London', 'UK'),
    ('Digital Solutions', 'Michael Chen', 'michael@digitalsolutions.com', '+86-10-1234-5678', '789 Digital Avenue, Beijing', 'China'),
    ('Gaming Gear Co.', 'David Wilson', 'david@gaminggear.com', '+1-555-0202', '456 Game Street, Seattle, WA', 'USA'),
    ('AudioTech Systems', 'Emma Brown', 'emma@audiotech.com', '+1-555-0303', '789 Sound Road, Nashville, TN', 'USA'),
    ('Storage Solutions', 'James Lee', 'james@storagesolutions.com', '+1-555-0404', '321 Data Drive, Austin, TX', 'USA'),
    ('Office Supplies Pro', 'Lisa Anderson', 'lisa@officesupplies.com', '+1-555-0505', '654 Office Park, Chicago, IL', 'USA'),
    ('Network Experts', 'Robert Taylor', 'robert@networkexperts.com', '+1-555-0606', '987 Network Way, Boston, MA', 'USA');

-- ================================================================
-- Insert Sample Products
-- ================================================================
INSERT INTO products (name, description, price, stock_quantity, category_id, supplier_id, sku, weight, dimensions, reorder_level)
VALUES 
    -- Laptops
    ('ProBook X1', 'High-performance business laptop with 16GB RAM', 1299.99, 15, 9, 1, 'LAP-X1-001', 1.8, '14" x 9" x 0.7"', 5),
    ('Gaming Beast', 'Gaming laptop with RTX 3080, 32GB RAM', 2499.99, 8, 9, 4, 'LAP-GB-001', 2.5, '15.6" x 11" x 1"', 3),
    ('UltraBook Air', 'Ultra-thin laptop with 12-hour battery', 999.99, 20, 9, 1, 'LAP-UA-001', 1.2, '13" x 8" x 0.5"', 7),
    
    -- Desktops
    ('WorkStation Pro', 'Professional workstation with dual monitors', 1999.99, 10, 10, 1, 'DESK-WP-001', 15.0, '18" x 8" x 16"', 4),
    ('Gaming Tower', 'High-end gaming desktop with liquid cooling', 2999.99, 5, 16, 4, 'DESK-GT-001', 20.0, '20" x 10" x 18"', 2),
    
    -- Keyboards
    ('Mechanical Pro', 'Mechanical keyboard with RGB lighting', 149.99, 30, 11, 2, 'KB-MP-001', 1.2, '17" x 5" x 1.5"', 10),
    ('Wireless Elite', 'Wireless keyboard with numeric pad', 79.99, 25, 11, 2, 'KB-WE-001', 0.8, '18" x 6" x 1"', 8),
    
    -- Mice
    ('Gaming Mouse Pro', 'High-precision gaming mouse', 89.99, 40, 12, 4, 'M-GP-001', 0.3, '5" x 3" x 1.5"', 15),
    ('Wireless Track', 'Wireless mouse with long battery life', 49.99, 35, 12, 2, 'M-WT-001', 0.2, '4" x 2.5" x 1.2"', 12),
    
    -- Headphones
    ('Noise Cancelling Pro', 'Premium noise-cancelling headphones', 299.99, 20, 13, 5, 'HP-NC-001', 0.4, '7" x 6" x 3"', 8),
    ('Gaming Headset', '7.1 surround sound gaming headset', 129.99, 25, 13, 4, 'HP-GH-001', 0.5, '8" x 7" x 4"', 10),
    
    -- Speakers
    ('Studio Monitors', 'Professional studio monitors', 399.99, 10, 14, 5, 'SP-SM-001', 8.0, '12" x 8" x 10"', 4),
    ('Bluetooth Soundbar', 'Wireless soundbar with subwoofer', 249.99, 15, 14, 5, 'SP-BS-001', 5.0, '36" x 3" x 4"', 6),
    
    -- External Drives
    ('SSD Pro 1TB', '1TB external SSD with USB 3.1', 199.99, 30, 15, 6, 'ED-SP-001', 0.2, '4" x 2" x 0.5"', 12),
    ('HDD Backup 4TB', '4TB external HDD for backup', 129.99, 25, 15, 6, 'ED-HB-001', 0.5, '5" x 3" x 1"', 10),
    
    -- Printers
    ('Laser Pro', 'Business laser printer with duplex', 399.99, 12, 18, 7, 'PR-LP-001', 25.0, '18" x 16" x 12"', 5),
    ('Photo Inkjet', 'Photo-quality inkjet printer', 299.99, 15, 18, 7, 'PR-PI-001', 15.0, '16" x 14" x 8"', 6),
    
    -- Networking
    ('WiFi 6 Router', 'High-speed WiFi 6 router', 199.99, 20, 19, 8, 'NET-WR-001', 1.5, '10" x 7" x 2"', 8),
    ('Gigabit Switch', '24-port gigabit network switch', 299.99, 10, 20, 8, 'NET-GS-001', 3.0, '17" x 10" x 1.5"', 4);

-- ================================================================
-- Insert initial stats record
-- ================================================================
INSERT INTO product_stats (stat_id, total_products, average_price, total_stock_value, low_stock_count, discontinued_count, last_updated)
VALUES (1, 0, 0, 0, 0, 0, CURRENT_TIMESTAMP);

-- ================================================================
-- Update initial statistics
-- ================================================================
UPDATE product_stats
SET 
    total_products = (SELECT COUNT(*) FROM products),
    average_price = (SELECT AVG(price) FROM products),
    total_stock_value = (SELECT SUM(price * stock_quantity) FROM products),
    low_stock_count = (SELECT COUNT(*) FROM products WHERE stock_quantity <= reorder_level),
    discontinued_count = (SELECT COUNT(*) FROM products WHERE is_discontinued = TRUE),
    last_updated = CURRENT_TIMESTAMP
WHERE stat_id = 1;

-- ================================================================
-- Create Trigger for Product History
-- ================================================================
CREATE OR REPLACE FUNCTION trg_products_history_func()
RETURNS TRIGGER AS $$
BEGIN
    -- Handle INSERT
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO product_history (product_id, action, new_price, new_stock, modified_by)
        VALUES (NEW.product_id, 'INSERT', NEW.price, NEW.stock_quantity, current_user);
        RETURN NEW;
    END IF;
    
    -- Handle UPDATE
    IF (TG_OP = 'UPDATE') THEN
        IF (NEW.price <> OLD.price OR NEW.stock_quantity <> OLD.stock_quantity) THEN
            INSERT INTO product_history (product_id, action, old_price, new_price, old_stock, new_stock, modified_by)
            VALUES (NEW.product_id, 'UPDATE', OLD.price, NEW.price, OLD.stock_quantity, NEW.stock_quantity, current_user);
        END IF;
        RETURN NEW;
    END IF;
    
    -- Handle DELETE
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO product_history (product_id, action, old_price, old_stock, modified_by)
        VALUES (OLD.product_id, 'DELETE', OLD.price, OLD.stock_quantity, current_user);
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER trg_products_history
AFTER INSERT OR UPDATE OR DELETE ON products
FOR EACH ROW
EXECUTE FUNCTION trg_products_history_func();

-- ================================================================
-- Create Functions (equivalent to SQL Server Stored Procedures)
-- ================================================================

-- Function for Getting All Products
CREATE OR REPLACE FUNCTION sp_get_all_products()
RETURNS TABLE (
    product_id INT,
    name VARCHAR(100),
    description VARCHAR(500),
    price NUMERIC(18,2),
    stock_quantity INT,
    created_date TIMESTAMP,
    modified_date TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.product_id, p.name, p.description, p.price, p.stock_quantity, p.created_date, p.modified_date
    FROM products p
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- Function for Getting Product by ID
CREATE OR REPLACE FUNCTION sp_get_product_by_id(p_product_id INT)
RETURNS TABLE (
    product_id INT,
    name VARCHAR(100),
    description VARCHAR(500),
    price NUMERIC(18,2),
    stock_quantity INT,
    created_date TIMESTAMP,
    modified_date TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.product_id, p.name, p.description, p.price, p.stock_quantity, p.created_date, p.modified_date
    FROM products p
    WHERE p.product_id = p_product_id;
END;
$$ LANGUAGE plpgsql;

-- Function for Inserting Product
CREATE OR REPLACE FUNCTION sp_insert_product(
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18,2),
    p_stock_quantity INT
)
RETURNS INT AS $$
DECLARE
    v_product_id INT;
BEGIN
    INSERT INTO products (name, description, price, stock_quantity)
    VALUES (p_name, p_description, p_price, p_stock_quantity)
    RETURNING product_id INTO v_product_id;
    
    RETURN v_product_id;
END;
$$ LANGUAGE plpgsql;

-- Function for Updating Product
CREATE OR REPLACE FUNCTION sp_update_product(
    p_product_id INT,
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18,2),
    p_stock_quantity INT
)
RETURNS VOID AS $$
BEGIN
    UPDATE products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stock_quantity = p_stock_quantity,
        modified_date = CURRENT_TIMESTAMP
    WHERE product_id = p_product_id;
END;
$$ LANGUAGE plpgsql;

-- Function for Deleting Product
CREATE OR REPLACE FUNCTION sp_delete_product(p_product_id INT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM products
    WHERE product_id = p_product_id;
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- Verification Queries
-- ================================================================

-- Verify table creation
SELECT 'Tables created successfully' AS status;
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Verify data insertion
SELECT 'Data inserted successfully' AS status;
SELECT 'Categories' AS table_name, COUNT(*) AS row_count FROM categories
UNION ALL
SELECT 'Suppliers', COUNT(*) FROM suppliers
UNION ALL
SELECT 'Products', COUNT(*) FROM products
UNION ALL
SELECT 'ProductStats', COUNT(*) FROM product_stats;

-- Verify sample products
SELECT 'Sample products loaded' AS status;
SELECT product_id, name, price, stock_quantity FROM products LIMIT 5;

-- ================================================================
-- Setup Complete
-- ================================================================
-- The ProductManagement database is now ready for use with the
-- ADO.NET Core PostgreSQL application.
--
-- Default connection string:
-- Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres
--
-- IMPORTANT: Change the default password in production!
-- ================================================================
