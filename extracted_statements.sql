-- ============================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- Migration: Microsoft SQL Server to PostgreSQL
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ============================================================================
-- Location: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Range: ~38-66
-- Type: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), CASE
-- Parameters: None
-- Usage: Retrieves all products with price category analysis using window functions

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
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ============================================================================
-- Location: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Range: ~78-105
-- Type: SELECT with CTE, Window Functions (LAG OVER), CASE
-- Parameters: @ProductId (int)
-- Usage: Retrieves product by ID with historical price comparison using LAG

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
-- STATEMENT 3: InsertProductAsync - Transaction Block with SCOPE_IDENTITY
-- ============================================================================
-- Location: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Range: ~117-141
-- Type: INSERT in Transaction Block with SCOPE_IDENTITY(), GETDATE()
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Usage: Inserts new product with transaction, logs to history, updates stats
-- Notes: Contains T-SQL specific SCOPE_IDENTITY() and GETDATE() functions

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
-- STATEMENT 4: UpdateProductAsync - Transaction Block with Variable Declarations
-- ============================================================================
-- Location: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Range: ~154-183
-- Type: UPDATE in Transaction Block with DECLARE, GETDATE()
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Usage: Updates product with transaction, logs changes to history, updates stats
-- Notes: Contains T-SQL specific DECLARE syntax and GETDATE() function

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
-- STATEMENT 5: DeleteProductAsync - Transaction Block with Complex CASE
-- ============================================================================
-- Location: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Range: ~191-223
-- Type: DELETE in Transaction Block with DECLARE, CASE, GETDATE()
-- Parameters: @ProductId
-- Usage: Deletes product with transaction, logs to history, updates stats
-- Notes: Contains T-SQL specific DECLARE, CASE in UPDATE, and GETDATE()

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
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ============================================================================
-- Location: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Range: ~231-254
-- Type: SELECT with CTE, Window Functions (RANK, PERCENT_RANK), CASE
-- Parameters: @MinPrice, @MaxPrice
-- Usage: Retrieves products in price range with ranking and segmentation

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
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ============================================================================
-- Location: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Range: ~268-293
-- Type: SELECT with CTE, Window Functions (AVG OVER, MIN OVER, MAX OVER), CASE
-- Parameters: @Threshold
-- Usage: Retrieves low stock products with stock analysis using window functions

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
-- Total Statements Extracted: 7
-- Statement Types:
--   - SELECT with CTE and Window Functions: 4 statements (1, 2, 6, 7)
--   - INSERT with Transaction: 1 statement (3)
--   - UPDATE with Transaction: 1 statement (4)
--   - DELETE with Transaction: 1 statement (5)
--
-- T-SQL Specific Constructs Identified:
--   - SCOPE_IDENTITY() - Statement 3
--   - GETDATE() - Statements 3, 4, 5
--   - BEGIN TRANSACTION/COMMIT - Statements 3, 4, 5
--   - DECLARE variable syntax - Statements 3, 4, 5
--   - Window Functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX OVER)
--   - Common Table Expressions (WITH clause)
--   - CASE expressions
--
-- All statements require conversion through DMS MCP tool for PostgreSQL compatibility
-- ============================================================================
