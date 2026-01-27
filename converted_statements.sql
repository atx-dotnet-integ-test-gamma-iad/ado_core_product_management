-- ============================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Migration: Microsoft SQL Server to PostgreSQL
-- Source: ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (All statements)
-- ============================================================

-- ============================================================
-- STATEMENT ID: STMT_001
-- Source Method: GetAllProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Tool Output: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- DMS Tool Timestamp: 2026-01-27T11:04:47.135242
-- Schema Object Name Changes: None (using default public schema for PostgreSQL)
-- ============================================================

-- ORIGINAL SQL SERVER:
-- WITH ProductStats AS (
--     SELECT 
--         ProductId,
--         AVG(Price) OVER() as AvgPrice,
--         COUNT(*) OVER() as TotalProducts
--     FROM Products
-- )
-- SELECT 
--     p.ProductId,
--     p.Name,
--     p.Description,
--     p.Price,
--     p.StockQuantity,
--     p.CreatedDate,
--     p.ModifiedDate,
--     CASE 
--         WHEN p.Price > ps.AvgPrice THEN 'Above Average'
--         WHEN p.Price < ps.AvgPrice THEN 'Below Average'
--         ELSE 'Average'
--     END as PriceCategory,
--     ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
-- FROM Products p
-- INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
-- ORDER BY 
--     CASE 
--         WHEN p.Price > ps.AvgPrice THEN 1
--         ELSE 2
--     END,
--     p.Name

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

-- Manual Conversion Notes:
-- - CTEs and window functions (AVG OVER, COUNT OVER) are fully compatible in PostgreSQL
-- - ROUND() function syntax is identical
-- - CASE expressions work the same way
-- - No schema changes needed

-- ============================================================
-- STATEMENT ID: STMT_002
-- Source Method: GetProductByIdAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Tool Output: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- DMS Tool Timestamp: 2026-01-27T11:09:47.429804
-- Schema Object Name Changes: None
-- ============================================================

-- ORIGINAL SQL SERVER:
-- WITH ProductHistory AS (
--     SELECT 
--         ProductId,
--         LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
--         LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
--     FROM Products
--     WHERE ProductId = @ProductId
-- )
-- SELECT 
--     p.ProductId,
--     p.Name,
--     p.Description,
--     p.Price,
--     p.StockQuantity,
--     p.CreatedDate,
--     p.ModifiedDate,
--     ph.PreviousPrice,
--     ph.PreviousStock,
--     CASE 
--         WHEN ph.PreviousPrice IS NOT NULL THEN 
--             ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
--         ELSE NULL
--     END as PriceChangePercentage
-- FROM Products p
-- LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
-- WHERE p.ProductId = @ProductId

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

-- Manual Conversion Notes:
-- - LAG() window function is fully compatible in PostgreSQL
-- - Parameter syntax (@ProductId) works with Npgsql
-- - No changes needed for this query

-- ============================================================
-- STATEMENT ID: STMT_003
-- Source Method: InsertProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Tool Output: Metadata model creation failed: {'error': "Metadata model creation failed: {'default_error_details': {'message': 'Statement definition is not valid.'}}"}
-- DMS Tool Timestamp: 2026-01-27T11:12:23.422160
-- Schema Object Name Changes: None
-- ============================================================

-- ORIGINAL SQL SERVER:
-- DECLARE @NewProductId INT;
-- 
-- BEGIN TRANSACTION;
--     -- Insert the new product
--     INSERT INTO Products (Name, Description, Price, StockQuantity)
--     VALUES (@Name, @Description, @Price, @StockQuantity);
--     
--     SET @NewProductId = SCOPE_IDENTITY();
--     
--     -- Log the insertion
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
--     
--     -- Update product statistics
--     UPDATE ProductStats
--     SET 
--         TotalProducts = TotalProducts + 1,
--         AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
--         LastUpdated = GETDATE()
--     WHERE StatId = 1;
-- COMMIT;
-- 
-- SELECT @NewProductId;

-- CONVERTED POSTGRESQL:
-- Note: PostgreSQL doesn't support BEGIN TRANSACTION inside a function call
-- This will be executed as a stored procedure or as separate statements with transaction management in C# code
-- Using DO block for illustration, but actual implementation will use C# transaction management

DO $$
DECLARE
    v_NewProductId INT;
BEGIN
    -- Insert the new product and get the ID using RETURNING clause
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId INTO v_NewProductId;
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (v_NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = NOW()
    WHERE StatId = 1;
    
    -- Return the new product ID
    -- Note: In actual C# implementation, we'll capture this from RETURNING clause
END $$;

-- Manual Conversion Notes:
-- - SCOPE_IDENTITY() replaced with RETURNING clause in INSERT statement
-- - GETDATE() replaced with NOW()
-- - DECLARE syntax changed from @variable to variable (PostgreSQL style)
-- - BEGIN TRANSACTION/COMMIT will be handled by C# NpgsqlTransaction instead
-- - The actual implementation will break this into separate statements with RETURNING

-- ============================================================
-- STATEMENT ID: STMT_004
-- Source Method: UpdateProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Tool Output: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- DMS Tool Timestamp: 2026-01-27T11:16:18.743795
-- Schema Object Name Changes: None
-- ============================================================

-- ORIGINAL SQL SERVER:
-- BEGIN TRANSACTION;
--     -- Store old values for history
--     DECLARE @OldPrice DECIMAL(18,2);
--     DECLARE @OldStock INT;
--     
--     SELECT @OldPrice = Price, @OldStock = StockQuantity
--     FROM Products
--     WHERE ProductId = @ProductId;
--     
--     -- Update the product
--     UPDATE Products
--     SET 
--         Name = @Name,
--         Description = @Description,
--         Price = @Price,
--         StockQuantity = @StockQuantity,
--         ModifiedDate = GETDATE()
--     WHERE ProductId = @ProductId;
--     
--     -- Log the changes
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
--     
--     -- Update product statistics
--     UPDATE ProductStats
--     SET 
--         AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
--         LastUpdated = GETDATE()
--     WHERE StatId = 1;
-- COMMIT;

-- CONVERTED POSTGRESQL:
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
        ModifiedDate = NOW()
    WHERE ProductId = @ProductId;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', v_OldPrice, @Price, v_OldStock, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - v_OldPrice + @Price) / TotalProducts,
        LastUpdated = NOW()
    WHERE StatId = 1;
END $$;

-- Manual Conversion Notes:
-- - GETDATE() replaced with NOW()
-- - DECLARE @variable changed to DECLARE variable (PostgreSQL style)
-- - SELECT INTO syntax updated for PostgreSQL
-- - BEGIN TRANSACTION/COMMIT will be handled by C# NpgsqlTransaction
-- - Variables referenced use PostgreSQL style (v_OldPrice instead of @OldPrice)

-- ============================================================
-- STATEMENT ID: STMT_005
-- Source Method: DeleteProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Tool Output: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- DMS Tool Timestamp: 2026-01-27T11:21:17.457813
-- Schema Object Name Changes: None
-- ============================================================

-- ORIGINAL SQL SERVER:
-- BEGIN TRANSACTION;
--     -- Store product info for history
--     DECLARE @OldPrice DECIMAL(18,2);
--     DECLARE @OldStock INT;
--     
--     SELECT @OldPrice = Price, @OldStock = StockQuantity
--     FROM Products
--     WHERE ProductId = @ProductId;
--     
--     -- Log the deletion
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
--     
--     -- Delete the product
--     DELETE FROM Products 
--     WHERE ProductId = @ProductId;
--     
--     -- Update product statistics
--     UPDATE ProductStats
--     SET 
--         TotalProducts = TotalProducts - 1,
--         AveragePrice = CASE 
--             WHEN TotalProducts > 1 
--             THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
--             ELSE 0
--         END,
--         LastUpdated = GETDATE()
--     WHERE StatId = 1;
-- COMMIT;

-- CONVERTED POSTGRESQL:
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
    VALUES (@ProductId, 'DELETE', v_OldPrice, NULL, v_OldStock, NULL, NOW());
    
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
        LastUpdated = NOW()
    WHERE StatId = 1;
END $$;

-- Manual Conversion Notes:
-- - GETDATE() replaced with NOW()
-- - DECLARE @variable changed to DECLARE variable (PostgreSQL style)
-- - SELECT INTO syntax updated for PostgreSQL
-- - BEGIN TRANSACTION/COMMIT will be handled by C# NpgsqlTransaction
-- - Variables referenced use PostgreSQL style (v_OldPrice instead of @OldPrice)

-- ============================================================
-- STATEMENT ID: STMT_006
-- Source Method: GetProductsByPriceRangeAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: TIMEOUT
-- DMS Tool Output: Command execution timed out after 300 seconds
-- DMS Tool Timestamp: N/A (timeout)
-- Schema Object Name Changes: None
-- ============================================================

-- ORIGINAL SQL SERVER:
-- WITH RankedProducts AS (
--     SELECT 
--         p.*,
--         RANK() OVER (ORDER BY p.Price) as PriceRank,
--         PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
--     FROM Products p
--     WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
-- )
-- SELECT 
--     rp.*,
--     CASE 
--         WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
--         WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
--         ELSE 'Premium'
--     END as PriceSegment
-- FROM RankedProducts rp
-- ORDER BY rp.PriceRank

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

-- Manual Conversion Notes:
-- - RANK() and PERCENT_RANK() window functions are fully compatible in PostgreSQL
-- - BETWEEN operator works the same way
-- - No changes needed for this query

-- ============================================================
-- STATEMENT ID: STMT_007
-- Source Method: GetLowStockProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: TIMEOUT
-- DMS Tool Output: Command execution timed out after 300 seconds
-- DMS Tool Timestamp: N/A (timeout)
-- Schema Object Name Changes: None
-- ============================================================

-- ORIGINAL SQL SERVER:
-- WITH StockAnalysis AS (
--     SELECT 
--         p.*,
--         AVG(StockQuantity) OVER() as AvgStock,
--         MIN(StockQuantity) OVER() as MinStock,
--         MAX(StockQuantity) OVER() as MaxStock
--     FROM Products p
-- )
-- SELECT 
--     sa.*,
--     CASE 
--         WHEN StockQuantity <= @Threshold THEN 'Critical'
--         WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
--         ELSE 'Adequate'
--     END as StockStatus,
--     ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
-- FROM StockAnalysis sa
-- WHERE StockQuantity <= @Threshold
-- ORDER BY StockQuantity

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

-- Manual Conversion Notes:
-- - AVG(), MIN(), MAX() window functions are fully compatible in PostgreSQL
-- - ROUND() function syntax is identical
-- - No changes needed for this query

-- ============================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- ============================================================
-- CONVERSION SUMMARY:
-- Total Statements: 7
-- DMS Tool Successful Conversions: 0
-- Manual Conversions After DMS Failure: 7
-- 
-- KEY CONVERSION PATTERNS:
-- 1. GETDATE() -> NOW() (Statements 3, 4, 5)
-- 2. SCOPE_IDENTITY() -> RETURNING clause (Statement 3)
-- 3. DECLARE @variable -> DECLARE variable (Statements 3, 4, 5)
-- 4. BEGIN TRANSACTION/COMMIT -> Handled by C# NpgsqlTransaction
-- 5. Window functions (AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK) -> No changes (fully compatible)
-- 6. CTEs -> No changes (fully compatible)
-- 7. Parameter syntax @param -> Works with Npgsql (no changes in SQL)
-- ============================================================
