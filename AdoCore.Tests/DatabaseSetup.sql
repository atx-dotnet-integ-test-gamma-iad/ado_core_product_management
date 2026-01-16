-- PostgreSQL Database Setup Script for AdoCore Integration Tests
-- This script creates the necessary database, schema, and tables for testing

-- Connect to PostgreSQL and create the test database
-- Run this as: psql -U postgres -f DatabaseSetup.sql

-- Drop database if exists (for clean setup)
DROP DATABASE IF EXISTS adocore_test;

-- Create the test database
CREATE DATABASE adocore_test;

-- Connect to the new database
\c adocore_test;

-- Create the schema
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;

-- Create the products table
CREATE TABLE productmanagement_dbo.products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(18, 2) NOT NULL,
    stockquantity INT NOT NULL,
    createddate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP
);

-- Create the producthistory table
CREATE TABLE productmanagement_dbo.producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INT NOT NULL,
    action VARCHAR(50) NOT NULL,
    oldprice DECIMAL(18, 2),
    newprice DECIMAL(18, 2),
    oldstock INT,
    newstock INT,
    actiondate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (productid) REFERENCES productmanagement_dbo.products(productid) ON DELETE CASCADE
);

-- Create the productstats table
CREATE TABLE productmanagement_dbo.productstats (
    statid INT PRIMARY KEY,
    totalproducts INT DEFAULT 0,
    averageprice DECIMAL(18, 2) DEFAULT 0,
    lastupdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Initialize productstats with a default record (statid = 1)
INSERT INTO productmanagement_dbo.productstats (statid, totalproducts, averageprice, lastupdated)
VALUES (1, 0, 0, CURRENT_TIMESTAMP);

-- Create indexes for better performance
CREATE INDEX idx_products_price ON productmanagement_dbo.products(price);
CREATE INDEX idx_products_stockquantity ON productmanagement_dbo.products(stockquantity);
CREATE INDEX idx_producthistory_productid ON productmanagement_dbo.producthistory(productid);
CREATE INDEX idx_producthistory_actiondate ON productmanagement_dbo.producthistory(actiondate);

-- Insert sample test data (optional, for manual testing)
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES 
    ('Sample Product 1', 'Description for product 1', 29.99, 100),
    ('Sample Product 2', 'Description for product 2', 49.99, 50),
    ('Sample Product 3', 'Description for product 3', 99.99, 25);

-- Update productstats to reflect sample data
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = 3,
    averageprice = (29.99 + 49.99 + 99.99) / 3,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- Grant permissions (adjust as needed for your environment)
GRANT ALL PRIVILEGES ON SCHEMA productmanagement_dbo TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA productmanagement_dbo TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA productmanagement_dbo TO postgres;

-- Display setup completion message
SELECT 'Database setup completed successfully!' AS status;
