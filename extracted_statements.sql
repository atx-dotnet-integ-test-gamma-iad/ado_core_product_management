-- =====================================================================
-- SQL Server to PostgreSQL Migration - Extracted SQL Statements Catalog
-- =====================================================================
-- Project: AdoCore - Microsoft SQL Server to PostgreSQL Migration
-- Extraction Date: 2024-12-28
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- =====================================================================

-- =====================================================================
-- STATEMENT 1: Get All Products with Window Functions and CTE
-- =====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Range: Lines 41-68
-- Statement Type: SELECT with CTE and Window Functions
-- Parameters: None
-- Description: Complex query using CTE and window functions (AVG OVER, COUNT OVER)
--              to calculate product statistics and categorize products by price
-- T-SQL Features: WITH (CTE), AVG() OVER(), COUNT() OVER(), CASE WHEN
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
-- STATEMENT 2: Get Product By ID with LAG Window Function
-- =====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Range: Lines 82-109
-- Statement Type: SELECT with CTE and LAG Window Function
-- Parameters: @ProductId (int)
-- Description: Retrieves product by ID with historical price/stock comparison
--              using LAG window function to get previous values
-- T-SQL Features: WITH (CTE), LAG() OVER (ORDER BY), CASE WHEN, NULL handling
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
-- STATEMENT 3: Insert Product with Transaction Block
-- =====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Range: Lines 123-146
-- Statement Type: Multi-statement Transaction (INSERT operations)
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: Multi-statement transaction that inserts product, logs to history,
--              updates statistics, and returns new product ID
-- T-SQL Features: DECLARE, BEGIN TRANSACTION, SCOPE_IDENTITY(), GETDATE(), COMMIT
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
-- STATEMENT 4: Update Product with Transaction Block
-- =====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Range: Lines 160-191
-- Statement Type: Multi-statement Transaction (UPDATE and INSERT operations)
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: Multi-statement transaction that updates product, logs changes to history,
--              and updates statistics
-- T-SQL Features: DECLARE, BEGIN TRANSACTION, GETDATE(), COMMIT
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
-- STATEMENT 5: Delete Product with Transaction Block
-- =====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Range: Lines 205-236
-- Statement Type: Multi-statement Transaction (INSERT, DELETE, UPDATE operations)
-- Parameters: @ProductId (int)
-- Description: Multi-statement transaction that logs deletion to history, deletes product,
--              and updates statistics with conditional logic
-- T-SQL Features: DECLARE, BEGIN TRANSACTION, GETDATE(), CASE WHEN, COMMIT
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
-- STATEMENT 6: Get Products By Price Range with Window Functions
-- =====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Range: Lines 250-272
-- Statement Type: SELECT with CTE and Window Functions
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Description: Query using CTE with RANK() and PERCENT_RANK() window functions
--              to analyze and categorize products within a price range
-- T-SQL Features: WITH (CTE), RANK() OVER (ORDER BY), PERCENT_RANK() OVER, BETWEEN, CASE WHEN
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
-- STATEMENT 7: Get Low Stock Products with Window Functions
-- =====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Range: Lines 286-312
-- Statement Type: SELECT with CTE and Window Functions
-- Parameters: @Threshold (int)
-- Description: Query using CTE with multiple window functions (AVG, MIN, MAX)
--              to analyze stock levels and categorize products by stock status
-- T-SQL Features: WITH (CTE), AVG() OVER(), MIN() OVER(), MAX() OVER(), CASE WHEN, ROUND
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
-- END OF EXTRACTED STATEMENTS CATALOG
-- Total Statements Extracted: 7
-- =====================================================================
