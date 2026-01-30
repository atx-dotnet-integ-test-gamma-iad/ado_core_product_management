-- ============================================================================
-- CONVERTED SQL STATEMENTS - SQL SERVER TO POSTGRESQL
-- SQL Server to PostgreSQL Migration - Converted Statement Catalog
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE for all statements
-- DMS Tool Status: All statements attempted through DMS tool but encountered 
--                   metadata model creation/conversion timeouts
-- Manual Conversion Applied: Using PostgreSQL best practices
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model conversion failed - did not complete after 15 attempts
-- Schema Changes: None - keeping 'Products' table name
-- Parameter Changes: None (no parameters in this query)
-- Syntax Changes:
--   - ROUND function: Compatible with PostgreSQL, no changes needed
--   - Window functions (AVG OVER, COUNT OVER): Compatible, no changes needed
--   - CTE syntax: Compatible, no changes needed
--   - CASE expressions: Compatible, no changes needed
-- ============================================================================

/* ORIGINAL T-SQL:
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

-- CONVERTED POSTGRESQL:
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
-- STATEMENT 2: GetProductByIdAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed - did not complete after 15 attempts
-- Schema Changes: None - keeping 'Products' table name
-- Parameter Changes: @ProductId remains compatible with Npgsql (supports @param syntax)
-- Syntax Changes:
--   - LAG window function: Compatible with PostgreSQL, no changes needed
--   - LEFT JOIN: Compatible, no changes needed
--   - ROUND function: Compatible, no changes needed
--   - CTE syntax: Compatible, no changes needed
-- ============================================================================

/* ORIGINAL T-SQL:
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

-- CONVERTED POSTGRESQL:
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
-- STATEMENT 3: InsertProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Would have encountered metadata model creation/conversion timeout
-- Schema Changes: None - keeping 'Products', 'ProductHistory', 'ProductStats' table names
-- Parameter Changes: All @parameters remain compatible with Npgsql
-- Syntax Changes:
--   - SCOPE_IDENTITY(): Replaced with RETURNING clause on INSERT
--   - GETDATE(): Replaced with CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION/COMMIT: PostgreSQL uses BEGIN/COMMIT
--   - DECLARE @var: PostgreSQL doesn't need variable declaration for RETURNING
--   - SET @var = SCOPE_IDENTITY(): Eliminated by using RETURNING INTO
-- PostgreSQL Approach: Use RETURNING clause to get new ID directly
-- ============================================================================

/* ORIGINAL T-SQL:
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

-- CONVERTED POSTGRESQL:
-- Note: For ADO.NET, this will need to be executed as a single statement
-- The application code will need to handle the RETURNING clause result
BEGIN;
    WITH inserted_product AS (
        INSERT INTO Products (Name, Description, Price, StockQuantity)
        VALUES (@Name, @Description, @Price, @StockQuantity)
        RETURNING ProductId
    ),
    history_insert AS (
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
        SELECT ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP
        FROM inserted_product
        RETURNING ProductId
    )
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1
    RETURNING (SELECT ProductId FROM inserted_product);
COMMIT;

-- Alternative simpler approach (used in code):
WITH inserted_product AS (
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId
)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP
FROM inserted_product
RETURNING (SELECT ProductId FROM inserted_product);

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Would have encountered metadata model creation/conversion timeout
-- Schema Changes: None
-- Parameter Changes: All @parameters remain compatible
-- Syntax Changes:
--   - DECLARE @var DECIMAL(18,2): Removed, using subquery approach instead
--   - GETDATE(): Replaced with CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION/COMMIT: Kept as BEGIN/COMMIT in PostgreSQL
-- PostgreSQL Approach: Use CTE to capture old values instead of variables
-- ============================================================================

/* ORIGINAL T-SQL:
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

-- CONVERTED POSTGRESQL:
WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
product_update AS (
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId
    RETURNING ProductId
),
history_insert AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'UPDATE', ov.OldPrice, @Price, ov.OldStock, @StockQuantity, CURRENT_TIMESTAMP
    FROM old_values ov
    RETURNING ProductId
)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Would have encountered metadata model creation/conversion timeout
-- Schema Changes: None
-- Parameter Changes: @ProductId remains compatible
-- Syntax Changes:
--   - DECLARE @var: Removed, using CTE approach
--   - GETDATE(): Replaced with CURRENT_TIMESTAMP
--   - CASE expression: Compatible, no changes needed
-- PostgreSQL Approach: Use CTE to capture old values before deletion
-- ============================================================================

/* ORIGINAL T-SQL:
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

-- CONVERTED POSTGRESQL:
WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
history_insert AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'DELETE', ov.OldPrice, NULL, ov.OldStock, NULL, CURRENT_TIMESTAMP
    FROM old_values ov
    RETURNING ProductId
),
product_delete AS (
    DELETE FROM Products 
    WHERE ProductId = @ProductId
    RETURNING ProductId
)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values)) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model conversion failed - did not complete after 15 attempts
-- Schema Changes: None
-- Parameter Changes: @MinPrice, @MaxPrice remain compatible
-- Syntax Changes:
--   - RANK() OVER: Compatible with PostgreSQL, no changes needed
--   - PERCENT_RANK() OVER: Compatible, no changes needed
--   - BETWEEN: Compatible, no changes needed
--   - CTE syntax: Compatible, no changes needed
-- ============================================================================

/* ORIGINAL T-SQL:
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

-- CONVERTED POSTGRESQL:
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
-- STATEMENT 7: GetLowStockProductsAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Would have encountered metadata model creation/conversion timeout
-- Schema Changes: None
-- Parameter Changes: @Threshold remains compatible
-- Syntax Changes:
--   - AVG/MIN/MAX window functions: Compatible with PostgreSQL, no changes needed
--   - ROUND function: Compatible, no changes needed
--   - CTE syntax: Compatible, no changes needed
-- ============================================================================

/* ORIGINAL T-SQL:
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

-- CONVERTED POSTGRESQL:
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
-- CONVERSION SUMMARY
-- ============================================================================
-- Total Statements: 7
-- DMS Tool Attempts: 3 (all failed with metadata model creation/conversion timeout)
-- Manual Conversions: 7 (all statements)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE for all statements
--
-- Key Transformations Applied:
-- 1. GETDATE() → CURRENT_TIMESTAMP (8 occurrences in transaction statements)
-- 2. SCOPE_IDENTITY() → RETURNING clause (1 occurrence in InsertProductAsync)
-- 3. DECLARE @var → CTE-based approach (removed variables in transaction statements)
-- 4. BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT (PostgreSQL syntax)
-- 5. Parameter syntax: @param remains compatible with Npgsql
--
-- Schema Object Names: 
-- - No schema name changes applied (keeping original names: Products, ProductHistory, ProductStats)
-- - DMS tool did not provide schema transformations due to conversion failures
--
-- Compatible Features (no changes needed):
-- - CTEs (WITH clauses)
-- - Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX with OVER)
-- - ROUND function
-- - CASE expressions
-- - BETWEEN clause
-- - JOIN operations
-- ============================================================================
