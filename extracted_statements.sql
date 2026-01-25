-- ============================================================
-- EXTRACTED SQL STATEMENTS FOR DMS CONVERSION
-- Source: Microsoft SQL Server ADO.NET Application (AdoCore)
-- Target: PostgreSQL
-- Total Statements: 7
-- ============================================================

-- ============================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions
-- ============================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync
-- Line Numbers: 38-67
-- Purpose: Retrieve all products with price statistics using window functions
-- Features: CTE, AVG() OVER(), COUNT() OVER(), CASE expressions, ROUND function
-- Tables: Products
-- ============================================================

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

-- ============================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ============================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync
-- Line Numbers: 83-109
-- Purpose: Retrieve product by ID with price history comparison
-- Features: CTE, LAG() OVER(), LEFT JOIN, parameterized query (@ProductId)
-- Tables: Products
-- Parameters: @ProductId (int)
-- ============================================================

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

-- ============================================================
-- STATEMENT 3: InsertProductAsync - Transaction with SCOPE_IDENTITY()
-- ============================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync
-- Line Numbers: 124-146
-- Purpose: Insert new product with transaction, history logging, and statistics update
-- Features: BEGIN TRANSACTION, DECLARE variables, SCOPE_IDENTITY(), GETDATE(), COMMIT
-- Tables: Products, ProductHistory, ProductStats
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- ============================================================

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

-- ============================================================
-- STATEMENT 4: UpdateProductAsync - Transaction with Variable Declarations
-- ============================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync
-- Line Numbers: 163-192
-- Purpose: Update product with transaction, history logging, and statistics update
-- Features: BEGIN TRANSACTION, DECLARE variables, UPDATE with subquery, GETDATE(), COMMIT
-- Tables: Products, ProductHistory, ProductStats
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- ============================================================

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

-- ============================================================
-- STATEMENT 5: DeleteProductAsync - Transaction with Conditional Logic
-- ============================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync
-- Line Numbers: 207-238
-- Purpose: Delete product with transaction, history logging, and conditional statistics update
-- Features: BEGIN TRANSACTION, DECLARE variables, DELETE, CASE expression in UPDATE, GETDATE(), COMMIT
-- Tables: Products, ProductHistory, ProductStats
-- Parameters: @ProductId (int)
-- ============================================================

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

-- ============================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ============================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync
-- Line Numbers: 253-275
-- Purpose: Retrieve products within price range with ranking statistics
-- Features: CTE, RANK() OVER(), PERCENT_RANK() OVER(), CASE expression, BETWEEN
-- Tables: Products
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- ============================================================

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

-- ============================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Window Functions
-- ============================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync
-- Line Numbers: 290-316
-- Purpose: Retrieve low stock products with stock analysis
-- Features: CTE, AVG() OVER(), MIN() OVER(), MAX() OVER(), CASE expression, ROUND
-- Tables: Products
-- Parameters: @Threshold (int)
-- ============================================================

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

-- ============================================================
-- END OF EXTRACTION
-- Total Statements Extracted: 7
-- Ready for DMS Conversion
-- ============================================================
