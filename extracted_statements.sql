/*
==============================================================================
SQL Statement Extraction Catalog
SQL Server to PostgreSQL Migration - ADO.NET Application
==============================================================================
Source File: DataAccess/ProductRepository.cs
Total Statements: 7
Extraction Date: 2026-02-19
Purpose: Comprehensive catalog of all SQL statements for DMS conversion
==============================================================================
*/

-- ==============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ==============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Purpose: Retrieve all products with price analysis using window functions
-- Parameters: None
-- SQL Server Features Used:
--   - Common Table Expression (CTE) - WITH clause
--   - Window Functions: AVG() OVER(), COUNT(*) OVER()
--   - CASE expressions for categorization
--   - ROUND function for percentage calculation
--   - Complex ORDER BY with CASE
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 2: GetProductByIdAsync
-- ==============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Purpose: Get single product by ID with historical price/stock comparison
-- Parameters: @ProductId (int)
-- SQL Server Features Used:
--   - Common Table Expression (CTE) - WITH clause
--   - Window Function: LAG() OVER (ORDER BY ModifiedDate)
--   - CASE expression for NULL handling
--   - ROUND function for percentage calculation
--   - LEFT JOIN for optional history data
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 3: InsertProductAsync
-- ==============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Purpose: Insert new product with transaction, history logging, and statistics update
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- SQL Server Features Used:
--   - BEGIN TRANSACTION / COMMIT
--   - DECLARE for local variables
--   - SCOPE_IDENTITY() - returns last inserted identity value
--   - GETDATE() - current date/time function (3 occurrences)
--   - Multi-statement transaction block
--   - INSERT with VALUES
--   - UPDATE with arithmetic expressions
--   - SELECT to return inserted ID
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 4: UpdateProductAsync
-- ==============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Purpose: Update product with transaction, history logging, and statistics update
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- SQL Server Features Used:
--   - BEGIN TRANSACTION / COMMIT
--   - DECLARE for local variables (2 variables)
--   - SELECT into variables for capturing old values
--   - GETDATE() - current date/time function (3 occurrences)
--   - UPDATE with multiple SET clauses
--   - INSERT for history logging
--   - Multi-statement transaction block
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 5: DeleteProductAsync
-- ==============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Purpose: Delete product with transaction, history logging, and statistics update
-- Parameters: @ProductId
-- SQL Server Features Used:
--   - BEGIN TRANSACTION / COMMIT
--   - DECLARE for local variables (2 variables)
--   - SELECT into variables for capturing values before deletion
--   - INSERT for history logging
--   - DELETE statement
--   - UPDATE with CASE expression for conditional calculation
--   - GETDATE() - current date/time function (2 occurrences)
--   - Multi-statement transaction block
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ==============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Purpose: Get products within price range with ranking and percentile analysis
-- Parameters: @MinPrice, @MaxPrice
-- SQL Server Features Used:
--   - Common Table Expression (CTE) - WITH clause
--   - Window Functions: RANK() OVER (ORDER BY), PERCENT_RANK() OVER (ORDER BY)
--   - BETWEEN operator for range filtering
--   - CASE expression for segmentation
--   - Wildcard SELECT (p.*)
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- ==============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Purpose: Get low stock products with stock level analysis
-- Parameters: @Threshold
-- SQL Server Features Used:
--   - Common Table Expression (CTE) - WITH clause
--   - Window Functions: AVG() OVER(), MIN() OVER(), MAX() OVER()
--   - CASE expression for status categorization
--   - ROUND function for percentage calculation
--   - Arithmetic expressions in CASE conditions
--   - Wildcard SELECT (p.*)
-- ==============================================================================

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

-- ==============================================================================
-- END OF EXTRACTION CATALOG
-- ==============================================================================
-- Summary:
-- - Total SQL Statements Extracted: 7
-- - Statements with CTEs: 4 (Statements 1, 2, 6, 7)
-- - Statements with Window Functions: 5 (Statements 1, 2, 6, 7 with multiple functions)
-- - Statements with Transactions: 3 (Statements 3, 4, 5)
-- - Statements with DECLARE: 3 (Statements 3, 4, 5)
-- - Statements using GETDATE(): 3 (Statements 3, 4, 5)
-- - Statements using SCOPE_IDENTITY(): 1 (Statement 3)
-- - Statements using LAG(): 1 (Statement 2)
-- - Statements using RANK/PERCENT_RANK: 1 (Statement 6)
-- ==============================================================================
