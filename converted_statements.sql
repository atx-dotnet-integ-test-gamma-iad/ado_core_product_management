-- ====================================================================================================
-- CONVERTED SQL STATEMENTS FROM MS SQL SERVER TO POSTGRESQL
-- ====================================================================================================
-- Conversion Date: 2026-02-02
-- Total SQL Operations: 7
-- Conversion Method: Manual conversion after DMS tool failures (documented in dms_conversion_log.json)
-- Target Database: PostgreSQL
-- ====================================================================================================

-- ====================================================================================================
-- STATEMENT 1: GetAllProductsAsync - SELECT with CTE and Window Functions
-- ====================================================================================================
-- Conversion Notes:
-- - CTE syntax is compatible between MS SQL Server and PostgreSQL
-- - Window functions (AVG OVER, COUNT OVER) are compatible
-- - CASE expressions are compatible
-- - ROUND function is compatible
-- - Changed cast behavior for ROUND to use NUMERIC for precision
-- - No schema name changes needed
-- ====================================================================================================

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
    ROUND(CAST((p.Price / ps.AvgPrice) * 100 AS NUMERIC), 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name;

-- ====================================================================================================
-- STATEMENT 2: GetProductByIdAsync - SELECT with CTE and LAG Window Function
-- ====================================================================================================
-- Conversion Notes:
-- - CTE syntax is compatible
-- - LAG window function is compatible in PostgreSQL
-- - LEFT JOIN syntax is compatible
-- - CASE expression is compatible
-- - ROUND function adjusted to use NUMERIC cast for precision
-- - Parameter @ProductId uses same syntax in both databases
-- ====================================================================================================

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
            ROUND(CAST(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100 AS NUMERIC), 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;

-- ====================================================================================================
-- STATEMENT 3: InsertProductAsync - Transaction Block with INSERT and RETURNING Clause
-- ====================================================================================================
-- Conversion Notes:
-- - DECLARE @variable removed (PostgreSQL doesn't require pre-declaration in simple transactions)
-- - BEGIN TRANSACTION changed to BEGIN
-- - SCOPE_IDENTITY() replaced with RETURNING clause in INSERT statement
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- - SET @variable removed (value captured via RETURNING)
-- - Transaction structure: BEGIN...COMMIT
-- - Multiple statements combined; final SELECT replaced with RETURNING in first INSERT
-- - This requires refactoring into multiple commands in C# code or using DO blocks
-- ====================================================================================================

-- Note: This conversion requires code-level changes to capture RETURNING value
-- The transaction should be executed as follows in PostgreSQL:

BEGIN;
    -- Insert the new product and return the new ID
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId;
    
    -- Note: The following statements would use the returned ProductId
    -- In actual implementation, this needs to be split into separate commands
    -- or use a DO block with variables
    
    -- Log the insertion (using the returned ProductId from above)
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- ====================================================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction Block with Variables
-- ====================================================================================================
-- Conversion Notes:
-- - BEGIN TRANSACTION changed to BEGIN
-- - DECLARE statements moved inside DO block (PostgreSQL approach)
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- - SELECT INTO variables compatible with minor syntax adjustments
-- - PostgreSQL requires DO $$ block for procedural code with variables
-- ====================================================================================================

-- PostgreSQL version using DO block:
DO $$
DECLARE
    old_price DECIMAL(18,2);
    old_stock INT;
BEGIN
    -- Store old values for history
    SELECT Price, StockQuantity INTO old_price, old_stock
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Update the product
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', old_price, @Price, old_stock, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - old_price + @Price) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- ====================================================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction Block with Complex CASE Logic
-- ====================================================================================================
-- Conversion Notes:
-- - BEGIN TRANSACTION changed to BEGIN
-- - DECLARE statements moved inside DO block
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- - CASE expression in UPDATE is compatible
-- - PostgreSQL requires DO $$ block for procedural code with variables
-- ====================================================================================================

-- PostgreSQL version using DO block:
DO $$
DECLARE
    old_price DECIMAL(18,2);
    old_stock INT;
BEGIN
    -- Store product info for history
    SELECT Price, StockQuantity INTO old_price, old_stock
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', old_price, NULL, old_stock, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - old_price) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- ====================================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - SELECT with CTE, RANK, and PERCENT_RANK
-- ====================================================================================================
-- Conversion Notes:
-- - CTE syntax is compatible
-- - RANK() OVER and PERCENT_RANK() OVER are compatible in PostgreSQL
-- - BETWEEN clause is compatible
-- - CASE expression is compatible
-- - No changes needed except table aliases
-- ====================================================================================================

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

-- ====================================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - SELECT with CTE and Aggregate Window Functions
-- ====================================================================================================
-- Conversion Notes:
-- - CTE syntax is compatible
-- - Window functions (AVG OVER, MIN OVER, MAX OVER) are compatible
-- - CASE expression is compatible
-- - ROUND function adjusted to use NUMERIC cast
-- - No schema changes needed
-- ====================================================================================================

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
    ROUND(CAST((StockQuantity / AvgStock) * 100 AS NUMERIC), 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;

-- ====================================================================================================
-- END OF CONVERTED SQL STATEMENTS
-- ====================================================================================================
-- IMPORTANT IMPLEMENTATION NOTES:
-- 
-- For Statements 3, 4, and 5 (Transaction blocks with variables):
-- These conversions show PostgreSQL DO blocks, but in ADO.NET code, these should be executed as
-- separate commands within a transaction using NpgsqlConnection.BeginTransaction().
-- 
-- Key differences:
-- 1. SCOPE_IDENTITY() → Use RETURNING clause and capture with ExecuteScalar
-- 2. GETDATE() → CURRENT_TIMESTAMP or NOW()
-- 3. BEGIN TRANSACTION → BEGIN (or use DbConnection.BeginTransaction())
-- 4. Variables: Use code-level variables instead of SQL variables when possible
-- 5. DECLARE: Not needed in simple transactions; use in DO blocks if necessary
-- 
-- Recommended C# implementation pattern:
-- - Use NpgsqlTransaction for transaction control
-- - Capture RETURNING values with ExecuteScalarAsync()
-- - Pass values between statements using C# variables
-- - Avoid DO blocks unless absolutely necessary for complex procedural logic
-- ====================================================================================================
