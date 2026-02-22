-- ============================================================================
-- SQL Statement Extraction Catalog
-- Source: Microsoft SQL Server ADO.NET Application
-- Target: PostgreSQL Migration
-- Date: Migration Phase
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Range: 38-71
-- Description: Complex query with CTE (ProductStats), window functions (AVG OVER, COUNT OVER),
--              CASE expressions, and ORDER BY with conditional logic
-- Complexity: High - Contains CTE, multiple window functions, CASE expressions
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync - LAG Window Function
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Range: 85-111
-- Description: Query with CTE using LAG window function to track historical price/stock changes,
--              includes parameterized WHERE clause (@ProductId)
-- Complexity: Medium - Contains CTE, LAG window function, LEFT JOIN, CASE expression
-- Parameters: @ProductId (INT)
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 3: InsertProductAsync - Transaction Block with Multiple Statements
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Range: 125-150
-- Description: Multi-statement transaction block including INSERT with SCOPE_IDENTITY(),
--              audit logging to ProductHistory, and statistics update
-- Complexity: High - Transaction block, SCOPE_IDENTITY(), GETDATE(), multiple INSERTs/UPDATEs
-- Parameters: @Name (VARCHAR), @Description (VARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Critical: Uses SCOPE_IDENTITY() which needs conversion to RETURNING clause in PostgreSQL
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction Block with Variable Storage
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Range: 164-194
-- Description: Transaction block with variable declarations, SELECT to store old values,
--              UPDATE with GETDATE(), audit logging, and statistics update
-- Complexity: High - Transaction block, DECLARE variables, multiple statements
-- Parameters: @ProductId (INT), @Name (VARCHAR), @Description (VARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction Block with Cascading Updates
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Range: 208-239
-- Description: Transaction block with variable storage, audit logging before deletion,
--              DELETE operation, and statistics update with conditional CASE
-- Complexity: High - Transaction block, DECLARE variables, DELETE with audit trail
-- Parameters: @ProductId (INT)
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - RANK and PERCENT_RANK Window Functions
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Range: 253-277
-- Description: CTE with RANK() and PERCENT_RANK() window functions for price analysis,
--              includes CASE expression for price segmentation
-- Complexity: Medium-High - CTE, multiple window functions (RANK, PERCENT_RANK), BETWEEN clause
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - Multiple Window Aggregate Functions
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Range: 291-314
-- Description: CTE with multiple window aggregate functions (AVG, MIN, MAX OVER),
--              complex CASE expression for stock status categorization
-- Complexity: Medium-High - CTE, multiple window aggregates, arithmetic calculations
-- Parameters: @Threshold (INT)
-- ============================================================================

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

-- ============================================================================
-- EXTRACTION SUMMARY
-- ============================================================================
-- Total Statements Extracted: 7
-- Simple SELECT statements: 0
-- CTE-based statements: 5 (Statements 1, 2, 6, 7)
-- Transaction blocks: 3 (Statements 3, 4, 5)
-- Window functions used: AVG OVER, COUNT OVER, LAG OVER, RANK OVER, PERCENT_RANK OVER, MIN OVER, MAX OVER
-- SQL Server specific functions requiring conversion:
--   - SCOPE_IDENTITY() (Statement 3) -> PostgreSQL RETURNING clause
--   - GETDATE() (Statements 3, 4, 5) -> CURRENT_TIMESTAMP or NOW()
-- Parameter syntax: All use @ParamName format (needs conversion to $1, $2, etc. for PostgreSQL)
-- ============================================================================
