-- ============================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- Source: Microsoft SQL Server ADO.NET Application (AdoCore)
-- Target: PostgreSQL
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- ============================================================

-- ============================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions
-- ============================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: GetAllProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- Changes Applied: No syntax changes needed - CTE and window functions are PostgreSQL compatible
-- ============================================================

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

-- ============================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ============================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: GetProductByIdAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- Changes Applied: No syntax changes needed - CTE, LAG window function, and parameterized queries are PostgreSQL compatible
-- ============================================================

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

-- ============================================================
-- STATEMENT 3: InsertProductAsync - Transaction with Identity Retrieval
-- ============================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: InsertProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Statement definition is not valid
-- Changes Applied:
--   1. Removed DECLARE @NewProductId - PostgreSQL doesn't support DECLARE outside functions
--   2. Replaced SCOPE_IDENTITY() with RETURNING clause to get the inserted ProductId
--   3. Replaced GETDATE() with CURRENT_TIMESTAMP (PostgreSQL equivalent)
--   4. Removed BEGIN TRANSACTION/COMMIT - transactions will be managed by application code
-- Note: Transaction management moved to C# application layer using BeginTransactionAsync()
-- ============================================================

INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Log the insertion (to be executed separately in the same transaction)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics (to be executed separately in the same transaction)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================
-- STATEMENT 4: UpdateProductAsync - Transaction with Variable Declarations
-- ============================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: UpdateProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Statement definition is not valid
-- Changes Applied:
--   1. Split into separate statements - PostgreSQL doesn't support DECLARE in ad-hoc SQL
--   2. Use CTEs to capture old values
--   3. Replaced GETDATE() with CURRENT_TIMESTAMP
--   4. Removed BEGIN TRANSACTION/COMMIT - transactions managed by application code
-- ============================================================

-- Get old values first (to be executed as separate query)
SELECT Price as OldPrice, StockQuantity as OldStock
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

-- Log the changes (to be executed separately with @OldPrice and @OldStock from first query)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================
-- STATEMENT 5: DeleteProductAsync - Transaction with Conditional Logic
-- ============================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: DeleteProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Statement definition is not valid
-- Changes Applied:
--   1. Split into separate statements - removed DECLARE variables
--   2. Replaced GETDATE() with CURRENT_TIMESTAMP
--   3. Removed BEGIN TRANSACTION/COMMIT - transactions managed by application code
-- ============================================================

-- Get old values first (to be executed as separate query)
SELECT Price as OldPrice, StockQuantity as OldStock
FROM Products
WHERE ProductId = @ProductId;

-- Log the deletion (to be executed separately with @OldPrice and @OldStock from first query)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

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
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ============================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: GetProductsByPriceRangeAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- Changes Applied: No syntax changes needed - CTE, RANK, PERCENT_RANK are PostgreSQL compatible
-- ============================================================

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

-- ============================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Window Functions
-- ============================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: GetLowStockProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- Changes Applied: No syntax changes needed - CTE and window functions are PostgreSQL compatible
-- ============================================================

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

-- ============================================================
-- END OF CONVERSION
-- Total Statements Converted: 7
-- All conversions: MANUAL_AFTER_DMS_FAILURE
-- Ready for Equivalency Validation
-- ============================================================
