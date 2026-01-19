-- ================================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- Source: ProductRepository.cs
-- Total Statement Groups: 7
-- Extraction Date: 2026-01-19
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 40-69
-- Method: GetAllProductsAsync()
-- Statement Type: CTE with Window Functions and CASE statements
-- Construction Pattern: const string variable
-- Parameters: None

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
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 84-111
-- Method: GetProductByIdAsync(int productId)
-- Statement Type: CTE with LAG Window Function
-- Construction Pattern: const string variable
-- Parameters: @ProductId (int)

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
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 126-148
-- Method: InsertProductAsync(Product product)
-- Statement Type: Multi-statement Transaction with SCOPE_IDENTITY()
-- Construction Pattern: const string variable
-- Parameters: @Name, @Description, @Price, @StockQuantity

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
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 163-189
-- Method: UpdateProductAsync(Product product)
-- Statement Type: Multi-statement Transaction with Variable Declarations
-- Construction Pattern: const string variable
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity

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
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 204-231
-- Method: DeleteProductAsync(int productId)
-- Statement Type: Multi-statement Transaction with Conditional Logic
-- Construction Pattern: const string variable
-- Parameters: @ProductId

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
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 246-267
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Statement Type: CTE with RANK and PERCENT_RANK Window Functions
-- Construction Pattern: const string variable
-- Parameters: @MinPrice, @MaxPrice

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
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 284-306
-- Method: GetLowStockProductsAsync(int threshold)
-- Statement Type: CTE with Multiple Window Functions (AVG, MIN, MAX)
-- Construction Pattern: const string variable
-- Parameters: @Threshold

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
-- EXTRACTION SUMMARY
-- ================================================================================
-- Total SQL Statement Groups: 7
-- - GetAllProductsAsync: CTE with window functions (AVG, COUNT)
-- - GetProductByIdAsync: CTE with LAG window function
-- - InsertProductAsync: Transaction block with SCOPE_IDENTITY()
-- - UpdateProductAsync: Transaction block with variable declarations
-- - DeleteProductAsync: Transaction block with conditional logic
-- - GetProductsByPriceRangeAsync: CTE with RANK and PERCENT_RANK
-- - GetLowStockProductsAsync: CTE with multiple window functions
--
-- SQL Server Specific Features Identified:
-- - SCOPE_IDENTITY() function
-- - GETDATE() function
-- - Window Functions: AVG OVER(), COUNT OVER(), LAG, RANK, PERCENT_RANK
-- - BEGIN TRANSACTION / COMMIT syntax
-- - DECLARE variable syntax
-- - CASE expressions
-- - Common Table Expressions (CTEs)
-- ================================================================================
