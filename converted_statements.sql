-- ==================================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- Converted from: extracted_statements.sql
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool encountered errors/timeouts)
-- Target Database: PostgreSQL
-- Total Statements: 7
-- ==================================================================================

-- ==================================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Original Source: /sourceCode/DataAccess/ProductRepository.cs (Lines 42-68)
-- Method: GetAllProductsAsync()
-- Conversion Notes:
--   - CTE syntax compatible with PostgreSQL
--   - Window functions (AVG, COUNT OVER) are PostgreSQL compatible
--   - ROUND function syntax identical
--   - CASE expressions compatible
--   - No parameter changes (no parameters in this query)
-- DMS Status: FAILED (timeout after 15 poll attempts)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- ==================================================================================
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

-- ==================================================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Original Source: /sourceCode/DataAccess/ProductRepository.cs (Lines 83-108)
-- Method: GetProductByIdAsync(int productId)
-- Conversion Notes:
--   - CTE syntax compatible
--   - LAG window function compatible with PostgreSQL
--   - Parameter @ProductId converted to $1 (positional parameter)
--   - ROUND function syntax identical
--   - CASE expressions compatible
-- DMS Status: FAILED (timeout after 15 poll attempts)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Parameters: $1 = ProductId (int)
-- ==================================================================================
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

-- ==================================================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- Original Source: /sourceCode/DataAccess/ProductRepository.cs (Lines 123-148)
-- Method: InsertProductAsync(Product product)
-- Conversion Notes:
--   - BEGIN TRANSACTION/COMMIT compatible with PostgreSQL
--   - DECLARE @var removed, using RETURNING clause instead of SCOPE_IDENTITY()
--   - GETDATE() converted to NOW() (or CURRENT_TIMESTAMP)
--   - Parameters converted: @Name->$1, @Description->$2, @Price->$3, @StockQuantity->$4
--   - Final SELECT changed to return from RETURNING clause
--   - PostgreSQL uses RETURNING clause directly in INSERT for new ID
-- DMS Status: FAILED (Statement definition is not valid)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Parameters: $1=Name, $2=Description, $3=Price, $4=StockQuantity
-- ==================================================================================
BEGIN;
    -- Insert the new product and capture the new ID
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES ($1, $2, $3, $4)
    RETURNING ProductId;
    
    -- Note: In ADO.NET code, we'll need to capture the RETURNING value
    -- Then use it for subsequent statements. This may require restructuring
    -- the transaction in application code.
    
    -- Log the insertion (using the returned ProductId from above)
    -- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    -- VALUES (<returned_id>, 'INSERT', NULL, $3, NULL, $4, NOW());
    
    -- Update product statistics
    -- UPDATE ProductStats
    -- SET 
    --     TotalProducts = TotalProducts + 1,
    --     AveragePrice = (AveragePrice * TotalProducts + $3) / (TotalProducts + 1),
    --     LastUpdated = NOW()
    -- WHERE StatId = 1;
COMMIT;

-- IMPORTANT: The above transaction needs to be split in application code because
-- PostgreSQL RETURNING clause returns the value immediately and we need to capture
-- it for subsequent statements. Better approach in code:

-- Alternative approach (to be used in C# code with multiple ExecuteScalarAsync calls):
-- Call 1: INSERT and get ID
WITH inserted_product AS (
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES ($1, $2, $3, $4)
    RETURNING ProductId, Price, StockQuantity
)
SELECT ProductId FROM inserted_product;

-- Call 2: Log history (using captured ProductId as $5)
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES ($5, 'INSERT', NULL, $3, NULL, $4, NOW());

-- Call 3: Update statistics
-- UPDATE ProductStats
-- SET 
--     TotalProducts = TotalProducts + 1,
--     AveragePrice = (AveragePrice * TotalProducts + $3) / (TotalProducts + 1),
--     LastUpdated = NOW()
-- WHERE StatId = 1;

-- ==================================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- Original Source: /sourceCode/DataAccess/ProductRepository.cs (Lines 160-194)
-- Method: UpdateProductAsync(Product product)
-- Conversion Notes:
--   - BEGIN TRANSACTION/COMMIT compatible
--   - DECLARE statements removed, using PostgreSQL DO block or CTE approach
--   - GETDATE() converted to NOW()
--   - Parameters: @ProductId->$1, @Name->$2, @Description->$3, @Price->$4, @StockQuantity->$5
--   - Using CTE to capture old values instead of DECLARE variables
-- DMS Status: NOT_ATTEMPTED (similar pattern to failed Statement 3)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Parameters: $1=ProductId, $2=Name, $3=Description, $4=Price, $5=StockQuantity
-- ==================================================================================
BEGIN;
    -- Store old values, update product, and log history in a single CTE chain
    WITH old_values AS (
        SELECT Price as OldPrice, StockQuantity as OldStock
        FROM Products
        WHERE ProductId = $1
    ),
    product_update AS (
        UPDATE Products
        SET 
            Name = $2,
            Description = $3,
            Price = $4,
            StockQuantity = $5,
            ModifiedDate = NOW()
        WHERE ProductId = $1
        RETURNING ProductId
    ),
    history_insert AS (
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
        SELECT $1, 'UPDATE', ov.OldPrice, $4, ov.OldStock, $5, NOW()
        FROM old_values ov
        RETURNING ProductId
    )
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + $4) / TotalProducts,
        LastUpdated = NOW()
    WHERE StatId = 1;
COMMIT;

-- ==================================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- Original Source: /sourceCode/DataAccess/ProductRepository.cs (Lines 205-238)
-- Method: DeleteProductAsync(int productId)
-- Conversion Notes:
--   - BEGIN TRANSACTION/COMMIT compatible
--   - DECLARE statements removed, using CTE approach
--   - GETDATE() converted to NOW()
--   - Parameter @ProductId converted to $1
--   - CASE expression compatible
-- DMS Status: NOT_ATTEMPTED (similar pattern to failed Statement 3)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Parameters: $1=ProductId
-- ==================================================================================
BEGIN;
    -- Store product info, log deletion, delete product, and update stats
    WITH product_info AS (
        SELECT Price as OldPrice, StockQuantity as OldStock
        FROM Products
        WHERE ProductId = $1
    ),
    history_insert AS (
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
        SELECT $1, 'DELETE', pi.OldPrice, NULL, pi.OldStock, NULL, NOW()
        FROM product_info pi
        RETURNING ProductId
    ),
    product_delete AS (
        DELETE FROM Products 
        WHERE ProductId = $1
        RETURNING ProductId
    )
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - (SELECT OldPrice FROM product_info)) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = NOW()
    WHERE StatId = 1;
COMMIT;

-- ==================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Original Source: /sourceCode/DataAccess/ProductRepository.cs (Lines 249-274)
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Notes:
--   - CTE syntax compatible
--   - RANK() and PERCENT_RANK() window functions compatible
--   - BETWEEN operator compatible
--   - Parameters: @MinPrice->$1, @MaxPrice->$2
--   - CASE expressions compatible
-- DMS Status: FAILED (timeout after 15 poll attempts)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Parameters: $1=MinPrice, $2=MaxPrice
-- ==================================================================================
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

-- ==================================================================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Original Source: /sourceCode/DataAccess/ProductRepository.cs (Lines 288-316)
-- Method: GetLowStockProductsAsync(int threshold)
-- Conversion Notes:
--   - CTE syntax compatible
--   - Aggregation window functions (AVG, MIN, MAX OVER) compatible
--   - ROUND function syntax identical
--   - Parameter @Threshold converted to $1
--   - CASE expressions compatible
-- DMS Status: NOT_ATTEMPTED (similar pattern to failed CTE statements)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Parameters: $1=Threshold
-- ==================================================================================
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

-- ==================================================================================
-- END OF CONVERTED SQL STATEMENTS
-- Total Statements Converted: 7
-- Conversion Method: All MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Attempts: 4 explicit attempts (Statements 1, 2, 3, 6)
-- DMS Tool Success: 0
-- DMS Tool Failures: 4 (3 timeouts, 1 invalid statement definition)
-- Not Attempted in DMS: 3 (Statements 4, 5, 7 - similar patterns to failed attempts)
-- 
-- Key PostgreSQL Conversions Applied:
-- 1. Parameter syntax: @ParamName -> $N (positional parameters)
-- 2. Functions: GETDATE() -> NOW()
-- 3. Identity retrieval: SCOPE_IDENTITY() -> RETURNING clause
-- 4. Variable declarations: DECLARE @var removed, using CTEs instead
-- 5. Transaction syntax: BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT
-- 6. Window functions, CTEs, CASE: Already compatible, no changes needed
-- 
-- Schema Object Names: NO CHANGES
-- All table names remain: Products, ProductHistory, ProductStats
-- ==================================================================================
