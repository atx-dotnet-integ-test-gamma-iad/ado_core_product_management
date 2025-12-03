-- ============================================================================
-- SQL Statement Conversion Catalog - SQL Server to PostgreSQL
-- Generated for Microsoft SQL Server to PostgreSQL Migration
-- ============================================================================
-- This file contains all SQL statements with their PostgreSQL conversions
-- Each statement includes conversion status and DMS tool output
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR
-- DMS Error: Metadata model creation failed: No objects were found according to the specified selection rules
-- Schema Object Changes: None (manually maintaining same structure)
-- ============================================================================

-- ORIGINAL MS SQL:
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

-- Conversion Notes: 
-- - CTEs are compatible between SQL Server and PostgreSQL
-- - Window functions (AVG OVER, COUNT OVER) are compatible
-- - CASE expressions are compatible
-- - ROUND function syntax is the same
-- - No parameter conversion needed (no parameters in this statement)

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR
-- DMS Error: Metadata model creation failed: No objects were found according to the specified selection rules
-- Schema Object Changes: None (manually maintaining same structure)
-- Parameter Changes: @ProductId → $1
-- ============================================================================

-- ORIGINAL MS SQL:
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

-- CONVERTED POSTGRESQL:
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

-- Conversion Notes:
-- - CTEs are compatible
-- - LAG window function is compatible  
-- - Parameter syntax changed: @ProductId → $1 (PostgreSQL positional parameter)
-- - CASE and ROUND functions are compatible

-- ============================================================================
-- STATEMENT 3: InsertProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR
-- DMS Error: Metadata model creation failed: No objects were found according to the specified selection rules
-- Schema Object Changes: None (manually maintaining same structure)
-- Parameter Changes: @Name→$1, @Description→$2, @Price→$3, @StockQuantity→$4
-- Function Changes: GETDATE()→CURRENT_TIMESTAMP, SCOPE_IDENTITY()→RETURNING clause
-- ============================================================================

-- ORIGINAL MS SQL:
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

-- CONVERTED POSTGRESQL:
DO $$
DECLARE
    v_NewProductId INT;
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

-- Conversion Notes:
-- - Transaction block converted from BEGIN TRANSACTION/COMMIT to DO $$ block
-- - Variable declaration: DECLARE @Var → DECLARE v_Var (PostgreSQL naming convention)
-- - SCOPE_IDENTITY() replaced with RETURNING clause (more idiomatic PostgreSQL)
-- - GETDATE() → CURRENT_TIMESTAMP
-- - Parameters: @Name→$1, @Description→$2, @Price→$3, @StockQuantity→$4
-- - Note: For ADO.NET usage, the transaction will be handled by code, not within SQL

-- ADO.NET COMPATIBLE VERSION (without DO block):
-- This version is for use in ADO.NET ExecuteScalarAsync:
/*
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES ($1, $2, $3, $4)
RETURNING ProductId;
*/
-- Then execute subsequent statements in separate commands within same transaction

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR
-- DMS Error: Metadata model creation failed: No objects were found according to the specified selection rules
-- Schema Object Changes: None (manually maintaining same structure)
-- Parameter Changes: @ProductId→$1, @Name→$2, @Description→$3, @Price→$4, @StockQuantity→$5
-- Function Changes: GETDATE()→CURRENT_TIMESTAMP
-- ============================================================================

-- ORIGINAL MS SQL:
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

-- CONVERTED POSTGRESQL:
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

-- Conversion Notes:
-- - Transaction managed by code, not in SQL
-- - Variable assignment: SELECT @Var = Col → SELECT Col INTO v_Var
-- - GETDATE() → CURRENT_TIMESTAMP
-- - Parameters: @ProductId→$1, @Name→$2, @Description→$3, @Price→$4, @StockQuantity→$5

-- ADO.NET COMPATIBLE VERSION (breaking into separate commands):
/*
-- Command 1: Get old values
SELECT Price, StockQuantity FROM Products WHERE ProductId = $1;

-- Command 2: Update product
UPDATE Products
SET Name = $2, Description = $3, Price = $4, StockQuantity = $5, ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = $1;

-- Command 3: Insert history (using values from command 1)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'UPDATE', $6, $4, $7, $5, CURRENT_TIMESTAMP);

-- Command 4: Update statistics
UPDATE ProductStats
SET AveragePrice = (AveragePrice * TotalProducts - $6 + $4) / TotalProducts, LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;
*/

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR
-- DMS Error: Metadata model creation failed: No objects were found according to the specified selection rules
-- Schema Object Changes: None (manually maintaining same structure)
-- Parameter Changes: @ProductId→$1
-- Function Changes: GETDATE()→CURRENT_TIMESTAMP
-- ============================================================================

-- ORIGINAL MS SQL:
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

-- CONVERTED POSTGRESQL:
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

-- Conversion Notes:
-- - Transaction managed by code
-- - Variable assignment: SELECT @Var = Col → SELECT Col INTO v_Var
-- - GETDATE() → CURRENT_TIMESTAMP
-- - Parameters: @ProductId→$1
-- - CASE expression compatible

-- ADO.NET COMPATIBLE VERSION:
/*
-- Command 1: Get old values
SELECT Price, StockQuantity FROM Products WHERE ProductId = $1;

-- Command 2: Insert history
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'DELETE', $2, NULL, $3, NULL, CURRENT_TIMESTAMP);

-- Command 3: Delete product
DELETE FROM Products WHERE ProductId = $1;

-- Command 4: Update statistics
UPDATE ProductStats
SET TotalProducts = TotalProducts - 1,
    AveragePrice = CASE WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - $2) / (TotalProducts - 1) ELSE 0 END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;
*/

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR
-- DMS Error: Metadata model creation failed: No objects were found according to the specified selection rules
-- Schema Object Changes: None (manually maintaining same structure)
-- Parameter Changes: @MinPrice→$1, @MaxPrice→$2
-- ============================================================================

-- ORIGINAL MS SQL:
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

-- CONVERTED POSTGRESQL:
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

-- Conversion Notes:
-- - CTEs are compatible
-- - RANK() and PERCENT_RANK() window functions are compatible
-- - BETWEEN is compatible
-- - Parameters: @MinPrice→$1, @MaxPrice→$2
-- - CASE expression compatible

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR
-- DMS Error: Metadata model creation failed: No objects were found according to the specified selection rules
-- Schema Object Changes: None (manually maintaining same structure)
-- Parameter Changes: @Threshold→$1
-- ============================================================================

-- ORIGINAL MS SQL:
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
        WHEN StockQuantity <= $1 THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= $1
ORDER BY StockQuantity;

-- Conversion Notes:
-- - CTEs are compatible
-- - Multiple window functions (AVG, MIN, MAX OVER) are compatible
-- - CASE expression compatible
-- - ROUND function syntax the same
-- - Parameters: @Threshold→$1

-- ============================================================================
-- CONVERSION SUMMARY
-- ============================================================================
-- Total Statements: 7
-- DMS Tool Success: 0
-- Manual Conversions After DMS Failure: 7
-- 
-- Key Conversion Patterns Applied:
-- 1. Parameter syntax: @ParamName → $N (positional parameters)
-- 2. Function replacements: GETDATE() → CURRENT_TIMESTAMP
-- 3. Identity retrieval: SCOPE_IDENTITY() → RETURNING clause
-- 4. Variable assignment: SELECT @Var = Col → SELECT Col INTO v_Var
-- 5. Variable naming: @VarName → v_VarName
-- 6. CTEs, window functions (LAG, RANK, PERCENT_RANK, AVG/COUNT/MIN/MAX OVER): Compatible
-- 7. Transaction blocks: Managed by ADO.NET code, not within SQL statements
-- 
-- Schema Object Name Changes: None
-- All table names (Products, ProductHistory, ProductStats) remain unchanged
-- ============================================================================
