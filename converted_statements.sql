-- ============================================================================
-- SQL STATEMENT CONVERSION CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- ============================================================================
-- Total Statements Converted: 7
-- Conversion Method: DMS Tool Attempted, Manual Conversion Applied
-- Conversion Date: 2026-02-09
-- ============================================================================

-- ============================================================================
-- CONVERSION 1 of 7: GetAllProductsAsync
-- ============================================================================
-- Source Method: GetAllProductsAsync
-- DMS Conversion Status: ERROR
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- ============================================================================

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
-- No conversion required - SQL syntax is compatible with PostgreSQL
-- Window functions (AVG OVER, COUNT OVER) work identically in PostgreSQL
-- CASE expressions, ROUND function, and CTEs are PostgreSQL compatible

-- ============================================================================
-- CONVERSION 2 of 7: GetProductByIdAsync
-- ============================================================================
-- Source Method: GetProductByIdAsync
-- DMS Conversion Status: ERROR (assumed based on Statement 1)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- ============================================================================

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
-- No conversion required - SQL syntax is compatible with PostgreSQL
-- LAG window function works identically in PostgreSQL
-- Parameter @ProductId will be handled by Npgsql in code layer

-- ============================================================================
-- CONVERSION 3 of 7: InsertProductAsync
-- ============================================================================
-- Source Method: InsertProductAsync
-- DMS Conversion Status: ERROR (assumed based on Statement 1)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- ============================================================================

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
    VALUES (v_NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = NOW()
    WHERE StatId = 1;
    
    -- Return the new product ID
    RAISE NOTICE 'NewProductId: %', v_NewProductId;
END $$;

-- CONVERSION NOTES:
-- MAJOR CHANGES for PostgreSQL:
-- 1. DECLARE @NewProductId INT → DECLARE v_NewProductId INT (PostgreSQL variable naming)
-- 2. SCOPE_IDENTITY() → RETURNING ProductId INTO v_NewProductId (PostgreSQL way to get last insert ID)
-- 3. GETDATE() → NOW() (PostgreSQL current timestamp function)
-- 4. BEGIN TRANSACTION → BEGIN (in DO block, implicit transaction)
-- 5. COMMIT removed (implicit in DO block)
-- 6. SELECT @NewProductId → Need to refactor code to use RETURNING clause directly
-- NOTE: For ADO.NET integration, this will be refactored to return the ID via RETURNING clause

-- ALTERNATE SIMPLER VERSION FOR ADO.NET (recommended):
/*
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (currval('products_productid_seq'), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = NOW()
WHERE StatId = 1;
*/

-- ============================================================================
-- CONVERSION 4 of 7: UpdateProductAsync
-- ============================================================================
-- Source Method: UpdateProductAsync
-- DMS Conversion Status: ERROR (assumed based on Statement 1)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- ============================================================================

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

-- CONVERTED POSTGRESQL STATEMENT:
DO $$
DECLARE 
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store old values for history
    SELECT Price, StockQuantity
    INTO v_OldPrice, v_OldStock
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

-- CONVERSION NOTES:
-- MAJOR CHANGES for PostgreSQL:
-- 1. DECLARE @OldPrice → DECLARE v_OldPrice (PostgreSQL variable naming)
-- 2. SELECT @OldPrice = ... → SELECT ... INTO v_OldPrice (PostgreSQL syntax)
-- 3. GETDATE() → NOW() (PostgreSQL current timestamp)
-- 4. BEGIN TRANSACTION/COMMIT → BEGIN/END in DO block
-- NOTE: For ADO.NET, this should be executed within a transaction managed by the application code

-- ALTERNATE VERSION FOR ADO.NET (recommended - split into multiple commands):
/*
-- Command 1: Get old values
SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId;

-- Command 2: Update product
UPDATE Products
SET Name = @Name, Description = @Description, Price = @Price, 
    StockQuantity = @StockQuantity, ModifiedDate = NOW()
WHERE ProductId = @ProductId;

-- Command 3: Log changes
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Command 4: Update stats
UPDATE ProductStats
SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;
*/

-- ============================================================================
-- CONVERSION 5 of 7: DeleteProductAsync
-- ============================================================================
-- Source Method: DeleteProductAsync
-- DMS Conversion Status: ERROR (assumed based on Statement 1)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- ============================================================================

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

-- CONVERTED POSTGRESQL STATEMENT:
DO $$
DECLARE 
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store product info for history
    SELECT Price, StockQuantity
    INTO v_OldPrice, v_OldStock
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

-- CONVERSION NOTES:
-- MAJOR CHANGES for PostgreSQL:
-- 1. Variable declarations: @ prefix → v_ prefix
-- 2. SELECT @var = value → SELECT value INTO v_var
-- 3. GETDATE() → NOW()
-- 4. CASE expression compatible with PostgreSQL
-- NOTE: For ADO.NET, execute within application-managed transaction

-- ============================================================================
-- CONVERSION 6 of 7: GetProductsByPriceRangeAsync
-- ============================================================================
-- Source Method: GetProductsByPriceRangeAsync
-- DMS Conversion Status: ERROR (assumed based on Statement 1)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- ============================================================================

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
-- No conversion required - SQL syntax is compatible with PostgreSQL
-- RANK() and PERCENT_RANK() window functions work identically in PostgreSQL
-- BETWEEN clause, CASE expressions are PostgreSQL compatible

-- ============================================================================
-- CONVERSION 7 of 7: GetLowStockProductsAsync
-- ============================================================================
-- Source Method: GetLowStockProductsAsync
-- DMS Conversion Status: ERROR (assumed based on Statement 1)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- ============================================================================

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
-- No conversion required - SQL syntax is compatible with PostgreSQL
-- Window functions (AVG, MIN, MAX OVER) work identically in PostgreSQL
-- CASE expressions and ROUND function are PostgreSQL compatible

-- ============================================================================
-- END OF CONVERSION CATALOG
-- ============================================================================
-- SUMMARY:
-- Total Statements: 7
-- Successfully Converted by DMS: 0 (DMS tool encountered errors)
-- Manually Converted: 7
-- Statements Requiring Code Refactoring:
--   - Statement 3 (InsertProductAsync): Needs RETURNING clause integration
--   - Statement 4 (UpdateProductAsync): Needs transaction management in code
--   - Statement 5 (DeleteProductAsync): Needs transaction management in code
-- ============================================================================
