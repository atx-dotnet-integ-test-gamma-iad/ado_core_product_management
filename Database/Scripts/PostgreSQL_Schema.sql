-- ============================================================================
-- PostgreSQL Database Schema for ProductManagement
-- Converted from SQL Server Schema
-- Date: 2026-01-20
-- ============================================================================

-- Products Table
CREATE TABLE IF NOT EXISTS Products (
    ProductId SERIAL PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Description TEXT,
    Price DECIMAL(18,2) NOT NULL,
    StockQuantity INTEGER NOT NULL,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ModifiedDate TIMESTAMP
);

-- ProductHistory Table
CREATE TABLE IF NOT EXISTS ProductHistory (
    HistoryId SERIAL PRIMARY KEY,
    ProductId INTEGER NOT NULL,
    Action VARCHAR(50) NOT NULL,
    OldPrice DECIMAL(18,2),
    NewPrice DECIMAL(18,2),
    OldStock INTEGER,
    NewStock INTEGER,
    ActionDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId) ON DELETE CASCADE
);

-- ProductStats Table
CREATE TABLE IF NOT EXISTS ProductStats (
    StatId INTEGER PRIMARY KEY,
    TotalProducts INTEGER NOT NULL DEFAULT 0,
    AveragePrice DECIMAL(18,2) NOT NULL DEFAULT 0,
    LastUpdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_products_price ON Products(Price);
CREATE INDEX IF NOT EXISTS idx_products_stock ON Products(StockQuantity);
CREATE INDEX IF NOT EXISTS idx_producthistory_productid ON ProductHistory(ProductId);
CREATE INDEX IF NOT EXISTS idx_producthistory_actiondate ON ProductHistory(ActionDate);

-- Initialize ProductStats table
INSERT INTO ProductStats (StatId, TotalProducts, AveragePrice, LastUpdated)
VALUES (1, 0, 0, CURRENT_TIMESTAMP)
ON CONFLICT (StatId) DO NOTHING;
