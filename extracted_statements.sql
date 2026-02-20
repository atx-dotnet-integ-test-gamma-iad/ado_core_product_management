-- ===============================================================================
-- EXTRACTED SQL STATEMENTS FROM PRODUCTREPOSITORY.CS
-- Microsoft SQL Server to PostgreSQL Migration
-- ===============================================================================
-- This file contains all SQL statements extracted from the .NET ADO Core application
-- for conversion to PostgreSQL syntax. Each statement is documented with its source
-- location, parameters, and SQL Server specific syntax that requires transformation.
-- ===============================================================================

-- ===============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ===============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Numbers: 39-68
-- Parameters: None
-- SQL Server Specific Syntax:
--   - AVG() OVER() window function
--   - COUNT(*) OVER() window function
--   - ROUND() function
--   - CASE expressions
--   - CTE (WITH clause)
-- Description: 
--   Retrieves all products with calculated price statistics using window functions.
--   Includes price category classification and percentage calculations relative to average.
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
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ===============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Numbers: 77-106
-- Parameters: 
--   @ProductId (int) - The product ID to retrieve
-- SQL Server Specific Syntax:
--   - LAG() OVER (ORDER BY) window function
--   - LEFT JOIN
--   - ROUND() function
--   - CASE expression with NULL handling
--   - Parameter: @ProductId
-- Description:
--   Retrieves a single product by ID with historical price and stock change analysis
--   using LAG window function to compare current values with previous values.
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
-- STATEMENT 3: InsertProductAsync - Transaction Block with INSERT and SCOPE_IDENTITY
-- ===============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Numbers: 115-141
-- Parameters:
--   @Name (string) - Product name
--   @Description (string, nullable) - Product description
--   @Price (decimal) - Product price
--   @StockQuantity (int) - Initial stock quantity
-- SQL Server Specific Syntax:
--   - DECLARE @variable syntax
--   - BEGIN TRANSACTION / COMMIT syntax
--   - SCOPE_IDENTITY() function (returns last inserted identity)
--   - GETDATE() function (current timestamp)
--   - SET @variable = value syntax
-- Description:
--   Inserts a new product within a transaction, logs the insertion to ProductHistory,
--   updates aggregate statistics in ProductStats, and returns the new product ID.
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
-- STATEMENT 4: UpdateProductAsync - Transaction Block with UPDATE and History Logging
-- ===============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Numbers: 150-185
-- Parameters:
--   @ProductId (int) - Product ID to update
--   @Name (string) - Updated product name
--   @Description (string, nullable) - Updated product description
--   @Price (decimal) - Updated product price
--   @StockQuantity (int) - Updated stock quantity
-- SQL Server Specific Syntax:
--   - DECLARE @variable DECIMAL/INT syntax
--   - BEGIN TRANSACTION / COMMIT syntax
--   - GETDATE() function (current timestamp)
--   - Variable assignment from SELECT
-- Description:
--   Updates a product within a transaction, capturing old values for history logging,
--   updating the product record, logging changes to ProductHistory, and updating
--   aggregate statistics in ProductStats.
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
-- STATEMENT 5: DeleteProductAsync - Transaction Block with DELETE and Statistics Update
-- ===============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Numbers: 194-229
-- Parameters:
--   @ProductId (int) - Product ID to delete
-- SQL Server Specific Syntax:
--   - DECLARE @variable DECIMAL/INT syntax
--   - BEGIN TRANSACTION / COMMIT syntax
--   - GETDATE() function (current timestamp)
--   - Variable assignment from SELECT
--   - CASE expression for conditional average calculation
-- Description:
--   Deletes a product within a transaction, capturing values for history logging,
--   logging the deletion to ProductHistory, deleting the product record, and updating
--   aggregate statistics in ProductStats with conditional average recalculation.
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ===============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Numbers: 237-266
-- Parameters:
--   @MinPrice (decimal) - Minimum price threshold
--   @MaxPrice (decimal) - Maximum price threshold
-- SQL Server Specific Syntax:
--   - RANK() OVER (ORDER BY) window function
--   - PERCENT_RANK() OVER (ORDER BY) window function
--   - BETWEEN clause
--   - CASE expression for segmentation
--   - CTE (WITH clause)
-- Description:
--   Retrieves products within a price range with ranking and percentile calculations,
--   classifying products into Budget/Mid-Range/Premium segments based on their
--   position in the price distribution.
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
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ===============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Numbers: 274-306
-- Parameters:
--   @Threshold (int) - Stock quantity threshold for low stock identification
-- SQL Server Specific Syntax:
--   - AVG() OVER() window function
--   - MIN() OVER() window function
--   - MAX() OVER() window function
--   - ROUND() function
--   - CASE expression for status classification
--   - CTE (WITH clause)
-- Description:
--   Retrieves products with stock quantities at or below a threshold, calculating
--   stock statistics using window functions and classifying stock status as
--   Critical/Low/Adequate based on threshold and average stock comparisons.
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
-- END OF EXTRACTED SQL STATEMENTS
-- ===============================================================================
-- Total Statements Extracted: 7
-- SELECT Statements: 4 (Statements 1, 2, 6, 7)
-- Transaction Blocks: 3 (Statements 3, 4, 5)
-- ===============================================================================
