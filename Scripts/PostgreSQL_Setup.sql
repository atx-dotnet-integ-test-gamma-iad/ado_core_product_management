-- PostgreSQL Database Setup Script
-- This script creates the database and tables required for the migrated ADO.NET application

-- Create ProductManagement Database (run this as postgres superuser)
-- Note: You may need to run "CREATE DATABASE ProductManagement;" separately if not connected as superuser

-- Connect to ProductManagement database before running the rest of this script
-- \c ProductManagement

-- Create Products Table
CREATE TABLE IF NOT EXISTS Products (
    ProductId SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(500),
    Price NUMERIC(18, 2) NOT NULL,
    StockQuantity INTEGER NOT NULL,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ModifiedDate TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_products_name ON Products(Name);
CREATE INDEX IF NOT EXISTS idx_products_price ON Products(Price);
CREATE INDEX IF NOT EXISTS idx_products_stock ON Products(StockQuantity);

-- Insert Sample Data
INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
SELECT 'Laptop', 'High-performance laptop', 999.99, 10, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE Name = 'Laptop');

INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
SELECT 'Mouse', 'Wireless gaming mouse', 49.99, 20, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE Name = 'Mouse');

INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
SELECT 'Keyboard', 'Mechanical keyboard', 129.99, 15, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE Name = 'Keyboard');

INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
SELECT 'Monitor', '27-inch 4K monitor', 399.99, 8, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE Name = 'Monitor');

INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
SELECT 'Webcam', 'HD webcam with microphone', 79.99, 25, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE Name = 'Webcam');

INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
SELECT 'Headset', 'Noise-cancelling headset', 149.99, 12, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE Name = 'Headset');

INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
SELECT 'USB Cable', 'USB-C to USB-A cable', 12.99, 50, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE Name = 'USB Cable');

INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
SELECT 'Docking Station', 'Multi-port docking station', 199.99, 5, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE Name = 'Docking Station');

-- Verify the setup
SELECT 'Products table created successfully' AS status;
SELECT COUNT(*) AS total_products FROM Products;
SELECT * FROM Products ORDER BY Name;
