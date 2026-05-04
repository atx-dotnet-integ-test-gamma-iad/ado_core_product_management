-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: AdoCore .NET Application - MS SQL Server to PostgreSQL Migration
-- ============================================================================
-- This file catalogs ALL SQL statements found in the application codebase.
-- Each statement includes: source file, method, variable name, line location,
-- and the reconstructed MS SQL Server version of the statement.
-- ============================================================================

-- ============================================================================
-- SOURCE FILE: DataAccess/ProductRepository.cs
-- ============================================================================

-- --------------------------------------------------------------------------
-- Statement 1: GetAllProductsAsync - CTE with window functions
-- Method: GetAllProductsAsync()
-- Variable: sql (const string)
-- Original MS SQL Server version (reconstructed from current PostgreSQL-like code):
-- --------------------------------------------------------------------------
-- STATEMENT_ID: REPO_01
-- SOURCE: DataAccess/ProductRepository.cs
-- METHOD: GetAllProductsAsync
-- VARIABLE: sql
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

-- --------------------------------------------------------------------------
-- Statement 2: GetProductByIdAsync - CTE with LAG window function
-- Method: GetProductByIdAsync(int productId)
-- Variable: sql (const string)
-- Original MS SQL Server version:
-- --------------------------------------------------------------------------
-- STATEMENT_ID: REPO_02
-- SOURCE: DataAccess/ProductRepository.cs
-- METHOD: GetProductByIdAsync
-- VARIABLE: sql
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

-- --------------------------------------------------------------------------
-- Statement 3: InsertProductAsync - INSERT with SCOPE_IDENTITY
-- Method: InsertProductAsync(Product product)
-- Variable: insertProductSql (const string)
-- Original MS SQL Server version:
-- --------------------------------------------------------------------------
-- STATEMENT_ID: REPO_03
-- SOURCE: DataAccess/ProductRepository.cs
-- METHOD: InsertProductAsync
-- VARIABLE: insertProductSql
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity);
SELECT SCOPE_IDENTITY() AS ProductId;

-- --------------------------------------------------------------------------
-- Statement 4: InsertProductAsync - INSERT into ProductHistory (INSERT action)
-- Method: InsertProductAsync(Product product)
-- Variable: insertHistorySql (const string)
-- Original MS SQL Server version:
-- --------------------------------------------------------------------------
-- STATEMENT_ID: REPO_04
-- SOURCE: DataAccess/ProductRepository.cs
-- METHOD: InsertProductAsync
-- VARIABLE: insertHistorySql
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());

-- --------------------------------------------------------------------------
-- Statement 5: InsertProductAsync - UPDATE ProductStats
-- Method: InsertProductAsync(Product product)
-- Variable: updateStatsSql (const string)
-- Original MS SQL Server version:
-- --------------------------------------------------------------------------
-- STATEMENT_ID: REPO_05
-- SOURCE: DataAccess/ProductRepository.cs
-- METHOD: InsertProductAsync
-- VARIABLE: updateStatsSql
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = GETDATE()
WHERE StatId = 1;

-- --------------------------------------------------------------------------
-- Statement 6: UpdateProductAsync - SELECT old values
-- Method: UpdateProductAsync(Product product)
-- Variable: selectOldValuesSql (const string)
-- Original MS SQL Server version:
-- --------------------------------------------------------------------------
-- STATEMENT_ID: REPO_06
-- SOURCE: DataAccess/ProductRepository.cs
-- METHOD: UpdateProductAsync
-- VARIABLE: selectOldValuesSql
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- --------------------------------------------------------------------------
-- Statement 7: UpdateProductAsync - UPDATE products
-- Method: UpdateProductAsync(Product product)
-- Variable: updateProductSql (const string)
-- Original MS SQL Server version:
-- --------------------------------------------------------------------------
-- STATEMENT_ID: REPO_07
-- SOURCE: DataAccess/ProductRepository.cs
-- METHOD: UpdateProductAsync
-- VARIABLE: updateProductSql
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = GETDATE()
WHERE ProductId = @ProductId;

-- --------------------------------------------------------------------------
-- Statement 8: UpdateProductAsync - INSERT into ProductHistory (UPDATE action)
-- Method: UpdateProductAsync(Product product)
-- Variable: insertHistorySql (const string)
-- Original MS SQL Server version:
-- --------------------------------------------------------------------------
-- STATEMENT_ID: REPO_08
-- SOURCE: DataAccess/ProductRepository.cs
-- METHOD: UpdateProductAsync
-- VARIABLE: insertHistorySql
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());

-- --------------------------------------------------------------------------
-- Statement 9: UpdateProductAsync - UPDATE ProductStats
-- Method: UpdateProductAsync(Product product)
-- Variable: updateStatsSql (const string)
-- Original MS SQL Server version:
-- --------------------------------------------------------------------------
-- STATEMENT_ID: REPO_09
-- SOURCE: DataAccess/ProductRepository.cs
-- METHOD: UpdateProductAsync
-- VARIABLE: updateStatsSql
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = GETDATE()
WHERE StatId = 1;

-- --------------------------------------------------------------------------
-- Statement 10: DeleteProductAsync - SELECT old values
-- Method: DeleteProductAsync(int productId)
-- Variable: selectOldValuesSql (const string)
-- Original MS SQL Server version:
-- --------------------------------------------------------------------------
-- STATEMENT_ID: REPO_10
-- SOURCE: DataAccess/ProductRepository.cs
-- METHOD: DeleteProductAsync
-- VARIABLE: selectOldValuesSql
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- --------------------------------------------------------------------------
-- Statement 11: DeleteProductAsync - INSERT into ProductHistory (DELETE action)
-- Method: DeleteProductAsync(int productId)
-- Variable: insertHistorySql (const string)
-- Original MS SQL Server version:
-- --------------------------------------------------------------------------
-- STATEMENT_ID: REPO_11
-- SOURCE: DataAccess/ProductRepository.cs
-- METHOD: DeleteProductAsync
-- VARIABLE: insertHistorySql
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());

-- --------------------------------------------------------------------------
-- Statement 12: DeleteProductAsync - DELETE from Products
-- Method: DeleteProductAsync(int productId)
-- Variable: deleteProductSql (const string)
-- Original MS SQL Server version:
-- --------------------------------------------------------------------------
-- STATEMENT_ID: REPO_12
-- SOURCE: DataAccess/ProductRepository.cs
-- METHOD: DeleteProductAsync
-- VARIABLE: deleteProductSql
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- --------------------------------------------------------------------------
-- Statement 13: DeleteProductAsync - UPDATE ProductStats
-- Method: DeleteProductAsync(int productId)
-- Variable: updateStatsSql (const string)
-- Original MS SQL Server version:
-- --------------------------------------------------------------------------
-- STATEMENT_ID: REPO_13
-- SOURCE: DataAccess/ProductRepository.cs
-- METHOD: DeleteProductAsync
-- VARIABLE: updateStatsSql
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

-- --------------------------------------------------------------------------
-- Statement 14: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Variable: sql (const string)
-- Original MS SQL Server version:
-- --------------------------------------------------------------------------
-- STATEMENT_ID: REPO_14
-- SOURCE: DataAccess/ProductRepository.cs
-- METHOD: GetProductsByPriceRangeAsync
-- VARIABLE: sql
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

-- --------------------------------------------------------------------------
-- Statement 15: GetLowStockProductsAsync - CTE with stock analysis
-- Method: GetLowStockProductsAsync(int threshold)
-- Variable: sql (const string)
-- Original MS SQL Server version (reconstructed: ::numeric -> CAST AS NUMERIC):
-- --------------------------------------------------------------------------
-- STATEMENT_ID: REPO_15
-- SOURCE: DataAccess/ProductRepository.cs
-- METHOD: GetLowStockProductsAsync
-- VARIABLE: sql
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
    ROUND(CAST(StockQuantity AS NUMERIC) / AvgStock * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;

-- ============================================================================
-- SOURCE FILE: Scripts/01_InitialSetup.sql (Simple version)
-- ============================================================================

-- --------------------------------------------------------------------------
-- Statement 16: Create Database
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_SIMPLE_01
-- SOURCE: Scripts/01_InitialSetup.sql
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ProductManagement')
BEGIN
    CREATE DATABASE ProductManagement;
END

-- --------------------------------------------------------------------------
-- Statement 17: Create Products Table
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_SIMPLE_02
-- SOURCE: Scripts/01_InitialSetup.sql
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Products]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Products](
        [ProductId] [int] IDENTITY(1,1) PRIMARY KEY,
        [Name] [nvarchar](100) NOT NULL,
        [Description] [nvarchar](500) NULL,
        [Price] [decimal](18, 2) NOT NULL,
        [StockQuantity] [int] NOT NULL,
        [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
        [ModifiedDate] [datetime] NULL
    )
END

-- --------------------------------------------------------------------------
-- Statement 18: sp_GetAllProducts stored procedure
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_SIMPLE_03
-- SOURCE: Scripts/01_InitialSetup.sql
CREATE OR ALTER PROCEDURE [dbo].[sp_GetAllProducts]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    ORDER BY Name;
END

-- --------------------------------------------------------------------------
-- Statement 19: sp_GetProductById stored procedure
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_SIMPLE_04
-- SOURCE: Scripts/01_InitialSetup.sql
CREATE OR ALTER PROCEDURE [dbo].[sp_GetProductById]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    WHERE ProductId = @ProductId;
END

-- --------------------------------------------------------------------------
-- Statement 20: sp_InsertProduct stored procedure
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_SIMPLE_05
-- SOURCE: Scripts/01_InitialSetup.sql
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

-- --------------------------------------------------------------------------
-- Statement 21: sp_UpdateProduct stored procedure
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_SIMPLE_06
-- SOURCE: Scripts/01_InitialSetup.sql
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

-- --------------------------------------------------------------------------
-- Statement 22: sp_DeleteProduct stored procedure
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_SIMPLE_07
-- SOURCE: Scripts/01_InitialSetup.sql
CREATE OR ALTER PROCEDURE [dbo].[sp_DeleteProduct]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Products
    WHERE ProductId = @ProductId;
END

-- --------------------------------------------------------------------------
-- Statement 23: Insert Sample Data
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_SIMPLE_08
-- SOURCE: Scripts/01_InitialSetup.sql
IF NOT EXISTS (SELECT TOP 1 1 FROM Products)
BEGIN
    EXEC sp_InsertProduct 'Laptop', 'High-performance laptop', 999.99, 10;
    EXEC sp_InsertProduct 'Mouse', 'Wireless gaming mouse', 49.99, 20;
    EXEC sp_InsertProduct 'Keyboard', 'Mechanical keyboard', 129.99, 15;
END

-- ============================================================================
-- SOURCE FILE: Database/Scripts/01_InitialSetup.sql (Full version)
-- ============================================================================

-- --------------------------------------------------------------------------
-- Statement 24: Create Database (full script)
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_01
-- SOURCE: Database/Scripts/01_InitialSetup.sql
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ProductManagement')
BEGIN
    CREATE DATABASE ProductManagement;
END

-- --------------------------------------------------------------------------
-- Statement 25: Drop Trigger trg_Products_History
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_02
-- SOURCE: Database/Scripts/01_InitialSetup.sql
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[trg_Products_History]') AND type = 'TR')
BEGIN
    DROP TRIGGER [dbo].[trg_Products_History]
END

-- --------------------------------------------------------------------------
-- Statement 26: Drop Table ProductHistory
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_03
-- SOURCE: Database/Scripts/01_InitialSetup.sql
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProductHistory]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[ProductHistory]
END

-- --------------------------------------------------------------------------
-- Statement 27: Drop Table Products
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_04
-- SOURCE: Database/Scripts/01_InitialSetup.sql
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Products]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[Products]
END

-- --------------------------------------------------------------------------
-- Statement 28: Drop Table Categories
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_05
-- SOURCE: Database/Scripts/01_InitialSetup.sql
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Categories]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[Categories]
END

-- --------------------------------------------------------------------------
-- Statement 29: Drop Table Suppliers
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_06
-- SOURCE: Database/Scripts/01_InitialSetup.sql
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Suppliers]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[Suppliers]
END

-- --------------------------------------------------------------------------
-- Statement 30: Drop Table ProductStats
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_07
-- SOURCE: Database/Scripts/01_InitialSetup.sql
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProductStats]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[ProductStats]
END

-- --------------------------------------------------------------------------
-- Statement 31: Create Categories Table
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_08
-- SOURCE: Database/Scripts/01_InitialSetup.sql
CREATE TABLE [dbo].[Categories](
    [CategoryId] [int] IDENTITY(1,1) PRIMARY KEY,
    [Name] [nvarchar](50) NOT NULL,
    [Description] [nvarchar](200) NULL,
    [ParentCategoryId] [int] NULL,
    [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE()
);

-- --------------------------------------------------------------------------
-- Statement 32: Add FK_Categories_Categories
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_09
-- SOURCE: Database/Scripts/01_InitialSetup.sql
ALTER TABLE [dbo].[Categories]
ADD CONSTRAINT [FK_Categories_Categories] 
FOREIGN KEY ([ParentCategoryId]) REFERENCES [dbo].[Categories] ([CategoryId]);

-- --------------------------------------------------------------------------
-- Statement 33: Create Suppliers Table
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_10
-- SOURCE: Database/Scripts/01_InitialSetup.sql
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
);

-- --------------------------------------------------------------------------
-- Statement 34: Create Products Table (full version)
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_11
-- SOURCE: Database/Scripts/01_InitialSetup.sql
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
);

-- --------------------------------------------------------------------------
-- Statement 35: Create ProductHistory Table
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_12
-- SOURCE: Database/Scripts/01_InitialSetup.sql
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
);

-- --------------------------------------------------------------------------
-- Statement 36: Create ProductStats Table
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_13
-- SOURCE: Database/Scripts/01_InitialSetup.sql
CREATE TABLE [dbo].[ProductStats](
    [StatId] [int] PRIMARY KEY DEFAULT 1,
    [TotalProducts] [int] NOT NULL DEFAULT 0,
    [AveragePrice] [decimal](18, 2) NOT NULL DEFAULT 0,
    [TotalStockValue] [decimal](18, 2) NOT NULL DEFAULT 0,
    [LowStockCount] [int] NOT NULL DEFAULT 0,
    [DiscontinuedCount] [int] NOT NULL DEFAULT 0,
    [LastUpdated] [datetime] NOT NULL DEFAULT GETDATE()
);

-- --------------------------------------------------------------------------
-- Statement 37: Create Index IX_Products_CategoryId
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_14
-- SOURCE: Database/Scripts/01_InitialSetup.sql
CREATE INDEX [IX_Products_CategoryId] ON [dbo].[Products] ([CategoryId]);

-- --------------------------------------------------------------------------
-- Statement 38: Create Index IX_Products_SupplierId
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_15
-- SOURCE: Database/Scripts/01_InitialSetup.sql
CREATE INDEX [IX_Products_SupplierId] ON [dbo].[Products] ([SupplierId]);

-- --------------------------------------------------------------------------
-- Statement 39: Create Unique Index IX_Products_SKU
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_16
-- SOURCE: Database/Scripts/01_InitialSetup.sql
CREATE UNIQUE INDEX [IX_Products_SKU] ON [dbo].[Products] ([SKU]);

-- --------------------------------------------------------------------------
-- Statement 40: Create Index IX_ProductHistory_ProductId
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_17
-- SOURCE: Database/Scripts/01_InitialSetup.sql
CREATE INDEX [IX_ProductHistory_ProductId] ON [dbo].[ProductHistory] ([ProductId]);

-- --------------------------------------------------------------------------
-- Statement 41: Create Index IX_ProductHistory_ActionDate
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_18
-- SOURCE: Database/Scripts/01_InitialSetup.sql
CREATE INDEX [IX_ProductHistory_ActionDate] ON [dbo].[ProductHistory] ([ActionDate]);

-- --------------------------------------------------------------------------
-- Statement 42: Insert Sample Categories
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_19
-- SOURCE: Database/Scripts/01_InitialSetup.sql
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
    ('Switches', 'Network switches', 8);

-- --------------------------------------------------------------------------
-- Statement 43: Insert Sample Suppliers
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_20
-- SOURCE: Database/Scripts/01_InitialSetup.sql
INSERT INTO Suppliers (Name, ContactName, Email, Phone, Address, Country)
VALUES 
    ('TechGlobal Inc.', 'John Smith', 'john@techglobal.com', '+1-555-0101', '123 Tech Street, Silicon Valley, CA', 'USA'),
    ('ElectroParts Ltd.', 'Sarah Johnson', 'sarah@electroparts.com', '+44-20-7123-4567', '45 Circuit Road, London', 'UK'),
    ('Digital Solutions', 'Michael Chen', 'michael@digitalsolutions.com', '+86-10-1234-5678', '789 Digital Avenue, Beijing', 'China'),
    ('Gaming Gear Co.', 'David Wilson', 'david@gaminggear.com', '+1-555-0202', '456 Game Street, Seattle, WA', 'USA'),
    ('AudioTech Systems', 'Emma Brown', 'emma@audiotech.com', '+1-555-0303', '789 Sound Road, Nashville, TN', 'USA'),
    ('Storage Solutions', 'James Lee', 'james@storagesolutions.com', '+1-555-0404', '321 Data Drive, Austin, TX', 'USA'),
    ('Office Supplies Pro', 'Lisa Anderson', 'lisa@officesupplies.com', '+1-555-0505', '654 Office Park, Chicago, IL', 'USA'),
    ('Network Experts', 'Robert Taylor', 'robert@networkexperts.com', '+1-555-0606', '987 Network Way, Boston, MA', 'USA');

-- --------------------------------------------------------------------------
-- Statement 44: Insert Sample Products
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_21
-- SOURCE: Database/Scripts/01_InitialSetup.sql
INSERT INTO Products (Name, Description, Price, StockQuantity, CategoryId, SupplierId, SKU, Weight, Dimensions, ReorderLevel)
VALUES 
    ('ProBook X1', 'High-performance business laptop with 16GB RAM', 1299.99, 15, 9, 1, 'LAP-X1-001', 1.8, '14" x 9" x 0.7"', 5),
    ('Gaming Beast', 'Gaming laptop with RTX 3080, 32GB RAM', 2499.99, 8, 9, 4, 'LAP-GB-001', 2.5, '15.6" x 11" x 1"', 3),
    ('UltraBook Air', 'Ultra-thin laptop with 12-hour battery', 999.99, 20, 9, 1, 'LAP-UA-001', 1.2, '13" x 8" x 0.5"', 7),
    ('WorkStation Pro', 'Professional workstation with dual monitors', 1999.99, 10, 10, 1, 'DESK-WP-001', 15.0, '18" x 8" x 16"', 4),
    ('Gaming Tower', 'High-end gaming desktop with liquid cooling', 2999.99, 5, 16, 4, 'DESK-GT-001', 20.0, '20" x 10" x 18"', 2),
    ('Mechanical Pro', 'Mechanical keyboard with RGB lighting', 149.99, 30, 11, 2, 'KB-MP-001', 1.2, '17" x 5" x 1.5"', 10),
    ('Wireless Elite', 'Wireless keyboard with numeric pad', 79.99, 25, 11, 2, 'KB-WE-001', 0.8, '18" x 6" x 1"', 8),
    ('Gaming Mouse Pro', 'High-precision gaming mouse', 89.99, 40, 12, 4, 'M-GP-001', 0.3, '5" x 3" x 1.5"', 15),
    ('Wireless Track', 'Wireless mouse with long battery life', 49.99, 35, 12, 2, 'M-WT-001', 0.2, '4" x 2.5" x 1.2"', 12),
    ('Noise Cancelling Pro', 'Premium noise-cancelling headphones', 299.99, 20, 13, 5, 'HP-NC-001', 0.4, '7" x 6" x 3"', 8),
    ('Gaming Headset', '7.1 surround sound gaming headset', 129.99, 25, 13, 4, 'HP-GH-001', 0.5, '8" x 7" x 4"', 10),
    ('Studio Monitors', 'Professional studio monitors', 399.99, 10, 14, 5, 'SP-SM-001', 8.0, '12" x 8" x 10"', 4),
    ('Bluetooth Soundbar', 'Wireless soundbar with subwoofer', 249.99, 15, 14, 5, 'SP-BS-001', 5.0, '36" x 3" x 4"', 6),
    ('SSD Pro 1TB', '1TB external SSD with USB 3.1', 199.99, 30, 15, 6, 'ED-SP-001', 0.2, '4" x 2" x 0.5"', 12),
    ('HDD Backup 4TB', '4TB external HDD for backup', 129.99, 25, 15, 6, 'ED-HB-001', 0.5, '5" x 3" x 1"', 10),
    ('Laser Pro', 'Business laser printer with duplex', 399.99, 12, 18, 7, 'PR-LP-001', 25.0, '18" x 16" x 12"', 5),
    ('Photo Inkjet', 'Photo-quality inkjet printer', 299.99, 15, 18, 7, 'PR-PI-001', 15.0, '16" x 14" x 8"', 6),
    ('WiFi 6 Router', 'High-speed WiFi 6 router', 199.99, 20, 19, 8, 'NET-WR-001', 1.5, '10" x 7" x 2"', 8),
    ('Gigabit Switch', '24-port gigabit network switch', 299.99, 10, 20, 8, 'NET-GS-001', 3.0, '17" x 10" x 1.5"', 4);

-- --------------------------------------------------------------------------
-- Statement 45: Insert initial stats record
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_22
-- SOURCE: Database/Scripts/01_InitialSetup.sql
INSERT INTO ProductStats (StatId, TotalProducts, AveragePrice, TotalStockValue, LowStockCount, DiscontinuedCount, LastUpdated)
VALUES (1, 0, 0, 0, 0, 0, GETDATE());

-- --------------------------------------------------------------------------
-- Statement 46: Update initial statistics
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_23
-- SOURCE: Database/Scripts/01_InitialSetup.sql
UPDATE ProductStats
SET 
    TotalProducts = (SELECT COUNT(*) FROM Products),
    AveragePrice = (SELECT AVG(Price) FROM Products),
    TotalStockValue = (SELECT SUM(Price * StockQuantity) FROM Products),
    LowStockCount = (SELECT COUNT(*) FROM Products WHERE StockQuantity <= ReorderLevel),
    DiscontinuedCount = (SELECT COUNT(*) FROM Products WHERE IsDiscontinued = 1),
    LastUpdated = GETDATE()
WHERE StatId = 1;

-- --------------------------------------------------------------------------
-- Statement 47: Create Trigger trg_Products_History
-- --------------------------------------------------------------------------
-- STATEMENT_ID: SCRIPT_FULL_24
-- SOURCE: Database/Scripts/01_InitialSetup.sql
CREATE TRIGGER [dbo].[trg_Products_History]
ON [dbo].[Products]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
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

-- --------------------------------------------------------------------------
-- Statements 48-52: Stored Procedures from Full script (same as Statements 18-22)
-- --------------------------------------------------------------------------
-- These are identical to SCRIPT_SIMPLE_03 through SCRIPT_SIMPLE_07
-- See Statements 18-22 above for the SQL text

-- ============================================================================
-- TOTAL STATEMENTS CATALOGED: 47 unique SQL statements
-- (5 stored procedures in full script are duplicates of simple script ones)
-- 
-- Breakdown:
-- - ProductRepository.cs: 15 SQL statements (REPO_01 through REPO_15)
-- - Scripts/01_InitialSetup.sql: 8 SQL statements (SCRIPT_SIMPLE_01 through SCRIPT_SIMPLE_08)
-- - Database/Scripts/01_InitialSetup.sql: 24 SQL statements (SCRIPT_FULL_01 through SCRIPT_FULL_24)
-- ============================================================================
