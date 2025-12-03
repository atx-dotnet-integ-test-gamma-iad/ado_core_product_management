-- ============================================================================
-- SQL Statement Extraction Catalog
-- Generated for Microsoft SQL Server to PostgreSQL Migration
-- ============================================================================
-- This file contains all SQL statements extracted from the codebase
-- Each statement is documented with metadata for tracking through conversion
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - SELECT with CTE and Window Functions
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync
-- Line: 38-66
-- Statement Type: SELECT
-- Uses Parameters: No
-- Transaction Block: No
-- Features: CTE (Common Table Expression), Window Functions (AVG OVER, COUNT OVER), CASE expressions, Complex JOIN
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
-- STATEMENT 2: GetProductByIdAsync - SELECT with CTE and LAG Window Function
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync
-- Line: 81-109
-- Statement Type: SELECT
-- Uses Parameters: Yes (@ProductId)
-- Transaction Block: No
-- Features: CTE, Window Function (LAG OVER), Complex CASE calculations, LEFT JOIN
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
-- STATEMENT 3: InsertProductAsync - INSERT with Transaction and SCOPE_IDENTITY
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync
-- Line: 116-141
-- Statement Type: INSERT (Transaction Block)
-- Uses Parameters: Yes (@Name, @Description, @Price, @StockQuantity)
-- Transaction Block: Yes (BEGIN TRANSACTION...COMMIT)
-- Features: Variable declaration, SCOPE_IDENTITY(), GETDATE(), Multiple statements in transaction
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
-- STATEMENT 4: UpdateProductAsync - UPDATE with Transaction and Variable Storage
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync
-- Line: 156-188
-- Statement Type: UPDATE (Transaction Block)
-- Uses Parameters: Yes (@ProductId, @Name, @Description, @Price, @StockQuantity)
-- Transaction Block: Yes (BEGIN TRANSACTION...COMMIT)
-- Features: Variable declaration and assignment from SELECT, Multiple statements, GETDATE()
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
-- STATEMENT 5: DeleteProductAsync - DELETE with Transaction and Variable Storage
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync
-- Line: 197-229
-- Statement Type: DELETE (Transaction Block)
-- Uses Parameters: Yes (@ProductId)
-- Transaction Block: Yes (BEGIN TRANSACTION...COMMIT)
-- Features: Variable declaration and assignment, Complex CASE in UPDATE, GETDATE()
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - SELECT with CTE, RANK and PERCENT_RANK
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync
-- Line: 237-259
-- Statement Type: SELECT
-- Uses Parameters: Yes (@MinPrice, @MaxPrice)
-- Transaction Block: No
-- Features: CTE, Window Functions (RANK OVER, PERCENT_RANK OVER), CASE expressions, BETWEEN
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
-- STATEMENT 7: GetLowStockProductsAsync - SELECT with CTE and Multiple Window Functions
-- ============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync
-- Line: 276-302
-- Statement Type: SELECT
-- Uses Parameters: Yes (@Threshold)
-- Transaction Block: No
-- Features: CTE, Multiple Window Functions (AVG OVER, MIN OVER, MAX OVER), Complex CASE, ROUND
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
-- EXTRACTION SUMMARY
-- ============================================================================
-- Total Statements Extracted: 7
-- Statements with Parameters: 5
-- Statements in Transaction Blocks: 3
-- Statements with CTEs: 5
-- Statements with Window Functions: 5
-- Statements with GETDATE(): 3
-- Statements with SCOPE_IDENTITY(): 1
-- ============================================================================
