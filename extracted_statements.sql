-- ============================================================================
-- EXTRACTED SQL STATEMENTS - Microsoft SQL Server to PostgreSQL Migration
-- Source File: DataAccess/ProductRepository.cs
-- Total SQL Statements: 6 main statements (with 15+ individual SQL operations)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync
-- Lines: ~42-70
-- Type: SELECT with CTE, Window Functions, CASE expressions
-- Complexity: HIGH - Contains CTE, AVG OVER, COUNT OVER, CASE, complex ORDER BY
-- SQL Server Features: CTE, Window Functions (AVG OVER, COUNT OVER), CASE expressions
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
-- STATEMENT 2: GetProductByIdAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync
-- Lines: ~84-113
-- Type: SELECT with CTE, LAG Window Function, LEFT JOIN, Parameterized Query
-- Complexity: HIGH - Contains CTE, LAG window function, LEFT JOIN, parameter @ProductId
-- SQL Server Features: CTE, LAG() window function, LEFT JOIN, parameterized queries
-- Parameters: @ProductId (INT)
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
-- STATEMENT 3: InsertProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync
-- Lines: ~123-150
-- Type: Multi-statement TRANSACTION with INSERT, SCOPE_IDENTITY(), UPDATE
-- Complexity: VERY HIGH - Multi-statement transaction, SCOPE_IDENTITY(), GETDATE()
-- SQL Server Features: BEGIN TRANSACTION/COMMIT, DECLARE, SCOPE_IDENTITY(), GETDATE()
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- ============================================================================
-- Sub-statement 3.1: DECLARE
DECLARE @NewProductId INT;

-- Sub-statement 3.2: BEGIN TRANSACTION
BEGIN TRANSACTION;

-- Sub-statement 3.3: INSERT into Products
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity);

-- Sub-statement 3.4: Get SCOPE_IDENTITY
SET @NewProductId = SCOPE_IDENTITY();

-- Sub-statement 3.5: INSERT into ProductHistory (logging)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());

-- Sub-statement 3.6: UPDATE ProductStats
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = GETDATE()
WHERE StatId = 1;

-- Sub-statement 3.7: COMMIT
COMMIT;

-- Sub-statement 3.8: SELECT new ID
SELECT @NewProductId;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync
-- Lines: ~158-193
-- Type: Multi-statement TRANSACTION with DECLARE, SELECT, UPDATE, INSERT
-- Complexity: VERY HIGH - Multi-statement transaction, DECLARE variables, GETDATE()
-- SQL Server Features: BEGIN TRANSACTION/COMMIT, DECLARE, GETDATE()
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- ============================================================================
-- Sub-statement 4.1: BEGIN TRANSACTION
BEGIN TRANSACTION;

-- Sub-statement 4.2: DECLARE variables
DECLARE @OldPrice DECIMAL(18,2);
DECLARE @OldStock INT;

-- Sub-statement 4.3: SELECT old values
SELECT @OldPrice = Price, @OldStock = StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Sub-statement 4.4: UPDATE Products
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = GETDATE()
WHERE ProductId = @ProductId;

-- Sub-statement 4.5: INSERT into ProductHistory (logging)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());

-- Sub-statement 4.6: UPDATE ProductStats
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = GETDATE()
WHERE StatId = 1;

-- Sub-statement 4.7: COMMIT
COMMIT;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync
-- Lines: ~201-234
-- Type: Multi-statement TRANSACTION with DECLARE, SELECT, INSERT, DELETE, UPDATE
-- Complexity: VERY HIGH - Multi-statement transaction, DECLARE variables, conditional UPDATE
-- SQL Server Features: BEGIN TRANSACTION/COMMIT, DECLARE, GETDATE(), CASE expression in UPDATE
-- Parameters: @ProductId (INT)
-- ============================================================================
-- Sub-statement 5.1: BEGIN TRANSACTION
BEGIN TRANSACTION;

-- Sub-statement 5.2: DECLARE variables
DECLARE @OldPrice DECIMAL(18,2);
DECLARE @OldStock INT;

-- Sub-statement 5.3: SELECT product info
SELECT @OldPrice = Price, @OldStock = StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Sub-statement 5.4: INSERT into ProductHistory (logging)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());

-- Sub-statement 5.5: DELETE from Products
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Sub-statement 5.6: UPDATE ProductStats with CASE
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

-- Sub-statement 5.7: COMMIT
COMMIT;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync
-- Lines: ~242-264
-- Type: SELECT with CTE, RANK/PERCENT_RANK Window Functions, Parameterized Query
-- Complexity: HIGH - Contains CTE, RANK(), PERCENT_RANK(), CASE expressions
-- SQL Server Features: CTE, Window Functions (RANK, PERCENT_RANK), CASE expressions
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
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
-- STATEMENT 7: GetLowStockProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync
-- Lines: ~272-296
-- Type: SELECT with CTE, Multiple Window Functions, Parameterized Query
-- Complexity: VERY HIGH - Contains CTE, multiple window functions (AVG, MIN, MAX OVER), CASE
-- SQL Server Features: CTE, Window Functions (AVG, MIN, MAX with OVER), CASE expressions
-- Parameters: @Threshold (INT)
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
-- SUMMARY
-- ============================================================================
-- Total SQL Methods: 7
-- Total SQL Statements Identified: 25 (including sub-statements in transactions)
-- Statements with CTEs: 4
-- Statements with Window Functions: 4
-- Statements with Transactions: 3
-- Statements with SCOPE_IDENTITY(): 1
-- Statements with GETDATE(): 6
-- Statements with Parameterized Queries: 5
-- 
-- SQL Server-Specific Features Requiring Conversion:
-- 1. SCOPE_IDENTITY() - PostgreSQL uses RETURNING clause or currval()
-- 2. GETDATE() - PostgreSQL uses CURRENT_TIMESTAMP or NOW()
-- 3. BEGIN TRANSACTION/COMMIT - PostgreSQL syntax differences
-- 4. DECLARE variable syntax - PostgreSQL uses different syntax
-- 5. Window function syntax - May have minor differences
-- 6. CASE expressions - Should be compatible but verify
-- 7. CTE syntax - Generally compatible but verify
-- ============================================================================
