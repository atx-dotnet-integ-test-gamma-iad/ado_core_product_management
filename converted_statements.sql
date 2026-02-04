-- ============================================================================
-- CONVERTED SQL STATEMENTS - POSTGRESQL VERSION
-- Microsoft SQL Server to PostgreSQL Migration
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Date: 2026-02-04
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool encountered systemic error)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED TO POSTGRESQL)
-- ============================================================================
-- Source Method: GetAllProductsAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Added ::numeric cast for ROUND() operation
--   - Added statement terminator semicolon
--   - CTE, window functions, and CASE expressions are PostgreSQL compatible
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
    ROUND((p.Price / ps.AvgPrice)::numeric * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED TO POSTGRESQL)
-- ============================================================================
-- Source Method: GetProductByIdAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Parameter @ProductId → $1 (2 occurrences)
--   - Added ::numeric cast for ROUND() operation
--   - Added statement terminator semicolon
--   - CTE and LAG() window function are PostgreSQL compatible
-- ============================================================================

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
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice)::numeric * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = $1;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED TO POSTGRESQL)
-- ============================================================================
-- Source Method: InsertProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Wrapped in DO $$ anonymous block for multi-statement execution
--   - DECLARE @NewProductId INT → DECLARE v_NewProductId INT
--   - SCOPE_IDENTITY() → RETURNING ProductId INTO v_NewProductId
--   - GETDATE() → CURRENT_TIMESTAMP (2 occurrences)
--   - Parameters: @Name, @Description, @Price, @StockQuantity → $1, $2, $3, $4
--   - BEGIN TRANSACTION/COMMIT → implicit in DO block
--   - SET @NewProductId = SCOPE_IDENTITY() → RETURNING clause
--
-- IMPORTANT NOTE: For ADO.NET usage, this should be restructured to use
-- RETURNING clause at the application level with NpgsqlCommand.ExecuteScalar()
-- or similar pattern. The DO block is provided for completeness but may need
-- adjustment for actual ADO.NET integration.
-- ============================================================================

DO $$
DECLARE v_NewProductId INT;
BEGIN
    -- Insert the new product
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES ($1, $2, $3, $4)
    RETURNING ProductId INTO v_NewProductId;
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (v_NewProductId, 'INSERT', NULL, $3, NULL, $4, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + $3) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- Alternative for ADO.NET (split into multiple commands with transaction):
-- Command 1 (ExecuteScalar to get new ID):
-- INSERT INTO Products (Name, Description, Price, StockQuantity)
-- VALUES ($1, $2, $3, $4)
-- RETURNING ProductId;
--
-- Command 2 (using returned ID):
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES ($1, 'INSERT', NULL, $2, NULL, $3, CURRENT_TIMESTAMP);
--
-- Command 3 (using price parameter):
-- UPDATE ProductStats
-- SET TotalProducts = TotalProducts + 1,
--     AveragePrice = (AveragePrice * TotalProducts + $1) / (TotalProducts + 1),
--     LastUpdated = CURRENT_TIMESTAMP
-- WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED TO POSTGRESQL)
-- ============================================================================
-- Source Method: UpdateProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Wrapped in DO $$ anonymous block
--   - DECLARE @OldPrice/@OldStock → DECLARE v_OldPrice/v_OldStock
--   - SELECT @Var = ... → SELECT ... INTO v_Var
--   - GETDATE() → CURRENT_TIMESTAMP (3 occurrences)
--   - Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity → $1, $2, $3, $4, $5
--   - BEGIN TRANSACTION/COMMIT → implicit in DO block
--
-- IMPORTANT NOTE: For ADO.NET usage, split into separate commands within a
-- NpgsqlTransaction for better control and error handling.
-- ============================================================================

DO $$
DECLARE 
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store old values for history
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
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
    VALUES ($1, 'UPDATE', v_OldPrice, $4, v_OldStock, $5, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - v_OldPrice + $4) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- Alternative for ADO.NET (split into multiple commands with transaction):
-- Command 1 (get old values):
-- SELECT Price, StockQuantity FROM Products WHERE ProductId = $1;
--
-- Command 2 (update product):
-- UPDATE Products
-- SET Name = $1, Description = $2, Price = $3, StockQuantity = $4, ModifiedDate = CURRENT_TIMESTAMP
-- WHERE ProductId = $5;
--
-- Command 3 (insert history):
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES ($1, 'UPDATE', $2, $3, $4, $5, CURRENT_TIMESTAMP);
--
-- Command 4 (update stats):
-- UPDATE ProductStats
-- SET AveragePrice = (AveragePrice * TotalProducts - $1 + $2) / TotalProducts,
--     LastUpdated = CURRENT_TIMESTAMP
-- WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED TO POSTGRESQL)
-- ============================================================================
-- Source Method: DeleteProductAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Wrapped in DO $$ anonymous block
--   - DECLARE @OldPrice/@OldStock → DECLARE v_OldPrice/v_OldStock
--   - SELECT @Var = ... → SELECT ... INTO v_Var
--   - GETDATE() → CURRENT_TIMESTAMP (2 occurrences)
--   - Parameter: @ProductId → $1 (4 occurrences)
--   - BEGIN TRANSACTION/COMMIT → implicit in DO block
--   - CASE expression is compatible
--
-- IMPORTANT NOTE: For ADO.NET usage, split into separate commands within a
-- NpgsqlTransaction for better control and error handling.
-- ============================================================================

DO $$
DECLARE 
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store product info for history
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = $1;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES ($1, 'DELETE', v_OldPrice, NULL, v_OldStock, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = $1;
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - v_OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- Alternative for ADO.NET (split into multiple commands with transaction):
-- Command 1 (get old values):
-- SELECT Price, StockQuantity FROM Products WHERE ProductId = $1;
--
-- Command 2 (insert history):
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES ($1, 'DELETE', $2, NULL, $3, NULL, CURRENT_TIMESTAMP);
--
-- Command 3 (delete product):
-- DELETE FROM Products WHERE ProductId = $1;
--
-- Command 4 (update stats):
-- UPDATE ProductStats
-- SET TotalProducts = TotalProducts - 1,
--     AveragePrice = CASE 
--         WHEN TotalProducts > 1 
--         THEN (AveragePrice * TotalProducts - $1) / (TotalProducts - 1)
--         ELSE 0
--     END,
--     LastUpdated = CURRENT_TIMESTAMP
-- WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED TO POSTGRESQL)
-- ============================================================================
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Parameters: @MinPrice, @MaxPrice → $1, $2
--   - Added statement terminator semicolon
--   - CTE, RANK(), PERCENT_RANK() window functions are PostgreSQL compatible
--   - BETWEEN clause is compatible
--   - CASE expression is compatible
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED TO POSTGRESQL)
-- ============================================================================
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Parameter: @Threshold → $1 (2 occurrences)
--   - Added ::numeric cast for ROUND() operation
--   - Added statement terminator semicolon
--   - CTE and window functions (AVG, MIN, MAX) are PostgreSQL compatible
--   - CASE expression is compatible
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
        WHEN StockQuantity <= $1 THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock)::numeric * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= $1
ORDER BY StockQuantity;

-- ============================================================================
-- CONVERSION SUMMARY
-- ============================================================================
-- Total Statements Converted: 7
-- Conversion Method: All statements manually converted after DMS tool failure
-- 
-- Key PostgreSQL Conversions Applied:
-- ------------------------------------
-- 1. Parameter Syntax Changes:
--    - SQL Server: @ParameterName
--    - PostgreSQL: $N (positional parameters: $1, $2, $3, etc.)
--
-- 2. Date/Time Functions:
--    - GETDATE() → CURRENT_TIMESTAMP (or NOW())
--
-- 3. Identity Retrieval:
--    - SCOPE_IDENTITY() → RETURNING clause
--    - Example: INSERT ... RETURNING ProductId INTO variable
--
-- 4. Variable Declarations:
--    - DECLARE @VariableName → DECLARE v_VariableName
--    - PostgreSQL convention: use v_ prefix for variables
--
-- 5. Variable Assignment:
--    - SELECT @Var = column FROM table → SELECT column INTO v_Var FROM table
--
-- 6. Transaction Blocks:
--    - BEGIN TRANSACTION ... COMMIT → DO $$ BEGIN ... END $$
--    - For ADO.NET: Use application-level NpgsqlTransaction
--
-- 7. Type Casting:
--    - Explicit casts: value::numeric for ROUND() operations
--    - Ensures proper decimal precision in calculations
--
-- 8. Statement Terminators:
--    - Added semicolons at end of all statements (PostgreSQL convention)
--
-- Compatible Syntax (No Changes Required):
-- -----------------------------------------
-- - Common Table Expressions (WITH ... AS)
-- - Window Functions (LAG, RANK, PERCENT_RANK, AVG, MIN, MAX with OVER)
-- - CASE expressions
-- - JOIN syntax (INNER JOIN, LEFT JOIN)
-- - WHERE, ORDER BY, BETWEEN clauses
-- - Aggregate functions
--
-- Schema Object Names:
-- --------------------
-- No schema object name changes were made. All table names remain:
-- - Products
-- - ProductHistory  
-- - ProductStats
--
-- ADO.NET Integration Notes:
-- ---------------------------
-- Transaction blocks (Statements 3, 4, 5) are provided as DO blocks for
-- reference, but should be restructured for ADO.NET usage:
-- 1. Use NpgsqlTransaction at application level
-- 2. Split multi-statement blocks into separate NpgsqlCommand executions
-- 3. Use RETURNING clause with ExecuteScalar() for INSERT operations
-- 4. Handle errors and rollback at application level
--
-- All converted statements maintain functional equivalence with original
-- SQL Server statements while following PostgreSQL syntax and conventions.
-- ============================================================================
