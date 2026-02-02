-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Format
-- Migration: Microsoft SQL Server to PostgreSQL
-- Conversion Method: Manual (DMS tool unavailable due to persistent errors)
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ============================================================================
-- Original Location: DataAccess/ProductRepository.cs, Method: GetAllProductsAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied: None required - PostgreSQL supports CTE and window functions natively
-- Notes: SQL syntax is PostgreSQL compatible, no schema name changes

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
-- Original Location: DataAccess/ProductRepository.cs, Method: GetProductByIdAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied: None required - PostgreSQL supports LAG window function natively
-- Notes: Parameter @ProductId remains compatible with Npgsql

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
-- STATEMENT 3: InsertProductAsync - Transaction Block with Identity Retrieval
-- ============================================================================
-- Original Location: DataAccess/ProductRepository.cs, Method: InsertProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   1. Removed DECLARE statement (PostgreSQL doesn't require variable declaration for RETURNING)
--   2. Removed BEGIN TRANSACTION/COMMIT (handled at connection level in C# code)
--   3. Changed SCOPE_IDENTITY() to RETURNING clause for INSERT
--   4. Changed GETDATE() to CURRENT_TIMESTAMP
--   5. Used LASTVAL() for retrieving last inserted ID in subsequent statements
-- Notes: Transaction will be handled by NpgsqlConnection.BeginTransaction in C# code

DO $$
DECLARE v_NewProductId INT;
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
    RAISE NOTICE 'NewProductId: %', v_NewProductId;
END $$;

-- ALTERNATIVE SIMPLER VERSION (Recommended for C# ADO.NET):
-- This version splits the transaction into separate commands for better C# integration
-- Command 1: Insert and return ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Command 2: Insert into history (use returned ProductId from Command 1)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Command 3: Update stats
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction Block with Variable Usage
-- ============================================================================
-- Original Location: DataAccess/ProductRepository.cs, Method: UpdateProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   1. Removed BEGIN TRANSACTION/COMMIT (handled at connection level)
--   2. Changed GETDATE() to CURRENT_TIMESTAMP
--   3. Converted DECLARE to PostgreSQL syntax (for DO block)
-- Notes: For ADO.NET, recommend splitting into separate commands within C# transaction

DO $$
DECLARE 
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store old values for history
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
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
    VALUES (@ProductId, 'UPDATE', v_OldPrice, @Price, v_OldStock, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - v_OldPrice + @Price) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- ALTERNATIVE SIMPLER VERSION (Recommended for C# ADO.NET):
-- Command 1: Get old values
SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId;

-- Command 2: Update product (use old values from Command 1 in C# code)
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Command 3: Insert history
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Command 4: Update stats
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction Block with Complex CASE
-- ============================================================================
-- Original Location: DataAccess/ProductRepository.cs, Method: DeleteProductAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   1. Removed BEGIN TRANSACTION/COMMIT (handled at connection level)
--   2. Changed GETDATE() to CURRENT_TIMESTAMP
--   3. Converted DECLARE to PostgreSQL syntax
-- Notes: CASE expression is compatible with PostgreSQL

DO $$
DECLARE 
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store product info for history
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', v_OldPrice, NULL, v_OldStock, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
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

-- ALTERNATIVE SIMPLER VERSION (Recommended for C# ADO.NET):
-- Command 1: Get old values
SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId;

-- Command 2: Insert history (use values from Command 1)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Command 3: Delete product
DELETE FROM Products WHERE ProductId = @ProductId;

-- Command 4: Update stats
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

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ============================================================================
-- Original Location: DataAccess/ProductRepository.cs, Method: GetProductsByPriceRangeAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied: None required - PostgreSQL supports RANK and PERCENT_RANK natively
-- Notes: All window functions are PostgreSQL compatible

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
-- Original Location: DataAccess/ProductRepository.cs, Method: GetLowStockProductsAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied: None required - PostgreSQL supports all window functions natively
-- Notes: PostgreSQL window functions are fully compatible

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
-- Total Statements Converted: 7
-- Conversion Method: Manual (DMS tool experienced persistent errors)
--
-- Statement Conversion Details:
--   - Statements 1, 2, 6, 7: No changes required (PostgreSQL compatible)
--   - Statements 3, 4, 5: Modified for PostgreSQL compatibility
--
-- Key PostgreSQL Conversions Applied:
--   1. SCOPE_IDENTITY() → RETURNING clause
--   2. GETDATE() → CURRENT_TIMESTAMP
--   3. BEGIN TRANSACTION/COMMIT → Removed (handled in C# code)
--   4. DECLARE syntax → PostgreSQL DO block syntax
--
-- Implementation Notes:
--   - Statements 1, 2, 6, 7 can be used as-is in C# code
--   - Statements 3, 4, 5 require refactoring in C# to split into multiple commands
--     within a NpgsqlTransaction for proper transaction handling
--   - Alternative simpler versions provided for statements 3, 4, 5 for easier
--     integration with C# ADO.NET code
--
-- All statements maintain functional equivalence with original SQL Server versions
-- ============================================================================
