-- ================================================================================
-- TABLE SCHEMAS FOR SQL EQUIVALENCY VALIDATION
-- Microsoft SQL Server and PostgreSQL Table Definitions
-- ================================================================================

-- ================================================================================
-- MICROSOFT SQL SERVER TABLE SCHEMAS
-- ================================================================================

-- Products Table (SQL Server)
CREATE TABLE Products (
    ProductId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX),
    Price DECIMAL(18,2) NOT NULL,
    StockQuantity INT NOT NULL DEFAULT 0,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME2
);

-- ProductHistory Table (SQL Server)
CREATE TABLE ProductHistory (
    HistoryId INT IDENTITY(1,1) PRIMARY KEY,
    ProductId INT NOT NULL,
    Action NVARCHAR(50) NOT NULL,
    OldPrice DECIMAL(18,2),
    NewPrice DECIMAL(18,2),
    OldStock INT,
    NewStock INT,
    ActionDate DATETIME2 NOT NULL
);

-- ProductStats Table (SQL Server)
CREATE TABLE ProductStats (
    StatId INT PRIMARY KEY,
    TotalProducts INT NOT NULL DEFAULT 0,
    AveragePrice DECIMAL(18,2) NOT NULL DEFAULT 0,
    LastUpdated DATETIME2 NOT NULL DEFAULT GETDATE()
);

-- ================================================================================
-- POSTGRESQL TABLE SCHEMAS
-- ================================================================================

-- Products Table (PostgreSQL)
CREATE TABLE Products (
    ProductId SERIAL PRIMARY KEY,
    Name VARCHAR(200) NOT NULL,
    Description TEXT,
    Price NUMERIC(18,2) NOT NULL,
    StockQuantity INTEGER NOT NULL DEFAULT 0,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ModifiedDate TIMESTAMP
);

-- ProductHistory Table (PostgreSQL)
CREATE TABLE ProductHistory (
    HistoryId SERIAL PRIMARY KEY,
    ProductId INTEGER NOT NULL,
    Action VARCHAR(50) NOT NULL,
    OldPrice NUMERIC(18,2),
    NewPrice NUMERIC(18,2),
    OldStock INTEGER,
    NewStock INTEGER,
    ActionDate TIMESTAMP NOT NULL
);

-- ProductStats Table (PostgreSQL)
CREATE TABLE ProductStats (
    StatId INTEGER PRIMARY KEY,
    TotalProducts INTEGER NOT NULL DEFAULT 0,
    AveragePrice NUMERIC(18,2) NOT NULL DEFAULT 0,
    LastUpdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ================================================================================
-- SAMPLE DATA FOR VALIDATION
-- ================================================================================

-- Sample Products Data (SQL Server syntax)
INSERT INTO Products (ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate)
VALUES 
(1, 'Product A', 'Description A', 100.00, 50, '2024-01-01', '2024-01-15'),
(2, 'Product B', 'Description B', 150.00, 30, '2024-01-02', '2024-01-16'),
(3, 'Product C', 'Description C', 200.00, 20, '2024-01-03', '2024-01-17'),
(4, 'Product D', 'Description D', 75.00, 100, '2024-01-04', '2024-01-18'),
(5, 'Product E', 'Description E', 250.00, 10, '2024-01-05', '2024-01-19');

-- Sample ProductStats Data
INSERT INTO ProductStats (StatId, TotalProducts, AveragePrice, LastUpdated)
VALUES (1, 5, 155.00, '2024-01-19');

-- ================================================================================
-- NOTES FOR EQUIVALENCY VALIDATION
-- ================================================================================
-- Type Mappings:
-- - SQL Server INT IDENTITY → PostgreSQL SERIAL
-- - SQL Server NVARCHAR → PostgreSQL VARCHAR
-- - SQL Server NVARCHAR(MAX) → PostgreSQL TEXT
-- - SQL Server DECIMAL(18,2) → PostgreSQL NUMERIC(18,2)
-- - SQL Server INT → PostgreSQL INTEGER
-- - SQL Server DATETIME2 → PostgreSQL TIMESTAMP
-- - SQL Server GETDATE() → PostgreSQL CURRENT_TIMESTAMP
-- 
-- Window Functions: Fully compatible between SQL Server and PostgreSQL
-- CTE (WITH): Fully compatible between SQL Server and PostgreSQL
-- ================================================================================
