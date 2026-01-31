-- ============================================================================
-- SQL Statement Extraction Catalog for PostgreSQL Migration
-- Source: AdoCore ADO.NET Application
-- Extraction Date: 2026-01-31
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Range: 39-69
-- Method Name: GetAllProductsAsync
-- Statement Type: SELECT with CTE
-- Parameters: None
-- Transaction: No
-- Special Features: 
--   - Common Table Expression (CTE) - ProductStats
--   - Window Functions: AVG() OVER(), COUNT() OVER()
--   - CASE expressions for PriceCategory
--   - INNER JOIN
--   - Complex ORDER BY with CASE
-- Notes: Uses window functions to calculate average price and total products,
--        then categorizes products based on price relative to average.
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
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Range: 83-110
-- Method Name: GetProductByIdAsync
-- Statement Type: SELECT with CTE
-- Parameters: 
--   - @ProductId (INT) - Product identifier
-- Transaction: No
-- Special Features:
--   - Common Table Expression (CTE) - ProductHistory
--   - LAG() window function for previous values
--   - LEFT JOIN
--   - CASE expression for percentage calculation
--   - NULL handling (IS NOT NULL)
-- Notes: Retrieves product with historical price and stock data using LAG
--        window function to access previous values.
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
-- STATEMENT 3: InsertProductAsync - Transaction Block with Multiple Statements
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Range: 121-145
-- Method Name: InsertProductAsync
-- Statement Type: INSERT (Transaction Block)
-- Parameters:
--   - @Name (VARCHAR) - Product name
--   - @Description (VARCHAR, nullable) - Product description
--   - @Price (DECIMAL(18,2)) - Product price
--   - @StockQuantity (INT) - Stock quantity
-- Transaction: Yes (BEGIN TRANSACTION / COMMIT)
-- Special Features:
--   - DECLARE variable (@NewProductId)
--   - BEGIN TRANSACTION / COMMIT block
--   - Multiple INSERT statements
--   - SCOPE_IDENTITY() for retrieving last inserted ID
--   - GETDATE() function (3 occurrences)
--   - UPDATE statement within transaction
--   - Final SELECT to return new ID
-- Notes: Complex transaction inserting product, logging to history,
--        and updating statistics. SCOPE_IDENTITY() must be converted to
--        PostgreSQL RETURNING clause. GETDATE() converts to NOW() or CURRENT_TIMESTAMP.
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
-- STATEMENT 4: UpdateProductAsync - Transaction Block with History Logging
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Range: 158-186
-- Method Name: UpdateProductAsync
-- Statement Type: UPDATE (Transaction Block)
-- Parameters:
--   - @ProductId (INT) - Product identifier
--   - @Name (VARCHAR) - Product name
--   - @Description (VARCHAR, nullable) - Product description
--   - @Price (DECIMAL(18,2)) - Product price
--   - @StockQuantity (INT) - Stock quantity
-- Transaction: Yes (BEGIN TRANSACTION / COMMIT)
-- Special Features:
--   - DECLARE variables (@OldPrice, @OldStock)
--   - BEGIN TRANSACTION / COMMIT block
--   - SELECT to capture old values
--   - UPDATE statement
--   - INSERT statement (history logging)
--   - GETDATE() function (3 occurrences)
--   - UPDATE ProductStats
-- Notes: Transaction captures old values, updates product, logs changes
--        to history, and updates statistics. GETDATE() converts to NOW().
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
-- STATEMENT 5: DeleteProductAsync - Transaction Block with Cleanup
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Range: 199-228
-- Method Name: DeleteProductAsync
-- Statement Type: DELETE (Transaction Block)
-- Parameters:
--   - @ProductId (INT) - Product identifier
-- Transaction: Yes (BEGIN TRANSACTION / COMMIT)
-- Special Features:
--   - DECLARE variables (@OldPrice, @OldStock)
--   - BEGIN TRANSACTION / COMMIT block
--   - SELECT to capture values before delete
--   - INSERT statement (history logging)
--   - DELETE statement
--   - UPDATE statement with CASE expression
--   - GETDATE() function (2 occurrences)
-- Notes: Transaction logs deletion to history before removing product,
--        then updates statistics with CASE to handle last product deletion.
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Range: 242-263
-- Method Name: GetProductsByPriceRangeAsync
-- Statement Type: SELECT with CTE
-- Parameters:
--   - @MinPrice (DECIMAL(18,2)) - Minimum price
--   - @MaxPrice (DECIMAL(18,2)) - Maximum price
-- Transaction: No
-- Special Features:
--   - Common Table Expression (CTE) - RankedProducts
--   - RANK() window function
--   - PERCENT_RANK() window function
--   - BETWEEN clause for range filtering
--   - CASE expression for segmentation
--   - Wildcard projection (p.*)
-- Notes: Uses ranking window functions to categorize products within
--        price range into Budget/Mid-Range/Premium segments.
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
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Range: 277-303
-- Method Name: GetLowStockProductsAsync
-- Statement Type: SELECT with CTE
-- Parameters:
--   - @Threshold (INT) - Stock quantity threshold
-- Transaction: No
-- Special Features:
--   - Common Table Expression (CTE) - StockAnalysis
--   - Multiple window functions: AVG() OVER(), MIN() OVER(), MAX() OVER()
--   - CASE expression for status categorization
--   - Wildcard projection (p.*)
--   - Arithmetic calculation with window function result
-- Notes: Analyzes stock levels using multiple window functions to calculate
--        aggregate statistics and categorize products below threshold.
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
-- Total SQL Statements: 7
-- SELECT Statements: 4 (Statements 1, 2, 6, 7)
-- INSERT Statements: 1 (Statement 3 - with transaction)
-- UPDATE Statements: 1 (Statement 4 - with transaction)
-- DELETE Statements: 1 (Statement 5 - with transaction)
-- Transaction Blocks: 3 (Statements 3, 4, 5)
-- CTEs Used: 5 (Statements 1, 2, 6, 7 - Statement 7 has 1 CTE)
-- Window Functions: All 7 statements use window functions
-- SCOPE_IDENTITY(): 1 occurrence (Statement 3)
-- GETDATE(): 8 total occurrences (3 in Statement 3, 3 in Statement 4, 2 in Statement 5)
-- Parameters: 9 unique parameters across all statements
--
-- Key Conversion Challenges:
-- 1. SCOPE_IDENTITY() -> PostgreSQL RETURNING clause
-- 2. GETDATE() -> NOW() or CURRENT_TIMESTAMP
-- 3. Transaction syntax (BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT)
-- 4. Parameter syntax (@param might need conversion to $1, $2, etc.)
-- 5. DECLARE syntax and variable usage
-- 6. Window function syntax variations
-- 7. Data type compatibility (DECIMAL, INT, VARCHAR, DATETIME)
-- ============================================================================
