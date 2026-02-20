-- ============================================================
-- COMPLETE EXTRACTED SQL STATEMENTS CATALOG
-- Source: MS SQL Server (Original)
-- Total Statements: 26 (7 from C# code + 19 from SQL scripts)
-- ============================================================

-- ############################################################
-- SECTION A: SQL Statements from ProductRepository.cs (7)
-- ############################################################

-- ============================================================
-- Statement 1: GetAllProductsAsync
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED
-- ============================================================
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

-- ============================================================
-- Statement 2: GetProductByIdAsync
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED
-- ============================================================
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

-- ============================================================
-- Statement 3: InsertProductAsync
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED
-- ============================================================
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;

-- ============================================================
-- Statement 4: UpdateProductAsync
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED
-- ============================================================
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

-- ============================================================
-- Statement 5: DeleteProductAsync
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED
-- ============================================================
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
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

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED
-- ============================================================
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

-- ============================================================
-- Statement 7: GetLowStockProductsAsync
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED
-- ============================================================
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

-- ############################################################
-- SECTION B: SQL Statements from Database/Scripts/01_InitialSetup.sql (14)
-- ############################################################

-- Statement 8: CREATE TABLE Categories
CREATE TABLE [dbo].[Categories](
    [CategoryId] [int] IDENTITY(1,1) PRIMARY KEY,
    [Name] [nvarchar](50) NOT NULL,
    [Description] [nvarchar](200) NULL,
    [ParentCategoryId] [int] NULL,
    [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE()
);
GO

-- Statement 9: CREATE TABLE Suppliers
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
GO

-- Statement 10: CREATE TABLE Products
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
    [ModifiedDate] [datetime] NULL
);
GO

-- Statement 11: CREATE TABLE ProductHistory
CREATE TABLE [dbo].[ProductHistory](
    [HistoryId] [int] IDENTITY(1,1) PRIMARY KEY,
    [ProductId] [int] NOT NULL,
    [Action] [varchar](10) NOT NULL,
    [OldPrice] [decimal](18, 2) NULL,
    [NewPrice] [decimal](18, 2) NULL,
    [OldStock] [int] NULL,
    [NewStock] [int] NULL,
    [ActionDate] [datetime] NOT NULL DEFAULT GETDATE(),
    [ModifiedBy] [nvarchar](100) NULL
);
GO

-- Statement 12: CREATE TABLE ProductStats
CREATE TABLE [dbo].[ProductStats](
    [StatId] [int] PRIMARY KEY DEFAULT 1,
    [TotalProducts] [int] NOT NULL DEFAULT 0,
    [AveragePrice] [decimal](18, 2) NOT NULL DEFAULT 0,
    [TotalStockValue] [decimal](18, 2) NOT NULL DEFAULT 0,
    [LowStockCount] [int] NOT NULL DEFAULT 0,
    [DiscontinuedCount] [int] NOT NULL DEFAULT 0,
    [LastUpdated] [datetime] NOT NULL DEFAULT GETDATE()
);
GO

-- Statement 13: INSERT Categories
INSERT INTO Categories (Name, Description, ParentCategoryId)
VALUES 
    ('Electronics', 'Electronic devices and accessories', NULL),
    ('Computers', 'Computers and related equipment', 1);
GO

-- Statement 14: INSERT Suppliers
INSERT INTO Suppliers (Name, ContactName, Email, Phone, Address, Country)
VALUES 
    ('TechGlobal Inc.', 'John Smith', 'john@techglobal.com', '+1-555-0101', '123 Tech Street, Silicon Valley, CA', 'USA');
GO

-- Statement 15: INSERT Products
INSERT INTO Products (Name, Description, Price, StockQuantity, CategoryId, SupplierId, SKU, Weight, Dimensions, ReorderLevel)
VALUES 
    ('ProBook X1', 'High-performance business laptop with 16GB RAM', 1299.99, 15, 9, 1, 'LAP-X1-001', 1.8, '14" x 9" x 0.7"', 5);
GO

-- Statement 16: INSERT ProductStats
INSERT INTO ProductStats (StatId, TotalProducts, AveragePrice, TotalStockValue, LowStockCount, DiscontinuedCount, LastUpdated)
VALUES (1, 0, 0, 0, 0, 0, GETDATE());
GO

-- Statement 17: UPDATE ProductStats
UPDATE ProductStats
SET 
    TotalProducts = (SELECT COUNT(*) FROM Products),
    AveragePrice = (SELECT AVG(Price) FROM Products),
    TotalStockValue = (SELECT SUM(Price * StockQuantity) FROM Products),
    LowStockCount = (SELECT COUNT(*) FROM Products WHERE StockQuantity <= ReorderLevel),
    DiscontinuedCount = (SELECT COUNT(*) FROM Products WHERE IsDiscontinued = 1),
    LastUpdated = GETDATE()
WHERE StatId = 1;
GO

-- Statement 18: CREATE TRIGGER trg_Products_History
CREATE TRIGGER [dbo].[trg_Products_History]
ON [dbo].[Products]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    -- Handle INSERT/UPDATE/DELETE with inserted/deleted tables
END;
GO

-- Statement 19: CREATE PROCEDURE sp_GetAllProducts
CREATE OR ALTER PROCEDURE [dbo].[sp_GetAllProducts]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    ORDER BY Name;
END;
GO

-- Statement 20: CREATE PROCEDURE sp_GetProductById
CREATE OR ALTER PROCEDURE [dbo].[sp_GetProductById]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    WHERE ProductId = @ProductId;
END;
GO

-- Statement 21: CREATE PROCEDURE sp_InsertProduct
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
GO

-- ############################################################
-- SECTION C: SQL Statements from Scripts/01_InitialSetup.sql (5)
-- ############################################################

-- Statement 22: CREATE TABLE Products IF NOT EXISTS
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
END;
GO

-- Statement 23: CREATE PROCEDURE sp_UpdateProduct
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
    SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
END;
GO

-- Statement 24: CREATE PROCEDURE sp_DeleteProduct
CREATE OR ALTER PROCEDURE [dbo].[sp_DeleteProduct]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Products WHERE ProductId = @ProductId;
END;
GO

-- Statement 25: INSERT Sample Data
IF NOT EXISTS (SELECT TOP 1 1 FROM Products)
BEGIN
    EXEC sp_InsertProduct 'Laptop', 'High-performance laptop', 999.99, 10;
    EXEC sp_InsertProduct 'Mouse', 'Wireless gaming mouse', 49.99, 20;
    EXEC sp_InsertProduct 'Keyboard', 'Mechanical keyboard', 129.99, 15;
END;
GO

-- Statement 26: ALTER TABLE Categories FK
ALTER TABLE [dbo].[Categories]
ADD CONSTRAINT [FK_Categories_Categories] 
FOREIGN KEY ([ParentCategoryId]) REFERENCES [dbo].[Categories] ([CategoryId]);
GO
