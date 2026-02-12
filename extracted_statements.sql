-- ============================================================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION FOR POSTGRESQL MIGRATION
-- ============================================================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Total Statements: 7
-- ============================================================================================================

-- ============================================================================================================
-- STATEMENT #1: GetAllProductsAsync
-- ============================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetAllProductsAsync()
-- Line Numbers: 37-69
-- Description: Complex CTE with window functions, CASE statements, and INNER JOIN
-- SQL Server Features: CTE (WITH), window functions (AVG OVER, COUNT OVER), CASE expressions, ROUND function
-- ============================================================================================================

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

-- ============================================================================================================
-- STATEMENT #2: GetProductByIdAsync
-- ============================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetProductByIdAsync(int productId)
-- Line Numbers: 84-111
-- Description: CTE with LAG window function and LEFT JOIN
-- SQL Server Features: CTE (WITH), LAG window function, parameterized query (@ProductId), CASE expressions
-- Parameters: @ProductId (int)
-- ============================================================================================================

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

-- ============================================================================================================
-- STATEMENT #3: InsertProductAsync
-- ============================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: InsertProductAsync(Product product)
-- Line Numbers: 127-149
-- Description: Transaction block with multiple INSERT and UPDATE statements
-- SQL Server Features: DECLARE variables, BEGIN TRANSACTION/COMMIT, SCOPE_IDENTITY(), GETDATE(), INSERT/UPDATE
-- Parameters: @Name (string), @Description (string, nullable), @Price (decimal), @StockQuantity (int)
-- CRITICAL: Contains SCOPE_IDENTITY() and GETDATE() which require PostgreSQL conversion
-- ============================================================================================================

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

-- ============================================================================================================
-- STATEMENT #4: UpdateProductAsync
-- ============================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: UpdateProductAsync(Product product)
-- Line Numbers: 157-190
-- Description: Transaction block with DECLARE, SELECT INTO, UPDATE, and INSERT statements
-- SQL Server Features: BEGIN TRANSACTION/COMMIT, DECLARE variables, SELECT INTO variables, UPDATE, INSERT, GETDATE()
-- Parameters: @ProductId (int), @Name (string), @Description (string, nullable), @Price (decimal), @StockQuantity (int)
-- CRITICAL: Contains GETDATE() which requires PostgreSQL conversion
-- ============================================================================================================

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

-- ============================================================================================================
-- STATEMENT #5: DeleteProductAsync
-- ============================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: DeleteProductAsync(int productId)
-- Line Numbers: 198-232
-- Description: Transaction block with DECLARE, SELECT INTO, INSERT, DELETE, and UPDATE with CASE
-- SQL Server Features: BEGIN TRANSACTION/COMMIT, DECLARE variables, DELETE, INSERT, UPDATE with CASE, GETDATE()
-- Parameters: @ProductId (int)
-- CRITICAL: Contains GETDATE() which requires PostgreSQL conversion
-- ============================================================================================================

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

-- ============================================================================================================
-- STATEMENT #6: GetProductsByPriceRangeAsync
-- ============================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Numbers: 240-265
-- Description: CTE with RANK and PERCENT_RANK window functions
-- SQL Server Features: CTE (WITH), RANK() OVER, PERCENT_RANK() OVER, BETWEEN operator, CASE expressions
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- ============================================================================================================

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

-- ============================================================================================================
-- STATEMENT #7: GetLowStockProductsAsync
-- ============================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetLowStockProductsAsync(int threshold)
-- Line Numbers: 273-301
-- Description: CTE with multiple aggregate window functions (AVG, MIN, MAX)
-- SQL Server Features: CTE (WITH), AVG() OVER, MIN() OVER, MAX() OVER, CASE expressions, ROUND function
-- Parameters: @Threshold (int)
-- ============================================================================================================

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

-- ============================================================================================================
-- END OF EXTRACTED SQL STATEMENTS
-- ============================================================================================================
-- Summary:
-- - Total Statements Extracted: 7
-- - Statements with CTEs: 5 (Statements 1, 2, 6, 7)
-- - Statements with Window Functions: 5 (Statements 1, 2, 6, 7)
-- - Statements with Transactions: 3 (Statements 3, 4, 5)
-- - Statements with SQL Server Specific Functions: 3 (SCOPE_IDENTITY, GETDATE in Statements 3, 4, 5)
-- - Parameterized Statements: 6 (All except Statement 1)
-- ============================================================================================================
