-- ============================================================================
-- EXTRACTED SQL STATEMENTS FOR MIGRATION
-- Source: AdoCore Application - Microsoft SQL Server to PostgreSQL Migration
-- Total Statements: 7
-- Transaction Blocks: 3
-- Simple Queries: 4
-- All statements use parameterized queries with @ prefix parameters
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: GetAllProductsAsync, Lines: 44-72
-- Statement Type: SELECT with CTE and window functions
-- Parameters: None
-- SQL Server Features: 
--   - CTE (Common Table Expression)
--   - AVG() OVER() window function
--   - COUNT(*) OVER() window function
--   - CASE expressions
--   - INNER JOIN
--   - ROUND function
-- Construction Method: const string (direct SQL string literal)
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
    p.Name

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync
-- ============================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: GetProductByIdAsync, Lines: 88-118
-- Statement Type: SELECT with CTE, window functions, and LEFT JOIN
-- Parameters: @ProductId (int)
-- SQL Server Features:
--   - CTE (Common Table Expression)
--   - LAG() window function with ORDER BY
--   - LEFT JOIN
--   - NULL handling in CASE expressions
--   - ROUND function for percentage calculations
-- Construction Method: const string (direct SQL string literal)
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
WHERE p.ProductId = @ProductId

-- ============================================================================
-- STATEMENT 3: InsertProductAsync
-- ============================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: InsertProductAsync, Lines: 137-169
-- Statement Type: MULTI-STATEMENT TRANSACTION (INSERT + IDENTITY + UPDATE + COMMIT)
-- Parameters: @Name (string), @Description (string/null), @Price (decimal), @StockQuantity (int)
-- SQL Server Features:
--   - BEGIN TRANSACTION / COMMIT
--   - DECLARE variable (@NewProductId)
--   - INSERT with explicit column list
--   - SCOPE_IDENTITY() to retrieve last inserted identity value
--   - GETDATE() function (3 occurrences)
--   - Multi-table INSERT/UPDATE within transaction
-- Construction Method: const string (direct SQL string literal)
-- Transaction Atomicity: All operations must succeed or rollback together
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
-- Source Location: DataAccess/ProductRepository.cs, Method: UpdateProductAsync, Lines: 177-213
-- Statement Type: MULTI-STATEMENT TRANSACTION (DECLARE + SELECT + UPDATE + INSERT + COMMIT)
-- Parameters: @ProductId (int), @Name (string), @Description (string/null), @Price (decimal), @StockQuantity (int)
-- SQL Server Features:
--   - BEGIN TRANSACTION / COMMIT
--   - DECLARE multiple variables (@OldPrice, @OldStock)
--   - Variable assignment through SELECT
--   - UPDATE statement
--   - INSERT into history table
--   - GETDATE() function (3 occurrences)
--   - Multi-table UPDATE/INSERT within transaction
-- Construction Method: const string (direct SQL string literal)
-- Transaction Atomicity: All operations must succeed or rollback together
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
-- Source Location: DataAccess/ProductRepository.cs, Method: DeleteProductAsync, Lines: 219-254
-- Statement Type: MULTI-STATEMENT TRANSACTION (DECLARE + SELECT + INSERT + DELETE + UPDATE + COMMIT)
-- Parameters: @ProductId (int)
-- SQL Server Features:
--   - BEGIN TRANSACTION / COMMIT
--   - DECLARE multiple variables (@OldPrice, @OldStock)
--   - Variable assignment through SELECT
--   - INSERT into history table (logging before deletion)
--   - DELETE statement
--   - UPDATE with complex CASE expression
--   - GETDATE() function (2 occurrences)
--   - Multi-table INSERT/DELETE/UPDATE within transaction
-- Construction Method: const string (direct SQL string literal)
-- Transaction Atomicity: All operations must succeed or rollback together
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
-- Source Location: DataAccess/ProductRepository.cs, Method: GetProductsByPriceRangeAsync, Lines: 262-285
-- Statement Type: SELECT with CTE and window functions
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- SQL Server Features:
--   - CTE (Common Table Expression)
--   - RANK() OVER (ORDER BY) window function
--   - PERCENT_RANK() OVER (ORDER BY) window function
--   - BETWEEN clause
--   - CASE expression with percentile-based categorization
-- Construction Method: const string (direct SQL string literal)
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
ORDER BY rp.PriceRank

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- ============================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: GetLowStockProductsAsync, Lines: 297-324
-- Statement Type: SELECT with CTE and multiple window functions
-- Parameters: @Threshold (int)
-- SQL Server Features:
--   - CTE (Common Table Expression)
--   - AVG() OVER() window function
--   - MIN() OVER() window function
--   - MAX() OVER() window function
--   - Complex CASE expression with multiple conditions
--   - ROUND function for percentage calculation
--   - WHERE clause filtering on window function results
-- Construction Method: const string (direct SQL string literal)
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
ORDER BY StockQuantity

-- ============================================================================
-- EXTRACTION SUMMARY
-- ============================================================================
-- Total Statements Extracted: 7
-- Simple SELECT Queries: 4
-- Transaction Blocks: 3
-- 
-- SQL Server Specific Features Requiring Conversion:
-- - SCOPE_IDENTITY() - needs PostgreSQL RETURNING or currval() equivalent
-- - GETDATE() - needs NOW() or CURRENT_TIMESTAMP
-- - BEGIN TRANSACTION/COMMIT syntax - verify PostgreSQL compatibility
-- - DECLARE variable syntax - may need DO block or different syntax
-- - SET variable = SCOPE_IDENTITY() - needs PostgreSQL approach
-- - Window functions - verify syntax compatibility
-- - ROUND function - verify PostgreSQL signature
-- - Parameter prefix @ - may need conversion to $1, $2, etc. or remain as @
-- 
-- Schema Objects Referenced:
-- - Products (table)
-- - ProductHistory (table)
-- - ProductStats (table)
-- 
-- All statements ready for DMS MCP tool conversion
-- ============================================================================
