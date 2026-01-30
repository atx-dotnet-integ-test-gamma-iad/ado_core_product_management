-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- .NET ADO Application - AdoCore
-- ============================================================================
-- This file contains all SQL statements extracted from the codebase for 
-- migration from SQL Server to PostgreSQL. Each statement includes:
-- - Statement ID
-- - Source file path
-- - Method name
-- - Line number range
-- - Statement type
-- - SQL Server specific features used
-- - Complete SQL text
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - SELECT with CTE and Window Functions
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Lines: 40-69
-- Type: SELECT with CTE
-- Complexity: HIGH
-- SQL Server Features: WITH CTE, AVG() OVER(), COUNT() OVER(), CASE, INNER JOIN, ORDER BY
-- Description: Retrieves all products with average price calculation using window functions
--              and categorizes products based on their price relative to the average.
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
-- STATEMENT 2: GetProductByIdAsync - SELECT with CTE and LAG Window Function
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Lines: 85-112
-- Type: SELECT with CTE and LAG window function
-- Complexity: HIGH
-- SQL Server Features: WITH CTE, LAG() OVER(), @parameter, LEFT JOIN, WHERE
-- Parameters: @ProductId (int)
-- Description: Retrieves a specific product by ID with historical price and stock
--              information using the LAG window function to access previous values.
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
-- STATEMENT 3: InsertProductAsync - INSERT with Transaction and SCOPE_IDENTITY
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Lines: 128-153
-- Type: INSERT with transaction
-- Complexity: HIGH
-- SQL Server Features: BEGIN TRANSACTION, COMMIT, DECLARE, SET, SCOPE_IDENTITY(), GETDATE(), INSERT, UPDATE, SELECT
-- Parameters: @Name (string), @Description (string/null), @Price (decimal), @StockQuantity (int)
-- Description: Inserts a new product within a transaction, logs the insertion to ProductHistory,
--              updates ProductStats, and returns the newly created ProductId using SCOPE_IDENTITY().
--              This is a multi-statement transaction with auto-generated ID retrieval.
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
-- STATEMENT 4: UpdateProductAsync - UPDATE with Transaction and History Logging
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Lines: 169-200
-- Type: UPDATE with transaction
-- Complexity: HIGH
-- SQL Server Features: BEGIN TRANSACTION, COMMIT, DECLARE, SELECT into variables, UPDATE, INSERT, GETDATE()
-- Parameters: @ProductId (int), @Name (string), @Description (string/null), @Price (decimal), @StockQuantity (int)
-- Description: Updates an existing product within a transaction, stores old values in variables,
--              logs the update to ProductHistory, and updates ProductStats with the new average price.
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
-- STATEMENT 5: DeleteProductAsync - DELETE with Transaction and Cleanup
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Lines: 216-245
-- Type: DELETE with transaction
-- Complexity: HIGH
-- SQL Server Features: BEGIN TRANSACTION, COMMIT, DECLARE, SELECT into variables, INSERT, DELETE, UPDATE with CASE, GETDATE()
-- Parameters: @ProductId (int)
-- Description: Deletes a product within a transaction, stores product info in variables for history,
--              logs the deletion to ProductHistory, deletes the product, and updates ProductStats
--              with recalculated average price using CASE expression for division by zero protection.
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - SELECT with CTE and RANK/PERCENT_RANK
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Lines: 261-280
-- Type: SELECT with CTE and window functions
-- Complexity: HIGH
-- SQL Server Features: WITH CTE, RANK() OVER(), PERCENT_RANK() OVER(), BETWEEN, CASE, WHERE, ORDER BY
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Description: Retrieves products within a price range, ranks them by price using RANK(),
--              calculates price percentile using PERCENT_RANK(), and categorizes products
--              into Budget/Mid-Range/Premium segments based on percentile.
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
-- STATEMENT 7: GetLowStockProductsAsync - SELECT with CTE and Aggregate Window Functions
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Lines: 296-318
-- Type: SELECT with CTE and window functions
-- Complexity: HIGH
-- SQL Server Features: WITH CTE, AVG() OVER(), MIN() OVER(), MAX() OVER(), CASE, WHERE, ORDER BY
-- Parameters: @Threshold (int)
-- Description: Retrieves products with low stock (below threshold) using window functions
--              to calculate average, minimum, and maximum stock across all products.
--              Categorizes stock status as Critical/Low/Adequate based on threshold and average.
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
-- END OF EXTRACTED STATEMENTS CATALOG
-- ============================================================================
-- Summary:
-- Total Statements: 7
-- Source Files: 1 (DataAccess/ProductRepository.cs)
-- Statement Types:
--   - SELECT with CTE: 4 statements (#1, #2, #6, #7)
--   - INSERT with transaction: 1 statement (#3)
--   - UPDATE with transaction: 1 statement (#4)
--   - DELETE with transaction: 1 statement (#5)
-- 
-- SQL Server Specific Features Requiring Conversion:
--   - Window Functions: AVG() OVER(), COUNT() OVER(), LAG() OVER(), RANK() OVER(), 
--                       PERCENT_RANK() OVER(), MIN() OVER(), MAX() OVER()
--   - SCOPE_IDENTITY(): Used in INSERT statement (#3) - requires RETURNING clause
--   - GETDATE(): Used in transactions (#3, #4, #5) - requires NOW() or CURRENT_TIMESTAMP
--   - Transaction syntax: BEGIN TRANSACTION/COMMIT (PostgreSQL uses BEGIN/COMMIT)
--   - Parameter syntax: @parameter (compatible with PostgreSQL)
--   - CTEs: WITH clause (compatible with PostgreSQL)
--   - CASE expressions (compatible with PostgreSQL)
--   - ROUND function (compatible with PostgreSQL)
--   - BETWEEN operator (compatible with PostgreSQL)
-- 
-- All statements are ready for DMS MCP tool conversion.
-- ============================================================================
