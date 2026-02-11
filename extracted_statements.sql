-- ============================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Extraction Date: Migration Phase 1
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync
-- Lines: 38-72
-- Statement Type: SELECT with CTE, Window Functions, and Complex JOIN
-- Complexity: High
-- Features: 
--   - Common Table Expression (CTE)
--   - Window Functions: AVG() OVER(), COUNT() OVER()
--   - CASE statements (multiple)
--   - INNER JOIN
--   - Complex ORDER BY with CASE
-- Parameters: None
-- Construction Method: Direct string constant
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
-- File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync
-- Lines: 78-109
-- Statement Type: SELECT with CTE and LAG Window Function
-- Complexity: High
-- Features:
--   - Common Table Expression (CTE)
--   - Window Function: LAG() OVER()
--   - LEFT JOIN
--   - CASE statement with NULL handling
--   - Mathematical calculation in CASE
-- Parameters: @ProductId (int)
-- Construction Method: Direct string constant with parameterized query
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
-- File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync
-- Lines: 117-141
-- Statement Type: Multi-statement Transaction (INSERT, UPDATE, SELECT)
-- Complexity: Very High
-- Features:
--   - DECLARE statement for variable
--   - BEGIN TRANSACTION / COMMIT
--   - Multiple INSERT statements
--   - SCOPE_IDENTITY() function
--   - GETDATE() function (multiple uses)
--   - UPDATE with arithmetic calculations
--   - Multi-table transaction
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Construction Method: Direct string constant with parameterized query
-- Notes: Returns new ProductId via SCOPE_IDENTITY()
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
-- File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync
-- Lines: 149-179
-- Statement Type: Multi-statement Transaction (SELECT, UPDATE, INSERT)
-- Complexity: Very High
-- Features:
--   - BEGIN TRANSACTION / COMMIT
--   - Multiple DECLARE statements for variables
--   - SELECT into variables
--   - UPDATE statement
--   - INSERT statement for history
--   - GETDATE() function (multiple uses)
--   - Arithmetic calculations in UPDATE
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Construction Method: Direct string constant with parameterized query
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
-- File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync
-- Lines: 187-220
-- Statement Type: Multi-statement Transaction (SELECT, INSERT, DELETE, UPDATE)
-- Complexity: Very High
-- Features:
--   - BEGIN TRANSACTION / COMMIT
--   - Multiple DECLARE statements for variables
--   - SELECT into variables
--   - INSERT statement for history logging
--   - DELETE statement
--   - UPDATE with CASE statement and arithmetic
--   - GETDATE() function
-- Parameters: @ProductId (int)
-- Construction Method: Direct string constant with parameterized query
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
-- File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync
-- Lines: 228-253
-- Statement Type: SELECT with CTE and Window Functions
-- Complexity: High
-- Features:
--   - Common Table Expression (CTE)
--   - Window Functions: RANK() OVER(), PERCENT_RANK() OVER()
--   - CASE statement for segmentation
--   - WHERE clause with BETWEEN
--   - ORDER BY
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Construction Method: Direct string constant with parameterized query
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
-- File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync
-- Lines: 261-288
-- Statement Type: SELECT with CTE and Multiple Window Functions
-- Complexity: High
-- Features:
--   - Common Table Expression (CTE)
--   - Multiple Window Functions: AVG() OVER(), MIN() OVER(), MAX() OVER()
--   - CASE statement with multiple conditions
--   - Arithmetic calculation with window function reference
--   - WHERE clause filtering
--   - ORDER BY
-- Parameters: @Threshold (int)
-- Construction Method: Direct string constant with parameterized query
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
-- END OF EXTRACTED SQL STATEMENTS
-- ============================================================================
-- SUMMARY:
-- Total Statements Extracted: 7
-- Simple SELECT: 0
-- Complex SELECT with CTE/Window Functions: 4 (Statements 1, 2, 6, 7)
-- Multi-statement Transactions: 3 (Statements 3, 4, 5)
-- 
-- SQL Server Specific Features to Convert:
-- - SCOPE_IDENTITY() -> PostgreSQL RETURNING clause
-- - GETDATE() -> PostgreSQL NOW() or CURRENT_TIMESTAMP
-- - BEGIN TRANSACTION / COMMIT -> PostgreSQL transaction syntax
-- - DECLARE statements -> PostgreSQL variable syntax
-- - Window functions syntax variations
-- - DECIMAL data type -> NUMERIC in PostgreSQL
-- - NVARCHAR -> VARCHAR or TEXT in PostgreSQL
-- ============================================================================
