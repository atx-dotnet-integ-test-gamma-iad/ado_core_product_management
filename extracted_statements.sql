-- =====================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- This file contains all SQL statements extracted from the codebase
-- with source location, line numbers, and context information
-- =====================================================================

-- =====================================================================
-- SOURCE: DataAccess/ProductRepository.cs
-- =====================================================================

-- ---------------------------------------------------------------------
-- STATEMENT 1: GetAllProductsAsync
-- Location: DataAccess/ProductRepository.cs, Lines 38-63
-- Type: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER)
-- Context: Retrieves all products with price statistics and categorization
-- ---------------------------------------------------------------------
WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name;

-- ---------------------------------------------------------------------
-- STATEMENT 2: GetProductByIdAsync
-- Location: DataAccess/ProductRepository.cs, Lines 80-106
-- Type: SELECT with CTE, Window Function (LAG OVER)
-- Context: Retrieves single product with historical price comparison
-- Parameters: @ProductId
-- ---------------------------------------------------------------------
WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = @ProductId
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    ph.PreviousPrice,
    ph.PreviousStock,
    CASE 
        WHEN ph.PreviousPrice IS NOT NULL THEN 
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;

-- ---------------------------------------------------------------------
-- STATEMENT 3: InsertProductAsync
-- Location: DataAccess/ProductRepository.cs, Lines 123-143
-- Type: Multi-statement transaction with BEGIN/COMMIT, SCOPE_IDENTITY()
-- Context: Inserts new product, logs to history, updates statistics
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- SQL Server Functions: SCOPE_IDENTITY(), GETDATE()
-- ---------------------------------------------------------------------
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    -- Insert the new product
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;

-- ---------------------------------------------------------------------
-- STATEMENT 4: UpdateProductAsync
-- Location: DataAccess/ProductRepository.cs, Lines 157-181
-- Type: Multi-statement transaction with variable declarations
-- Context: Updates product, logs changes to history, updates statistics
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- SQL Server Functions: GETDATE()
-- ---------------------------------------------------------------------
BEGIN TRANSACTION;
    -- Store old values for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Update the product
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

-- ---------------------------------------------------------------------
-- STATEMENT 5: DeleteProductAsync
-- Location: DataAccess/ProductRepository.cs, Lines 198-227
-- Type: Multi-statement transaction with cascading operations
-- Context: Deletes product, logs deletion, updates statistics
-- Parameters: @ProductId
-- SQL Server Functions: GETDATE()
-- ---------------------------------------------------------------------
BEGIN TRANSACTION;
    -- Store product info for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

-- ---------------------------------------------------------------------
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Location: DataAccess/ProductRepository.cs, Lines 237-260
-- Type: SELECT with CTE, Window Functions (RANK, PERCENT_RANK)
-- Context: Retrieves products in price range with ranking and segmentation
-- Parameters: @MinPrice, @MaxPrice
-- ---------------------------------------------------------------------
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as PriceSegment
FROM RankedProducts rp
ORDER BY rp.PriceRank;

-- ---------------------------------------------------------------------
-- STATEMENT 7: GetLowStockProductsAsync
-- Location: DataAccess/ProductRepository.cs, Lines 274-298
-- Type: SELECT with CTE, Aggregate Window Functions
-- Context: Retrieves low stock products with stock analysis
-- Parameters: @Threshold
-- ---------------------------------------------------------------------
WITH StockAnalysis AS (
    SELECT 
        p.*,
        AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock,
        MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT 
    sa.*,
    CASE 
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;

-- =====================================================================
-- SOURCE: Database/Scripts/01_InitialSetup.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- STATEMENT 8: Create Database
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 2-5
-- Type: DDL - Database Creation
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ProductManagement')
BEGIN
    CREATE DATABASE ProductManagement;
END
GO

-- ---------------------------------------------------------------------
-- STATEMENT 9: Use Database
-- Location: Database/Scripts/01_InitialSetup.sql, Line 8
-- Type: DDL - Database Selection
-- ---------------------------------------------------------------------
USE ProductManagement;
GO

-- ---------------------------------------------------------------------
-- STATEMENT 10: Drop Trigger trg_Products_History
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 11-15
-- Type: DDL - Drop Trigger
-- ---------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[trg_Products_History]') AND type = 'TR')
BEGIN
    DROP TRIGGER [dbo].[trg_Products_History]
END
GO

-- ---------------------------------------------------------------------
-- STATEMENT 11: Drop Table ProductHistory
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 17-21
-- Type: DDL - Drop Table
-- ---------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProductHistory]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[ProductHistory]
END
GO

-- ---------------------------------------------------------------------
-- STATEMENT 12: Drop Table Products
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 23-27
-- Type: DDL - Drop Table
-- ---------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Products]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[Products]
END
GO

-- ---------------------------------------------------------------------
-- STATEMENT 13: Drop Table Categories
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 29-33
-- Type: DDL - Drop Table
-- ---------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Categories]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[Categories]
END
GO

-- ---------------------------------------------------------------------
-- STATEMENT 14: Drop Table Suppliers
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 35-39
-- Type: DDL - Drop Table
-- ---------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Suppliers]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[Suppliers]
END
GO

-- ---------------------------------------------------------------------
-- STATEMENT 15: Drop Table ProductStats
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 41-45
-- Type: DDL - Drop Table
-- ---------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProductStats]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[ProductStats]
END
GO

-- ---------------------------------------------------------------------
-- STATEMENT 16: Create Table Categories
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 47-54
-- Type: DDL - Create Table
-- SQL Server Functions: GETDATE()
-- ---------------------------------------------------------------------
CREATE TABLE [dbo].[Categories](
    [CategoryId] [int] IDENTITY(1,1) PRIMARY KEY,
    [Name] [nvarchar](50) NOT NULL,
    [Description] [nvarchar](200) NULL,
    [ParentCategoryId] [int] NULL,
    [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE()
)
GO

-- ---------------------------------------------------------------------
-- STATEMENT 17: Add Foreign Key to Categories
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 56-60
-- Type: DDL - Alter Table - Add Foreign Key
-- ---------------------------------------------------------------------
ALTER TABLE [dbo].[Categories]
ADD CONSTRAINT [FK_Categories_Categories] 
FOREIGN KEY ([ParentCategoryId]) REFERENCES [dbo].[Categories] ([CategoryId])
GO

-- ---------------------------------------------------------------------
-- STATEMENT 18: Create Table Suppliers
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 62-73
-- Type: DDL - Create Table
-- SQL Server Functions: GETDATE()
-- ---------------------------------------------------------------------
CREATE TABLE [dbo].[Suppliers](
    [SupplierId] [int] IDENTITY(1,1) PRIMARY KEY,
    [Name] [nvarchar](100) NOT NULL,
    [ContactName] [nvarchar](100) NULL,
    [Email] [nvarchar](100) NULL,
    [Phone] [nvarchar](20) NULL,
    [Address] [nvarchar](200) NULL,
    [Country] [nvarchar](50) NULL,
    [IsActive] [bit] NOT NULL DEFAULT 1,
    [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE()
)
GO

-- ---------------------------------------------------------------------
-- STATEMENT 19: Create Table Products
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 75-93
-- Type: DDL - Create Table with Foreign Keys
-- SQL Server Functions: GETDATE()
-- ---------------------------------------------------------------------
CREATE TABLE [dbo].[Products](
    [ProductId] [int] IDENTITY(1,1) PRIMARY KEY,
    [Name] [nvarchar](100) NOT NULL,
    [Description] [nvarchar](500) NULL,
    [Price] [decimal](18, 2) NOT NULL,
    [StockQuantity] [int] NOT NULL,
    [CategoryId] [int] NULL,
    [SupplierId] [int] NULL,
    [SKU] [nvarchar](50) NULL,
    [Weight] [decimal](10, 2) NULL,
    [Dimensions] [nvarchar](50) NULL,
    [IsDiscontinued] [bit] NOT NULL DEFAULT 0,
    [ReorderLevel] [int] NOT NULL DEFAULT 10,
    [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
    [ModifiedDate] [datetime] NULL,
    CONSTRAINT [FK_Products_Categories] FOREIGN KEY ([CategoryId]) 
        REFERENCES [dbo].[Categories] ([CategoryId]),
    CONSTRAINT [FK_Products_Suppliers] FOREIGN KEY ([SupplierId]) 
        REFERENCES [dbo].[Suppliers] ([SupplierId])
)
GO

-- ---------------------------------------------------------------------
-- STATEMENT 20: Create Table ProductHistory
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 95-107
-- Type: DDL - Create Table with Foreign Key
-- SQL Server Functions: GETDATE()
-- ---------------------------------------------------------------------
CREATE TABLE [dbo].[ProductHistory](
    [HistoryId] [int] IDENTITY(1,1) PRIMARY KEY,
    [ProductId] [int] NOT NULL,
    [Action] [varchar](10) NOT NULL,
    [OldPrice] [decimal](18, 2) NULL,
    [NewPrice] [decimal](18, 2) NULL,
    [OldStock] [int] NULL,
    [NewStock] [int] NULL,
    [ActionDate] [datetime] NOT NULL DEFAULT GETDATE(),
    [ModifiedBy] [nvarchar](100) NULL,
    CONSTRAINT [FK_ProductHistory_Products] FOREIGN KEY ([ProductId]) 
        REFERENCES [dbo].[Products] ([ProductId])
)
GO

-- ---------------------------------------------------------------------
-- STATEMENT 21: Create Table ProductStats
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 109-118
-- Type: DDL - Create Table
-- SQL Server Functions: GETDATE()
-- ---------------------------------------------------------------------
CREATE TABLE [dbo].[ProductStats](
    [StatId] [int] PRIMARY KEY DEFAULT 1,
    [TotalProducts] [int] NOT NULL DEFAULT 0,
    [AveragePrice] [decimal](18, 2) NOT NULL DEFAULT 0,
    [TotalStockValue] [decimal](18, 2) NOT NULL DEFAULT 0,
    [LowStockCount] [int] NOT NULL DEFAULT 0,
    [DiscontinuedCount] [int] NOT NULL DEFAULT 0,
    [LastUpdated] [datetime] NOT NULL DEFAULT GETDATE()
)
GO

-- ---------------------------------------------------------------------
-- STATEMENT 22: Create Index IX_Products_CategoryId
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 120-122
-- Type: DDL - Create Index
-- ---------------------------------------------------------------------
CREATE INDEX [IX_Products_CategoryId] ON [dbo].[Products] ([CategoryId])
GO

-- ---------------------------------------------------------------------
-- STATEMENT 23: Create Index IX_Products_SupplierId
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 124-126
-- Type: DDL - Create Index
-- ---------------------------------------------------------------------
CREATE INDEX [IX_Products_SupplierId] ON [dbo].[Products] ([SupplierId])
GO

-- ---------------------------------------------------------------------
-- STATEMENT 24: Create Unique Index IX_Products_SKU
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 128-130
-- Type: DDL - Create Unique Index
-- ---------------------------------------------------------------------
CREATE UNIQUE INDEX [IX_Products_SKU] ON [dbo].[Products] ([SKU])
GO

-- ---------------------------------------------------------------------
-- STATEMENT 25: Create Index IX_ProductHistory_ProductId
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 132-134
-- Type: DDL - Create Index
-- ---------------------------------------------------------------------
CREATE INDEX [IX_ProductHistory_ProductId] ON [dbo].[ProductHistory] ([ProductId])
GO

-- ---------------------------------------------------------------------
-- STATEMENT 26: Create Index IX_ProductHistory_ActionDate
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 136-138
-- Type: DDL - Create Index
-- ---------------------------------------------------------------------
CREATE INDEX [IX_ProductHistory_ActionDate] ON [dbo].[ProductHistory] ([ActionDate])
GO

-- ---------------------------------------------------------------------
-- STATEMENT 27: Insert Sample Categories
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 140-162
-- Type: DML - Insert
-- ---------------------------------------------------------------------
INSERT INTO Categories (Name, Description, ParentCategoryId)
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
    ('Switches', 'Network switches', 8)
GO

-- ---------------------------------------------------------------------
-- STATEMENT 28: Insert Sample Suppliers
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 164-174
-- Type: DML - Insert
-- ---------------------------------------------------------------------
INSERT INTO Suppliers (Name, ContactName, Email, Phone, Address, Country)
VALUES 
    ('TechGlobal Inc.', 'John Smith', 'john@techglobal.com', '+1-555-0101', '123 Tech Street, Silicon Valley, CA', 'USA'),
    ('ElectroParts Ltd.', 'Sarah Johnson', 'sarah@electroparts.com', '+44-20-7123-4567', '45 Circuit Road, London', 'UK'),
    ('Digital Solutions', 'Michael Chen', 'michael@digitalsolutions.com', '+86-10-1234-5678', '789 Digital Avenue, Beijing', 'China'),
    ('Gaming Gear Co.', 'David Wilson', 'david@gaminggear.com', '+1-555-0202', '456 Game Street, Seattle, WA', 'USA'),
    ('AudioTech Systems', 'Emma Brown', 'emma@audiotech.com', '+1-555-0303', '789 Sound Road, Nashville, TN', 'USA'),
    ('Storage Solutions', 'James Lee', 'james@storagesolutions.com', '+1-555-0404', '321 Data Drive, Austin, TX', 'USA'),
    ('Office Supplies Pro', 'Lisa Anderson', 'lisa@officesupplies.com', '+1-555-0505', '654 Office Park, Chicago, IL', 'USA'),
    ('Network Experts', 'Robert Taylor', 'robert@networkexperts.com', '+1-555-0606', '987 Network Way, Boston, MA', 'USA')
GO

-- ---------------------------------------------------------------------
-- STATEMENT 29: Insert Sample Products
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 176-209
-- Type: DML - Insert
-- ---------------------------------------------------------------------
INSERT INTO Products (Name, Description, Price, StockQuantity, CategoryId, SupplierId, SKU, Weight, Dimensions, ReorderLevel)
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
    ('Gigabit Switch', '24-port gigabit network switch', 299.99, 10, 20, 8, 'NET-GS-001', 3.0, '17" x 10" x 1.5"', 4)
GO

-- ---------------------------------------------------------------------
-- STATEMENT 30: Insert Initial ProductStats
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 211-214
-- Type: DML - Insert
-- SQL Server Functions: GETDATE()
-- ---------------------------------------------------------------------
INSERT INTO ProductStats (StatId, TotalProducts, AveragePrice, TotalStockValue, LowStockCount, DiscontinuedCount, LastUpdated)
VALUES (1, 0, 0, 0, 0, 0, GETDATE())
GO

-- ---------------------------------------------------------------------
-- STATEMENT 31: Update Initial ProductStats
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 216-224
-- Type: DML - Update with Aggregate Subqueries
-- SQL Server Functions: GETDATE()
-- ---------------------------------------------------------------------
UPDATE ProductStats
SET 
    TotalProducts = (SELECT COUNT(*) FROM Products),
    AveragePrice = (SELECT AVG(Price) FROM Products),
    TotalStockValue = (SELECT SUM(Price * StockQuantity) FROM Products),
    LowStockCount = (SELECT COUNT(*) FROM Products WHERE StockQuantity <= ReorderLevel),
    DiscontinuedCount = (SELECT COUNT(*) FROM Products WHERE IsDiscontinued = 1),
    LastUpdated = GETDATE()
WHERE StatId = 1
GO

-- ---------------------------------------------------------------------
-- STATEMENT 32: Create Trigger trg_Products_History
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 226-267
-- Type: DDL - Create Trigger (INSERT, UPDATE, DELETE)
-- SQL Server Functions: SYSTEM_USER
-- ---------------------------------------------------------------------
CREATE TRIGGER [dbo].[trg_Products_History]
ON [dbo].[Products]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Handle INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO ProductHistory (ProductId, Action, NewPrice, NewStock, ModifiedBy)
        SELECT 
            ProductId,
            'INSERT',
            Price,
            StockQuantity,
            SYSTEM_USER
        FROM inserted;
    END
    
    -- Handle UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ModifiedBy)
        SELECT 
            i.ProductId,
            'UPDATE',
            d.Price,
            i.Price,
            d.StockQuantity,
            i.StockQuantity,
            SYSTEM_USER
        FROM inserted i
        INNER JOIN deleted d ON i.ProductId = d.ProductId
        WHERE i.Price <> d.Price OR i.StockQuantity <> d.StockQuantity;
    END
    
    -- Handle DELETE
    IF NOT EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, OldStock, ModifiedBy)
        SELECT 
            ProductId,
            'DELETE',
            Price,
            StockQuantity,
            SYSTEM_USER
        FROM deleted;
    END
END
GO

-- ---------------------------------------------------------------------
-- STATEMENT 33: Create Stored Procedure sp_GetAllProducts
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 269-277
-- Type: DDL - Create Stored Procedure
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_GetAllProducts]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    ORDER BY Name;
END
GO

-- ---------------------------------------------------------------------
-- STATEMENT 34: Create Stored Procedure sp_GetProductById
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 279-289
-- Type: DDL - Create Stored Procedure
-- Parameters: @ProductId
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_GetProductById]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    WHERE ProductId = @ProductId;
END
GO

-- ---------------------------------------------------------------------
-- STATEMENT 35: Create Stored Procedure sp_InsertProduct
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 291-303
-- Type: DDL - Create Stored Procedure
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- SQL Server Functions: SCOPE_IDENTITY()
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_InsertProduct]
    @Name NVARCHAR(100),
    @Description NVARCHAR(500),
    @Price DECIMAL(18,2),
    @StockQuantity INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SELECT SCOPE_IDENTITY() AS ProductId;
END
GO

-- ---------------------------------------------------------------------
-- STATEMENT 36: Create Stored Procedure sp_UpdateProduct
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 305-320
-- Type: DDL - Create Stored Procedure
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- SQL Server Functions: GETDATE()
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_UpdateProduct]
    @ProductId INT,
    @Name NVARCHAR(100),
    @Description NVARCHAR(500),
    @Price DECIMAL(18,2),
    @StockQuantity INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Products
    SET Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
END
GO

-- ---------------------------------------------------------------------
-- STATEMENT 37: Create Stored Procedure sp_DeleteProduct
-- Location: Database/Scripts/01_InitialSetup.sql, Lines 322-332
-- Type: DDL - Create Stored Procedure
-- Parameters: @ProductId
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_DeleteProduct]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Products
    WHERE ProductId = @ProductId;
END
GO

-- =====================================================================
-- EXTRACTION SUMMARY
-- =====================================================================
-- Total Statements Extracted: 37
-- Source Files: 2
--   - DataAccess/ProductRepository.cs: 7 statements (CRUD operations)
--   - Database/Scripts/01_InitialSetup.sql: 30 statements (DDL/DML)
-- 
-- Statement Types:
--   - SELECT with CTEs and Window Functions: 4
--   - Multi-statement Transactions: 3
--   - DDL (CREATE/DROP/ALTER): 26
--   - DML (INSERT/UPDATE): 4
-- 
-- SQL Server Specific Features Identified:
--   - SCOPE_IDENTITY(): 3 occurrences
--   - GETDATE(): 14 occurrences
--   - IDENTITY columns: 7 occurrences
--   - Window Functions (AVG, COUNT, LAG, RANK, PERCENT_RANK): 7 occurrences
--   - sys.databases, sys.objects: 6 occurrences
--   - SYSTEM_USER: 3 occurrences
--   - [dbo] schema notation: Extensive use
--   - NVARCHAR data types: Extensive use
-- =====================================================================
