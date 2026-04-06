-- =============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: AdoCore Application - MS SQL Server to PostgreSQL Migration
-- Generated: 2026-04-06
-- =============================================================================
-- This file catalogs all SQL statements extracted from the codebase for
-- conversion from MS SQL Server syntax to PostgreSQL syntax.
-- =============================================================================

-- =============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line: ~43-66
-- Parameters: None
-- Description: CTE-based SELECT with window functions (AVG OVER, COUNT OVER),
--              CASE expressions, ROUND, INNER JOIN, ORDER BY with CASE
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line: ~76-99
-- Parameters: @ProductId (INT)
-- Description: CTE-based SELECT with LAG window function, CASE with NULL checks,
--              ROUND, LEFT JOIN, parameterized WHERE clause
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 3: InsertProductAsync
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line: ~113-135
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Description: Transaction block with DECLARE, BEGIN TRANSACTION/COMMIT,
--              INSERT INTO Products, SCOPE_IDENTITY(), INSERT INTO ProductHistory
--              with GETDATE(), UPDATE ProductStats, SELECT @NewProductId
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 4: UpdateProductAsync
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line: ~149-176
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR),
--             @Price (DECIMAL), @StockQuantity (INT)
-- Description: Transaction block with DECLARE, BEGIN TRANSACTION/COMMIT,
--              SELECT into variables, UPDATE Products with GETDATE(),
--              INSERT INTO ProductHistory, UPDATE ProductStats
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 5: DeleteProductAsync
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line: ~186-213
-- Parameters: @ProductId (INT)
-- Description: Transaction block with DECLARE, BEGIN TRANSACTION/COMMIT,
--              SELECT into variables, INSERT INTO ProductHistory with GETDATE(),
--              DELETE FROM Products, UPDATE ProductStats with CASE expression
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line: ~222-241
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Description: CTE with RANK() OVER, PERCENT_RANK() OVER, BETWEEN clause,
--              CASE for PriceSegment, parameterized
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line: ~255-275
-- Parameters: @Threshold (INT)
-- Description: CTE with AVG/MIN/MAX OVER window functions, CASE for StockStatus,
--              ROUND, parameterized, WHERE and ORDER BY
-- =============================================================================

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
-- ADDITIONAL REFERENCES: Database Setup Scripts
-- =============================================================================
-- The following DDL and seed data statements are found in the setup scripts.
-- These are NOT inline SQL in the application code but are documented here
-- for completeness of the migration catalog.
--
-- Source Files:
--   - sourceCode/Scripts/01_InitialSetup.sql
--   - sourceCode/Database/Scripts/01_InitialSetup.sql
--
-- These scripts contain:
--   - CREATE DATABASE ProductManagement
--   - CREATE TABLE Products, ProductHistory, ProductStats, Categories, Suppliers
--   - CREATE INDEX statements
--   - CREATE TRIGGER trg_Products_History
--   - CREATE/ALTER PROCEDURE sp_GetAllProducts, sp_GetProductById,
--     sp_InsertProduct, sp_UpdateProduct, sp_DeleteProduct
--   - INSERT sample data for Categories, Suppliers, Products, ProductStats
--   - UPDATE ProductStats initial statistics
--
-- Note: These DDL statements are handled separately by DMS schema migration
-- and are not part of the application code SQL conversion.
-- =============================================================================
