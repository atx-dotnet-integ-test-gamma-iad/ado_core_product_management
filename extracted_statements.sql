-- =====================================================================
-- SQL STATEMENTS EXTRACTED FROM ADO.NET APPLICATION
-- EXTRACTION DATE: Migration to PostgreSQL
-- TOTAL STATEMENTS: 7
-- =====================================================================

-- =====================================================================
-- STATEMENT 1: GetAllProductsAsync
-- SOURCE FILE: ProductRepository.cs
-- METHOD: GetAllProductsAsync()
-- LINE NUMBERS: ~38-67
-- DESCRIPTION: Complex CTE with window functions (AVG OVER, COUNT OVER) and CASE expressions
-- STATEMENT TYPE: SELECT with CTE
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 2: GetProductByIdAsync
-- SOURCE FILE: ProductRepository.cs
-- METHOD: GetProductByIdAsync(int productId)
-- LINE NUMBERS: ~82-107
-- DESCRIPTION: CTE with LAG window function for historical analysis
-- STATEMENT TYPE: SELECT with CTE and parameters
-- PARAMETERS: @ProductId (int)
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 3: InsertProductAsync
-- SOURCE FILE: ProductRepository.cs
-- METHOD: InsertProductAsync(Product product)
-- LINE NUMBERS: ~122-146
-- DESCRIPTION: Multi-statement transaction with SCOPE_IDENTITY() and GETDATE() functions
-- STATEMENT TYPE: INSERT with transaction
-- PARAMETERS: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- CRITICAL FEATURES: Uses SCOPE_IDENTITY(), GETDATE(), BEGIN TRANSACTION/COMMIT
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 4: UpdateProductAsync
-- SOURCE FILE: ProductRepository.cs
-- METHOD: UpdateProductAsync(Product product)
-- LINE NUMBERS: ~160-189
-- DESCRIPTION: Multi-statement transaction with variable declarations
-- STATEMENT TYPE: UPDATE with transaction
-- PARAMETERS: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- CRITICAL FEATURES: Uses DECLARE variables, GETDATE(), BEGIN TRANSACTION/COMMIT
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 5: DeleteProductAsync
-- SOURCE FILE: ProductRepository.cs
-- METHOD: DeleteProductAsync(int productId)
-- LINE NUMBERS: ~203-234
-- DESCRIPTION: Multi-statement transaction with conditional logic
-- STATEMENT TYPE: DELETE with transaction
-- PARAMETERS: @ProductId (int)
-- CRITICAL FEATURES: Uses DECLARE variables, GETDATE(), BEGIN TRANSACTION/COMMIT, conditional CASE
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- SOURCE FILE: ProductRepository.cs
-- METHOD: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- LINE NUMBERS: ~248-268
-- DESCRIPTION: CTE with RANK() and PERCENT_RANK() window functions
-- STATEMENT TYPE: SELECT with CTE and window functions
-- PARAMETERS: @MinPrice (decimal), @MaxPrice (decimal)
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- SOURCE FILE: ProductRepository.cs
-- METHOD: GetLowStockProductsAsync(int threshold)
-- LINE NUMBERS: ~283-308
-- DESCRIPTION: CTE with AVG, MIN, MAX window functions
-- STATEMENT TYPE: SELECT with CTE and window functions
-- PARAMETERS: @Threshold (int)
-- =====================================================================
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

-- =====================================================================
-- END OF EXTRACTED STATEMENTS
-- SUMMARY:
-- - Total statements extracted: 7
-- - Statement types: 4 SELECT (with CTEs and window functions), 1 INSERT, 1 UPDATE, 1 DELETE
-- - All statements use parameterized queries
-- - Transactions: 3 statements use explicit transactions
-- - SQL Server specific features identified:
--   * SCOPE_IDENTITY() - needs conversion to RETURNING clause
--   * GETDATE() - needs conversion to NOW() or CURRENT_TIMESTAMP
--   * BEGIN TRANSACTION/COMMIT - needs PostgreSQL syntax
--   * DECLARE variables - needs pl/pgsql format or subquery conversion
--   * Window functions - verify PostgreSQL compatibility
-- =====================================================================
