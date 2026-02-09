-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Version
-- Microsoft SQL Server to PostgreSQL Migration
-- ============================================================================
-- Total Statements Converted: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool returned metadata model creation errors)
-- Source File: extracted_statements.sql
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Original Location: ProductRepository.cs, Lines 37-70
-- Conversion Changes:
--   - CTE syntax remains compatible
--   - Window functions (AVG OVER, COUNT OVER) are PostgreSQL compatible
--   - CASE expressions remain the same
--   - ROUND function compatible but PostgreSQL uses numeric type handling
--   - INNER JOIN syntax remains the same
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
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Original Location: ProductRepository.cs, Lines 82-111
-- Conversion Changes:
--   - Parameter syntax: @ProductId remains compatible with Npgsql
--   - LAG window function is PostgreSQL compatible
--   - CASE and ROUND expressions compatible
--   - LEFT JOIN syntax remains the same
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
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- Original Location: ProductRepository.cs, Lines 127-151
-- Conversion Changes:
--   - Removed DECLARE @NewProductId INT (not needed in PostgreSQL block)
--   - BEGIN TRANSACTION → BEGIN (PostgreSQL standard)
--   - COMMIT remains the same
--   - SCOPE_IDENTITY() → use RETURNING clause instead
--   - GETDATE() → CURRENT_TIMESTAMP or NOW()
--   - Combined into single statement with RETURNING for new ID
-- NOTE: This requires code-level changes - cannot use SELECT @NewProductId at end
-- The INSERT should use RETURNING ProductId and be handled in code differently
-- ============================================================================
BEGIN;
    -- Insert the new product and return the ID
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId;
    
    -- Note: The following statements need the returned ProductId from above
    -- This will need to be restructured in C# code to capture RETURNING value
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (/* returned ProductId */, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED - ALTERNATIVE APPROACH)
-- This version uses a DO block to handle the variable
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
    -- Note: DO blocks cannot return values directly
    -- This needs to be refactored in C# code
END $$;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED - RECOMMENDED FOR ADO.NET)
-- Split into multiple statements executed in transaction from C# code
-- ============================================================================
-- First statement - Insert and get ID via RETURNING:
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Second statement - Log the insertion (using @NewProductId from first result):
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Third statement - Update product statistics:
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- Original Location: ProductRepository.cs, Lines 163-196
-- Conversion Changes:
--   - BEGIN TRANSACTION → BEGIN
--   - DECLARE statements remain but PostgreSQL syntax slightly different
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Variable assignment in SELECT requires different syntax
-- NOTE: This requires refactoring to use separate SELECT then UPDATE
-- ============================================================================
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

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED - RECOMMENDED FOR ADO.NET)
-- Split into multiple statements with parameters
-- ============================================================================
-- First statement - Get old values:
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Second statement - Update the product (using @OldPrice, @OldStock captured in C#):
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Third statement - Log the changes:
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Fourth statement - Update product statistics:
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- Original Location: ProductRepository.cs, Lines 208-242
-- Conversion Changes: Similar to UpdateProductAsync
--   - BEGIN TRANSACTION → BEGIN
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Variable handling needs refactoring
-- ============================================================================
-- First statement - Get old values:
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Second statement - Log the deletion:
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Third statement - Delete the product:
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Fourth statement - Update product statistics:
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
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Original Location: ProductRepository.cs, Lines 250-279
-- Conversion Changes:
--   - RANK() and PERCENT_RANK() window functions are PostgreSQL compatible
--   - BETWEEN clause remains the same
--   - CASE expression compatible
--   - Parameter syntax compatible with Npgsql
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
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Original Location: ProductRepository.cs, Lines 287-318
-- Conversion Changes:
--   - Window functions (AVG, MIN, MAX with OVER) are PostgreSQL compatible
--   - CASE expression compatible
--   - ROUND function compatible
--   - Parameter syntax compatible with Npgsql
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
-- END OF CONVERTED SQL STATEMENTS
-- ============================================================================
-- CONVERSION SUMMARY:
-- - Statements 1, 2, 6, 7: Direct conversion (minimal changes, mostly PostgreSQL compatible)
-- - Statements 3, 4, 5: Require code-level refactoring due to transaction handling differences
--   * T-SQL DECLARE variables and SCOPE_IDENTITY() pattern needs to be split into multiple statements
--   * GETDATE() → CURRENT_TIMESTAMP
--   * Transaction control handled by ADO.NET code, not in SQL
-- ============================================================================
