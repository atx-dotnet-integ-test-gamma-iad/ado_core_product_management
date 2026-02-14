-- ========================================================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO CORE APPLICATION
-- ========================================================================================================
-- Purpose: Comprehensive catalog of all SQL statements extracted from the codebase for DMS processing
-- Extraction Date: 2026-02-14
-- Total Statements: 7
-- ========================================================================================================

-- ========================================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ========================================================================================================
-- Statement ID: STMT_001_GetAllProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Line Number: ~42-72
-- Method: GetAllProductsAsync()
-- Purpose: Retrieves all products with price analysis using CTE and window functions
-- Return Type: List<Product>
-- Parameters: None
-- Context: Uses CTE with AVG() OVER() window function to calculate average price and categorize products
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
-- ========================================================================================================
-- Statement ID: STMT_002_GetProductByIdAsync
-- Source File: DataAccess/ProductRepository.cs
-- Line Number: ~82-110
-- Method: GetProductByIdAsync(int productId)
-- Purpose: Retrieves a specific product by ID with historical price analysis using LAG window function
-- Return Type: Product
-- Parameters: @ProductId (int)
-- Context: Uses CTE with LAG() OVER() window function to track price and stock changes over time
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
-- ========================================================================================================
-- Statement ID: STMT_003_InsertProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Line Number: ~122-145
-- Method: InsertProductAsync(Product product)
-- Purpose: Multi-statement transaction block to insert a new product with history logging and statistics update
-- Return Type: int (new ProductId)
-- Parameters: @Name (string), @Description (string/null), @Price (decimal), @StockQuantity (int)
-- Context: Transaction with SCOPE_IDENTITY() for new ID, GETDATE() for timestamps, updates ProductHistory and ProductStats
-- Special Notes: SCOPE_IDENTITY() needs conversion to PostgreSQL RETURNING clause or LASTVAL()
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
-- ========================================================================================================
-- Statement ID: STMT_004_UpdateProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Line Number: ~157-188
-- Method: UpdateProductAsync(Product product)
-- Purpose: Multi-statement transaction block to update product with history logging and statistics update
-- Return Type: void
-- Parameters: @ProductId (int), @Name (string), @Description (string/null), @Price (decimal), @StockQuantity (int)
-- Context: Transaction with variable declarations, captures old values before update, logs to ProductHistory, updates ProductStats
-- Special Notes: GETDATE() needs conversion to CURRENT_TIMESTAMP or NOW()
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
-- ========================================================================================================
-- Statement ID: STMT_005_DeleteProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Line Number: ~198-229
-- Method: DeleteProductAsync(int productId)
-- Purpose: Multi-statement transaction block to delete product with history logging and statistics update
-- Return Type: void
-- Parameters: @ProductId (int)
-- Context: Transaction with variable declarations, captures product info before deletion, logs to ProductHistory, updates ProductStats with conditional logic
-- Special Notes: GETDATE() needs conversion to CURRENT_TIMESTAMP or NOW()
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
-- ========================================================================================================
-- Statement ID: STMT_006_GetProductsByPriceRangeAsync
-- Source File: DataAccess/ProductRepository.cs
-- Line Number: ~239-265
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Purpose: Retrieves products within a price range with ranking and percentile analysis
-- Return Type: List<Product>
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Context: Uses CTE with RANK() and PERCENT_RANK() window functions to categorize products into price segments
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
-- ========================================================================================================
-- Statement ID: STMT_007_GetLowStockProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Line Number: ~275-302
-- Method: GetLowStockProductsAsync(int threshold)
-- Purpose: Retrieves low stock products with stock level analysis using aggregate window functions
-- Return Type: List<Product>
-- Parameters: @Threshold (int)
-- Context: Uses CTE with AVG(), MIN(), MAX() aggregate window functions to analyze stock levels
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
-- END OF EXTRACTED STATEMENTS
-- ========================================================================================================
-- SUMMARY:
-- - Total Statements Extracted: 7
-- - Simple SELECT Queries: 4 (STMT_001, STMT_002, STMT_006, STMT_007)
-- - Multi-Statement Transactions: 3 (STMT_003, STMT_004, STMT_005)
-- - Statements with Window Functions: 4 (STMT_001, STMT_002, STMT_006, STMT_007)
-- - Statements with CTEs: 5 (STMT_001, STMT_002, STMT_006, STMT_007)
-- - Statements with SCOPE_IDENTITY(): 1 (STMT_003)
-- - Statements with GETDATE(): 3 (STMT_003, STMT_004, STMT_005)
-- - Statements with Parameters: 6 (all except STMT_001)
-- ========================================================================================================
