-- ============================================================================
-- SQL Statement Extraction Catalog for ProductRepository.cs
-- Purpose: Comprehensive catalog of all SQL statements for DMS conversion
-- Date: Generated during MS SQL Server to PostgreSQL Migration
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Source File: ProductRepository.cs
-- Source Method: GetAllProductsAsync()
-- Line Numbers: Approximately lines 39-71
-- Purpose: Retrieve all products with price analysis using CTE and window functions
-- Complexity: High (CTE, Window Functions, CASE expressions, Complex JOIN)
-- Features: Common Table Expression, AVG/COUNT window functions, CASE WHEN logic
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
-- Source File: ProductRepository.cs
-- Source Method: GetProductByIdAsync(int productId)
-- Line Numbers: Approximately lines 83-107
-- Purpose: Get single product by ID with historical price comparison
-- Complexity: High (CTE, LAG window function, calculated columns)
-- Parameters: @ProductId (int)
-- Features: CTE, LAG window function, LEFT JOIN, CASE WHEN with calculations
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
-- Source File: ProductRepository.cs
-- Source Method: InsertProductAsync(Product product)
-- Line Numbers: Approximately lines 119-148
-- Purpose: Insert new product with transaction, history logging, and statistics update
-- Complexity: Very High (Multi-statement transaction, SCOPE_IDENTITY, GETDATE functions)
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Features: Transaction block, Variable declaration, SCOPE_IDENTITY(), GETDATE(), Multiple INSERTs/UPDATEs
-- SQL Server Specific: SCOPE_IDENTITY(), GETDATE(), BEGIN TRANSACTION/COMMIT syntax
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
-- Source File: ProductRepository.cs
-- Source Method: UpdateProductAsync(Product product)
-- Line Numbers: Approximately lines 160-193
-- Purpose: Update product with transaction, history logging, and statistics update
-- Complexity: Very High (Multi-statement transaction, variable handling, GETDATE)
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Features: Transaction block, Variable declarations, GETDATE(), UPDATE with subquery, INSERT
-- SQL Server Specific: GETDATE(), BEGIN TRANSACTION/COMMIT syntax, DECLARE syntax
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
-- Source File: ProductRepository.cs
-- Source Method: DeleteProductAsync(int productId)
-- Line Numbers: Approximately lines 205-237
-- Purpose: Delete product with transaction, history logging, and statistics update
-- Complexity: Very High (Multi-statement transaction, variable handling, CASE in UPDATE)
-- Parameters: @ProductId (int)
-- Features: Transaction block, Variable declarations, GETDATE(), DELETE, INSERT, UPDATE with CASE
-- SQL Server Specific: GETDATE(), BEGIN TRANSACTION/COMMIT syntax, DECLARE syntax
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
-- Source File: ProductRepository.cs
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Numbers: Approximately lines 249-271
-- Purpose: Get products within price range with ranking analysis
-- Complexity: High (CTE, RANK and PERCENT_RANK window functions, CASE expression)
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Features: CTE, RANK() and PERCENT_RANK() window functions, BETWEEN operator, CASE WHEN
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
-- Source File: ProductRepository.cs
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Line Numbers: Approximately lines 283-308
-- Purpose: Get low stock products with stock level analysis
-- Complexity: High (CTE, multiple window functions AVG/MIN/MAX, CASE expression)
-- Parameters: @Threshold (int)
-- Features: CTE, AVG/MIN/MAX window functions, CASE WHEN with calculations
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
-- 
-- Summary:
-- - 2 Simple SELECT queries with CTEs and window functions
-- - 3 Complex transaction blocks with multiple DML statements
-- - 2 Analytical queries with ranking and statistical window functions
-- 
-- SQL Server Specific Features Identified:
-- - SCOPE_IDENTITY() function (Statement 3)
-- - GETDATE() function (Statements 3, 4, 5)
-- - BEGIN TRANSACTION/COMMIT syntax (Statements 3, 4, 5)
-- - DECLARE variable syntax (Statements 3, 4, 5)
-- - Window functions: AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK, MIN OVER, MAX OVER
-- 
-- All statements require DMS conversion for PostgreSQL compatibility
-- ============================================================================
