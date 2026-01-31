-- ==================================================================================
-- MS SQL SERVER TABLE DEFINITIONS
-- ==================================================================================
-- Database: ProductManagement
-- Schema: dbo
-- Purpose: Table definitions for SQL equivalency validation
-- ==================================================================================

-- Products Table
CREATE TABLE Products (
    ProductId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    Price DECIMAL(18,2) NOT NULL,
    StockQuantity INT NOT NULL,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME
);

-- ProductHistory Table
CREATE TABLE ProductHistory (
    HistoryId INT IDENTITY(1,1) PRIMARY KEY,
    ProductId INT NOT NULL,
    Action NVARCHAR(50) NOT NULL,
    OldPrice DECIMAL(18,2),
    NewPrice DECIMAL(18,2),
    OldStock INT,
    NewStock INT,
    ActionDate DATETIME NOT NULL,
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
);

-- ProductStats Table
CREATE TABLE ProductStats (
    StatId INT PRIMARY KEY,
    TotalProducts INT NOT NULL DEFAULT 0,
    AveragePrice DECIMAL(18,2) NOT NULL DEFAULT 0,
    LastUpdated DATETIME NOT NULL DEFAULT GETDATE()
);
