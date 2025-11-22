-- ============================================================================
-- SQL STATEMENT EXTRACTION CATALOG
-- Migration: Microsoft SQL Server to PostgreSQL
-- Project: AdoCore - .NET ADO Application
-- Date: 2024-11-22
-- ============================================================================

-- STATEMENT ID: SQL_001
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Numbers: 44-68
-- Statement Type: SELECT with CTE and CASE expressions
-- Parameters: None
-- Description: Retrieves all products with calculated price categories using CTE and window functions
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

-- STATEMENT ID: SQL_002
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Numbers: 85-111
-- Statement Type: SELECT with CTE and LAG window function
-- Parameters: @ProductId (int)
-- Description: Retrieves a single product by ID with price history using LAG window function
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

-- STATEMENT ID: SQL_003
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Numbers: 121-147
-- Statement Type: TRANSACTION BLOCK with INSERT, UPDATE statements
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: Inserts a new product with transaction, logs to history, updates stats, returns new ID
-- SQL Server-specific: SCOPE_IDENTITY(), GETDATE(), BEGIN TRANSACTION, DECLARE
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

-- STATEMENT ID: SQL_004
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Numbers: 155-181
-- Statement Type: TRANSACTION BLOCK with UPDATE and INSERT statements
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: Updates a product with transaction, logs changes to history, updates stats
-- SQL Server-specific: GETDATE(), BEGIN TRANSACTION, DECLARE
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

-- STATEMENT ID: SQL_005
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Numbers: 189-217
-- Statement Type: TRANSACTION BLOCK with DELETE, INSERT, and UPDATE statements
-- Parameters: @ProductId (int)
-- Description: Deletes a product with transaction, logs to history, updates stats
-- SQL Server-specific: GETDATE(), BEGIN TRANSACTION, DECLARE
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

-- STATEMENT ID: SQL_006
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Numbers: 225-245
-- Statement Type: SELECT with CTE and window functions (RANK, PERCENT_RANK)
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Description: Retrieves products within a price range with ranking and percentile calculations
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

-- STATEMENT ID: SQL_007
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Numbers: 253-275
-- Statement Type: SELECT with CTE and window functions (AVG, MIN, MAX)
-- Parameters: @Threshold (int)
-- Description: Retrieves products below stock threshold with statistical analysis
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
-- END OF EXTRACTION CATALOG
-- Total Statements Extracted: 7
-- ============================================================================
