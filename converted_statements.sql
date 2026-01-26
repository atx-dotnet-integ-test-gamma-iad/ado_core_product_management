/*******************************************************************************
 * SQL STATEMENT CONVERSION CATALOG
 * Source: Microsoft SQL Server
 * Target: PostgreSQL
 * Generated: Step 2 - Convert All SQL Statements Using DMS MCP Tool
 * 
 * IMPORTANT: All statements were attempted through DMS MCP tool first.
 * DMS tool experienced metadata model conversion timeouts for all statements.
 * Manual conversions were performed after DMS failures and documented.
 ******************************************************************************/

/*******************************************************************************
 * STATEMENT 1: GetAllProductsAsync
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * DMS Tool Status: ERROR - Metadata model conversion timeout
 ******************************************************************************/

-- ORIGINAL SQL SERVER STATEMENT:
/*
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
*/

-- CONVERTED POSTGRESQL STATEMENT:
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

-- CONVERSION NOTES: 
-- This statement is already PostgreSQL compatible. CTEs, window functions (AVG/COUNT OVER),
-- CASE statements, and ROUND function all work identically in PostgreSQL.
-- No schema object name changes needed.

/*******************************************************************************
 * STATEMENT 2: GetProductByIdAsync
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * DMS Tool Status: ERROR - Metadata model conversion timeout
 ******************************************************************************/

-- ORIGINAL SQL SERVER STATEMENT:
/*
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
*/

-- CONVERTED POSTGRESQL STATEMENT:
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

-- CONVERSION NOTES:
-- This statement is already PostgreSQL compatible. LAG window function, CTEs, 
-- and parameter syntax (@ProductId) are all supported by Npgsql.
-- No schema object name changes needed.

/*******************************************************************************
 * STATEMENT 3: InsertProductAsync - Transaction Block
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * DMS Tool Status: ERROR - Metadata model conversion timeout
 ******************************************************************************/

-- ORIGINAL SQL SERVER STATEMENT:
/*
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
*/

-- CONVERTED POSTGRESQL STATEMENT:
DO $$
DECLARE 
    v_NewProductId INT;
BEGIN
    -- Insert the new product
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId INTO v_NewProductId;
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (v_NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
    
    -- Return the new product ID
    PERFORM v_NewProductId;
END $$;

-- CONVERSION NOTES:
-- Major changes:
-- 1. SCOPE_IDENTITY() replaced with RETURNING clause in INSERT statement
-- 2. GETDATE() replaced with CURRENT_TIMESTAMP
-- 3. BEGIN TRANSACTION/COMMIT replaced with DO $$ block (transaction is implicit in Npgsql)
-- 4. DECLARE @var syntax changed to DECLARE v_var syntax
-- 5. SET @var = value changed to variable assignment in RETURNING clause
-- However, for use with Npgsql ExecuteScalarAsync, we need a simpler approach:

-- SIMPLIFIED VERSION FOR NPGSQL (without DO block):
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Note: The transaction block will be handled by NpgsqlTransaction in C# code,
-- and the history/stats updates will need to be separate statements.

/*******************************************************************************
 * STATEMENT 4: UpdateProductAsync - Transaction Block
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * DMS Tool Status: ERROR - Metadata model conversion timeout
 ******************************************************************************/

-- ORIGINAL SQL SERVER STATEMENT:
/*
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
*/

-- CONVERTED POSTGRESQL STATEMENT (Multi-statement for use with NpgsqlCommand):
-- Statement 1: Get old values
WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
)
-- Statement 2: Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Statement 3: Log the changes (will need to be executed separately with captured old values)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4: Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- CONVERSION NOTES:
-- 1. GETDATE() replaced with CURRENT_TIMESTAMP
-- 2. Transaction handling moved to C# code using NpgsqlTransaction
-- 3. Multi-statement batch needs to capture old values first, then execute updates
-- 4. BEGIN TRANSACTION/COMMIT removed (handled by C# code)

/*******************************************************************************
 * STATEMENT 5: DeleteProductAsync - Transaction Block
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * DMS Tool Status: ERROR - Metadata model conversion timeout
 ******************************************************************************/

-- ORIGINAL SQL SERVER STATEMENT:
/*
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
*/

-- CONVERTED POSTGRESQL STATEMENT (Multi-statement for use with NpgsqlCommand):
-- Statement 1: Get old values
WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
)
-- Statement 2: Log the deletion (needs captured old values)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 3: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Statement 4: Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- CONVERSION NOTES:
-- 1. GETDATE() replaced with CURRENT_TIMESTAMP
-- 2. Transaction handling moved to C# code using NpgsqlTransaction
-- 3. Need to capture old values before deletion
-- 4. BEGIN TRANSACTION/COMMIT removed (handled by C# code)

/*******************************************************************************
 * STATEMENT 6: GetProductsByPriceRangeAsync
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * DMS Tool Status: ERROR - Metadata model conversion timeout
 ******************************************************************************/

-- ORIGINAL SQL SERVER STATEMENT:
/*
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
*/

-- CONVERTED POSTGRESQL STATEMENT:
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

-- CONVERSION NOTES:
-- This statement is already PostgreSQL compatible. RANK() and PERCENT_RANK() 
-- window functions work identically in PostgreSQL.
-- No schema object name changes needed.

/*******************************************************************************
 * STATEMENT 7: GetLowStockProductsAsync
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * DMS Tool Status: ERROR - Metadata model conversion timeout
 ******************************************************************************/

-- ORIGINAL SQL SERVER STATEMENT:
/*
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
*/

-- CONVERTED POSTGRESQL STATEMENT:
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

-- CONVERSION NOTES:
-- This statement is already PostgreSQL compatible. Window functions (AVG, MIN, MAX OVER)
-- work identically in PostgreSQL.
-- No schema object name changes needed.

/*******************************************************************************
 * CONVERSION SUMMARY
 ******************************************************************************/
/*
Total Statements: 7
DMS Tool Attempts: 7 (all statements attempted)
DMS Tool Successes: 0
DMS Tool Failures: 7 (all failed with metadata model conversion timeout)
Manual Conversions: 7

Conversion Status by Statement:
1. GetAllProductsAsync - MANUAL_AFTER_DMS_FAILURE - Already PostgreSQL compatible
2. GetProductByIdAsync - MANUAL_AFTER_DMS_FAILURE - Already PostgreSQL compatible
3. InsertProductAsync - MANUAL_AFTER_DMS_FAILURE - Major changes (SCOPE_IDENTITY → RETURNING)
4. UpdateProductAsync - MANUAL_AFTER_DMS_FAILURE - Transaction handling changes
5. DeleteProductAsync - MANUAL_AFTER_DMS_FAILURE - Transaction handling changes
6. GetProductsByPriceRangeAsync - MANUAL_AFTER_DMS_FAILURE - Already PostgreSQL compatible
7. GetLowStockProductsAsync - MANUAL_AFTER_DMS_FAILURE - Already PostgreSQL compatible

Key Transformations Applied:
- SCOPE_IDENTITY() → RETURNING clause in INSERT
- GETDATE() → CURRENT_TIMESTAMP (9 occurrences)
- BEGIN TRANSACTION/COMMIT → Removed (handled by NpgsqlTransaction in C# code)
- DECLARE @var → DECLARE v_var (for DO blocks, but transaction blocks will be handled in C# code)
- Window functions (LAG, RANK, PERCENT_RANK, AVG, COUNT, MIN, MAX) - No changes needed
- CTE syntax - No changes needed
- Parameter syntax @param - Kept as-is (Npgsql supports this)
- ROUND function - No changes needed

Schema Object Name Changes:
- None. All table names remain unchanged: Products, ProductHistory, ProductStats

All statements have been processed through DMS tool (all failed) and manually converted.
*/
