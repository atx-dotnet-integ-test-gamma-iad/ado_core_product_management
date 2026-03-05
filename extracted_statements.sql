-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: AdoCore .NET Application (MS SQL Server to PostgreSQL Migration)
-- Generated: 2026-03-05
-- ============================================================================
-- This file contains ALL original MS SQL Server statements extracted from the
-- application codebase. Statements from ProductRepository.cs are reconstructed
-- from the PostgreSQL-migrated code back to their original MS SQL Server form
-- based on schema definitions in 01_InitialSetup.sql.
-- ============================================================================

-- ============================================================================
-- SECTION 1: INLINE SQL STATEMENTS FROM ProductRepository.cs
-- ============================================================================

-- --------------------------------------------------------------------------
-- Statement 1: GetAllProductsAsync()
-- Source: sourceCode/DataAccess/ProductRepository.cs, Line ~44
-- Method: GetAllProductsAsync()
-- Description: CTE with AVG/COUNT window functions, CASE/WHEN, INNER JOIN
-- --------------------------------------------------------------------------
-- Original MS SQL Server version (reconstructed):
WITH ProductStats
AS (SELECT
    ProductId, AVG(Price) OVER () AS AvgPrice, COUNT(*) OVER () AS TotalProducts
    FROM [dbo].[Products])
SELECT
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    CASE
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END AS PriceCategory, ROUND((p.Price / ps.AvgPrice) * 100, 2) AS PricePercentageOfAverage
    FROM [dbo].[Products] AS p
    INNER JOIN ProductStats AS ps
        ON p.ProductId = ps.ProductId
    ORDER BY
    CASE
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END, p.Name;

-- --------------------------------------------------------------------------
-- Statement 2: GetProductByIdAsync()
-- Source: sourceCode/DataAccess/ProductRepository.cs, Line ~72
-- Method: GetProductByIdAsync(int productId)
-- Description: CTE with LAG() window function, LEFT OUTER JOIN, parameterized
-- --------------------------------------------------------------------------
-- Original MS SQL Server version (reconstructed):
WITH ProductHistory
AS (SELECT
    ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) AS PreviousPrice, LAG(StockQuantity) OVER (ORDER BY ModifiedDate) AS PreviousStock
    FROM [dbo].[Products]
    WHERE ProductId = @ProductId)
SELECT
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, ph.PreviousPrice, ph.PreviousStock,
    CASE
        WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END AS PriceChangePercentage
    FROM [dbo].[Products] AS p
    LEFT OUTER JOIN ProductHistory AS ph
        ON p.ProductId = ph.ProductId
    WHERE p.ProductId = @ProductId;

-- --------------------------------------------------------------------------
-- Statement 3: InsertProductAsync()
-- Source: sourceCode/DataAccess/ProductRepository.cs, Line ~98
-- Method: InsertProductAsync(Product product)
-- Description: INSERT with SCOPE_IDENTITY(), INSERT into ProductHistory, UPDATE ProductStats
-- --------------------------------------------------------------------------
-- Original MS SQL Server version (reconstructed):
DECLARE @NewProductId INT;
INSERT INTO [dbo].[Products] (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity);
SET @NewProductId = SCOPE_IDENTITY();
INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
UPDATE [dbo].[ProductStats]
SET
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = GETDATE()
WHERE StatId = 1;
SELECT @NewProductId AS ProductId;

-- --------------------------------------------------------------------------
-- Statement 4: UpdateProductAsync()
-- Source: sourceCode/DataAccess/ProductRepository.cs, Line ~128
-- Method: UpdateProductAsync(Product product)
-- Description: DECLARE variables, UPDATE with GETDATE(), INSERT history, UPDATE stats
-- --------------------------------------------------------------------------
-- Original MS SQL Server version (reconstructed):
DECLARE @OldPrice DECIMAL(18,2), @OldStock INT;
SELECT @OldPrice = Price, @OldStock = StockQuantity
FROM [dbo].[Products]
WHERE ProductId = @ProductId;
UPDATE [dbo].[Products]
SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE()
WHERE ProductId = @ProductId;
INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
UPDATE [dbo].[ProductStats]
SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts, LastUpdated = GETDATE()
WHERE StatId = 1;

-- --------------------------------------------------------------------------
-- Statement 5: DeleteProductAsync()
-- Source: sourceCode/DataAccess/ProductRepository.cs, Line ~162
-- Method: DeleteProductAsync(int productId)
-- Description: DECLARE variables, DELETE, INSERT history, UPDATE stats with CASE
-- --------------------------------------------------------------------------
-- Original MS SQL Server version (reconstructed):
DECLARE @OldPrice DECIMAL(18,2), @OldStock INT;
SELECT @OldPrice = Price, @OldStock = StockQuantity
FROM [dbo].[Products]
WHERE ProductId = @ProductId;
INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
DELETE FROM [dbo].[Products]
WHERE ProductId = @ProductId;
UPDATE [dbo].[ProductStats]
SET TotalProducts = TotalProducts - 1, AveragePrice =
CASE
    WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
    ELSE 0
END, LastUpdated = GETDATE()
WHERE StatId = 1;

-- --------------------------------------------------------------------------
-- Statement 6: GetProductsByPriceRangeAsync()
-- Source: sourceCode/DataAccess/ProductRepository.cs, Line ~190
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Description: CTE with RANK(), PERCENT_RANK() window functions, BETWEEN, CASE
-- --------------------------------------------------------------------------
-- Original MS SQL Server version (reconstructed):
WITH RankedProducts
AS (SELECT
    p.*, RANK() OVER (ORDER BY p.Price) AS PriceRank, PERCENT_RANK() OVER (ORDER BY p.Price) AS PricePercentile
    FROM [dbo].[Products] AS p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice)
SELECT
    rp.*,
    CASE
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS PriceSegment
    FROM RankedProducts AS rp
    ORDER BY rp.PriceRank;

-- --------------------------------------------------------------------------
-- Statement 7: GetLowStockProductsAsync()
-- Source: sourceCode/DataAccess/ProductRepository.cs, Line ~218
-- Method: GetLowStockProductsAsync(int threshold)
-- Description: CTE with AVG/MIN/MAX window functions, CASE/WHEN, ROUND
-- --------------------------------------------------------------------------
-- Original MS SQL Server version (reconstructed):
WITH StockAnalysis
AS (SELECT
    p.*, AVG(StockQuantity) OVER () AS AvgStock, MIN(StockQuantity) OVER () AS MinStock, MAX(StockQuantity) OVER () AS MaxStock
    FROM [dbo].[Products] AS p)
SELECT
    sa.*,
    CASE
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS StockStatus, ROUND((CAST(StockQuantity AS DECIMAL) / AvgStock) * 100, 2) AS StockPercentageOfAverage
    FROM StockAnalysis AS sa
    WHERE StockQuantity <= @Threshold
    ORDER BY StockQuantity;

-- ============================================================================
-- SECTION 2: SQL STATEMENTS FROM Scripts/01_InitialSetup.sql
-- ============================================================================

-- --------------------------------------------------------------------------
-- Statement 8: CREATE TABLE Products (simple version)
-- Source: sourceCode/Scripts/01_InitialSetup.sql, Line ~14
-- --------------------------------------------------------------------------
CREATE TABLE [dbo].[Products](
    [ProductId] [int] IDENTITY(1,1) PRIMARY KEY,
    [Name] [nvarchar](100) NOT NULL,
    [Description] [nvarchar](500) NULL,
    [Price] [decimal](18, 2) NOT NULL,
    [StockQuantity] [int] NOT NULL,
    [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
    [ModifiedDate] [datetime] NULL
);

-- --------------------------------------------------------------------------
-- Statement 9: sp_GetAllProducts stored procedure
-- Source: sourceCode/Scripts/01_InitialSetup.sql, Line ~26
-- --------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_GetAllProducts]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    ORDER BY Name;
END;

-- --------------------------------------------------------------------------
-- Statement 10: sp_GetProductById stored procedure
-- Source: sourceCode/Scripts/01_InitialSetup.sql, Line ~36
-- --------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_GetProductById]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    WHERE ProductId = @ProductId;
END;

-- --------------------------------------------------------------------------
-- Statement 11: sp_InsertProduct stored procedure
-- Source: sourceCode/Scripts/01_InitialSetup.sql, Line ~47
-- --------------------------------------------------------------------------
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
END;

-- --------------------------------------------------------------------------
-- Statement 12: sp_UpdateProduct stored procedure
-- Source: sourceCode/Scripts/01_InitialSetup.sql, Line ~62
-- --------------------------------------------------------------------------
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
END;

-- --------------------------------------------------------------------------
-- Statement 13: sp_DeleteProduct stored procedure
-- Source: sourceCode/Scripts/01_InitialSetup.sql, Line ~79
-- --------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_DeleteProduct]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Products
    WHERE ProductId = @ProductId;
END;

-- ============================================================================
-- SECTION 3: SQL STATEMENTS FROM Database/Scripts/01_InitialSetup.sql
-- ============================================================================

-- --------------------------------------------------------------------------
-- Statement 14: CREATE TABLE Categories
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, Line ~50
-- --------------------------------------------------------------------------
CREATE TABLE [dbo].[Categories](
    [CategoryId] [int] IDENTITY(1,1) PRIMARY KEY,
    [Name] [nvarchar](50) NOT NULL,
    [Description] [nvarchar](200) NULL,
    [ParentCategoryId] [int] NULL,
    [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE()
);

-- --------------------------------------------------------------------------
-- Statement 15: CREATE TABLE Suppliers
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, Line ~64
-- --------------------------------------------------------------------------
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
-- Statement 16: CREATE TABLE Products (full version with FKs)
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, Line ~78
-- --------------------------------------------------------------------------
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
-- Statement 17: CREATE TABLE ProductHistory
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, Line ~100
-- --------------------------------------------------------------------------
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
-- Statement 18: CREATE TABLE ProductStats
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, Line ~115
-- --------------------------------------------------------------------------
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
-- Statement 19: INSERT Sample Categories
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, Line ~141
-- --------------------------------------------------------------------------
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
-- Statement 20: INSERT Sample Suppliers
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, Line ~166
-- --------------------------------------------------------------------------
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
-- Statement 21: INSERT Sample Products
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, Line ~179
-- --------------------------------------------------------------------------
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
-- Statement 22: INSERT ProductStats initial record
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, Line ~206
-- --------------------------------------------------------------------------
INSERT INTO ProductStats (StatId, TotalProducts, AveragePrice, TotalStockValue, LowStockCount, DiscontinuedCount, LastUpdated)
VALUES (1, 0, 0, 0, 0, 0, GETDATE());

-- --------------------------------------------------------------------------
-- Statement 23: UPDATE ProductStats initial statistics
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, Line ~211
-- --------------------------------------------------------------------------
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
-- Statement 24: CREATE TRIGGER trg_Products_History
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, Line ~222
-- --------------------------------------------------------------------------
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
END;

-- ============================================================================
-- END OF EXTRACTED STATEMENTS CATALOG
-- Total statements extracted: 24
-- Section 1 (ProductRepository.cs inline): 7 statements (reconstructed MS SQL)
-- Section 2 (Scripts/01_InitialSetup.sql): 6 statements
-- Section 3 (Database/Scripts/01_InitialSetup.sql): 11 statements
-- ============================================================================
