/*
 * Extracted SQL Statements from Microsoft SQL Server to PostgreSQL Migration
 * Source Application: AdoCore - Product Management System
 * Extraction Date: 2026-02-18
 * Total Statements: 7
 * 
 * This file contains all SQL statements extracted from the codebase for conversion to PostgreSQL.
 * Each statement includes complete metadata: source file, method name, line numbers, parameters, and full SQL text.
 */

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ================================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: GetAllProductsAsync
-- Line Numbers: 41-68
-- Parameters: None
-- Description: Retrieves all products with pricing statistics using CTE, window functions (AVG, COUNT OVER), 
--              and CASE statements for categorization
-- Transaction Block: No
-- SQL Statement:
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

-- ================================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ================================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: GetProductByIdAsync
-- Line Numbers: 81-108
-- Parameters: 
--   @ProductId (int) - The ID of the product to retrieve
-- Description: Retrieves a product by ID with historical price/stock comparison using CTE and LAG window function
-- Transaction Block: No
-- SQL Statement:
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

-- ================================================================================
-- STATEMENT 3: InsertProductAsync - Transaction with SCOPE_IDENTITY and GETDATE
-- ================================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: InsertProductAsync
-- Line Numbers: 122-147
-- Parameters:
--   @Name (string) - Product name
--   @Description (string, nullable) - Product description
--   @Price (decimal) - Product price
--   @StockQuantity (int) - Initial stock quantity
-- Description: Inserts a new product within a transaction, logs to history, updates statistics, 
--              uses SCOPE_IDENTITY() to get new ID and GETDATE() for timestamps
-- Transaction Block: Yes (BEGIN TRANSACTION...COMMIT)
-- SQL Statement:
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

-- ================================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction with Variable Declarations
-- ================================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: UpdateProductAsync
-- Line Numbers: 162-190
-- Parameters:
--   @ProductId (int) - Product ID to update
--   @Name (string) - Updated product name
--   @Description (string, nullable) - Updated product description
--   @Price (decimal) - Updated product price
--   @StockQuantity (int) - Updated stock quantity
-- Description: Updates product with transaction, stores old values in variables, logs to history, 
--              updates statistics, uses GETDATE() for timestamps
-- Transaction Block: Yes (BEGIN TRANSACTION...COMMIT)
-- SQL Statement:
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

-- ================================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction with Conditional Logic
-- ================================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: DeleteProductAsync
-- Line Numbers: 204-233
-- Parameters:
--   @ProductId (int) - Product ID to delete
-- Description: Deletes product within transaction, logs to history, updates statistics with conditional 
--              CASE statement, uses GETDATE() for timestamps
-- Transaction Block: Yes (BEGIN TRANSACTION...COMMIT)
-- SQL Statement:
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

-- ================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ================================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: GetProductsByPriceRangeAsync
-- Line Numbers: 248-266
-- Parameters:
--   @MinPrice (decimal) - Minimum price for range filter
--   @MaxPrice (decimal) - Maximum price for range filter
-- Description: Retrieves products in price range with ranking using CTE, RANK() and PERCENT_RANK() 
--              window functions, and CASE statement for segmentation
-- Transaction Block: No
-- SQL Statement:
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

-- ================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ================================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: GetLowStockProductsAsync
-- Line Numbers: 281-303
-- Parameters:
--   @Threshold (int) - Stock quantity threshold for low stock determination
-- Description: Retrieves low stock products with statistical analysis using CTE, multiple window functions 
--              (AVG, MIN, MAX OVER), CASE statement for status, and percentage calculations
-- Transaction Block: No
-- SQL Statement:
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

-- ================================================================================
-- END OF EXTRACTED STATEMENTS
-- ================================================================================
-- Summary:
-- Total SQL Statements Extracted: 7
-- Statements with Transactions: 3 (InsertProductAsync, UpdateProductAsync, DeleteProductAsync)
-- Statements with CTEs: 5 (GetAllProductsAsync, GetProductByIdAsync, GetProductsByPriceRangeAsync, GetLowStockProductsAsync)
-- Statements with Window Functions: 5
-- Statements with CASE Expressions: 5
-- Key SQL Server Features Used: SCOPE_IDENTITY(), GETDATE(), LAG(), RANK(), PERCENT_RANK(), AVG() OVER, COUNT() OVER
-- ================================================================================
