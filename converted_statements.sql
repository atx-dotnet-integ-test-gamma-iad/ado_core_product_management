-- ============================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- Conversion Date: 2026-01-24
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool consistently failed)
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED TO POSTGRESQL
-- Original Source: ProductRepository.cs, Line 38-67
-- Conversion Notes:
-- - CTE syntax compatible with PostgreSQL
-- - Window functions (AVG OVER, COUNT OVER) compatible
-- - ROUND function compatible
-- - CASE statements compatible
-- - No schema changes required
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
-- Original Source: ProductRepository.cs, Line 82-110
-- Conversion Notes:
-- - CTE syntax compatible with PostgreSQL
-- - LAG window function compatible
-- - CASE statements compatible
-- - ROUND function compatible
-- - Parameter @ProductId compatible with Npgsql
-- - No schema changes required
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
-- Original Source: ProductRepository.cs, Line 125-150
-- Conversion Notes:
-- - MAJOR CHANGE: SCOPE_IDENTITY() replaced with RETURNING clause
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- - Transaction syntax: BEGIN TRANSACTION → BEGIN, COMMIT unchanged
-- - Variable declaration moved inside transaction (PostgreSQL style)
-- - Multi-statement transaction converted to PostgreSQL block
-- - Returns productid directly via RETURNING instead of separate SELECT
-- ============================================================================
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
    RETURN v_NewProductId;
END $$;

-- NOTE: For ADO.NET ExecuteScalar, we need a simpler approach:
-- The above DO block won't work with ExecuteScalar. Instead use this:
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Then handle ProductHistory and ProductStats separately or use a function

-- ALTERNATIVE: Create a PostgreSQL function (RECOMMENDED):
/*
CREATE OR REPLACE FUNCTION InsertProduct(
    p_Name VARCHAR(100),
    p_Description VARCHAR(500),
    p_Price DECIMAL(18,2),
    p_StockQuantity INT
) RETURNS INT AS $$
DECLARE
    v_NewProductId INT;
BEGIN
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (p_Name, p_Description, p_Price, p_StockQuantity)
    RETURNING ProductId INTO v_NewProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (v_NewProductId, 'INSERT', NULL, p_Price, NULL, p_StockQuantity, CURRENT_TIMESTAMP);
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + p_Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
    
    RETURN v_NewProductId;
END;
$$ LANGUAGE plpgsql;
*/

-- FOR ADO.NET CODE: Use the simple RETURNING approach with manual transaction handling in C#

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED TO POSTGRESQL
-- Original Source: ProductRepository.cs, Line 165-196
-- Conversion Notes:
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- - Transaction managed in C# code (NpgsqlTransaction)
-- - Variable declarations removed (use separate SELECT)
-- - Multi-statement transaction maintained with C# transaction control
-- ============================================================================
-- First query to get old values:
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Update the product:
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Log the changes:
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics:
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- NOTE: These will be executed within a C# NpgsqlTransaction block

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED TO POSTGRESQL
-- Original Source: ProductRepository.cs, Line 211-239
-- Conversion Notes:
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- - Transaction managed in C# code (NpgsqlTransaction)
-- - Variable declarations removed (use separate SELECT)
-- - CASE statement syntax compatible
-- - Multi-statement transaction maintained with C# transaction control
-- ============================================================================
-- First query to get old values:
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Log the deletion:
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Delete the product:
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Update product statistics:
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

-- NOTE: These will be executed within a C# NpgsqlTransaction block

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED TO POSTGRESQL
-- Original Source: ProductRepository.cs, Line 254-279
-- Conversion Notes:
-- - CTE syntax compatible with PostgreSQL
-- - RANK() window function compatible
-- - PERCENT_RANK() window function compatible
-- - CASE statements compatible
-- - BETWEEN operator compatible
-- - Parameters @MinPrice, @MaxPrice compatible with Npgsql
-- - No schema changes required
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
-- Original Source: ProductRepository.cs, Line 294-318
-- Conversion Notes:
-- - CTE syntax compatible with PostgreSQL
-- - Multiple aggregate window functions (AVG, MIN, MAX OVER) compatible
-- - CASE statements compatible
-- - ROUND function compatible
-- - Parameter @Threshold compatible with Npgsql
-- - No schema changes required
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
-- CONVERSION SUMMARY
-- ============================================================================
-- Statements 1, 2, 6, 7: Nearly identical to SQL Server, minimal changes
-- Statement 3: Major changes for SCOPE_IDENTITY() → RETURNING clause
-- Statements 4, 5: Transaction block converted to C# transaction management
-- All GETDATE() → CURRENT_TIMESTAMP
-- All parameter names (@param) remain compatible with Npgsql
-- No schema object name changes required

-- ============================================================================
-- END OF CONVERTED STATEMENTS
-- ============================================================================
