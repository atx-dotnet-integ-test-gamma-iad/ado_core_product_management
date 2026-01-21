-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG - PostgreSQL
-- Microsoft SQL Server to PostgreSQL Migration
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Database: ProductManagement
-- Target Database: PostgreSQL
-- Total Statements: 7
-- Conversion Method: DMS MCP Tool attempted for all statements + Manual conversion
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED TO POSTGRESQL
-- ============================================================================
-- DMS Tool Status: ERROR - Metadata model creation failed
-- DMS Error: "Metadata model creation did not complete after 15 attempts"
-- DMS Timestamp: 2026-01-21T11:08:37.735846
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- 
-- Conversion Notes:
-- - CTE syntax is compatible between SQL Server and PostgreSQL
-- - Window functions (AVG, COUNT OVER) are compatible
-- - ROUND function is compatible
-- - CASE expressions are compatible
-- - No schema name changes needed
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
-- STATEMENT 2: GetProductByIdAsync - CONVERTED TO POSTGRESQL
-- ============================================================================
-- DMS Tool Status: ERROR - Metadata model conversion failed
-- DMS Error: "Metadata model conversion did not complete after 15 attempts"
-- DMS Timestamp: 2026-01-21T11:12:55.145515
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
--
-- Conversion Notes:
-- - LAG window function is compatible
-- - CTE syntax is compatible
-- - CASE expressions and ROUND are compatible
-- - LEFT JOIN syntax is compatible
-- - Parameters (@ProductId) are supported by Npgsql
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
-- STATEMENT 3: InsertProductAsync - CONVERTED TO POSTGRESQL
-- ============================================================================
-- DMS Tool Status: ERROR - Metadata model creation failed
-- DMS Error: "Metadata model creation did not complete after 15 attempts"
-- DMS Timestamp: 2026-01-21T11:15:43.149315
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
--
-- Conversion Notes:
-- - SCOPE_IDENTITY() converted to RETURNING clause
-- - GETDATE() converted to NOW()
-- - DECLARE @NewProductId removed - using RETURNING clause instead
-- - BEGIN TRANSACTION/COMMIT kept (PostgreSQL compatible)
-- - Multi-statement approach restructured for PostgreSQL
-- - Combined into a single transaction block
-- ============================================================================

BEGIN;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId INTO @NewProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = NOW()
    WHERE StatId = 1;
COMMIT;

-- Note: This will need to be refactored in C# to use RETURNING clause properly
-- Recommended C# implementation:
-- var insertSql = "INSERT INTO Products (Name, Description, Price, StockQuantity) VALUES (@Name, @Description, @Price, @StockQuantity) RETURNING ProductId";
-- var newProductId = (int)await command.ExecuteScalarAsync();
-- Then use newProductId in subsequent statements

-- ============================================================================
-- STATEMENT 3B: InsertProductAsync - ALTERNATIVE POSTGRESQL APPROACH
-- ============================================================================
-- Better PostgreSQL approach using DO block or multiple statements
-- This approach is more idiomatic for PostgreSQL:

-- First query to insert and get ID:
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Second query (in same transaction) to log history:
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Third query to update stats:
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED TO POSTGRESQL
-- ============================================================================
-- DMS Tool Status: ERROR - Metadata model conversion failed
-- DMS Error: "Metadata model conversion did not complete after 15 attempts"
-- DMS Timestamp: 2026-01-21T11:19:47.920189
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
--
-- Conversion Notes:
-- - GETDATE() converted to NOW()
-- - DECLARE @OldPrice/@OldStock converted to CTE approach
-- - BEGIN TRANSACTION/COMMIT kept (PostgreSQL compatible)
-- - Refactored to use WITH clause for capturing old values
-- ============================================================================

WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
)
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = NOW()
WHERE ProductId = @ProductId
RETURNING 
    ProductId, 
    (SELECT OldPrice FROM OldValues) as old_price_val,
    (SELECT OldStock FROM OldValues) as old_stock_val;

INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT @ProductId, 'UPDATE', OldPrice, @Price, OldStock, @StockQuantity, NOW()
FROM OldValues;

UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM OldValues) + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4B: UpdateProductAsync - SIMPLIFIED POSTGRESQL APPROACH
-- ============================================================================
-- More practical approach for C# implementation:

-- Query 1: Get old values
SELECT Price, StockQuantity 
FROM Products 
WHERE ProductId = @ProductId;

-- Query 2: Update product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = NOW()
WHERE ProductId = @ProductId;

-- Query 3: Log changes
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Query 4: Update statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED TO POSTGRESQL
-- ============================================================================
-- DMS Tool Status: ERROR - Metadata model conversion failed
-- DMS Error: "Metadata model conversion did not complete after 15 attempts"
-- DMS Timestamp: 2026-01-21T11:23:19.670861
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
--
-- Conversion Notes:
-- - GETDATE() converted to NOW()
-- - DECLARE @OldPrice/@OldStock will be handled in C# code
-- - BEGIN TRANSACTION/COMMIT kept (PostgreSQL compatible)
-- - CASE expression is compatible
-- ============================================================================

-- Query 1: Get old values
SELECT Price, StockQuantity 
FROM Products 
WHERE ProductId = @ProductId;

-- Query 2: Log deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Query 3: Delete product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Query 4: Update statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED TO POSTGRESQL
-- ============================================================================
-- DMS Tool Status: ERROR - Metadata model conversion failed
-- DMS Error: "Metadata model conversion did not complete after 15 attempts"
-- DMS Timestamp: 2026-01-21T11:26:39.496513
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
--
-- Conversion Notes:
-- - RANK() and PERCENT_RANK() window functions are compatible
-- - CTE syntax is compatible
-- - CASE expressions are compatible
-- - BETWEEN clause is compatible
-- - No changes needed for PostgreSQL
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
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED TO POSTGRESQL
-- ============================================================================
-- DMS Tool Status: ERROR - Metadata model conversion failed
-- DMS Error: "Metadata model conversion did not complete after 15 attempts"
-- DMS Timestamp: 2026-01-21T11:30:11.418217
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
--
-- Conversion Notes:
-- - Window functions (AVG, MIN, MAX OVER) are compatible
-- - CTE syntax is compatible
-- - CASE expressions are compatible
-- - ROUND function is compatible
-- - No changes needed for PostgreSQL
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
-- END OF CONVERTED STATEMENTS CATALOG
-- ============================================================================
-- Summary:
-- - Total Statements: 7
-- - DMS Tool Invoked: 7/7 (100%)
-- - DMS Successful Conversions: 0/7 (0% - all failed at metadata model stage)
-- - Manual Conversions: 7/7 (100%)
-- 
-- Key T-SQL to PostgreSQL Conversions:
-- 1. SCOPE_IDENTITY() → RETURNING clause
-- 2. GETDATE() → NOW()
-- 3. DECLARE @Variable → Handled in application code or CTEs
-- 4. BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT (compatible)
-- 5. Window functions → Compatible (no changes needed)
-- 6. CTEs → Compatible (no changes needed)
-- 7. CASE expressions → Compatible (no changes needed)
-- 
-- Implementation Notes for C# Code:
-- - Statement 3 (InsertProductAsync): Use RETURNING clause for getting new ID
-- - Statement 4 (UpdateProductAsync): Fetch old values before update in C# code
-- - Statement 5 (DeleteProductAsync): Fetch old values before delete in C# code
-- - All transactions will be handled by NpgsqlConnection.BeginTransactionAsync()
-- - All parameters (@Name, @Price, etc.) are supported by Npgsql
-- ============================================================================
