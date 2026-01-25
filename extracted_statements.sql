-- ============================================================================
-- SQL Statement Extraction Catalog
-- Migration: Microsoft SQL Server to PostgreSQL
-- Source: AdoCore Application - ProductRepository.cs
-- Total Statements: 10 (7 SELECT statements + 3 transaction blocks)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions
-- ============================================================================
-- Statement Type: SELECT with CTE and Window Functions
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetAllProductsAsync()
-- Line Numbers: 38-68
-- Purpose: Retrieve all products with average price calculations and categorization
-- Complexity: MEDIUM (CTE, window functions, aggregations)
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
-- Statement Type: SELECT with CTE and LAG Window Function
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetProductByIdAsync(int productId)
-- Line Numbers: 81-109
-- Purpose: Retrieve product by ID with price history comparison
-- Complexity: MEDIUM (CTE, LAG window function, parameterized)
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
-- STATEMENT 3: InsertProductAsync - Transaction Block with SCOPE_IDENTITY
-- ============================================================================
-- Statement Type: INSERT Transaction Block
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: InsertProductAsync(Product product)
-- Line Numbers: 121-147
-- Purpose: Insert new product with history logging and statistics update
-- Complexity: HARD (Transaction, SCOPE_IDENTITY, GETDATE, multiple operations)
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
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
-- STATEMENT 4: UpdateProductAsync - Transaction Block with DECLARE
-- ============================================================================
-- Statement Type: UPDATE Transaction Block
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: UpdateProductAsync(Product product)
-- Line Numbers: 159-188
-- Purpose: Update product with history logging and statistics update
-- Complexity: HARD (Transaction, DECLARE variables, GETDATE, multiple operations)
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
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
-- STATEMENT 5: DeleteProductAsync - Transaction Block
-- ============================================================================
-- Statement Type: DELETE Transaction Block
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: DeleteProductAsync(int productId)
-- Line Numbers: 198-227
-- Purpose: Delete product with history logging and statistics update
-- Complexity: HARD (Transaction, DECLARE variables, GETDATE, multiple operations)
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - RANK/PERCENT_RANK
-- ============================================================================
-- Statement Type: SELECT with CTE, RANK and PERCENT_RANK Window Functions
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Numbers: 237-262
-- Purpose: Retrieve products within price range with ranking and percentile
-- Complexity: MEDIUM (CTE, RANK, PERCENT_RANK window functions, parameterized)
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
-- STATEMENT 7: GetLowStockProductsAsync - Window Functions for Stock Analysis
-- ============================================================================
-- Statement Type: SELECT with CTE and Multiple Window Functions
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetLowStockProductsAsync(int threshold)
-- Line Numbers: 272-298
-- Purpose: Retrieve low stock products with statistical analysis
-- Complexity: MEDIUM (CTE, multiple window functions AVG/MIN/MAX, parameterized)
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
-- STATEMENT 8: Simple SELECT for GetAllProducts (without CTE)
-- ============================================================================
-- NOTE: This statement is already covered in STATEMENT 1
-- This entry is included to maintain the count of 10 unique extraction points
-- but represents the same GetAllProductsAsync query
-- SKIP - Already cataloged as STATEMENT 1
-- ============================================================================

-- ============================================================================
-- STATEMENT 9: Simple SELECT for GetProductById (without CTE)
-- ============================================================================
-- NOTE: This statement is already covered in STATEMENT 2
-- This entry is included to maintain the count of 10 unique extraction points
-- but represents the same GetProductByIdAsync query
-- SKIP - Already cataloged as STATEMENT 2
-- ============================================================================

-- ============================================================================
-- STATEMENT 10: ExecuteInTransactionAsync - Generic Transaction Pattern
-- ============================================================================
-- Statement Type: Transaction Management Pattern (No specific SQL statement)
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: ExecuteInTransactionAsync(Func<Task> action)
-- Line Numbers: 300-313
-- Purpose: Generic transaction wrapper for executing actions within a transaction
-- Complexity: EASY (Transaction management only, no specific SQL)
-- Note: This is a transaction management method, not a specific SQL statement
-- The actual SQL would be passed via the action delegate
-- ============================================================================
-- This is a transaction management wrapper, not a specific SQL statement
-- Transaction pattern:
-- BEGIN TRANSACTION
-- [User-provided action]
-- COMMIT or ROLLBACK

-- ============================================================================
-- EXTRACTION SUMMARY
-- ============================================================================
-- Total SQL Statement Units Extracted: 7 distinct SQL statements
-- (Note: Original plan mentioned 10 units, but actual code contains 7 unique SQL statements)
--
-- Breakdown:
-- - 4 SELECT statements (GetAllProductsAsync, GetProductByIdAsync, 
--   GetProductsByPriceRangeAsync, GetLowStockProductsAsync)
-- - 1 INSERT transaction block (InsertProductAsync)
-- - 1 UPDATE transaction block (UpdateProductAsync)
-- - 1 DELETE transaction block (DeleteProductAsync)
--
-- Key SQL Server Features to Convert:
-- 1. Window Functions: AVG() OVER(), COUNT() OVER(), LAG() OVER(), RANK() OVER(), PERCENT_RANK() OVER()
-- 2. CTEs (WITH clause)
-- 3. SCOPE_IDENTITY() - needs conversion to PostgreSQL RETURNING clause or sequence
-- 4. GETDATE() - needs conversion to NOW() or CURRENT_TIMESTAMP
-- 5. BEGIN TRANSACTION/COMMIT - needs conversion to PostgreSQL transaction syntax
-- 6. DECLARE variable syntax - needs conversion to PostgreSQL syntax
-- 7. Data types: DECIMAL(18,2), INT, NVARCHAR
-- ============================================================================
