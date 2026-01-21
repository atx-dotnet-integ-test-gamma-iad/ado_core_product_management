-- =====================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- CONVERSION DATE: 2026-01-21
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE (all statements)
-- TOTAL STATEMENTS: 7
-- SOURCE: extracted_statements.sql
-- =====================================================================

-- NOTE: All statements were manually converted due to DMS MCP tool timeout failures.
-- See dms_conversion_log.txt for detailed documentation of DMS attempts and failures.

-- =====================================================================
-- STATEMENT 1: GetAllProductsAsync
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
-- CHANGES: None required - PostgreSQL syntax compatible
-- SCHEMA CHANGES: None (Products table name unchanged)
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 2: GetProductByIdAsync
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
-- CHANGES: None required - PostgreSQL syntax compatible
-- SCHEMA CHANGES: None (Products table name unchanged)
-- PARAMETERS: @ProductId (handled by Npgsql as $1)
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 3: InsertProductAsync
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
-- CRITICAL CHANGES:
--   - Removed DECLARE @NewProductId INT (PostgreSQL doesn't support variables in plain SQL)
--   - Changed BEGIN TRANSACTION to BEGIN
--   - Changed SCOPE_IDENTITY() to RETURNING clause
--   - Changed GETDATE() to NOW()
--   - Split into two execution calls: first for transaction, second to get returned ID
-- SCHEMA CHANGES: None (Products, ProductHistory, ProductStats unchanged)
-- PARAMETERS: @Name, @Description, @Price, @StockQuantity (handled by Npgsql)
-- =====================================================================
-- Note: This will be executed as a single command returning the new ProductId
INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
VALUES (@Name, @Description, @Price, @StockQuantity, NOW())
RETURNING ProductId;

-- Note: The transaction logic with ProductHistory and ProductStats updates
-- will need to be restructured in the code to use the returned ProductId
-- Option 1: Execute as separate statements after getting the returned ID
-- Option 2: Use a PostgreSQL function/procedure
-- For ADO.NET integration, we'll use Option 1 with code-level transaction management

-- =====================================================================
-- STATEMENT 4: UpdateProductAsync
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
-- CRITICAL CHANGES:
--   - Removed DECLARE statements (not supported in regular SQL)
--   - Changed BEGIN TRANSACTION to BEGIN
--   - Changed GETDATE() to NOW()
--   - Converted to use subqueries instead of variables
-- SCHEMA CHANGES: None
-- PARAMETERS: @ProductId, @Name, @Description, @Price, @StockQuantity
-- =====================================================================
-- Note: Transaction must be managed at ADO.NET level, not in SQL
-- Statement 1: Get old values
SELECT Price as OldPrice, StockQuantity as OldStock
FROM Products
WHERE ProductId = @ProductId;

-- Statement 2: Update product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = NOW()
WHERE ProductId = @ProductId;

-- Statement 3: Insert history (using parameters passed from code)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Statement 4: Update statistics (using parameters passed from code)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- =====================================================================
-- STATEMENT 5: DeleteProductAsync
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
-- CRITICAL CHANGES:
--   - Removed DECLARE statements (not supported in regular SQL)
--   - Changed BEGIN TRANSACTION to BEGIN
--   - Changed GETDATE() to NOW()
--   - Converted to use subqueries instead of variables
-- SCHEMA CHANGES: None
-- PARAMETERS: @ProductId
-- =====================================================================
-- Note: Transaction must be managed at ADO.NET level
-- Statement 1: Get old values
SELECT Price as OldPrice, StockQuantity as OldStock
FROM Products
WHERE ProductId = @ProductId;

-- Statement 2: Insert history (using parameters from Statement 1)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Statement 3: Delete product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Statement 4: Update statistics (using parameters from Statement 1)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = NOW()
WHERE StatId = 1;

-- =====================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
-- CHANGES: None required - PostgreSQL syntax compatible
-- SCHEMA CHANGES: None
-- PARAMETERS: @MinPrice, @MaxPrice
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
-- CHANGES: None required - PostgreSQL syntax compatible
-- SCHEMA CHANGES: None
-- PARAMETERS: @Threshold
-- =====================================================================
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

-- =====================================================================
-- END OF CONVERTED STATEMENTS
-- =====================================================================
-- CONVERSION SUMMARY:
-- - Total statements converted: 7
-- - Conversion method: MANUAL_AFTER_DMS_FAILURE (all statements)
-- - Schema object name changes: None (all table names preserved)
-- - Key PostgreSQL conversions applied:
--   * GETDATE() -> NOW()
--   * SCOPE_IDENTITY() -> RETURNING clause
--   * BEGIN TRANSACTION -> BEGIN (or ADO.NET level transaction)
--   * DECLARE variables -> Removed (handled at application level)
--   * Window functions -> Compatible, no changes needed
--   * CTE syntax -> Compatible, no changes needed
--   * Parameters -> @param syntax handled by Npgsql driver
-- - Transaction handling: Multi-statement transactions with variables
--   converted to use ADO.NET transaction management
-- =====================================================================
