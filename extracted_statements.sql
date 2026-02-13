-- ============================================================================
-- SQL Statement Extraction Catalog
-- Source: ProductRepository.cs
-- Purpose: Comprehensive catalog of all SQL Server statements for DMS conversion
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STATEMENT 1: GetAllProductsAsync
-- Method: GetAllProductsAsync
-- Line Numbers: 42-71
-- Purpose: Retrieve all products with price statistics and categorization using CTE and window functions
-- SQL Server Features: CTE, AVG() OVER(), COUNT() OVER(), CASE expressions
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- STATEMENT 2: GetProductByIdAsync
-- Method: GetProductByIdAsync
-- Line Numbers: 87-117
-- Purpose: Retrieve product by ID with historical price comparison using LAG window function
-- SQL Server Features: CTE, LAG() OVER(), window functions, parameterized query (@ProductId)
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- STATEMENT 3: InsertProductAsync
-- Method: InsertProductAsync
-- Line Numbers: 128-153
-- Purpose: Insert new product with transaction, history logging, and statistics update
-- SQL Server Features: Transaction block (BEGIN TRANSACTION/COMMIT), SCOPE_IDENTITY(), GETDATE(), multi-table operations
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- STATEMENT 4: UpdateProductAsync
-- Method: UpdateProductAsync
-- Line Numbers: 167-199
-- Purpose: Update product with transaction, preserving history and updating statistics
-- SQL Server Features: Transaction block, DECLARE variables, GETDATE(), multi-table operations
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- STATEMENT 5: DeleteProductAsync
-- Method: DeleteProductAsync
-- Line Numbers: 211-244
-- Purpose: Delete product with transaction, history logging, and statistics recalculation
-- SQL Server Features: Transaction block, DECLARE variables, GETDATE(), CASE expression, multi-table operations
-- Parameters: @ProductId
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Method: GetProductsByPriceRangeAsync
-- Line Numbers: 256-283
-- Purpose: Retrieve products in price range with ranking and percentile analysis
-- SQL Server Features: CTE, RANK() OVER(), PERCENT_RANK() OVER(), window functions
-- Parameters: @MinPrice, @MaxPrice
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- STATEMENT 7: GetLowStockProductsAsync
-- Method: GetLowStockProductsAsync
-- Line Numbers: 295-325
-- Purpose: Retrieve low stock products with stock analysis using aggregates
-- SQL Server Features: CTE, AVG() OVER(), MIN() OVER(), MAX() OVER(), window functions
-- Parameters: @Threshold
-- ----------------------------------------------------------------------------
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
-- EXTRACTION SUMMARY
-- ============================================================================
-- Total SQL Statements Extracted: 7
-- Files Analyzed: ProductRepository.cs
-- 
-- Statement Types:
--   - SELECT with CTE and Window Functions: 4 (Statements 1, 2, 6, 7)
--   - INSERT with Transaction: 1 (Statement 3)
--   - UPDATE with Transaction: 1 (Statement 4)
--   - DELETE with Transaction: 1 (Statement 5)
--
-- SQL Server Specific Features Identified:
--   - Common Table Expressions (CTEs): 5 statements
--   - Window Functions (OVER clause): 4 statements
--   - Transaction Blocks (BEGIN TRANSACTION/COMMIT): 3 statements
--   - SCOPE_IDENTITY(): 1 statement (Statement 3)
--   - GETDATE(): 5 statements (Statements 3, 4, 5)
--   - LAG() window function: 1 statement (Statement 2)
--   - RANK() and PERCENT_RANK(): 1 statement (Statement 6)
--   - Aggregate window functions: 2 statements (Statements 1, 7)
-- ============================================================================
