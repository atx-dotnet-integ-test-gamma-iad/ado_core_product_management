-- ============================================================================
-- SQL STATEMENT EXTRACTION CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- ADO.NET Application: AdoCore
-- ============================================================================
-- This file contains all extracted SQL statements from the application code
-- Each statement is documented with:
--   - Statement Number
--   - Source File Path
--   - Line Number Range
--   - Method Name
--   - Statement Type
--   - SQL Syntax Patterns Used
--   - Full SQL Text
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Range: 40-68
-- Method: GetAllProductsAsync()
-- Statement Type: SELECT
-- Syntax Patterns: 
--   - Common Table Expression (CTE) - WITH clause
--   - Window Functions: AVG() OVER(), COUNT() OVER()
--   - CASE expressions
--   - INNER JOIN
--   - Complex ORDER BY with CASE
-- Parameters: None
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
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Range: 78-107
-- Method: GetProductByIdAsync(int productId)
-- Statement Type: SELECT
-- Syntax Patterns:
--   - Common Table Expression (CTE) - WITH clause
--   - Window Function: LAG() OVER (ORDER BY)
--   - LEFT JOIN
--   - CASE expressions with NULL handling
--   - Parameterized query (@ProductId)
-- Parameters: @ProductId (int)
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
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction Block
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Range: 117-144
-- Method: InsertProductAsync(Product product)
-- Statement Type: TRANSACTION (INSERT/UPDATE)
-- Syntax Patterns:
--   - Transaction Block: BEGIN TRANSACTION ... COMMIT
--   - Variable Declaration: DECLARE
--   - Variable Assignment: SET with SCOPE_IDENTITY()
--   - INSERT statements (multiple)
--   - UPDATE statement
--   - GETDATE() function
--   - Final SELECT to return value
-- Parameters: @Name, @Description, @Price, @StockQuantity
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
-- STATEMENT 4: UpdateProductAsync - Transaction with Variable Storage
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Range: 157-188
-- Method: UpdateProductAsync(Product product)
-- Statement Type: TRANSACTION (UPDATE/INSERT)
-- Syntax Patterns:
--   - Transaction Block: BEGIN TRANSACTION ... COMMIT
--   - Variable Declaration: DECLARE (multiple)
--   - SELECT into variables
--   - UPDATE statement
--   - INSERT statement
--   - GETDATE() function
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
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
-- STATEMENT 5: DeleteProductAsync - Transaction with Conditional Logic
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Range: 198-229
-- Method: DeleteProductAsync(int productId)
-- Statement Type: TRANSACTION (INSERT/DELETE/UPDATE)
-- Syntax Patterns:
--   - Transaction Block: BEGIN TRANSACTION ... COMMIT
--   - Variable Declaration: DECLARE (multiple)
--   - SELECT into variables
--   - INSERT statement
--   - DELETE statement
--   - UPDATE statement with CASE expression
--   - GETDATE() function
-- Parameters: @ProductId
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - RANK and PERCENT_RANK
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Range: 239-264
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Statement Type: SELECT
-- Syntax Patterns:
--   - Common Table Expression (CTE) - WITH clause
--   - Window Functions: RANK() OVER (ORDER BY), PERCENT_RANK() OVER (ORDER BY)
--   - BETWEEN clause
--   - CASE expressions
--   - Parameterized query (@MinPrice, @MaxPrice)
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
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
-- STATEMENT 7: GetLowStockProductsAsync - Multiple Window Aggregations
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Range: 274-300
-- Method: GetLowStockProductsAsync(int threshold)
-- Statement Type: SELECT
-- Syntax Patterns:
--   - Common Table Expression (CTE) - WITH clause
--   - Window Functions: AVG() OVER(), MIN() OVER(), MAX() OVER()
--   - CASE expressions with arithmetic operations
--   - ROUND function
--   - Parameterized query (@Threshold)
-- Parameters: @Threshold (int)
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
-- 
-- Statement Type Breakdown:
--   - SELECT queries: 4 (Statements 1, 2, 6, 7)
--   - Transaction blocks: 3 (Statements 3, 4, 5)
--
-- SQL Syntax Patterns Identified:
--   - Common Table Expressions (CTEs): 5 statements
--   - Window Functions: 6 statements
--     * AVG() OVER(): Statements 1, 7
--     * COUNT() OVER(): Statement 1
--     * LAG() OVER(): Statement 2
--     * RANK() OVER(): Statement 6
--     * PERCENT_RANK() OVER(): Statement 6
--     * MIN() OVER(): Statement 7
--     * MAX() OVER(): Statement 7
--   - Transaction blocks (BEGIN...COMMIT): Statements 3, 4, 5
--   - CASE expressions: Statements 1, 2, 5, 6, 7
--   - SCOPE_IDENTITY(): Statement 3
--   - GETDATE(): Statements 3, 4, 5
--   - Parameterized queries: Statements 2, 3, 4, 5, 6, 7
--
-- All statements ready for DMS MCP tool conversion
-- ============================================================================
