-- ==================================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Microsoft SQL Server to PostgreSQL Migration
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE for all statements
-- Total Statements: 7
-- ==================================================================================

-- ==================================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions (CONVERTED)
-- ==================================================================================
-- statement_id: STMT_001
-- conversion_method: MANUAL_AFTER_DMS_FAILURE
-- dms_status: ERROR - Metadata model conversion did not complete
-- sql_text:
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

-- Conversion notes: This query is PostgreSQL compatible as-is. Window functions (AVG OVER, COUNT OVER),
-- CTEs, CASE expressions, and ROUND function work identically in PostgreSQL.

-- ==================================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function (CONVERTED)
-- ==================================================================================
-- statement_id: STMT_002
-- conversion_method: MANUAL_AFTER_DMS_FAILURE
-- dms_status: ERROR - Metadata model conversion did not complete
-- sql_text:
WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = $1
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
WHERE p.ProductId = $1;

-- Conversion notes: Changed @ProductId to $1 for PostgreSQL positional parameter syntax.
-- LAG window function and CTE work identically in PostgreSQL.

-- ==================================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction (CONVERTED)
-- ==================================================================================
-- statement_id: STMT_003
-- conversion_method: MANUAL_AFTER_DMS_FAILURE
-- dms_status: ERROR - Statement definition is not valid
-- sql_text:
-- Transaction handling moved to application code, SQL statement for INSERT with RETURNING:
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES ($1, $2, $3, $4)
RETURNING ProductId;

-- Log the insertion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'INSERT', NULL, $2, NULL, $3, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + $1) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- Conversion notes: 
-- 1. Removed DECLARE and SET statements (not needed in PostgreSQL)
-- 2. SCOPE_IDENTITY() replaced with RETURNING clause on INSERT
-- 3. GETDATE() converted to CURRENT_TIMESTAMP
-- 4. @param style changed to $1, $2, $3, $4 positional parameters
-- 5. BEGIN TRANSACTION/COMMIT handled by NpgsqlTransaction in application code
-- 6. Returns the new ProductId directly from RETURNING clause

-- ==================================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction (CONVERTED)
-- ==================================================================================
-- statement_id: STMT_004
-- conversion_method: MANUAL_AFTER_DMS_FAILURE
-- dms_status: ERROR - Not attempted (multi-statement transaction)
-- sql_text:
-- Store old values for history (separate query)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = $1;

-- Update the product
UPDATE Products
SET 
    Name = $2,
    Description = $3,
    Price = $4,
    StockQuantity = $5,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = $1;

-- Log the changes
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'UPDATE', $2, $3, $4, $5, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - $2 + $3) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- Conversion notes:
-- 1. Removed DECLARE statements - variables handled in application code
-- 2. SELECT moved to separate query (first query in transaction)
-- 3. GETDATE() converted to CURRENT_TIMESTAMP
-- 4. @param style changed to $1, $2, etc. positional parameters
-- 5. Transaction boundaries (BEGIN/COMMIT) handled by NpgsqlTransaction

-- ==================================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction (CONVERTED)
-- ==================================================================================
-- statement_id: STMT_005
-- conversion_method: MANUAL_AFTER_DMS_FAILURE
-- dms_status: ERROR - Not attempted (multi-statement transaction)
-- sql_text:
-- Store product info for history (separate query)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = $1;

-- Log the deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'DELETE', $2, NULL, $3, NULL, CURRENT_TIMESTAMP);

-- Delete the product
DELETE FROM Products 
WHERE ProductId = $1;

-- Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - $2) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- Conversion notes:
-- 1. Removed DECLARE statements - variables handled in application code
-- 2. SELECT moved to separate query (first query in transaction)
-- 3. GETDATE() converted to CURRENT_TIMESTAMP
-- 4. @param style changed to $1, $2, $3 positional parameters
-- 5. Transaction boundaries (BEGIN/COMMIT) handled by NpgsqlTransaction

-- ==================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK (CONVERTED)
-- ==================================================================================
-- statement_id: STMT_006
-- conversion_method: MANUAL_AFTER_DMS_FAILURE
-- dms_status: ERROR - Metadata model conversion did not complete
-- sql_text:
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN $1 AND $2
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

-- Conversion notes: Changed @MinPrice and @MaxPrice to $1 and $2 for PostgreSQL positional parameters.
-- RANK() and PERCENT_RANK() window functions work identically in PostgreSQL.

-- ==================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Windows (CONVERTED)
-- ==================================================================================
-- statement_id: STMT_007
-- conversion_method: MANUAL_AFTER_DMS_FAILURE
-- dms_status: ERROR - Not attempted
-- sql_text:
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
        WHEN StockQuantity <= $1 THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= $1
ORDER BY StockQuantity;

-- Conversion notes: Changed @Threshold to $1 for PostgreSQL positional parameter.
-- Window functions (AVG, MIN, MAX OVER) work identically in PostgreSQL.

-- ==================================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- ==================================================================================
-- Conversion Summary:
-- - All 7 statements converted from SQL Server to PostgreSQL syntax
-- - DMS tool attempted for all statements but encountered errors
-- - Manual conversion performed following PostgreSQL best practices
-- - Key conversions: @param → $param, SCOPE_IDENTITY() → RETURNING, GETDATE() → CURRENT_TIMESTAMP
-- - Transaction handling moved from SQL to application code (NpgsqlTransaction)
-- ==================================================================================
