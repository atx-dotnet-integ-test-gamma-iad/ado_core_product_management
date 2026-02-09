-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Date: 2025-02-09
-- ============================================================================
-- This file catalogs ALL SQL statements extracted from the AdoCore application
-- for processing through the DMS MCP tool. Each statement is documented with:
-- - Statement ID
-- - Source file location
-- - Method name
-- - Line number range
-- - Original SQL Server syntax
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- Source: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Lines: 38-68
-- Description: Uses CTE with AVG() OVER(), COUNT() OVER() window functions, CASE expressions
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
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- Source: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Lines: 78-110
-- Description: Uses CTE with LAG() OVER() window function, parameterized query (@ProductId)
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
-- Source: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Lines: 120-147
-- Description: Transaction block with SCOPE_IDENTITY(), GETDATE() functions, parameterized queries
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
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction Block
-- Source: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Lines: 157-192
-- Description: Transaction block with variable declarations, UPDATE statements, GETDATE() function
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
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction Block
-- Source: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Lines: 202-236
-- Description: Transaction block with DELETE, INSERT, UPDATE statements, CASE expression, GETDATE()
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK Window Functions
-- Source: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Lines: 246-270
-- Description: Uses CTE with RANK() OVER(), PERCENT_RANK() OVER() window functions, BETWEEN clause
-- Parameters: @MinPrice, @MaxPrice
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
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- Source: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Lines: 280-307
-- Description: Uses CTE with AVG() OVER(), MIN() OVER(), MAX() OVER() window functions
-- Parameters: @Threshold
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
-- SUMMARY OF EXTRACTED STATEMENTS
-- ============================================================================
-- Total SQL Statements Extracted: 7
--
-- Statement Categories:
-- - Complex CTEs with Window Functions: 4 statements (1, 2, 6, 7)
-- - Multi-Statement Transaction Blocks: 3 statements (3, 4, 5)
--
-- SQL Server Specific Functions Identified:
-- - SCOPE_IDENTITY(): Used in Statement 3 (InsertProductAsync)
-- - GETDATE(): Used in Statements 3, 4, 5 (InsertProductAsync, UpdateProductAsync, DeleteProductAsync)
-- - LAG() OVER(): Used in Statement 2 (GetProductByIdAsync)
-- - RANK() OVER(): Used in Statement 6 (GetProductsByPriceRangeAsync)
-- - PERCENT_RANK() OVER(): Used in Statement 6 (GetProductsByPriceRangeAsync)
-- - AVG() OVER(): Used in Statements 1, 7 (GetAllProductsAsync, GetLowStockProductsAsync)
-- - COUNT() OVER(): Used in Statement 1 (GetAllProductsAsync)
-- - MIN() OVER(): Used in Statement 7 (GetLowStockProductsAsync)
-- - MAX() OVER(): Used in Statement 7 (GetLowStockProductsAsync)
--
-- Parameterized Queries:
-- - Statement 1: No parameters
-- - Statement 2: @ProductId
-- - Statement 3: @Name, @Description, @Price, @StockQuantity
-- - Statement 4: @ProductId, @Name, @Description, @Price, @StockQuantity
-- - Statement 5: @ProductId
-- - Statement 6: @MinPrice, @MaxPrice
-- - Statement 7: @Threshold
--
-- NEXT STEPS:
-- 1. Pass each statement through DMS MCP tool (dms-mcp____statement_conversion_tool)
-- 2. Document conversion results in converted_statements.sql
-- 3. Validate each statement pair with SQL Equivalency MCP tool
-- 4. Re-integrate converted statements into ProductRepository.cs
-- ============================================================================

-- ============================================================================
-- ADDENDUM: POST-MIGRATION REFACTORING (2025-02-09)
-- ============================================================================
-- STATEMENT 4 (UpdateProductAsync) and STATEMENT 5 (DeleteProductAsync) have been
-- refactored to use application-level transaction management instead of SQL Server
-- specific syntax (BEGIN TRANSACTION, DECLARE @variable, SELECT @var = value, COMMIT).
--
-- The SQL Server-specific transaction blocks with embedded variable declarations
-- were incompatible with PostgreSQL. These have been decomposed into separate
-- PostgreSQL-compatible SQL statements executed within application-managed
-- transactions using NpgsqlConnection.BeginTransactionAsync().
--
-- REFACTORED STATEMENT 4A: UpdateProductAsync - SELECT for old values
-- ============================================================================
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- ============================================================================
-- REFACTORED STATEMENT 4B: UpdateProductAsync - UPDATE product
-- ============================================================================
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = NOW()
WHERE ProductId = @ProductId;

-- ============================================================================
-- REFACTORED STATEMENT 4C: UpdateProductAsync - INSERT history
-- ============================================================================
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- ============================================================================
-- REFACTORED STATEMENT 4D: UpdateProductAsync - UPDATE statistics
-- ============================================================================
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- REFACTORED STATEMENT 5A: DeleteProductAsync - SELECT for old values
-- ============================================================================
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- ============================================================================
-- REFACTORED STATEMENT 5B: DeleteProductAsync - INSERT history
-- ============================================================================
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- ============================================================================
-- REFACTORED STATEMENT 5C: DeleteProductAsync - DELETE product
-- ============================================================================
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- ============================================================================
-- REFACTORED STATEMENT 5D: DeleteProductAsync - UPDATE statistics
-- ============================================================================
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- REFACTORING SUMMARY
-- ============================================================================
-- Original Statement 4 (UpdateProductAsync): Split into 4 separate SQL statements (4A-4D)
-- Original Statement 5 (DeleteProductAsync): Split into 4 separate SQL statements (5A-5D)
--
-- Key Changes:
-- 1. Removed SQL Server-specific "BEGIN TRANSACTION" and "COMMIT" from SQL strings
-- 2. Removed SQL Server-specific variable declarations "DECLARE @variable"
-- 3. Removed SQL Server-specific variable assignments "SELECT @var = value"
-- 4. Converted GETDATE() to NOW() for PostgreSQL compatibility
-- 5. Implemented application-level transaction management using:
--    - NpgsqlConnection.BeginTransactionAsync()
--    - NpgsqlTransaction.CommitAsync()
--    - NpgsqlTransaction.RollbackAsync()
--
-- Transaction Atomicity: Maintained through application-level transaction management
-- PostgreSQL Compatibility: All SQL statements now use standard PostgreSQL syntax
-- ============================================================================
