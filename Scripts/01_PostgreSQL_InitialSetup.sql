-- ============================================================================
-- PostgreSQL Database Setup Script for ProductManagement
-- Migration from SQL Server to PostgreSQL
-- ============================================================================

-- Create Products Table
CREATE TABLE IF NOT EXISTS Products (
    ProductId SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(500) NULL,
    Price DECIMAL(18, 2) NOT NULL,
    StockQuantity INTEGER NOT NULL,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ModifiedDate TIMESTAMP NULL
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_products_name ON Products(Name);
CREATE INDEX IF NOT EXISTS idx_products_price ON Products(Price);
CREATE INDEX IF NOT EXISTS idx_products_stock ON Products(StockQuantity);

-- Insert Sample Data (only if table is empty)
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
SELECT 'Headset', 'Noise-cancelling headset', 89.99, 25, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE Name = 'Headset');

INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
SELECT 'USB Cable', 'USB-C to USB-A cable', 12.99, 50, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE Name = 'USB Cable');

INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
SELECT 'Webcam', '1080p HD webcam', 79.99, 12, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE Name = 'Webcam');

INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
SELECT 'Desk Lamp', 'LED desk lamp with USB', 34.99, 18, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE Name = 'Desk Lamp');

INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
SELECT 'External SSD', '1TB portable SSD', 149.99, 5, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE Name = 'External SSD');

INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
SELECT 'Docking Station', 'USB-C docking station', 199.99, 3, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE Name = 'Docking Station');

-- Verify data insertion
SELECT COUNT(*) as TotalProducts FROM Products;
SELECT * FROM Products ORDER BY ProductId;
