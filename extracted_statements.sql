-- ============================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET REPOSITORY
-- File: DataAccess/ProductRepository.cs
-- Total Statements: 7 (includes complex multi-statement transactions)
-- Extraction Date: Migration Phase
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetAllProductsAsync
-- Line Numbers: ~37-66
-- Statement Type: SELECT with CTE
-- Complexity: MEDIUM
-- Features: CTE, Window Functions (AVG OVER, COUNT OVER), CASE expressions, INNER JOIN
-- Tables Referenced: Products, ProductStats (CTE)
-- Parameters: None
-- Description: Retrieves all products with price category analysis using window functions
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
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetProductByIdAsync
-- Line Numbers: ~76-102
-- Statement Type: SELECT with CTE
-- Complexity: MEDIUM
-- Features: CTE, Window Functions (LAG OVER), LEFT JOIN, CASE expression with NULL handling
-- Tables Referenced: Products, ProductHistory (CTE)
-- Parameters: @ProductId (INT)
-- Description: Retrieves single product with historical price change analysis using LAG window function
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
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: InsertProductAsync
-- Line Numbers: ~119-143
-- Statement Type: TRANSACTION with INSERT, UPDATE, SELECT
-- Complexity: HIGH
-- Features: Transaction, SCOPE_IDENTITY(), GETDATE(), Variable declaration, Multi-statement
-- Tables Referenced: Products, ProductHistory, ProductStats
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Description: Inserts new product, logs to history, updates statistics, returns new ID
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
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: UpdateProductAsync
-- Line Numbers: ~153-186
-- Statement Type: TRANSACTION with SELECT, UPDATE, INSERT
-- Complexity: HIGH
-- Features: Transaction, Variable declarations, GETDATE(), Multi-statement
-- Tables Referenced: Products, ProductHistory, ProductStats
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Description: Updates product, captures old values, logs changes, updates statistics
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
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: DeleteProductAsync
-- Line Numbers: ~196-228
-- Statement Type: TRANSACTION with SELECT, INSERT, DELETE, UPDATE
-- Complexity: HIGH
-- Features: Transaction, Variable declarations, GETDATE(), CASE expression, Multi-statement
-- Tables Referenced: Products, ProductHistory, ProductStats
-- Parameters: @ProductId (INT)
-- Description: Deletes product after logging to history and updating statistics with conditional logic
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
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetProductsByPriceRangeAsync
-- Line Numbers: ~238-262
-- Statement Type: SELECT with CTE
-- Complexity: MEDIUM
-- Features: CTE, Window Functions (RANK OVER, PERCENT_RANK OVER), CASE expression, BETWEEN
-- Tables Referenced: Products, RankedProducts (CTE)
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Description: Retrieves products in price range with ranking and percentile analysis
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
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetLowStockProductsAsync
-- Line Numbers: ~272-300
-- Statement Type: SELECT with CTE
-- Complexity: MEDIUM
-- Features: CTE, Window Functions (AVG OVER, MIN OVER, MAX OVER), CASE expression
-- Tables Referenced: Products, StockAnalysis (CTE)
-- Parameters: @Threshold (INT)
-- Description: Retrieves low stock products with stock level analysis using multiple window functions
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
-- - Total SQL Statement Units: 7
-- - CTEs with Window Functions: 4 (Statements 1, 2, 6, 7)
-- - Multi-statement Transactions: 3 (Statements 3, 4, 5)
-- - Window Functions Used: AVG OVER, COUNT OVER, LAG OVER, RANK, PERCENT_RANK, MIN OVER, MAX OVER
-- - T-SQL Specific Functions: SCOPE_IDENTITY, GETDATE
-- - Parameter Types: INT, NVARCHAR, DECIMAL(18,2)
-- - All statements ready for DMS MCP tool conversion
-- ============================================================================
