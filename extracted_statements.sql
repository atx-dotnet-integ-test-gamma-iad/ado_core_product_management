-- ===============================================================================
-- EXTRACTED SQL STATEMENTS FROM PRODUCTREPOSITORY.CS
-- Extraction Date: 2026-01-22
-- Total Statements: 7
-- Purpose: Catalog all SQL Server T-SQL statements for DMS MCP conversion
-- ===============================================================================

-- ===============================================================================
-- STATEMENT 1: GetAllProductsAsync()
-- Source File: DataAccess/ProductRepository.cs
-- Line Range: 39-69
-- Complexity: HIGH - CTE with window functions (AVG OVER, COUNT OVER), CASE expressions
-- Parameters: None
-- SQL Server Specific Features:
--   - Window functions: AVG() OVER(), COUNT() OVER()
--   - CTE (Common Table Expression)
--   - CASE expressions
-- ===============================================================================
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

-- ===============================================================================
-- STATEMENT 2: GetProductByIdAsync()
-- Source File: DataAccess/ProductRepository.cs
-- Line Range: 81-110
-- Complexity: MEDIUM - CTE with LAG window function, LEFT JOIN, parameterized query
-- Parameters: @ProductId (INT)
-- SQL Server Specific Features:
--   - LAG() OVER window function
--   - CTE (Common Table Expression)
--   - CASE expression with NULL handling
--   - Parameterized query (@ProductId)
-- ===============================================================================
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

-- ===============================================================================
-- STATEMENT 3: InsertProductAsync()
-- Source File: DataAccess/ProductRepository.cs
-- Line Range: 123-148
-- Complexity: VERY HIGH - Multi-statement transaction with variable declarations
-- Parameters: @Name (VARCHAR), @Description (VARCHAR/NULL), @Price (DECIMAL), @StockQuantity (INT)
-- SQL Server Specific Features:
--   - DECLARE variable (@NewProductId)
--   - BEGIN TRANSACTION / COMMIT
--   - SCOPE_IDENTITY() - returns last identity value inserted
--   - GETDATE() - current date/time function
--   - Multi-statement transaction block
--   - SELECT to return value at end
-- Transaction Tables:
--   - Products (INSERT)
--   - ProductHistory (INSERT)
--   - ProductStats (UPDATE)
-- ===============================================================================
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

-- ===============================================================================
-- STATEMENT 4: UpdateProductAsync()
-- Source File: DataAccess/ProductRepository.cs
-- Line Range: 160-191
-- Complexity: VERY HIGH - Multi-statement transaction with multiple variable declarations
-- Parameters: @ProductId (INT), @Name (VARCHAR), @Description (VARCHAR/NULL), @Price (DECIMAL), @StockQuantity (INT)
-- SQL Server Specific Features:
--   - DECLARE variables (@OldPrice, @OldStock)
--   - BEGIN TRANSACTION / COMMIT
--   - GETDATE() - current date/time function (3 occurrences)
--   - Multi-statement transaction block
--   - SELECT with multiple variable assignments
-- Transaction Tables:
--   - Products (SELECT, UPDATE)
--   - ProductHistory (INSERT)
--   - ProductStats (UPDATE)
-- ===============================================================================
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

-- ===============================================================================
-- STATEMENT 5: DeleteProductAsync()
-- Source File: DataAccess/ProductRepository.cs
-- Line Range: 202-233
-- Complexity: VERY HIGH - Multi-statement transaction with CASE expression in UPDATE
-- Parameters: @ProductId (INT)
-- SQL Server Specific Features:
--   - DECLARE variables (@OldPrice, @OldStock)
--   - BEGIN TRANSACTION / COMMIT
--   - GETDATE() - current date/time function (2 occurrences)
--   - Multi-statement transaction block
--   - CASE expression in UPDATE statement
--   - DELETE statement
-- Transaction Tables:
--   - Products (SELECT, DELETE)
--   - ProductHistory (INSERT)
--   - ProductStats (UPDATE)
-- ===============================================================================
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

-- ===============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync()
-- Source File: DataAccess/ProductRepository.cs
-- Line Range: 243-264
-- Complexity: MEDIUM-HIGH - CTE with RANK and PERCENT_RANK window functions
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- SQL Server Specific Features:
--   - CTE (Common Table Expression)
--   - RANK() OVER window function
--   - PERCENT_RANK() OVER window function
--   - CASE expression with percentile-based segmentation
--   - BETWEEN clause for price range filtering
-- ===============================================================================
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

-- ===============================================================================
-- STATEMENT 7: GetLowStockProductsAsync()
-- Source File: DataAccess/ProductRepository.cs
-- Line Range: 274-299
-- Complexity: MEDIUM-HIGH - CTE with multiple window functions (AVG, MIN, MAX OVER)
-- Parameters: @Threshold (INT)
-- SQL Server Specific Features:
--   - CTE (Common Table Expression)
--   - AVG() OVER window function
--   - MIN() OVER window function
--   - MAX() OVER window function
--   - CASE expression with calculated thresholds
--   - ROUND function with percentage calculation
-- ===============================================================================
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

-- ===============================================================================
-- END OF EXTRACTED STATEMENTS
-- Total Statements Extracted: 7
-- Ready for DMS MCP Tool Conversion
-- ===============================================================================
