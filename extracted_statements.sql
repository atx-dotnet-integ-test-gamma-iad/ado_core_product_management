-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- ============================================================================
-- Source: ADO.NET Core Application - ProductRepository.cs
-- Total Statements Extracted: 7
-- Extraction Date: 2026-02-10
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Source Location: ProductRepository.cs, Line ~38-68, Method: GetAllProductsAsync()
-- Context: Retrieves all products with CTE, window functions, and CASE expressions
-- Parameters: None
-- Transaction: No
-- String Construction: Direct string constant
-- Notes: Complex CTE with AVG() and COUNT() window functions, CASE expressions for categorization

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
-- Source Location: ProductRepository.cs, Line ~87-113, Method: GetProductByIdAsync(int productId)
-- Context: Retrieves a product by ID with LAG window function for historical comparison
-- Parameters: @ProductId (INT)
-- Transaction: No
-- String Construction: Direct string constant
-- Notes: CTE with LAG() window function, calculates price change percentage

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
-- Source Location: ProductRepository.cs, Line ~129-157, Method: InsertProductAsync(Product product)
-- Context: Multi-statement transaction with product insertion, history logging, and stats update
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Transaction: Yes (BEGIN TRANSACTION, COMMIT)
-- String Construction: Direct string constant
-- Notes: Uses SCOPE_IDENTITY(), GETDATE(), variable declarations (@NewProductId), multi-table updates

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
-- Source Location: ProductRepository.cs, Line ~168-199, Method: UpdateProductAsync(Product product)
-- Context: Multi-statement transaction to update product with history logging and stats update
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Transaction: Yes (BEGIN TRANSACTION, COMMIT)
-- String Construction: Direct string constant
-- Notes: Variable declarations (@OldPrice, @OldStock), GETDATE(), multi-table updates

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
-- Source Location: ProductRepository.cs, Line ~210-242, Method: DeleteProductAsync(int productId)
-- Context: Multi-statement transaction to delete product with history logging and stats update
-- Parameters: @ProductId (INT)
-- Transaction: Yes (BEGIN TRANSACTION, COMMIT)
-- String Construction: Direct string constant
-- Notes: Variable declarations (@OldPrice, @OldStock), GETDATE(), CASE expression in UPDATE, multi-table updates

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
-- Source Location: ProductRepository.cs, Line ~253-278, Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Context: Retrieves products within price range using CTE with RANK and PERCENT_RANK window functions
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Transaction: No
-- String Construction: Direct string constant
-- Notes: CTE with RANK() and PERCENT_RANK() window functions, CASE expression for segmentation

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
-- Source Location: ProductRepository.cs, Line ~290-319, Method: GetLowStockProductsAsync(int threshold)
-- Context: Retrieves low stock products using CTE with multiple window functions
-- Parameters: @Threshold (INT)
-- Transaction: No
-- String Construction: Direct string constant
-- Notes: CTE with AVG(), MIN(), MAX() window functions, CASE expression for stock status, ROUND function

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
-- EXTRACTION SUMMARY
-- ============================================================================
-- Total Statements: 7
-- Simple Queries: 2 (Statements 1, 6, 7 - CTEs with window functions)
-- Parameterized Queries: 7 (All statements use parameters)
-- Transaction Blocks: 3 (Statements 3, 4, 5)
-- Window Functions: 5 statements (1, 2, 6, 7 use OVER clauses)
-- CTEs: 5 statements (1, 2, 6, 7 use WITH clauses)
-- CASE Expressions: 6 statements (1, 2, 5, 6, 7)
-- SQL Server Specific Functions to Convert:
--   - SCOPE_IDENTITY() (Statement 3)
--   - GETDATE() (Statements 3, 4, 5)
--   - BEGIN TRANSACTION / COMMIT (Statements 3, 4, 5)
--   - Variable declarations with DECLARE (Statements 3, 4, 5)
-- ============================================================================
