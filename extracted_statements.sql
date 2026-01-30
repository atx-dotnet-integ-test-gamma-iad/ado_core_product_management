-- ============================================================================
-- EXTRACTED SQL STATEMENTS FROM ADONET APPLICATION
-- SQL Server to PostgreSQL Migration - Statement Catalog
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Extraction Date: Migration Phase 1
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Source Method: GetAllProductsAsync()
-- Line Range: Lines 38-69
-- Statement Type: SELECT with CTE
-- Complexity Features:
--   - Common Table Expression (CTE): ProductStats
--   - Window Functions: AVG() OVER(), COUNT() OVER()
--   - CASE expressions for conditional logic
--   - ROUND function for decimal precision
--   - INNER JOIN with CTE
--   - Complex ORDER BY with CASE
-- Parameters: None
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
-- ============================================================================
-- Source Method: GetProductByIdAsync(int productId)
-- Line Range: Lines 85-113
-- Statement Type: SELECT with CTE
-- Complexity Features:
--   - Common Table Expression (CTE): ProductHistory
--   - Window Function: LAG() OVER (ORDER BY ModifiedDate)
--   - LEFT JOIN with CTE
--   - CASE expression for conditional calculation
--   - ROUND function for percentage calculation
--   - NULL handling in CASE
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
-- ============================================================================
-- Source Method: InsertProductAsync(Product product)
-- Line Range: Lines 129-151
-- Statement Type: MULTI-STATEMENT TRANSACTION (INSERT with logging)
-- Complexity Features:
--   - DECLARE variable (@NewProductId)
--   - BEGIN TRANSACTION / COMMIT block
--   - INSERT statement
--   - SCOPE_IDENTITY() function for retrieving identity value
--   - Multiple INSERT statements within transaction
--   - GETDATE() function calls (3 occurrences)
--   - UPDATE statement with calculation
--   - SELECT to return new ID
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- ============================================================================
-- Source Method: UpdateProductAsync(Product product)
-- Line Range: Lines 167-197
-- Statement Type: MULTI-STATEMENT TRANSACTION (UPDATE with logging)
-- Complexity Features:
--   - DECLARE variables (@OldPrice, @OldStock)
--   - BEGIN TRANSACTION / COMMIT block
--   - SELECT to retrieve old values
--   - UPDATE statement with GETDATE()
--   - INSERT into history table with GETDATE()
--   - UPDATE statistics with calculation
--   - GETDATE() function calls (3 occurrences)
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- ============================================================================
-- Source Method: DeleteProductAsync(int productId)
-- Line Range: Lines 213-242
-- Statement Type: MULTI-STATEMENT TRANSACTION (DELETE with logging)
-- Complexity Features:
--   - DECLARE variables (@OldPrice, @OldStock)
--   - BEGIN TRANSACTION / COMMIT block
--   - SELECT to retrieve values before deletion
--   - INSERT into history table with GETDATE()
--   - DELETE statement
--   - UPDATE statistics with CASE expression
--   - CASE for division by zero protection
--   - GETDATE() function calls (2 occurrences)
-- Parameters: @ProductId (INT)
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ============================================================================
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Range: Lines 258-282
-- Statement Type: SELECT with CTE
-- Complexity Features:
--   - Common Table Expression (CTE): RankedProducts
--   - Window Functions: RANK() OVER (ORDER BY), PERCENT_RANK() OVER (ORDER BY)
--   - BETWEEN clause for range filtering
--   - CASE expression for price segmentation
--   - Percentile-based categorization
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
-- ============================================================================
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Line Range: Lines 298-324
-- Statement Type: SELECT with CTE
-- Complexity Features:
--   - Common Table Expression (CTE): StockAnalysis
--   - Multiple Window Functions: AVG() OVER(), MIN() OVER(), MAX() OVER()
--   - CASE expression for stock status categorization
--   - ROUND function for percentage calculation
--   - WHERE clause filtering on threshold
--   - Complex conditional logic with AVG calculation
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
-- END OF EXTRACTED STATEMENTS
-- ============================================================================
-- Summary:
--   - Total Statements: 7
--   - SELECT Statements: 4 (GetAllProductsAsync, GetProductByIdAsync, GetProductsByPriceRangeAsync, GetLowStockProductsAsync)
--   - Transaction Blocks: 3 (InsertProductAsync, UpdateProductAsync, DeleteProductAsync)
--   - CTEs Used: 5 (ProductStats, ProductHistory, RankedProducts, StockAnalysis)
--   - Window Functions: Multiple (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX with OVER)
--   - Date Functions: GETDATE() (8 occurrences across transaction blocks)
--   - Identity Functions: SCOPE_IDENTITY() (1 occurrence in InsertProductAsync)
-- ============================================================================
