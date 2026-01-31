-- ==================================================================================
-- POSTGRESQL TABLE DEFINITIONS
-- ==================================================================================
-- Database: productmanagement
-- Schema: public
-- Purpose: Table definitions for SQL equivalency validation
-- ==================================================================================

-- Products Table
CREATE TABLE Products (
    ProductId SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(500),
    Price NUMERIC(18,2) NOT NULL,
    StockQuantity INTEGER NOT NULL,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ModifiedDate TIMESTAMP
);

-- ProductHistory Table
CREATE TABLE ProductHistory (
    HistoryId SERIAL PRIMARY KEY,
    ProductId INTEGER NOT NULL,
    Action VARCHAR(50) NOT NULL,
    OldPrice NUMERIC(18,2),
    NewPrice NUMERIC(18,2),
    OldStock INTEGER,
    NewStock INTEGER,
    ActionDate TIMESTAMP NOT NULL,
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
);

-- ProductStats Table
CREATE TABLE ProductStats (
    StatId INTEGER PRIMARY KEY,
    TotalProducts INTEGER NOT NULL DEFAULT 0,
    AveragePrice NUMERIC(18,2) NOT NULL DEFAULT 0,
    LastUpdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
