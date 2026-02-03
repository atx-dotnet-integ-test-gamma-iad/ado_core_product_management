-- ================================================================
-- PostgreSQL Database Initialization Script
-- Converted from SQL Server Initial Setup
-- Database: ProductManagement (or use existing postgres database)
-- ================================================================

-- Create Products Table
CREATE TABLE IF NOT EXISTS Products (
    ProductId SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(500),
    Price DECIMAL(18, 2) NOT NULL,
    StockQuantity INTEGER NOT NULL,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ModifiedDate TIMESTAMP
);

-- Create ProductHistory Table (for audit logging)
CREATE TABLE IF NOT EXISTS ProductHistory (
    HistoryId SERIAL PRIMARY KEY,
    ProductId INTEGER NOT NULL,
    Action VARCHAR(20) NOT NULL,
    OldPrice DECIMAL(18, 2),
    NewPrice DECIMAL(18, 2),
    OldStock INTEGER,
    NewStock INTEGER,
    ActionDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create ProductStats Table (for statistics tracking)
CREATE TABLE IF NOT EXISTS ProductStats (
    StatId INTEGER PRIMARY KEY DEFAULT 1,
    TotalProducts INTEGER DEFAULT 0,
    AveragePrice DECIMAL(18, 2) DEFAULT 0,
    LastUpdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Initialize ProductStats with default row
INSERT INTO ProductStats (StatId, TotalProducts, AveragePrice, LastUpdated)
VALUES (1, 0, 0, CURRENT_TIMESTAMP)
ON CONFLICT (StatId) DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_products_price ON Products(Price);
CREATE INDEX IF NOT EXISTS idx_products_stock ON Products(StockQuantity);
CREATE INDEX IF NOT EXISTS idx_products_name ON Products(Name);
CREATE INDEX IF NOT EXISTS idx_producthistory_productid ON ProductHistory(ProductId);
CREATE INDEX IF NOT EXISTS idx_producthistory_actiondate ON ProductHistory(ActionDate);

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

-- Update ProductStats based on initial data
UPDATE ProductStats
SET 
    TotalProducts = (SELECT COUNT(*) FROM Products),
    AveragePrice = (SELECT COALESCE(AVG(Price), 0) FROM Products),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- Display confirmation
DO $$
BEGIN
    RAISE NOTICE 'PostgreSQL database initialization completed successfully.';
    RAISE NOTICE 'Products table created with % rows', (SELECT COUNT(*) FROM Products);
    RAISE NOTICE 'ProductHistory table created';
    RAISE NOTICE 'ProductStats table initialized';
END $$;
