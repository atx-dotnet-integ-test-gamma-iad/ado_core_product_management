/*
==================================================================================
SQL STATEMENT EXTRACTION CATALOG
Microsoft SQL Server to PostgreSQL Migration
ADO.NET Application - AdoCore
==================================================================================
Date: 2026-02-11
Source File: DataAccess/ProductRepository.cs
Total Statements Extracted: 7
==================================================================================
*/

-- ==============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ==============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 39-71
-- Method: GetAllProductsAsync()
-- Statement Type: SELECT with CTE
-- Complexity: HIGH - Uses CTE, Window Functions (AVG OVER, COUNT OVER), CASE expressions
-- Parameters: None
-- Description: Retrieves all products with price statistics using window functions
--              to calculate average price and categorize products relative to average.
-- ==============================================================================

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
    p.Name

-- ==============================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ==============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 79-110
-- Method: GetProductByIdAsync(int productId)
-- Statement Type: SELECT with CTE
-- Complexity: MEDIUM - Uses CTE, LAG window function for historical data
-- Parameters: @ProductId (INT)
-- Description: Retrieves a single product with historical price and stock changes
--              using LAG window function to access previous values.
-- ==============================================================================

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
WHERE p.ProductId = @ProductId

-- ==============================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction with SCOPE_IDENTITY
-- ==============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 120-147
-- Method: InsertProductAsync(Product product)
-- Statement Type: TRANSACTION (INSERT, INSERT, UPDATE)
-- Complexity: HIGH - Multi-statement transaction with SCOPE_IDENTITY(), GETDATE()
-- Parameters: @Name (VARCHAR), @Description (VARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Description: Inserts a new product and logs the action in ProductHistory table.
--              Uses SCOPE_IDENTITY() to get the newly inserted product ID.
--              Updates ProductStats table with new statistics.
-- SQL Server Specific: SCOPE_IDENTITY(), GETDATE(), BEGIN TRANSACTION/COMMIT syntax
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction with DECLARE, SELECT, UPDATE, INSERT
-- ==============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 157-190
-- Method: UpdateProductAsync(Product product)
-- Statement Type: TRANSACTION (DECLARE, SELECT, UPDATE, INSERT, UPDATE)
-- Complexity: HIGH - Multi-statement transaction with variable declarations
-- Parameters: @ProductId (INT), @Name (VARCHAR), @Description (VARCHAR), 
--             @Price (DECIMAL), @StockQuantity (INT)
-- Description: Updates an existing product, logs changes to ProductHistory,
--              and updates ProductStats table with recalculated averages.
-- SQL Server Specific: DECLARE, GETDATE(), BEGIN TRANSACTION/COMMIT syntax
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction with DELETE and Statistics UPDATE
-- ==============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 198-233
-- Method: DeleteProductAsync(int productId)
-- Statement Type: TRANSACTION (DECLARE, SELECT, INSERT, DELETE, UPDATE)
-- Complexity: HIGH - Multi-statement transaction with cascading statistics updates
-- Parameters: @ProductId (INT)
-- Description: Deletes a product, logs the deletion to ProductHistory,
--              and updates ProductStats with recalculated statistics.
--              Handles edge case when TotalProducts becomes 0 or 1.
-- SQL Server Specific: DECLARE, GETDATE(), BEGIN TRANSACTION/COMMIT syntax
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ==============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 241-267
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Statement Type: SELECT with CTE
-- Complexity: MEDIUM - Uses CTE with RANK and PERCENT_RANK window functions
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Description: Retrieves products within a price range with ranking and percentile
--              information. Categorizes products into Budget, Mid-Range, and Premium
--              segments based on price percentile.
-- ==============================================================================

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
ORDER BY rp.PriceRank

-- ==============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Aggregate Window Functions
-- ==============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 275-303
-- Method: GetLowStockProductsAsync(int threshold)
-- Statement Type: SELECT with CTE
-- Complexity: MEDIUM - Uses CTE with AVG, MIN, MAX window functions
-- Parameters: @Threshold (INT)
-- Description: Retrieves products below a stock threshold with statistical analysis.
--              Calculates average, minimum, and maximum stock levels across all products
--              and categorizes stock status as Critical, Low, or Adequate.
-- ==============================================================================

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
ORDER BY StockQuantity

/*
==================================================================================
EXTRACTION SUMMARY
==================================================================================
Total SQL Statements Extracted: 7

Statement Types:
- SELECT with CTE and Window Functions: 4 (Statements 1, 2, 6, 7)
- TRANSACTION with Multiple DML: 3 (Statements 3, 4, 5)

SQL Server Specific Features Identified:
- SCOPE_IDENTITY() - Statement 3 (needs conversion to RETURNING clause or LASTVAL())
- GETDATE() - Statements 3, 4, 5 (needs conversion to NOW() or CURRENT_TIMESTAMP)
- BEGIN TRANSACTION/COMMIT - Statements 3, 4, 5 (needs conversion to BEGIN/COMMIT)
- DECLARE statements - Statements 3, 4, 5 (needs PostgreSQL variable syntax)
- Window Functions - All statements (verify PostgreSQL compatibility)
- ROUND() function - Statements 1, 2, 7 (PostgreSQL compatible)
- CASE expressions - All statements (PostgreSQL compatible)

Parameters Used:
- @ProductId, @Name, @Description, @Price, @StockQuantity
- @MinPrice, @MaxPrice, @Threshold
All parameters use SQL Server syntax (@param) - may need conversion to PostgreSQL
named parameters or positional parameters ($1, $2, etc.) depending on Npgsql usage.

Next Steps:
1. Pass each statement through DMS MCP tool (dms-mcp____statement_conversion_tool)
2. Capture converted PostgreSQL statements
3. Validate equivalency using SQL Equivalency MCP tool
4. Re-integrate converted statements back into ProductRepository.cs

==================================================================================
*/
