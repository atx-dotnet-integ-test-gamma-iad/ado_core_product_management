-- ===============================================================================
-- SQL Statement Extraction Catalog
-- Generated for SQL Server to PostgreSQL Migration
-- Source Application: AdoCore
-- ===============================================================================

-- Statement ID: 1
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync
-- Line Number: ~38-68
-- Statement Type: SELECT with CTE and Window Functions
-- Complexity: HIGH (CTE, AVG OVER, COUNT OVER, CASE expressions, JOINs)
-- SQL Server Specific Functions: None (but uses window functions and CTE)
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
-- Statement ID: 2
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync
-- Line Number: ~75-105
-- Statement Type: SELECT with CTE and Window Functions
-- Complexity: HIGH (CTE, LAG window function, CASE expressions, LEFT JOIN)
-- SQL Server Specific Functions: None (but uses LAG window function)
-- Parameters: @ProductId
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
-- Statement ID: 3
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync
-- Line Number: ~112-137
-- Statement Type: TRANSACTION with INSERT statements
-- Complexity: VERY HIGH (Multi-statement transaction, SCOPE_IDENTITY, GETDATE)
-- SQL Server Specific Functions: SCOPE_IDENTITY(), GETDATE()
-- Parameters: @Name, @Description, @Price, @StockQuantity
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
-- Statement ID: 4
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync
-- Line Number: ~149-182
-- Statement Type: TRANSACTION with UPDATE statements
-- Complexity: VERY HIGH (Multi-statement transaction, variable declarations, GETDATE)
-- SQL Server Specific Functions: GETDATE()
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
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
-- Statement ID: 5
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync
-- Line Number: ~189-220
-- Statement Type: TRANSACTION with DELETE statement
-- Complexity: VERY HIGH (Multi-statement transaction, CASE expressions, GETDATE)
-- SQL Server Specific Functions: GETDATE()
-- Parameters: @ProductId
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
-- Statement ID: 6
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync
-- Line Number: ~227-253
-- Statement Type: SELECT with CTE and Window Functions
-- Complexity: HIGH (CTE, RANK, PERCENT_RANK window functions, CASE expressions)
-- SQL Server Specific Functions: None (but uses window functions)
-- Parameters: @MinPrice, @MaxPrice
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
-- Statement ID: 7
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync
-- Line Number: ~260-286
-- Statement Type: SELECT with CTE and Multiple Window Functions
-- Complexity: VERY HIGH (CTE, AVG OVER, MIN OVER, MAX OVER, CASE expressions)
-- SQL Server Specific Functions: None (but uses multiple window functions)
-- Parameters: @Threshold
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
-- SUMMARY
-- ===============================================================================
-- Total Statements Extracted: 7
-- Source Files: 1 (DataAccess/ProductRepository.cs)
-- Statement Types:
--   - SELECT with CTE: 4
--   - TRANSACTION (INSERT): 1
--   - TRANSACTION (UPDATE): 1
--   - TRANSACTION (DELETE): 1
-- SQL Server Specific Functions Identified:
--   - SCOPE_IDENTITY(): 1 occurrence (Statement 3)
--   - GETDATE(): 8 occurrences (Statements 3, 4, 5)
-- Window Functions:
--   - AVG OVER(): 2 occurrences
--   - COUNT OVER(): 1 occurrence
--   - LAG(): 1 occurrence
--   - RANK(): 1 occurrence
--   - PERCENT_RANK(): 1 occurrence
--   - MIN OVER(): 1 occurrence
--   - MAX OVER(): 1 occurrence
-- ===============================================================================
