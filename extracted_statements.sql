-- ================================================================
-- EXTRACTED SQL STATEMENTS FROM MS SQL SERVER CODEBASE
-- ================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Extraction Date: 2026-02-17
-- Total Statements: 6 (from 6 main methods)
-- ================================================================

-- ================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ================================================================
-- Source Location: ProductRepository.cs, Lines 38-68 (approx)
-- Method: GetAllProductsAsync()
-- Description: Retrieves all products with CTE, window functions (AVG OVER, COUNT OVER), CASE expressions
-- Parameters: None
-- Features: CTE (ProductStats), Window Functions (AVG, COUNT), CASE expressions, ROUND function
-- ================================================================

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

-- ================================================================
-- STATEMENT 2: GetProductByIdAsync
-- ================================================================
-- Source Location: ProductRepository.cs, Lines 77-102 (approx)
-- Method: GetProductByIdAsync(int productId)
-- Description: Retrieves a single product by ID with LAG window function for price history
-- Parameters: @ProductId (int)
-- Features: CTE (ProductHistory), LAG window function, LEFT JOIN, CASE expression
-- ================================================================

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

-- ================================================================
-- STATEMENT 3: InsertProductAsync
-- ================================================================
-- Source Location: ProductRepository.cs, Lines 117-142 (approx)
-- Method: InsertProductAsync(Product product)
-- Description: Transaction block for inserting product with history logging and stats update
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Features: Transaction (BEGIN/COMMIT), DECLARE variables, SCOPE_IDENTITY(), GETDATE(), multiple INSERT/UPDATE
-- ================================================================

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

-- ================================================================
-- STATEMENT 4: UpdateProductAsync
-- ================================================================
-- Source Location: ProductRepository.cs, Lines 153-181 (approx)
-- Method: UpdateProductAsync(Product product)
-- Description: Transaction block for updating product with history logging and stats update
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Features: Transaction (BEGIN/COMMIT), DECLARE variables, GETDATE(), SELECT into variables, UPDATE statements
-- ================================================================

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

-- ================================================================
-- STATEMENT 5: DeleteProductAsync
-- ================================================================
-- Source Location: ProductRepository.cs, Lines 193-220 (approx)
-- Method: DeleteProductAsync(int productId)
-- Description: Transaction block for deleting product with history logging and stats update
-- Parameters: @ProductId (int)
-- Features: Transaction (BEGIN/COMMIT), DECLARE variables, GETDATE(), SELECT into variables, DELETE, UPDATE with CASE
-- ================================================================

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

-- ================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ================================================================
-- Source Location: ProductRepository.cs, Lines 228-253 (approx)
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Description: Retrieves products in price range with RANK and PERCENT_RANK window functions
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Features: CTE (RankedProducts), RANK(), PERCENT_RANK() window functions, BETWEEN clause, CASE expression
-- ================================================================

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

-- ================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- ================================================================
-- Source Location: ProductRepository.cs, Lines 261-287 (approx)
-- Method: GetLowStockProductsAsync(int threshold)
-- Description: Retrieves low stock products with AVG, MIN, MAX window functions
-- Parameters: @Threshold (int)
-- Features: CTE (StockAnalysis), Multiple window functions (AVG, MIN, MAX), CASE expression, ROUND
-- ================================================================

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

-- ================================================================
-- END OF EXTRACTED STATEMENTS
-- ================================================================
-- SUMMARY:
-- - Total Methods Analyzed: 6
-- - Total SQL Statements Extracted: 7 (GetAllProductsAsync, GetProductByIdAsync, 
--   InsertProductAsync, UpdateProductAsync, DeleteProductAsync, 
--   GetProductsByPriceRangeAsync, GetLowStockProductsAsync)
-- - Common SQL Server Features Found:
--   * CTEs (WITH clauses)
--   * Window Functions (AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK, MIN, MAX)
--   * Transaction Blocks (BEGIN TRANSACTION, COMMIT)
--   * SCOPE_IDENTITY() function
--   * GETDATE() function
--   * CASE expressions
--   * ROUND function
--   * Variable declarations (DECLARE)
-- - All statements preserved with original formatting and parameter bindings
-- ================================================================
