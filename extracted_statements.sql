-- =============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: AdoCore .NET Application (Microsoft SQL Server)
-- Purpose: Comprehensive catalog of all SQL statements for DMS MCP conversion
-- =============================================================================

-- =============================================================================
-- SOURCE FILE: sourceCode/DataAccess/ProductRepository.cs
-- =============================================================================

-- ---------------------------------------------------------------------------
-- STATEMENT 1: GetAllProductsAsync()
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Type: SELECT with CTE, Window Functions, CASE, ROUND, INNER JOIN
-- Parameters: None
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- STATEMENT 2: GetProductByIdAsync()
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Type: SELECT with CTE, LAG Window Function, CASE, ROUND, LEFT JOIN
-- Parameters: @ProductId
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- STATEMENT 3: InsertProductAsync()
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Type: Transaction Block (DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY, UPDATE, COMMIT, SELECT)
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- STATEMENT 4: UpdateProductAsync()
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Type: Transaction Block (BEGIN TRANSACTION, DECLARE, SELECT INTO variables, UPDATE, INSERT, COMMIT)
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- STATEMENT 5: DeleteProductAsync()
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Type: Transaction Block (BEGIN TRANSACTION, DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE, COMMIT)
-- Parameters: @ProductId
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- STATEMENT 6: GetProductsByPriceRangeAsync()
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Type: SELECT with CTE, RANK, PERCENT_RANK Window Functions, BETWEEN, CASE
-- Parameters: @MinPrice, @MaxPrice
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- STATEMENT 7: GetLowStockProductsAsync()
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Type: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
-- Parameters: @Threshold
-- ---------------------------------------------------------------------------
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

-- =============================================================================
-- SOURCE FILE: sourceCode/Scripts/01_InitialSetup.sql
-- =============================================================================

-- ---------------------------------------------------------------------------
-- STATEMENT S1: Create Database Check
-- File: sourceCode/Scripts/01_InitialSetup.sql
-- Type: DDL - CREATE DATABASE (conditional)
-- ---------------------------------------------------------------------------
-- IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ProductManagement')
-- BEGIN
--     CREATE DATABASE ProductManagement;
-- END

-- ---------------------------------------------------------------------------
-- STATEMENT S2: Create Products Table
-- File: sourceCode/Scripts/01_InitialSetup.sql
-- Type: DDL - CREATE TABLE (conditional)
-- ---------------------------------------------------------------------------
-- IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Products]') AND type in (N'U'))
-- BEGIN
--     CREATE TABLE [dbo].[Products](
--         [ProductId] [int] IDENTITY(1,1) PRIMARY KEY,
--         [Name] [nvarchar](100) NOT NULL,
--         [Description] [nvarchar](500) NULL,
--         [Price] [decimal](18, 2) NOT NULL,
--         [StockQuantity] [int] NOT NULL,
--         [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
--         [ModifiedDate] [datetime] NULL
--     )
-- END

-- ---------------------------------------------------------------------------
-- STATEMENT S3-S7: Stored Procedures (sp_GetAllProducts, sp_GetProductById, sp_InsertProduct, sp_UpdateProduct, sp_DeleteProduct)
-- File: sourceCode/Scripts/01_InitialSetup.sql
-- Type: DDL - CREATE OR ALTER PROCEDURE
-- ---------------------------------------------------------------------------
-- (These are documented in the script file and will be converted in Step 6)

-- =============================================================================
-- SOURCE FILE: sourceCode/Database/Scripts/01_InitialSetup.sql
-- =============================================================================

-- ---------------------------------------------------------------------------
-- STATEMENT D1-D6: DROP objects (conditional)
-- STATEMENT D7-D11: CREATE TABLEs (Categories, Suppliers, Products, ProductHistory, ProductStats)
-- STATEMENT D12-D16: CREATE INDEXes
-- STATEMENT D17-D21: INSERT sample data
-- STATEMENT D22: UPDATE ProductStats
-- STATEMENT D23: CREATE TRIGGER trg_Products_History
-- STATEMENT D24-D28: CREATE OR ALTER PROCEDURE (stored procedures)
-- File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: Mixed DDL/DML
-- ---------------------------------------------------------------------------
-- (These are documented in the script file and will be converted in Step 6)

-- =============================================================================
-- END OF EXTRACTED STATEMENTS CATALOG
-- Total statements from ProductRepository.cs: 7
-- Total script files identified: 2
-- =============================================================================
