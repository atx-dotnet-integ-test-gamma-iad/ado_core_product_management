-- ============================================================================
-- SQL STATEMENTS EXTRACTION CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Source: ProductRepository.cs
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetAllProductsAsync
-- Line Range: 39-66
-- Description: CTE with window functions (AVG OVER, COUNT OVER) and CASE expressions
-- Complexity: Medium - Contains CTE, window functions, CASE expressions
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
-- Method Name: GetProductByIdAsync
-- Line Range: 82-110
-- Description: CTE with LAG window function for historical comparison
-- Parameters: @ProductId (INT)
-- Complexity: Medium - Contains CTE, LAG window function, CASE expressions
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
-- Method Name: InsertProductAsync
-- Line Range: 125-151
-- Description: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Complexity: High - Contains transaction, SCOPE_IDENTITY(), multiple DML operations
-- T-SQL Specific Functions: SCOPE_IDENTITY(), GETDATE(), BEGIN TRANSACTION, COMMIT
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
-- Method Name: UpdateProductAsync
-- Line Range: 167-197
-- Description: Transaction block with variable declarations and multiple DML operations
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Complexity: High - Contains transaction, variables, multiple DML operations
-- T-SQL Specific Functions: GETDATE(), BEGIN TRANSACTION, COMMIT, DECLARE
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
-- Method Name: DeleteProductAsync
-- Line Range: 211-238
-- Description: Transaction block with DELETE operation and conditional logic
-- Parameters: @ProductId (INT)
-- Complexity: High - Contains transaction, variables, DELETE operation, CASE expression
-- T-SQL Specific Functions: GETDATE(), BEGIN TRANSACTION, COMMIT, DECLARE
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
-- Method Name: GetProductsByPriceRangeAsync
-- Line Range: 254-275
-- Description: CTE with RANK() and PERCENT_RANK() window functions
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Complexity: Medium - Contains CTE, RANK(), PERCENT_RANK() window functions, CASE expressions
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
-- Method Name: GetLowStockProductsAsync
-- Line Range: 291-313
-- Description: CTE with multiple window functions (AVG, MIN, MAX) and filtering
-- Parameters: @Threshold (INT)
-- Complexity: Medium - Contains CTE, multiple window functions, CASE expressions
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
-- Statements with CTEs: 5 (Statements 1, 2, 6, 7, and partially 3-5)
-- Statements with Window Functions: 4 (Statements 1, 2, 6, 7)
-- Statements with Transactions: 3 (Statements 3, 4, 5)
-- T-SQL Specific Functions to Convert:
--   - SCOPE_IDENTITY() (Statement 3)
--   - GETDATE() (Statements 3, 4, 5)
--   - BEGIN TRANSACTION/COMMIT (Statements 3, 4, 5)
--   - DECLARE variable syntax (Statements 3, 4, 5)
--   - ROUND() function (multiple statements)
--   - CASE expressions (multiple statements)
-- Window Functions:
--   - AVG() OVER() (Statements 1, 7)
--   - COUNT() OVER() (Statement 1)
--   - LAG() OVER() (Statement 2)
--   - RANK() OVER() (Statement 6)
--   - PERCENT_RANK() OVER() (Statement 6)
--   - MIN() OVER() (Statement 7)
--   - MAX() OVER() (Statement 7)
-- ============================================================================
