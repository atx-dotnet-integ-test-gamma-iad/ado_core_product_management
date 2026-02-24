-- ===========================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- Source File: DataAccess/ProductRepository.cs
-- Extraction Date: 2026-02-24
-- Total Statements: 7
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- STATEMENT ID: STMT-001
-- Location: ProductRepository.cs, Method: GetAllProductsAsync, Lines: 40-64
-- Statement Type: SELECT with CTE
-- Parameters: None
-- Dependencies: Products table, ProductStats CTE
-- Description: Complex CTE with AVG() and COUNT() window functions, CASE statements, 
--              ROUND() function, and multiple JOINs. Returns all products with 
--              price category analysis.
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- STATEMENT ID: STMT-002
-- Location: ProductRepository.cs, Method: GetProductByIdAsync, Lines: 81-102
-- Statement Type: SELECT with CTE
-- Parameters: @ProductId (int)
-- Dependencies: Products table, ProductHistory CTE
-- Description: CTE with LAG() window function for tracking previous price and 
--              stock values. Includes price change percentage calculation.
--              Parameterized query with WHERE clause filter.
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- STATEMENT ID: STMT-003
-- Location: ProductRepository.cs, Method: InsertProductAsync, Lines: 122-144
-- Statement Type: TRANSACTION with INSERT, UPDATE
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Dependencies: Products table, ProductHistory table, ProductStats table
-- Description: Multi-statement transaction with SCOPE_IDENTITY() to capture new 
--              product ID, INSERT operations for product and history logging, 
--              UPDATE for statistics, and GETDATE() function calls.
--              CRITICAL: Uses SCOPE_IDENTITY() which must be converted to 
--              PostgreSQL RETURNING clause or sequence functions.
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- STATEMENT ID: STMT-004
-- Location: ProductRepository.cs, Method: UpdateProductAsync, Lines: 163-190
-- Statement Type: TRANSACTION with SELECT, UPDATE, INSERT
-- Parameters: @ProductId (int), @Name (string), @Description (string), 
--             @Price (decimal), @StockQuantity (int)
-- Dependencies: Products table, ProductHistory table, ProductStats table
-- Description: Multi-statement transaction with variable declarations (DECLARE),
--              SELECT to capture old values, UPDATE product record, INSERT 
--              history log, UPDATE statistics, and GETDATE() function calls.
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- STATEMENT ID: STMT-005
-- Location: ProductRepository.cs, Method: DeleteProductAsync, Lines: 210-239
-- Statement Type: TRANSACTION with SELECT, INSERT, DELETE, UPDATE
-- Parameters: @ProductId (int)
-- Dependencies: Products table, ProductHistory table, ProductStats table
-- Description: Multi-statement transaction with variable declarations (DECLARE),
--              SELECT to capture old values before deletion, INSERT history log,
--              DELETE product, UPDATE statistics with CASE expression, and 
--              GETDATE() function calls.
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- STATEMENT ID: STMT-006
-- Location: ProductRepository.cs, Method: GetProductsByPriceRangeAsync, Lines: 254-274
-- Statement Type: SELECT with CTE
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Dependencies: Products table, RankedProducts CTE
-- Description: CTE with RANK() and PERCENT_RANK() window functions for price 
--              ranking analysis. Includes BETWEEN clause for price range 
--              filtering and CASE statement for price segmentation.
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- STATEMENT ID: STMT-007
-- Location: ProductRepository.cs, Method: GetLowStockProductsAsync, Lines: 289-311
-- Statement Type: SELECT with CTE
-- Parameters: @Threshold (int)
-- Dependencies: Products table, StockAnalysis CTE
-- Description: CTE with AVG(), MIN(), MAX() window functions for stock analysis.
--              Includes CASE statement for stock status categorization and 
--              ROUND() function for percentage calculation. WHERE clause filters 
--              low stock items.
-- ---------------------------------------------------------------------------
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

-- ===========================================================================
-- END OF EXTRACTED STATEMENTS
-- ===========================================================================
-- 
-- SUMMARY:
-- - Total statements extracted: 7
-- - SELECT statements: 4 (STMT-001, STMT-002, STMT-006, STMT-007)
-- - Transaction blocks: 3 (STMT-003, STMT-004, STMT-005)
-- - CTEs used: 6 (all statements except STMT-003, STMT-004, STMT-005)
-- - Window functions: LAG, AVG, COUNT, RANK, PERCENT_RANK, MIN, MAX
-- - SQL Server specific functions: SCOPE_IDENTITY, GETDATE, ROUND
-- - Parameter count: 10 total parameters across all statements
-- 
-- CONVERSION NOTES:
-- All statements require DMS MCP tool conversion for:
-- 1. SCOPE_IDENTITY() → PostgreSQL RETURNING clause or sequence
-- 2. GETDATE() → CURRENT_TIMESTAMP or NOW()
-- 3. DECLARE variable syntax → PostgreSQL DO block or function
-- 4. BEGIN TRANSACTION/COMMIT → PostgreSQL transaction syntax
-- 5. Parameter syntax @ParamName → PostgreSQL $1, $2 or named parameters
-- 6. Window function syntax verification
-- 7. CTE syntax verification
-- 8. Data type compatibility (DECIMAL, INT, VARCHAR)
-- ===========================================================================
