-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Database: ProductManagement
-- Schema: dbo
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync
-- Line Numbers: 41-69
-- Complexity: Medium
-- Description: Complex CTE with AVG, COUNT window functions, CASE expressions, and JOIN
-- Statement Type: SELECT with CTE
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
-- Method: GetProductByIdAsync
-- Line Numbers: 84-110
-- Complexity: Medium
-- Description: CTE with LAG window function for historical data analysis
-- Statement Type: SELECT with CTE and LAG window function
-- Parameters: @ProductId INT
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
-- Method: InsertProductAsync
-- Line Numbers: 128-154
-- Complexity: Hard
-- Description: Multi-statement transaction with SCOPE_IDENTITY, GETDATE, and multiple INSERTs/UPDATEs
-- Statement Type: Multi-statement transaction with INSERT, UPDATE
-- Parameters: @Name NVARCHAR, @Description NVARCHAR, @Price DECIMAL(18,2), @StockQuantity INT
-- T-SQL Specific: SCOPE_IDENTITY(), GETDATE(), BEGIN TRANSACTION/COMMIT
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
-- Method: UpdateProductAsync
-- Line Numbers: 169-200
-- Complexity: Hard
-- Description: Multi-statement transaction with DECLARE variables, GETDATE, and history logging
-- Statement Type: Multi-statement transaction with UPDATE, INSERT
-- Parameters: @ProductId INT, @Name NVARCHAR, @Description NVARCHAR, @Price DECIMAL(18,2), @StockQuantity INT
-- T-SQL Specific: DECLARE variables, GETDATE(), BEGIN TRANSACTION/COMMIT
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
-- Method: DeleteProductAsync
-- Line Numbers: 215-246
-- Complexity: Hard
-- Description: Multi-statement transaction with DECLARE variables and cascading updates
-- Statement Type: Multi-statement transaction with DELETE, INSERT, UPDATE
-- Parameters: @ProductId INT
-- T-SQL Specific: DECLARE variables, GETDATE(), BEGIN TRANSACTION/COMMIT, CASE expression
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
-- Method: GetProductsByPriceRangeAsync
-- Line Numbers: 261-283
-- Complexity: Medium
-- Description: CTE with RANK and PERCENT_RANK window functions
-- Statement Type: SELECT with CTE and window functions
-- Parameters: @MinPrice DECIMAL(18,2), @MaxPrice DECIMAL(18,2)
-- T-SQL Specific: RANK(), PERCENT_RANK() window functions
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
-- Method: GetLowStockProductsAsync
-- Line Numbers: 298-322
-- Complexity: Medium
-- Description: CTE with multiple window functions (AVG, MIN, MAX) and CASE expression
-- Statement Type: SELECT with CTE and window functions
-- Parameters: @Threshold INT
-- T-SQL Specific: Multiple window functions (AVG, MIN, MAX) with OVER()
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
-- - Total Statements Extracted: 7
-- - SELECT Statements: 4 (statements 1, 2, 6, 7)
-- - Transaction Statements: 3 (statements 3, 4, 5)
-- - Statements with CTEs: 6 (all except statement 3)
-- - Statements with Window Functions: 5 (statements 1, 2, 6, 7 - GetAllProductsAsync has AVG/COUNT, GetProductByIdAsync has LAG, GetProductsByPriceRangeAsync has RANK/PERCENT_RANK, GetLowStockProductsAsync has AVG/MIN/MAX)
-- - T-SQL Specific Constructs to Convert:
--   * SCOPE_IDENTITY() - Statement 3
--   * GETDATE() - Statements 3, 4, 5
--   * BEGIN TRANSACTION/COMMIT - Statements 3, 4, 5
--   * DECLARE variables - Statements 3, 4, 5
-- ============================================================================
