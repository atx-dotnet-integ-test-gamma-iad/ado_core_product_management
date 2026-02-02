-- ===============================================================================
-- SQL STATEMENT EXTRACTION CATALOG
-- Source: ProductRepository.cs
-- Purpose: Comprehensive catalog of all SQL statements for DMS tool processing
-- Date: Migration from SQL Server to PostgreSQL
-- ===============================================================================

-- ===============================================================================
-- STATEMENT 1: Get All Products with CTE and Window Functions
-- ===============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync
-- Line Number: ~41-68
-- Statement Type: SELECT with CTE
-- Complexity: High (CTE, Window Functions, CASE expressions)
-- Parameters: None
-- Description: Retrieves all products with average price analysis using CTE and window functions
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
-- STATEMENT 2: Get Product By ID with Window Functions (LAG)
-- ===============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync
-- Line Number: ~78-107
-- Statement Type: SELECT with CTE and LAG
-- Complexity: High (CTE, LAG window function, CASE expressions)
-- Parameters: @ProductId (INT)
-- Description: Retrieves a single product with historical price comparison using LAG
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
-- STATEMENT 3: Insert Product with Transaction Block
-- ===============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync
-- Line Number: ~116-139
-- Statement Type: INSERT with TRANSACTION
-- Complexity: Very High (Transaction, SCOPE_IDENTITY, GETDATE, multi-table updates)
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Description: Inserts a new product and logs the action in ProductHistory, updates ProductStats
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
-- STATEMENT 4: Update Product with Transaction Block
-- ===============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync
-- Line Number: ~147-179
-- Statement Type: UPDATE with TRANSACTION
-- Complexity: Very High (Transaction, variable declarations, multi-table updates, GETDATE)
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Description: Updates product details, logs changes to ProductHistory, recalculates ProductStats
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
-- STATEMENT 5: Delete Product with Transaction Block
-- ===============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync
-- Line Number: ~186-221
-- Statement Type: DELETE with TRANSACTION
-- Complexity: Very High (Transaction, variable declarations, multi-table operations, GETDATE)
-- Parameters: @ProductId (INT)
-- Description: Deletes a product, logs the deletion to ProductHistory, updates ProductStats
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
-- STATEMENT 6: Get Products By Price Range with Window Functions
-- ===============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync
-- Line Number: ~228-253
-- Statement Type: SELECT with CTE and Window Functions
-- Complexity: High (CTE, RANK, PERCENT_RANK window functions, CASE expressions)
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Description: Retrieves products within price range with ranking and percentile calculations
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
-- STATEMENT 7: Get Low Stock Products with Window Functions
-- ===============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync
-- Line Number: ~260-289
-- Statement Type: SELECT with CTE and Window Functions
-- Complexity: High (CTE, AVG/MIN/MAX window functions, CASE expressions)
-- Parameters: @Threshold (INT)
-- Description: Retrieves products below stock threshold with stock analysis metrics
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
-- EXTRACTION SUMMARY
-- ===============================================================================
-- Total SQL Statements Extracted: 7
-- SELECT Statements: 4
-- INSERT Statements: 0 (part of transactions)
-- UPDATE Statements: 0 (part of transactions)
-- DELETE Statements: 0 (part of transactions)
-- TRANSACTION Blocks: 3 (Insert, Update, Delete)
-- ===============================================================================
-- Complexity Analysis:
-- - 4 statements use CTEs (Common Table Expressions)
-- - 4 statements use Window Functions (AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK)
-- - 3 statements are complex transaction blocks with multiple DML operations
-- - All statements use parameterized queries (@parameter syntax)
-- - 3 statements use SQL Server specific functions (SCOPE_IDENTITY, GETDATE)
-- ===============================================================================
