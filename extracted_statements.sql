-- ================================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET CODEBASE
-- ================================================================================
-- Purpose: Comprehensive catalog of all SQL statements for DMS conversion
-- Total Statements: 7
-- Source File: DataAccess/ProductRepository.cs
-- Extraction Date: 2026-02-24
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ================================================================================
-- File Location: DataAccess/ProductRepository.cs
-- Line Numbers: 39-69
-- Method: GetAllProductsAsync()
-- Statement Type: SELECT
-- Uses Parameters: No
-- Transaction Block: No
-- Features: CTE (Common Table Expression), Window Functions (AVG OVER, COUNT OVER), CASE expressions, INNER JOIN
-- Description: Retrieves all products with statistical analysis comparing each product price to average price
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
    p.Name

-- ================================================================================
-- STATEMENT 2: GetProductByIdAsync
-- ================================================================================
-- File Location: DataAccess/ProductRepository.cs
-- Line Numbers: 75-102
-- Method: GetProductByIdAsync(int productId)
-- Statement Type: SELECT
-- Uses Parameters: Yes (@ProductId)
-- Transaction Block: No
-- Features: CTE, LAG window function, LEFT JOIN, CASE expression for percentage calculation
-- Description: Retrieves a single product by ID with historical price and stock comparison
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
WHERE p.ProductId = @ProductId

-- ================================================================================
-- STATEMENT 3: InsertProductAsync
-- ================================================================================
-- File Location: DataAccess/ProductRepository.cs
-- Line Numbers: 110-133
-- Method: InsertProductAsync(Product product)
-- Statement Type: INSERT (Multi-statement transaction block)
-- Uses Parameters: Yes (@Name, @Description, @Price, @StockQuantity)
-- Transaction Block: Yes (BEGIN TRANSACTION...COMMIT)
-- Features: DECLARE variables, SCOPE_IDENTITY(), Multiple INSERT statements, UPDATE statement, GETDATE()
-- Description: Inserts a new product, logs the insertion to history, and updates product statistics
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
-- ================================================================================
-- File Location: DataAccess/ProductRepository.cs
-- Line Numbers: 146-178
-- Method: UpdateProductAsync(Product product)
-- Statement Type: UPDATE (Multi-statement transaction block)
-- Uses Parameters: Yes (@ProductId, @Name, @Description, @Price, @StockQuantity)
-- Transaction Block: Yes (BEGIN TRANSACTION...COMMIT)
-- Features: DECLARE variables, SELECT into variables, UPDATE statement, INSERT statement, GETDATE()
-- Description: Updates a product, logs the changes to history, and updates product statistics
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
-- ================================================================================
-- File Location: DataAccess/ProductRepository.cs
-- Line Numbers: 186-218
-- Method: DeleteProductAsync(int productId)
-- Statement Type: DELETE (Multi-statement transaction block)
-- Uses Parameters: Yes (@ProductId)
-- Transaction Block: Yes (BEGIN TRANSACTION...COMMIT)
-- Features: DECLARE variables, SELECT into variables, INSERT statement, DELETE statement, UPDATE with CASE, GETDATE()
-- Description: Deletes a product, logs the deletion to history, and updates product statistics
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
-- ================================================================================
-- File Location: DataAccess/ProductRepository.cs
-- Line Numbers: 226-249
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Statement Type: SELECT
-- Uses Parameters: Yes (@MinPrice, @MaxPrice)
-- Transaction Block: No
-- Features: CTE, RANK() window function, PERCENT_RANK() window function, CASE expression, BETWEEN
-- Description: Retrieves products within a price range with ranking and percentile analysis
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
ORDER BY rp.PriceRank

-- ================================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- ================================================================================
-- File Location: DataAccess/ProductRepository.cs
-- Line Numbers: 257-283
-- Method: GetLowStockProductsAsync(int threshold)
-- Statement Type: SELECT
-- Uses Parameters: Yes (@Threshold)
-- Transaction Block: No
-- Features: CTE, Multiple window functions (AVG OVER, MIN OVER, MAX OVER), CASE expression, ROUND
-- Description: Retrieves products with low stock levels with statistical analysis
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
ORDER BY StockQuantity

-- ================================================================================
-- END OF EXTRACTED STATEMENTS
-- ================================================================================
-- Summary:
-- - Total Statements Extracted: 7
-- - SELECT Statements: 4 (GetAllProductsAsync, GetProductByIdAsync, GetProductsByPriceRangeAsync, GetLowStockProductsAsync)
-- - INSERT Statements: 1 (InsertProductAsync - transaction block with multiple statements)
-- - UPDATE Statements: 1 (UpdateProductAsync - transaction block with multiple statements)
-- - DELETE Statements: 1 (DeleteProductAsync - transaction block with multiple statements)
-- - Transaction Blocks: 3 (InsertProductAsync, UpdateProductAsync, DeleteProductAsync)
-- - Parameterized Statements: 6 out of 7
-- - Statements with CTEs: 5 out of 7
-- - Statements with Window Functions: 5 out of 7
-- ================================================================================
