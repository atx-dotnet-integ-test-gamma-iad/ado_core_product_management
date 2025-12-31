-- ========================================================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- ========================================================================================================

-- ========================================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Location: DataAccess/ProductRepository.cs, Lines 43-70
-- Method: GetAllProductsAsync()
-- Parameters: None
-- Special T-SQL Features: CTE (WITH clause), Window Functions (AVG OVER, COUNT OVER), CASE expressions, ROUND function, INNER JOIN
-- Description: Retrieves all products with price category classification and percentage comparison to average price
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Location: DataAccess/ProductRepository.cs, Lines 88-115
-- Method: GetProductByIdAsync(int productId)
-- Parameters: @ProductId (INT)
-- Special T-SQL Features: CTE (WITH clause), LAG Window Function, LEFT JOIN, CASE expressions, ROUND function, NULL handling
-- Description: Retrieves a single product by ID with historical price and stock comparison using LAG window function
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 3: InsertProductAsync
-- Location: DataAccess/ProductRepository.cs, Lines 132-160
-- Method: InsertProductAsync(Product product)
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Special T-SQL Features: DECLARE, BEGIN TRANSACTION, COMMIT, SCOPE_IDENTITY(), GETDATE(), Multi-statement transaction
-- Description: Inserts a new product and logs the insertion in ProductHistory, updates ProductStats table
-- CRITICAL CONVERSION NOTES: 
--   - SCOPE_IDENTITY() needs to be converted to RETURNING clause or currval()
--   - GETDATE() needs to be converted to NOW() or CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION needs to be converted to BEGIN
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 4: UpdateProductAsync
-- Location: DataAccess/ProductRepository.cs, Lines 170-206
-- Method: UpdateProductAsync(Product product)
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Special T-SQL Features: BEGIN TRANSACTION, COMMIT, DECLARE, SELECT INTO variables, GETDATE(), Multi-statement transaction
-- Description: Updates an existing product, logs changes to ProductHistory, updates ProductStats
-- CRITICAL CONVERSION NOTES:
--   - DECLARE variables need PostgreSQL syntax
--   - SELECT INTO variables needs PostgreSQL syntax
--   - GETDATE() needs to be converted to NOW() or CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION needs to be converted to BEGIN
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 5: DeleteProductAsync
-- Location: DataAccess/ProductRepository.cs, Lines 216-248
-- Method: DeleteProductAsync(int productId)
-- Parameters: @ProductId (INT)
-- Special T-SQL Features: BEGIN TRANSACTION, COMMIT, DECLARE, SELECT INTO variables, GETDATE(), DELETE, CASE expression in UPDATE
-- Description: Deletes a product, logs deletion to ProductHistory, updates ProductStats with conditional CASE
-- CRITICAL CONVERSION NOTES:
--   - DECLARE variables need PostgreSQL syntax
--   - SELECT INTO variables needs PostgreSQL syntax
--   - GETDATE() needs to be converted to NOW() or CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION needs to be converted to BEGIN
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Location: DataAccess/ProductRepository.cs, Lines 258-283
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Special T-SQL Features: CTE (WITH clause), RANK() Window Function, PERCENT_RANK() Window Function, BETWEEN operator, CASE expression
-- Description: Retrieves products within a price range with rank and percentile calculations, categorizes into price segments
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Location: DataAccess/ProductRepository.cs, Lines 295-320
-- Method: GetLowStockProductsAsync(int threshold)
-- Parameters: @Threshold (INT)
-- Special T-SQL Features: CTE (WITH clause), AVG/MIN/MAX Window Functions (OVER), CASE expression, ROUND function
-- Description: Retrieves products with low stock levels, calculates stock status and percentage of average stock
-- ========================================================================================================

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

-- ========================================================================================================
-- END OF EXTRACTED STATEMENTS CATALOG
-- ========================================================================================================
