/*
==============================================================================
SQL Statement Conversion Catalog
SQL Server to PostgreSQL Migration - ADO.NET Application
==============================================================================
Source: extracted_statements.sql
Conversion Method: Manual conversion after DMS tool failures
Conversion Date: 2026-02-19
Total Statements Converted: 7

NOTE: All statements were submitted to DMS MCP tool but received metadata model 
creation errors. Manual conversions follow SQL Server to PostgreSQL best practices.
See dms_conversion_log.txt for detailed DMS tool output.
==============================================================================
*/

-- ==============================================================================
-- STATEMENT 1: GetAllProductsAsync (PostgreSQL Version)
-- ==============================================================================
-- Original SQL Server Statement: See extracted_statements.sql Statement 1
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes:
--   - CTE syntax: Compatible with PostgreSQL (no changes needed)
--   - Window functions (AVG, COUNT OVER): Compatible with PostgreSQL
--   - CASE expressions: Compatible with PostgreSQL
--   - ROUND function: Compatible with PostgreSQL
--   - Schema: Assuming 'Products' table in default public schema
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 2: GetProductByIdAsync (PostgreSQL Version)
-- ==============================================================================
-- Original SQL Server Statement: See extracted_statements.sql Statement 2
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes:
--   - CTE syntax: Compatible with PostgreSQL
--   - LAG window function: Compatible with PostgreSQL
--   - CASE expressions: Compatible with PostgreSQL
--   - ROUND function: Compatible with PostgreSQL
--   - Parameters (@ProductId): Compatible with Npgsql
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 3: InsertProductAsync (PostgreSQL Version)
-- ==============================================================================
-- Original SQL Server Statement: See extracted_statements.sql Statement 3
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes:
--   - Removed DECLARE @NewProductId - PostgreSQL handles this differently
--   - BEGIN TRANSACTION → BEGIN (PostgreSQL syntax)
--   - SCOPE_IDENTITY() → RETURNING ProductId (PostgreSQL syntax)
--   - GETDATE() → CURRENT_TIMESTAMP (PostgreSQL function)
--   - Combined INSERT with RETURNING to get new ID
--   - COMMIT → COMMIT (compatible)
--   - Restructured to use WITH clause for captured ID
-- ==============================================================================

WITH inserted_product AS (
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId
),
inserted_history AS (
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
FROM inserted_history
WHERE StatId = 1
RETURNING (SELECT ProductId FROM inserted_product);

-- ==============================================================================
-- STATEMENT 3 (Alternative Simpler Version for ADO.NET)
-- ==============================================================================
-- Note: The above version may be complex for ExecuteScalar. Here's a simpler version
-- that can be executed as multiple commands within a transaction in C# code:
-- ==============================================================================

INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Then in separate commands within the same transaction:
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
--
-- UPDATE ProductStats
-- SET 
--     TotalProducts = TotalProducts + 1,
--     AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
--     LastUpdated = CURRENT_TIMESTAMP
-- WHERE StatId = 1;

-- ==============================================================================
-- STATEMENT 4: UpdateProductAsync (PostgreSQL Version)
-- ==============================================================================
-- Original SQL Server Statement: See extracted_statements.sql Statement 4
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes:
--   - BEGIN TRANSACTION → BEGIN (will be handled by C# transaction management)
--   - DECLARE removed - using CTEs to capture old values
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Restructured to use WITH clause pattern
--   - COMMIT → COMMIT (will be handled by C# transaction management)
-- Note: For ADO.NET, simpler to break into multiple commands within C# transaction
-- ==============================================================================

WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
updated_product AS (
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
inserted_history AS (
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

-- ==============================================================================
-- STATEMENT 4 (Alternative Simpler Version for ADO.NET)
-- ==============================================================================
-- Breaking into separate commands is cleaner for ADO.NET ExecuteNonQuery:
-- ==============================================================================

-- Command 1: Get old values (can be done in C# code)
-- SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId;

-- Command 2: Update product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Command 3: Insert history (with @OldPrice and @OldStock from C# variables)
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Command 4: Update statistics
-- UPDATE ProductStats
-- SET 
--     AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
--     LastUpdated = CURRENT_TIMESTAMP
-- WHERE StatId = 1;

-- ==============================================================================
-- STATEMENT 5: DeleteProductAsync (PostgreSQL Version)
-- ==============================================================================
-- Original SQL Server Statement: See extracted_statements.sql Statement 5
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes:
--   - BEGIN TRANSACTION → BEGIN (handled by C# transaction)
--   - DECLARE removed - using CTEs
--   - GETDATE() → CURRENT_TIMESTAMP
--   - COMMIT → COMMIT (handled by C# transaction)
-- ==============================================================================

-- Simpler version broken into commands for ADO.NET:

WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
inserted_history AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, CURRENT_TIMESTAMP
    FROM old_values
    RETURNING ProductId
),
deleted_product AS (
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

-- ==============================================================================
-- STATEMENT 5 (Alternative Simpler Version for ADO.NET)
-- ==============================================================================

-- Command 1: Get old values
-- SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId;

-- Command 2: Insert history
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Command 3: Delete product
DELETE FROM Products WHERE ProductId = @ProductId;

-- Command 4: Update statistics
-- UPDATE ProductStats
-- SET 
--     TotalProducts = TotalProducts - 1,
--     AveragePrice = CASE 
--         WHEN TotalProducts > 1 
--         THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
--         ELSE 0
--     END,
--     LastUpdated = CURRENT_TIMESTAMP
-- WHERE StatId = 1;

-- ==============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (PostgreSQL Version)
-- ==============================================================================
-- Original SQL Server Statement: See extracted_statements.sql Statement 6
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes:
--   - CTE syntax: Compatible with PostgreSQL
--   - Window functions (RANK, PERCENT_RANK): Compatible with PostgreSQL
--   - BETWEEN operator: Compatible with PostgreSQL
--   - Wildcard SELECT (p.*): Compatible with PostgreSQL
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 7: GetLowStockProductsAsync (PostgreSQL Version)
-- ==============================================================================
-- Original SQL Server Statement: See extracted_statements.sql Statement 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes:
--   - CTE syntax: Compatible with PostgreSQL
--   - Window functions (AVG, MIN, MAX OVER): Compatible with PostgreSQL
--   - CASE expressions: Compatible with PostgreSQL
--   - ROUND function: Compatible with PostgreSQL
--   - Arithmetic in CASE conditions: Compatible with PostgreSQL
-- ==============================================================================

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

-- ==============================================================================
-- CONVERSION SUMMARY
-- ==============================================================================
-- Total Statements Converted: 7
-- Successfully Converted (fully compatible): 4 (Statements 1, 2, 6, 7)
-- Converted with restructuring (for ADO.NET simplicity): 3 (Statements 3, 4, 5)
--
-- Key PostgreSQL Conversions Applied:
-- 1. GETDATE() → CURRENT_TIMESTAMP (3 statements)
-- 2. SCOPE_IDENTITY() → RETURNING clause (1 statement)
-- 3. BEGIN TRANSACTION/COMMIT → Handled by C# transaction management
-- 4. DECLARE variables → Removed or converted to CTEs
-- 5. CTEs, Window Functions, CASE: All directly compatible
--
-- Schema Changes: None (Products table name unchanged)
--
-- For statements 3, 4, 5: Two versions provided
--   - Complex CTE version (may work in single query)
--   - Simple multi-command version (recommended for ADO.NET ExecuteNonQuery/ExecuteScalar)
-- ==============================================================================
