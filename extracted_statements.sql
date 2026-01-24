-- ============================================================================
-- EXTRACTED SQL STATEMENTS FROM SQL SERVER TO POSTGRESQL MIGRATION
-- ============================================================================
-- Project: AdoCore - Product Management System
-- Source Database: Microsoft SQL Server
-- Target Database: PostgreSQL
-- Extraction Date: 2026-01-24
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - Product List with Price Statistics
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Numbers: 42-67
-- Parameters: None
-- Description: CTE with window functions (AVG, COUNT OVER) and CASE statements
--              to categorize products by price relative to average
-- SQL Syntax Features:
--   - Common Table Expression (CTE)
--   - Window Functions: AVG() OVER(), COUNT(*) OVER()
--   - CASE expressions for conditional logic
--   - INNER JOIN with CTE
--   - ROUND() function for decimal precision
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
-- STATEMENT 2: GetProductByIdAsync - Product Details with History
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Numbers: 77-103
-- Parameters: @ProductId (INT)
-- Description: CTE with LAG window function to retrieve previous price and stock
--              for comparison and percentage calculation
-- SQL Syntax Features:
--   - Common Table Expression (CTE)
--   - Window Functions: LAG() OVER (ORDER BY)
--   - CASE expression for NULL handling
--   - LEFT JOIN with CTE
--   - ROUND() function for percentage calculation
--   - Parameterized query with @ProductId
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
-- STATEMENT 3: InsertProductAsync - Multi-statement Transaction Insert
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Numbers: 117-142
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Description: Transaction block that inserts a product, logs to history, and updates statistics
-- SQL Syntax Features:
--   - DECLARE statement for variables
--   - BEGIN TRANSACTION/COMMIT block
--   - SCOPE_IDENTITY() function (SQL Server specific)
--   - GETDATE() function (SQL Server specific)
--   - Multiple INSERT and UPDATE statements in transaction
--   - Variable assignment with SET
--   - Final SELECT to return new ID
-- Tables Involved: Products, ProductHistory, ProductStats
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
-- STATEMENT 4: UpdateProductAsync - Multi-statement Transaction Update
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Numbers: 158-187
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), 
--             @Price (DECIMAL), @StockQuantity (INT)
-- Description: Transaction block that updates product, logs to history, and updates statistics
-- SQL Syntax Features:
--   - DECLARE statements for multiple variables
--   - BEGIN TRANSACTION/COMMIT block
--   - GETDATE() function (SQL Server specific)
--   - Variable assignment from SELECT query
--   - UPDATE and INSERT statements in transaction
-- Tables Involved: Products, ProductHistory, ProductStats
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
-- STATEMENT 5: DeleteProductAsync - Multi-statement Transaction Delete
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Numbers: 201-232
-- Parameters: @ProductId (INT)
-- Description: Transaction block that logs deletion, deletes product, and updates statistics
-- SQL Syntax Features:
--   - DECLARE statements for variables
--   - BEGIN TRANSACTION/COMMIT block
--   - GETDATE() function (SQL Server specific)
--   - DELETE statement
--   - CASE expression in UPDATE
--   - Variable assignment from SELECT query
-- Tables Involved: Products, ProductHistory, ProductStats
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - Price Range with Ranking
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Numbers: 242-265
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Description: CTE with RANK() and PERCENT_RANK() window functions for price analysis
-- SQL Syntax Features:
--   - Common Table Expression (CTE)
--   - Window Functions: RANK() OVER, PERCENT_RANK() OVER
--   - BETWEEN operator for range filtering
--   - CASE expression for segmentation
--   - Parameterized query with range parameters
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
-- STATEMENT 7: GetLowStockProductsAsync - Low Stock Analysis
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Numbers: 275-302
-- Parameters: @Threshold (INT)
-- Description: CTE with AVG, MIN, MAX window functions for stock analysis
-- SQL Syntax Features:
--   - Common Table Expression (CTE)
--   - Window Functions: AVG() OVER(), MIN() OVER(), MAX() OVER()
--   - CASE expression for status categorization
--   - ROUND() function for percentage calculation
--   - WHERE clause filtering based on threshold
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
-- Statements with CTEs: 5 (Statements 1, 2, 6, 7)
-- Statements with Transactions: 3 (Statements 3, 4, 5)
-- Statements with Window Functions: 5 (Statements 1, 2, 6, 7)
-- SQL Server Specific Functions to Convert:
--   - SCOPE_IDENTITY() (Statement 3) -> PostgreSQL RETURNING clause
--   - GETDATE() (Statements 3, 4, 5) -> PostgreSQL NOW() or CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION/COMMIT (Statements 3, 4, 5) -> PostgreSQL transaction syntax
--   - DECLARE with SET (Statement 3) -> PostgreSQL variable handling
-- Tables Referenced: Products, ProductHistory, ProductStats
-- ============================================================================
