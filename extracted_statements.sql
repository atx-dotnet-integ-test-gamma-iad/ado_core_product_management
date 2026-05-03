-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: AdoCore Application - SQL Server to PostgreSQL Migration
-- Generated for DMS MCP conversion pipeline
-- ============================================================================

-- ============================================================================
-- SECTION A: SQL Statements from ProductRepository.cs (Inline C# SQL)
-- ============================================================================

-- Statement A1: GetAllProductsAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Context: const string sql in GetAllProductsAsync method
WITH productstats_cte AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- Statement A2: GetProductByIdAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Context: const string sql in GetProductByIdAsync method
WITH producthistory_cte AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = @ProductId
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    ph.previousprice,
    ph.previousstock,
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- Statement A3: InsertProductAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Context: const string sql in InsertProductAsync method
WITH new_product AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
log_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp()
    FROM new_product
),
update_stats AS (
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1
)
SELECT productid FROM new_product;

-- Statement A4: UpdateProductAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Context: const string sql in UpdateProductAsync method
WITH old_values AS (
    SELECT price AS oldprice, stockquantity AS oldstock
    FROM products
    WHERE productid = @ProductId
),
do_update AS (
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = clock_timestamp()
    WHERE productid = @ProductId
),
log_change AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', oldprice, @Price, oldstock, @StockQuantity, clock_timestamp()
    FROM old_values
)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- Statement A5: DeleteProductAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Context: const string sql in DeleteProductAsync method
WITH old_values AS (
    SELECT price AS oldprice, stockquantity AS oldstock
    FROM products
    WHERE productid = @ProductId
),
log_delete AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', oldprice, NULL, oldstock, NULL, clock_timestamp()
    FROM old_values
),
do_delete AS (
    DELETE FROM products 
    WHERE productid = @ProductId
)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- Statement A6: GetProductsByPriceRangeAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Context: const string sql in GetProductsByPriceRangeAsync method
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as pricesegment
FROM rankedproducts rp
ORDER BY rp.pricerank;

-- Statement A7: GetLowStockProductsAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Context: const string sql in GetLowStockProductsAsync method
WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT 
    sa.*,
    CASE 
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;

-- ============================================================================
-- SECTION B: SQL Statements from Scripts/01_InitialSetup.sql
-- ============================================================================

-- Statement B1: Create Database
-- Source: sourceCode/Scripts/01_InitialSetup.sql
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ProductManagement')
BEGIN
    CREATE DATABASE ProductManagement;
END

-- Statement B2: Use Database
-- Source: sourceCode/Scripts/01_InitialSetup.sql
USE ProductManagement;

-- Statement B3: Create Products Table
-- Source: sourceCode/Scripts/01_InitialSetup.sql
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

-- Statement B4: Create Stored Procedure sp_GetAllProducts
-- Source: sourceCode/Scripts/01_InitialSetup.sql
CREATE OR ALTER PROCEDURE [dbo].[sp_GetAllProducts]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    ORDER BY Name;
END

-- Statement B5: Create Stored Procedure sp_GetProductById
-- Source: sourceCode/Scripts/01_InitialSetup.sql
CREATE OR ALTER PROCEDURE [dbo].[sp_GetProductById]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    WHERE ProductId = @ProductId;
END

-- Statement B6: Create Stored Procedure sp_InsertProduct
-- Source: sourceCode/Scripts/01_InitialSetup.sql
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

-- Statement B7: Create Stored Procedure sp_UpdateProduct
-- Source: sourceCode/Scripts/01_InitialSetup.sql
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

-- Statement B8: Create Stored Procedure sp_DeleteProduct
-- Source: sourceCode/Scripts/01_InitialSetup.sql
CREATE OR ALTER PROCEDURE [dbo].[sp_DeleteProduct]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Products
    WHERE ProductId = @ProductId;
END

-- Statement B9: Insert Sample Data via Stored Procedures
-- Source: sourceCode/Scripts/01_InitialSetup.sql
IF NOT EXISTS (SELECT TOP 1 1 FROM Products)
BEGIN
    EXEC sp_InsertProduct 'Laptop', 'High-performance laptop', 999.99, 10;
    EXEC sp_InsertProduct 'Mouse', 'Wireless gaming mouse', 49.99, 20;
    EXEC sp_InsertProduct 'Keyboard', 'Mechanical keyboard', 129.99, 15;
END

-- ============================================================================
-- SECTION C: SQL Statements from Database/Scripts/01_InitialSetup.sql
-- ============================================================================

-- Statement C1: Create Database
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ProductManagement')
BEGIN
    CREATE DATABASE ProductManagement;
END

-- Statement C2: Use Database
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
USE ProductManagement;

-- Statement C3: Drop Trigger trg_Products_History
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[trg_Products_History]') AND type = 'TR')
BEGIN
    DROP TRIGGER [dbo].[trg_Products_History]
END

-- Statement C4: Drop Table ProductHistory
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProductHistory]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[ProductHistory]
END

-- Statement C5: Drop Table Products
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Products]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[Products]
END

-- Statement C6: Drop Table Categories
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Categories]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[Categories]
END

-- Statement C7: Drop Table Suppliers
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Suppliers]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[Suppliers]
END

-- Statement C8: Drop Table ProductStats
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProductStats]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[ProductStats]
END

-- Statement C9: Create Categories Table
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
CREATE TABLE [dbo].[Categories](
    [CategoryId] [int] IDENTITY(1,1) PRIMARY KEY,
    [Name] [nvarchar](50) NOT NULL,
    [Description] [nvarchar](200) NULL,
    [ParentCategoryId] [int] NULL,
    [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE()
)

-- Statement C10: Alter Table Categories Add FK
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
ALTER TABLE [dbo].[Categories]
ADD CONSTRAINT [FK_Categories_Categories] 
FOREIGN KEY ([ParentCategoryId]) REFERENCES [dbo].[Categories] ([CategoryId])

-- Statement C11: Create Suppliers Table
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
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

-- Statement C12: Create Products Table
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
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

-- Statement C13: Create ProductHistory Table
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
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

-- Statement C14: Create ProductStats Table
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
CREATE TABLE [dbo].[ProductStats](
    [StatId] [int] PRIMARY KEY DEFAULT 1,
    [TotalProducts] [int] NOT NULL DEFAULT 0,
    [AveragePrice] [decimal](18, 2) NOT NULL DEFAULT 0,
    [TotalStockValue] [decimal](18, 2) NOT NULL DEFAULT 0,
    [LowStockCount] [int] NOT NULL DEFAULT 0,
    [DiscontinuedCount] [int] NOT NULL DEFAULT 0,
    [LastUpdated] [datetime] NOT NULL DEFAULT GETDATE()
)

-- Statement C15: Create Index IX_Products_CategoryId
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
CREATE INDEX [IX_Products_CategoryId] ON [dbo].[Products] ([CategoryId])

-- Statement C16: Create Index IX_Products_SupplierId
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
CREATE INDEX [IX_Products_SupplierId] ON [dbo].[Products] ([SupplierId])

-- Statement C17: Create Unique Index IX_Products_SKU
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
CREATE UNIQUE INDEX [IX_Products_SKU] ON [dbo].[Products] ([SKU])

-- Statement C18: Create Index IX_ProductHistory_ProductId
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
CREATE INDEX [IX_ProductHistory_ProductId] ON [dbo].[ProductHistory] ([ProductId])

-- Statement C19: Create Index IX_ProductHistory_ActionDate
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
CREATE INDEX [IX_ProductHistory_ActionDate] ON [dbo].[ProductHistory] ([ActionDate])

-- Statement C20: Insert Sample Categories
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
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

-- Statement C21: Insert Sample Suppliers
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
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

-- Statement C22: Insert Sample Products
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
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
    ('Gigabit Switch', '24-port gigabit network switch', 299.99, 10, 20, 8, 'NET-GS-001', 3.0, '17" x 10" x 1.5"', 4)

-- Statement C23: Insert Initial ProductStats Record
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
INSERT INTO ProductStats (StatId, TotalProducts, AveragePrice, TotalStockValue, LowStockCount, DiscontinuedCount, LastUpdated)
VALUES (1, 0, 0, 0, 0, 0, GETDATE())

-- Statement C24: Update ProductStats with Initial Statistics
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
UPDATE ProductStats
SET 
    TotalProducts = (SELECT COUNT(*) FROM Products),
    AveragePrice = (SELECT AVG(Price) FROM Products),
    TotalStockValue = (SELECT SUM(Price * StockQuantity) FROM Products),
    LowStockCount = (SELECT COUNT(*) FROM Products WHERE StockQuantity <= ReorderLevel),
    DiscontinuedCount = (SELECT COUNT(*) FROM Products WHERE IsDiscontinued = 1),
    LastUpdated = GETDATE()
WHERE StatId = 1

-- Statement C25: Create Trigger trg_Products_History
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
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

-- Statement C26: Create Stored Procedure sp_GetAllProducts
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
CREATE OR ALTER PROCEDURE [dbo].[sp_GetAllProducts]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    ORDER BY Name;
END

-- Statement C27: Create Stored Procedure sp_GetProductById
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
CREATE OR ALTER PROCEDURE [dbo].[sp_GetProductById]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    WHERE ProductId = @ProductId;
END

-- Statement C28: Create Stored Procedure sp_InsertProduct
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
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

-- Statement C29: Create Stored Procedure sp_UpdateProduct
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
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

-- Statement C30: Create Stored Procedure sp_DeleteProduct
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
CREATE OR ALTER PROCEDURE [dbo].[sp_DeleteProduct]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Products
    WHERE ProductId = @ProductId;
END

-- ============================================================================
-- TOTAL: 46 SQL Statements extracted
-- Section A (ProductRepository.cs): 7 statements (A1-A7)
-- Section B (Scripts/01_InitialSetup.sql): 9 statements (B1-B9)
-- Section C (Database/Scripts/01_InitialSetup.sql): 30 statements (C1-C30)
-- ============================================================================
