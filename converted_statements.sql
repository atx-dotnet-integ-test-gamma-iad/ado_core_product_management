-- ============================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- ============================================================================
-- Source Project: AdoCore (Microsoft SQL Server to PostgreSQL Migration)
-- Conversion Date: 2025-02-09
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (All statements)
-- DMS Tool Status: Metadata model creation failed for all statements
-- ============================================================================

-- ============================================================================
-- STATEMENT ID: 1
-- Method: GetAllProductsAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================================================
-- Key Conversions:
-- - No changes needed for CTE syntax (compatible with PostgreSQL)
-- - Window functions (AVG OVER, COUNT OVER) are compatible
-- - CASE expressions are compatible
-- - ROUND function is compatible
-- - No SQL Server-specific functions in this query
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
-- STATEMENT ID: 2
-- Method: GetProductByIdAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================================================
-- Key Conversions:
-- - LAG window function syntax is compatible
-- - LEFT JOIN is compatible
-- - CASE expressions are compatible
-- - Parameter @ProductId remains (Npgsql handles it)
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
-- STATEMENT ID: 3
-- Method: InsertProductAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================================================
-- Key Conversions:
-- - Replaced SCOPE_IDENTITY() with RETURNING clause on INSERT
-- - Replaced GETDATE() with CURRENT_TIMESTAMP
-- - Transaction managed in C# code (BeginTransactionAsync), not in SQL
-- - This version is split into separate statements to be executed within a C# transaction
-- ============================================================================

-- NOTE: This statement should be executed as separate commands within a C# transaction:
-- 1. INSERT with RETURNING
-- 2. INSERT into ProductHistory using returned ID
-- 3. UPDATE ProductStats
--
-- For single-statement execution, use this combined version:
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- ============================================================================
-- STATEMENT ID: 4
-- Method: UpdateProductAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================================================
-- Key Conversions:
-- - Replaced GETDATE() with CURRENT_TIMESTAMP
-- - Transaction managed in C# code (BeginTransactionAsync), not in SQL
-- - Old values retrieved in C# code before update
-- - This is split into separate statements to be executed within a C# transaction
-- ============================================================================

-- NOTE: This statement should be executed as separate commands within a C# transaction:
-- 1. SELECT to get old values (in C#)
-- 2. UPDATE Products
-- 3. INSERT into ProductHistory
-- 4. UPDATE ProductStats
--
-- Main UPDATE statement:
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- ============================================================================
-- STATEMENT ID: 5
-- Method: DeleteProductAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================================================
-- Key Conversions:
-- - Replaced GETDATE() with CURRENT_TIMESTAMP
-- - Transaction managed in C# code (BeginTransactionAsync), not in SQL
-- - Old values retrieved in C# code before deletion
-- - This is split into separate statements to be executed within a C# transaction
-- - CASE expression is compatible
-- ============================================================================

-- NOTE: This statement should be executed as separate commands within a C# transaction:
-- 1. SELECT to get old values (in C#)
-- 2. INSERT into ProductHistory
-- 3. DELETE from Products
-- 4. UPDATE ProductStats
--
-- Main DELETE statement:
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- ============================================================================
-- STATEMENT ID: 6
-- Method: GetProductsByPriceRangeAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================================================
-- Key Conversions:
-- - RANK() and PERCENT_RANK() window functions are compatible
-- - BETWEEN clause is compatible
-- - CASE expression is compatible
-- - No SQL Server-specific syntax in this query
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
-- STATEMENT ID: 7
-- Method: GetLowStockProductsAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================================================
-- Key Conversions:
-- - AVG/MIN/MAX window functions are compatible
-- - CASE expression is compatible
-- - ROUND function is compatible
-- - No SQL Server-specific syntax in this query
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
-- END OF CONVERTED STATEMENTS
-- ============================================================================
-- IMPORTANT NOTES FOR C# CODE INTEGRATION:
-- 
-- 1. Statements 1, 2, 6, and 7 (SELECT queries):
--    - These are directly compatible with PostgreSQL
--    - No changes needed to C# code structure
--    - Just replace the SQL string with the converted version
--
-- 2. Statement 3 (INSERT):
--    - Use RETURNING clause instead of SCOPE_IDENTITY()
--    - Execute INSERT with ExecuteScalarAsync() to get the returned ProductId
--    - Execute subsequent INSERT and UPDATE within a transaction
--
-- 3. Statements 4 and 5 (UPDATE and DELETE transactions):
--    - Retrieve old values with a separate SELECT query first
--    - Store values in C# variables
--    - Execute UPDATE/DELETE and other statements using the C# variables
--    - All within an explicit NpgsqlTransaction
--
-- 4. Npgsql supports @parameter syntax (same as SQL Server), so parameter
--    markers do not need to be changed to $1, $2, etc.
--
-- 5. Replace GETDATE() with CURRENT_TIMESTAMP throughout
--
-- 6. Transaction management in C# should use NpgsqlTransaction explicitly:
--    - await connection.BeginTransactionAsync()
--    - await transaction.CommitAsync()
--    - await transaction.RollbackAsync()
-- ============================================================================
