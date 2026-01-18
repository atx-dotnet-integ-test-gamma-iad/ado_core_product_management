-- =====================================================
-- SQL Statement Extraction Catalog
-- Microsoft SQL Server to PostgreSQL Migration
-- Source: ProductRepository.cs
-- Total Statements: 7
-- =====================================================

-- =====================================================
-- Statement 1: GetAllProductsAsync
-- =====================================================
-- Statement ID: GetAllProductsAsync_Line38
-- Source File: /sourceCode/DataAccess/ProductRepository.cs
-- Line Numbers: 38-72
-- Statement Type: SELECT with CTE and Window Functions
-- Parameters: None
-- Dynamic Construction: No
-- Description: Retrieves all products with CTE using AVG and COUNT OVER window functions,
--              CASE expressions for price categorization, INNER JOIN, and price percentage calculations

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

-- =====================================================
-- Statement 2: GetProductByIdAsync
-- =====================================================
-- Statement ID: GetProductByIdAsync_Line78
-- Source File: /sourceCode/DataAccess/ProductRepository.cs
-- Line Numbers: 78-108
-- Statement Type: SELECT with CTE, Window Functions, and LEFT JOIN
-- Parameters: @ProductId (int)
-- Dynamic Construction: No
-- Description: Retrieves product by ID with CTE using LAG window function for historical comparison,
--              LEFT JOIN for product history, CASE expression for price change percentage

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

-- =====================================================
-- Statement 3: InsertProductAsync
-- =====================================================
-- Statement ID: InsertProductAsync_Line120
-- Source File: /sourceCode/DataAccess/ProductRepository.cs
-- Line Numbers: 120-146
-- Statement Type: TRANSACTION with INSERT, SCOPE_IDENTITY, UPDATE, GETDATE
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Dynamic Construction: No
-- Description: Multi-statement transaction block that inserts new product, captures identity with SCOPE_IDENTITY(),
--              logs insertion to ProductHistory, updates ProductStats, and returns new ProductId

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

-- =====================================================
-- Statement 4: UpdateProductAsync
-- =====================================================
-- Statement ID: UpdateProductAsync_Line157
-- Source File: /sourceCode/DataAccess/ProductRepository.cs
-- Line Numbers: 157-188
-- Statement Type: TRANSACTION with DECLARE, SELECT, UPDATE, INSERT, GETDATE
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Dynamic Construction: No
-- Description: Multi-statement transaction block that declares variables for old values, retrieves old product data,
--              updates product with GETDATE() for ModifiedDate, logs changes to ProductHistory, and updates ProductStats

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

-- =====================================================
-- Statement 5: DeleteProductAsync
-- =====================================================
-- Statement ID: DeleteProductAsync_Line197
-- Source File: /sourceCode/DataAccess/ProductRepository.cs
-- Line Numbers: 197-230
-- Statement Type: TRANSACTION with DECLARE, SELECT, INSERT, DELETE, UPDATE with CASE, GETDATE
-- Parameters: @ProductId (int)
-- Dynamic Construction: No
-- Description: Multi-statement transaction block that declares variables, retrieves product data before deletion,
--              logs deletion to ProductHistory, deletes product, and updates ProductStats with conditional CASE expression

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

-- =====================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- =====================================================
-- Statement ID: GetProductsByPriceRangeAsync_Line240
-- Source File: /sourceCode/DataAccess/ProductRepository.cs
-- Line Numbers: 240-267
-- Statement Type: SELECT with CTE, Window Functions (RANK, PERCENT_RANK), BETWEEN clause
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Dynamic Construction: No
-- Description: Retrieves products within price range using CTE with RANK() and PERCENT_RANK() window functions,
--              BETWEEN clause for filtering, and CASE expression for price segmentation (Budget/Mid-Range/Premium)

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

-- =====================================================
-- Statement 7: GetLowStockProductsAsync
-- =====================================================
-- Statement ID: GetLowStockProductsAsync_Line277
-- Source File: /sourceCode/DataAccess/ProductRepository.cs
-- Line Numbers: 277-307
-- Statement Type: SELECT with CTE, Multiple Window Functions (AVG, MIN, MAX OVER), CASE expressions
-- Parameters: @Threshold (int)
-- Dynamic Construction: No
-- Description: Retrieves low stock products using CTE with AVG(), MIN(), MAX() window functions,
--              CASE expressions for stock status categorization (Critical/Low/Adequate),
--              threshold filtering, and stock percentage calculations

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

-- =====================================================
-- End of SQL Statement Extraction Catalog
-- Total Statements Extracted: 7
-- =====================================================
