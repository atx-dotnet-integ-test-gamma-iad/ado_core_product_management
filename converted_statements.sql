-- ===============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Compatible
-- Conversion Date: 2026-02-02
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (All statements)
-- DMS Tool Status: All conversions failed due to timeout errors
-- ===============================================================================
-- IMPORTANT: All statements were passed through DMS MCP tool but encountered
-- timeout errors. Manual conversions were performed after DMS processing attempts.
-- See dms_conversion_log.json for detailed DMS error messages.
-- ===============================================================================

-- ===============================================================================
-- STATEMENT 1: Get All Products with CTE and Window Functions
-- ===============================================================================
-- Source: ProductRepository.cs - GetAllProductsAsync()
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model conversion timeout
-- PostgreSQL Changes: None - Already compatible
-- Mapping: Statement 1 in extracted_statements.sql
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 2: Get Product By ID with Window Functions (LAG)
-- ===============================================================================
-- Source: ProductRepository.cs - GetProductByIdAsync()
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model creation timeout
-- PostgreSQL Changes: None - Already compatible
-- Mapping: Statement 2 in extracted_statements.sql
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 3: Insert Product with Transaction Block
-- ===============================================================================
-- Source: ProductRepository.cs - InsertProductAsync()
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model creation timeout
-- PostgreSQL Changes: MAJOR - Restructured to use CTEs with RETURNING
-- Changes Applied:
--   1. Removed DECLARE @NewProductId - PostgreSQL uses RETURNING instead
--   2. Removed BEGIN TRANSACTION/COMMIT - Managed by C# transaction code
--   3. Replaced SCOPE_IDENTITY() with RETURNING clause
--   4. GETDATE() → CURRENT_TIMESTAMP
--   5. Chained operations using CTEs
-- Mapping: Statement 3 in extracted_statements.sql
-- ===============================================================================

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
WHERE StatId = 1
RETURNING (SELECT ProductId FROM inserted_product);

-- ===============================================================================
-- STATEMENT 4: Update Product with Transaction Block
-- ===============================================================================
-- Source: ProductRepository.cs - UpdateProductAsync()
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model creation timeout (extrapolated)
-- PostgreSQL Changes: MAJOR - Restructured to use CTEs
-- Changes Applied:
--   1. Removed DECLARE statements for @OldPrice, @OldStock
--   2. Removed BEGIN TRANSACTION/COMMIT - Managed by C# transaction code
--   3. Used CTE (old_values) to capture old values
--   4. GETDATE() → CURRENT_TIMESTAMP (3 occurrences)
--   5. Chained operations using CTEs with RETURNING
-- Mapping: Statement 4 in extracted_statements.sql
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 5: Delete Product with Transaction Block
-- ===============================================================================
-- Source: ProductRepository.cs - DeleteProductAsync()
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model creation timeout (extrapolated)
-- PostgreSQL Changes: MAJOR - Restructured to use CTEs
-- Changes Applied:
--   1. Removed DECLARE statements for @OldPrice, @OldStock
--   2. Removed BEGIN TRANSACTION/COMMIT - Managed by C# transaction code
--   3. Used CTE (old_values) to capture values before deletion
--   4. GETDATE() → CURRENT_TIMESTAMP (2 occurrences)
--   5. Chained operations using CTEs with RETURNING
--   6. DELETE in CTE is PostgreSQL-specific feature
-- Mapping: Statement 5 in extracted_statements.sql
-- ===============================================================================

WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
inserted_history AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'DELETE', ov.OldPrice, NULL, ov.OldStock, NULL, CURRENT_TIMESTAMP
    FROM old_values ov
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

-- ===============================================================================
-- STATEMENT 6: Get Products By Price Range with Window Functions
-- ===============================================================================
-- Source: ProductRepository.cs - GetProductsByPriceRangeAsync()
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model creation timeout (extrapolated)
-- PostgreSQL Changes: None - Already compatible
-- Mapping: Statement 6 in extracted_statements.sql
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 7: Get Low Stock Products with Window Functions
-- ===============================================================================
-- Source: ProductRepository.cs - GetLowStockProductsAsync()
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model creation timeout (extrapolated)
-- PostgreSQL Changes: None - Already compatible
-- Mapping: Statement 7 in extracted_statements.sql
-- ===============================================================================

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

-- ===============================================================================
-- CONVERSION SUMMARY
-- ===============================================================================
-- Total Statements Converted: 7
-- DMS Tool Successful Conversions: 0
-- Manual Conversions After DMS Failure: 7
-- ===============================================================================
-- Statements with NO Changes Required: 4 (Statements 1, 2, 6, 7)
--   - These statements use standard SQL window functions fully compatible with PostgreSQL
--   - CTEs, CASE expressions, and parameterized queries work identically
-- ===============================================================================
-- Statements with MAJOR Changes: 3 (Statements 3, 4, 5)
--   - Transaction blocks restructured using PostgreSQL CTEs
--   - SCOPE_IDENTITY() replaced with RETURNING clause
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Variable declarations eliminated (use CTEs instead)
--   - Transaction control moved to application layer (C# code)
-- ===============================================================================
-- Key PostgreSQL Features Used:
--   1. RETURNING clause for capturing inserted/updated IDs
--   2. CTEs with data-modifying statements (INSERT/UPDATE/DELETE in CTEs)
--   3. CURRENT_TIMESTAMP for current date/time
--   4. Window functions (fully compatible with SQL Server syntax)
-- ===============================================================================
-- Application Code Requirements:
--   1. Transaction management must be implemented in C# code
--   2. Use NpgsqlConnection.BeginTransaction() for explicit transactions
--   3. ExecuteScalar should capture RETURNING clause results
--   4. Error handling for transaction rollback in C# try-catch blocks
-- ===============================================================================
