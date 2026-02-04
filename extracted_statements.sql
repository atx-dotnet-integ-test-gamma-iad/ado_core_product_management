-- ============================================================================
-- EXTRACTED SQL STATEMENTS FROM PRODUCTREPOSITORY.CS
-- Microsoft SQL Server to PostgreSQL Migration
-- Source File: DataAccess/ProductRepository.cs
-- Extraction Date: 2026-02-04
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Source Method: GetAllProductsAsync()
-- Line Numbers: 41-67
-- Statement Type: SELECT with CTE
-- Parameters: None
-- SQL Server Specific Syntax:
--   - AVG() OVER() window function
--   - COUNT(*) OVER() window function
--   - CASE expressions
--   - ROUND() function
-- Description: Retrieves all products with price statistics using CTE and window functions
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
-- STATEMENT 2: GetProductByIdAsync
-- ============================================================================
-- Source Method: GetProductByIdAsync(int productId)
-- Line Numbers: 81-109
-- Statement Type: SELECT with CTE and LAG window function
-- Parameters: @ProductId (int)
-- SQL Server Specific Syntax:
--   - LAG() OVER() window function
--   - CTE (Common Table Expression)
--   - IS NOT NULL check
--   - ROUND() function
--   - Parameterized query with @ProductId
-- Description: Retrieves a product by ID with historical price comparison using LAG window function
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
-- STATEMENT 3: InsertProductAsync
-- ============================================================================
-- Source Method: InsertProductAsync(Product product)
-- Line Numbers: 121-144
-- Statement Type: TRANSACTION with INSERT, UPDATE, SELECT
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- SQL Server Specific Syntax:
--   - BEGIN TRANSACTION/COMMIT
--   - DECLARE @Variable syntax
--   - SCOPE_IDENTITY() function (returns last identity value)
--   - GETDATE() function (current timestamp)
--   - Multi-statement transaction block
--   - SET variable assignment
-- Description: Inserts a new product and logs history within a transaction
-- Tables Referenced: Products, ProductHistory, ProductStats
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
-- STATEMENT 4: UpdateProductAsync
-- ============================================================================
-- Source Method: UpdateProductAsync(Product product)
-- Line Numbers: 158-189
-- Statement Type: TRANSACTION with SELECT, UPDATE, INSERT
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- SQL Server Specific Syntax:
--   - BEGIN TRANSACTION/COMMIT
--   - DECLARE @Variable syntax (DECIMAL, INT)
--   - SELECT with multiple variable assignment
--   - GETDATE() function (3 occurrences)
--   - Multi-statement transaction block
-- Description: Updates a product and logs changes to history and stats
-- Tables Referenced: Products, ProductHistory, ProductStats
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
-- STATEMENT 5: DeleteProductAsync
-- ============================================================================
-- Source Method: DeleteProductAsync(int productId)
-- Line Numbers: 199-230
-- Statement Type: TRANSACTION with SELECT, INSERT, DELETE, UPDATE with CASE
-- Parameters: @ProductId
-- SQL Server Specific Syntax:
--   - BEGIN TRANSACTION/COMMIT
--   - DECLARE @Variable syntax (DECIMAL, INT)
--   - SELECT with multiple variable assignment
--   - GETDATE() function (2 occurrences)
--   - CASE expression in UPDATE SET clause
--   - Multi-statement transaction block
-- Description: Deletes a product with history logging and statistics update
-- Tables Referenced: Products, ProductHistory, ProductStats
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
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ============================================================================
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Numbers: 241-267
-- Statement Type: SELECT with CTE and window functions
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- SQL Server Specific Syntax:
--   - CTE (Common Table Expression)
--   - RANK() OVER() window function
--   - PERCENT_RANK() OVER() window function
--   - BETWEEN clause for range filtering
--   - CASE expression for segmentation
-- Description: Retrieves products within a price range with ranking and percentile
-- Tables Referenced: Products
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
-- STATEMENT 7: GetLowStockProductsAsync
-- ============================================================================
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Line Numbers: 277-303
-- Statement Type: SELECT with CTE and multiple window functions
-- Parameters: @Threshold (int)
-- SQL Server Specific Syntax:
--   - CTE (Common Table Expression)
--   - AVG() OVER() window function
--   - MIN() OVER() window function
--   - MAX() OVER() window function
--   - CASE expression with calculations
--   - ROUND() function
-- Description: Retrieves low stock products with stock analysis metrics
-- Tables Referenced: Products
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
-- Total SQL Statements Extracted: 7
-- Statements with CTEs: 5 (Statements 1, 2, 6, 7, and transactions)
-- Statements with Window Functions: 5 (Statements 1, 2, 6, 7)
-- Transaction Blocks: 3 (Statements 3, 4, 5)
-- Parameterized Queries: 6 (Statements 2, 3, 4, 5, 6, 7)
-- 
-- SQL Server Specific Functions Identified:
-- - SCOPE_IDENTITY(): 1 occurrence (Statement 3)
-- - GETDATE(): 8 occurrences (Statements 3, 4, 5)
-- - ROUND(): 4 occurrences (Statements 1, 2, 7)
-- - RANK(): 1 occurrence (Statement 6)
-- - PERCENT_RANK(): 1 occurrence (Statement 6)
-- - LAG(): 2 occurrences (Statement 2)
-- - AVG() OVER(): 2 occurrences (Statements 1, 7)
-- - COUNT() OVER(): 1 occurrence (Statement 1)
-- - MIN() OVER(): 1 occurrence (Statement 7)
-- - MAX() OVER(): 1 occurrence (Statement 7)
-- 
-- Tables Referenced:
-- - Products: All statements
-- - ProductHistory: Statements 3, 4, 5
-- - ProductStats: Statements 3, 4, 5
-- 
-- Key Migration Considerations:
-- 1. SCOPE_IDENTITY() must be converted to RETURNING clause in PostgreSQL
-- 2. GETDATE() must be converted to NOW() or CURRENT_TIMESTAMP
-- 3. Variable declarations (DECLARE @Variable) need PostgreSQL DO block or function
-- 4. Transaction syntax may need adjustment
-- 5. Window functions should be compatible but verify syntax
-- 6. Parameter syntax (@param) needs to be converted to PostgreSQL format ($1, $2, etc.)
-- ============================================================================
