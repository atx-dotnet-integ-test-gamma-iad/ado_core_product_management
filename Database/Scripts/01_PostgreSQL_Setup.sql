-- PostgreSQL Database Setup Script for ProductManagement
-- This script creates the database schema required for the AdoCore application
-- Run this script on your PostgreSQL instance before running the application

-- Create ProductManagement Database (run as superuser)
-- Note: You may need to run this separately: CREATE DATABASE productmanagement;
-- Then connect to the database before running the rest of this script

-- Create Products Table
CREATE TABLE IF NOT EXISTS products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    price DECIMAL(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP
);

-- Create ProductHistory Table for audit logging
CREATE TABLE IF NOT EXISTS producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(50) NOT NULL,
    oldprice DECIMAL(18, 2),
    newprice DECIMAL(18, 2),
    oldstock INTEGER,
    newstock INTEGER,
    actiondate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create ProductStats Table for aggregate statistics
CREATE TABLE IF NOT EXISTS productstats (
    statid SERIAL PRIMARY KEY,
    totalproducts INTEGER NOT NULL DEFAULT 0,
    averageprice DECIMAL(18, 2) NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_products_price ON products(price);
CREATE INDEX IF NOT EXISTS idx_products_stockquantity ON products(stockquantity);
CREATE INDEX IF NOT EXISTS idx_producthistory_productid ON producthistory(productid);
CREATE INDEX IF NOT EXISTS idx_producthistory_actiondate ON producthistory(actiondate);

-- Initialize ProductStats table with default record
INSERT INTO productstats (statid, totalproducts, averageprice, lastupdated)
VALUES (1, 0, 0, CURRENT_TIMESTAMP)
ON CONFLICT (statid) DO NOTHING;

-- Insert Sample Data
INSERT INTO products (name, description, price, stockquantity, createddate)
VALUES 
    ('Laptop', 'High-performance laptop', 999.99, 10, CURRENT_TIMESTAMP),
    ('Mouse', 'Wireless gaming mouse', 49.99, 20, CURRENT_TIMESTAMP),
    ('Keyboard', 'Mechanical keyboard', 129.99, 15, CURRENT_TIMESTAMP),
    ('Monitor', '27-inch 4K display', 399.99, 8, CURRENT_TIMESTAMP),
    ('Headphones', 'Noise-canceling headphones', 249.99, 12, CURRENT_TIMESTAMP)
ON CONFLICT (productid) DO NOTHING;

-- Update ProductStats with initial data
UPDATE productstats
SET 
    totalproducts = (SELECT COUNT(*) FROM products),
    averageprice = (SELECT AVG(price) FROM products),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- Grant permissions (adjust username as needed)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_username;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO your_username;

-- Display confirmation
SELECT 'Database setup completed successfully!' AS status;
SELECT COUNT(*) AS total_products FROM products;
SELECT * FROM productstats WHERE statid = 1;
