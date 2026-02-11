-- ============================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- Microsoft SQL Server to PostgreSQL Migration
-- Extraction Date: 2026-02-11
-- ============================================================================
-- Total Statements: 6
-- Source File: DataAccess/ProductRepository.cs
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Number: 40-68
-- Method Name: GetAllProductsAsync
-- Statement Type: SELECT with CTE and Window Functions
-- Purpose: Retrieve all products with price category analysis
-- SQL Server Features: CTE, OVER(), AVG() window function, COUNT() window function, CASE expressions
-- Complexity: Medium (CTE with window functions, multi-column ordering)
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
-- Source File: DataAccess/ProductRepository.cs
-- Line Number: 82-107
-- Method Name: GetProductByIdAsync
-- Statement Type: SELECT with CTE and LAG Window Function
-- Purpose: Retrieve single product with price history analysis
-- Parameters: @ProductId (INT)
-- SQL Server Features: CTE, LAG() window function, LEFT JOIN, CASE expressions
-- Complexity: Medium (CTE with LAG window function, calculated fields)
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
-- Source File: DataAccess/ProductRepository.cs
-- Line Number: 121-146
-- Method Name: InsertProductAsync
-- Statement Type: INSERT with Transaction Block
-- Purpose: Insert new product with history logging and statistics update
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- SQL Server Features: BEGIN TRANSACTION/COMMIT, SCOPE_IDENTITY(), GETDATE(), multi-statement transaction
-- Complexity: High (transaction with 3 DML statements, identity retrieval)
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
-- Source File: DataAccess/ProductRepository.cs
-- Line Number: 160-189
-- Method Name: UpdateProductAsync
-- Statement Type: UPDATE with Transaction Block
-- Purpose: Update product with history logging and statistics update
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- SQL Server Features: BEGIN TRANSACTION/COMMIT, GETDATE(), multi-statement transaction, variable declarations
-- Complexity: High (transaction with 3 DML statements, calculated statistics)
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
-- Source File: DataAccess/ProductRepository.cs
-- Line Number: 203-234
-- Method Name: DeleteProductAsync
-- Statement Type: DELETE with Transaction Block
-- Purpose: Delete product with history logging and statistics update
-- Parameters: @ProductId
-- SQL Server Features: BEGIN TRANSACTION/COMMIT, GETDATE(), multi-statement transaction, CASE expressions
-- Complexity: High (transaction with 3 DML statements, conditional statistics)
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
-- Source File: DataAccess/ProductRepository.cs
-- Line Number: 248-270
-- Method Name: GetProductsByPriceRangeAsync
-- Statement Type: SELECT with CTE and Window Functions
-- Purpose: Retrieve products within price range with ranking analysis
-- Parameters: @MinPrice, @MaxPrice
-- SQL Server Features: CTE, RANK() window function, PERCENT_RANK() window function, CASE expressions
-- Complexity: Medium (CTE with multiple window functions, percentile calculations)
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
-- Source File: DataAccess/ProductRepository.cs
-- Line Number: 284-310
-- Method Name: GetLowStockProductsAsync
-- Statement Type: SELECT with CTE and Window Functions
-- Purpose: Retrieve low stock products with stock analysis
-- Parameters: @Threshold
-- SQL Server Features: CTE, AVG() window function, MIN() window function, MAX() window function, CASE expressions
-- Complexity: Medium (CTE with multiple window functions, conditional filtering)
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
-- SELECT Statements: 4 (GetAllProductsAsync, GetProductByIdAsync, GetProductsByPriceRangeAsync, GetLowStockProductsAsync)
-- INSERT Statements: 1 (InsertProductAsync - within transaction)
-- UPDATE Statements: 2 (UpdateProductAsync, DeleteProductAsync - within transactions)
-- DELETE Statements: 1 (DeleteProductAsync - within transaction)
-- Transaction Blocks: 3 (InsertProductAsync, UpdateProductAsync, DeleteProductAsync)
-- 
-- SQL Server Features Requiring Conversion:
-- - SCOPE_IDENTITY() → PostgreSQL RETURNING clause
-- - GETDATE() → CURRENT_TIMESTAMP or NOW()
-- - BEGIN TRANSACTION/COMMIT → PostgreSQL BEGIN/COMMIT syntax
-- - Window functions (compatible but verify syntax)
-- - CTEs (compatible but verify syntax)
-- - CASE expressions (compatible but verify syntax)
-- 
-- All statements are ready for DMS MCP tool processing
-- ============================================================================
