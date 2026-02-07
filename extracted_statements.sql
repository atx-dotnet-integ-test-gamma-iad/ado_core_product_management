-- ================================================================================
-- EXTRACTED SQL STATEMENTS FROM ADOCORE APPLICATION
-- SQL Server to PostgreSQL Migration - Statement Catalog
-- Extraction Date: 2026-02-07
-- Source File: DataAccess/ProductRepository.cs
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Method: GetAllProductsAsync()
-- Lines: 38-68 (approx)
-- Type: SELECT with CTE and Window Functions
-- Parameters: None
-- Description: Retrieves all products with price categorization using window functions
--              Uses AVG() OVER(), COUNT() OVER() window functions and CASE expressions
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Method: GetProductByIdAsync(int productId)
-- Lines: 79-109 (approx)
-- Type: SELECT with CTE and LAG Window Function
-- Parameters: @ProductId (int)
-- Description: Retrieves a single product by ID with price history tracking
--              Uses LAG() OVER() window function for historical comparison
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 3: InsertProductAsync
-- Method: InsertProductAsync(Product product)
-- Lines: 120-149 (approx)
-- Type: Transaction Block with INSERT statements
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: Inserts a new product with history logging and statistics update
--              Uses SCOPE_IDENTITY() to retrieve new ID, GETDATE() for timestamps
--              Transaction includes: INSERT into Products, INSERT into ProductHistory, UPDATE ProductStats
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 4: UpdateProductAsync
-- Method: UpdateProductAsync(Product product)
-- Lines: 160-192 (approx)
-- Type: Transaction Block with SELECT, UPDATE, INSERT statements
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: Updates product with history logging and statistics recalculation
--              Uses DECLARE for variable storage, GETDATE() for timestamps
--              Transaction includes: SELECT for old values, UPDATE Products, INSERT ProductHistory, UPDATE ProductStats
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 5: DeleteProductAsync
-- Method: DeleteProductAsync(int productId)
-- Lines: 194-226 (approx)
-- Type: Transaction Block with SELECT, INSERT, DELETE, UPDATE statements
-- Parameters: @ProductId (int)
-- Description: Deletes a product with history logging and statistics recalculation
--              Uses DECLARE for variable storage, GETDATE() for timestamps
--              Transaction includes: SELECT for old values, INSERT ProductHistory, DELETE Products, UPDATE ProductStats
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Lines: 228-256 (approx)
-- Type: SELECT with CTE, RANK() and PERCENT_RANK() Window Functions
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Description: Retrieves products within a price range with ranking and percentile calculation
--              Uses RANK() OVER(), PERCENT_RANK() OVER() window functions
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Method: GetLowStockProductsAsync(int threshold)
-- Lines: 258-288 (approx)
-- Type: SELECT with CTE and Multiple Window Functions
-- Parameters: @Threshold (int)
-- Description: Retrieves products with low stock levels using window function analytics
--              Uses AVG() OVER(), MIN() OVER(), MAX() OVER() window functions
-- ================================================================================

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

-- ================================================================================
-- SUMMARY OF EXTRACTED STATEMENTS
-- ================================================================================
-- Total Statements Extracted: 7
-- 
-- Statement Types:
--   - SELECT with CTEs and Window Functions: 4 (Statements 1, 2, 6, 7)
--   - Transaction Blocks with Multiple DML: 3 (Statements 3, 4, 5)
--
-- SQL Server Specific Features Used:
--   - Window Functions: AVG() OVER(), COUNT() OVER(), LAG() OVER(), RANK() OVER(), PERCENT_RANK() OVER(), MIN() OVER(), MAX() OVER()
--   - CTEs (Common Table Expressions): WITH clause
--   - SCOPE_IDENTITY(): For retrieving last inserted identity value
--   - GETDATE(): For current timestamp
--   - BEGIN TRANSACTION / COMMIT: Transaction control
--   - DECLARE: Variable declarations in transaction blocks
--   - CASE expressions: Conditional logic
--   - ROUND(): Numeric formatting
--
-- Tables Referenced:
--   - Products (main table)
--   - ProductHistory (audit log)
--   - ProductStats (aggregated statistics)
-- ================================================================================
