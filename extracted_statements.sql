-- ===============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Source: AdoCore Application
-- Extraction Date: 2026-01-31
-- ===============================================================================
-- This file contains all SQL statements extracted from the .NET codebase
-- Each statement is documented with metadata for DMS tool conversion
-- ===============================================================================

-- ===============================================================================
-- STATEMENT ID: SQL_001
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync
-- Line Range: 40-67
-- Statement Type: SELECT with CTE and Window Functions
-- Parameters: None
-- Description: Complex CTE query with AVG OVER, COUNT OVER window functions and CASE expressions
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
    p.Name;

-- ===============================================================================
-- STATEMENT ID: SQL_002
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync
-- Line Range: 83-106
-- Statement Type: SELECT with CTE and LAG Window Function
-- Parameters: @ProductId (int)
-- Description: CTE with LAG window function to retrieve historical price and stock data
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
WHERE p.ProductId = @ProductId;

-- ===============================================================================
-- STATEMENT ID: SQL_003
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: InsertProductAsync
-- Line Range: 122-143
-- Statement Type: INSERT with Transaction Block
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: Transaction with INSERT, SCOPE_IDENTITY(), history logging, stats update, GETDATE()
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
-- STATEMENT ID: SQL_004
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync
-- Line Range: 159-185
-- Statement Type: UPDATE with Transaction Block
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: Transaction with variable declarations, UPDATE, history logging, stats update, GETDATE()
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
-- STATEMENT ID: SQL_005
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync
-- Line Range: 203-231
-- Statement Type: DELETE with Transaction Block
-- Parameters: @ProductId (int)
-- Description: Transaction with DELETE, history logging, stats update with CASE, GETDATE()
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
-- STATEMENT ID: SQL_006
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync
-- Line Range: 247-263
-- Statement Type: SELECT with CTE, RANK and PERCENT_RANK Window Functions
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Description: CTE with RANK and PERCENT_RANK window functions for price segmentation
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
ORDER BY rp.PriceRank;

-- ===============================================================================
-- STATEMENT ID: SQL_007
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync
-- Line Range: 281-302
-- Statement Type: SELECT with CTE and Multiple Window Functions
-- Parameters: @Threshold (int)
-- Description: CTE with AVG, MIN, MAX window functions for stock analysis
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
ORDER BY StockQuantity;

-- ===============================================================================
-- STATEMENT ID: SQL_008
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: ExecuteInTransactionAsync
-- Line Range: 313-325
-- Statement Type: Transaction Management (No explicit SQL statement)
-- Parameters: None
-- Description: Transaction wrapper using BeginTransactionAsync/CommitAsync/RollbackAsync
-- Note: This is managed through ADO.NET code, not a SQL statement to convert
-- ===============================================================================
-- NO SQL STATEMENT TO EXTRACT - Transaction management is handled via ADO.NET API
-- The method uses connection.BeginTransactionAsync(), transaction.CommitAsync(), transaction.RollbackAsync()

-- ===============================================================================
-- EXTRACTION SUMMARY
-- ===============================================================================
-- Total Statements Extracted: 7 SQL statements (8 including transaction management note)
-- Statement Types:
--   - SELECT with CTE and Window Functions: 4 (SQL_001, SQL_002, SQL_006, SQL_007)
--   - INSERT with Transaction: 1 (SQL_003)
--   - UPDATE with Transaction: 1 (SQL_004)
--   - DELETE with Transaction: 1 (SQL_005)
-- SQL Server Specific Features Identified:
--   - Window Functions: AVG OVER, COUNT OVER, LAG OVER, RANK, PERCENT_RANK
--   - Transaction Syntax: BEGIN TRANSACTION, COMMIT
--   - SQL Server Functions: SCOPE_IDENTITY(), GETDATE()
--   - Parameter Syntax: @ParameterName
--   - Variable Declarations: DECLARE @Variable Type
-- ===============================================================================
