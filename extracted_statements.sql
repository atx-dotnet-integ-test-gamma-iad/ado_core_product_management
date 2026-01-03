-- ============================================================================
-- SQL STATEMENTS EXTRACTION CATALOG
-- Extracted from: DataAccess/ProductRepository.cs
-- Purpose: Comprehensive catalog of all SQL statements for DMS conversion
-- Total Statements: 6
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Source Method: GetAllProductsAsync()
-- Line Number: ~37-68
-- Description: Complex CTE with window functions to get all products with price analysis
-- Parameters: None
-- Transaction Context: No transaction
-- SQL Type: SELECT with CTE, window functions (AVG OVER, COUNT OVER)
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
    p.Name

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync
-- ============================================================================
-- Source Method: GetProductByIdAsync(int productId)
-- Line Number: ~78-111
-- Description: CTE with LAG window function to get product with historical price comparison
-- Parameters: @ProductId (int) - The ID of the product to retrieve
-- Transaction Context: No transaction
-- SQL Type: SELECT with CTE, LAG window function
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
WHERE p.ProductId = @ProductId

-- ============================================================================
-- STATEMENT 3: InsertProductAsync
-- ============================================================================
-- Source Method: InsertProductAsync(Product product)
-- Line Number: ~123-149
-- Description: Multi-statement transaction with INSERT, SCOPE_IDENTITY(), history logging, and stats update
-- Parameters: 
--   @Name (nvarchar) - Product name
--   @Description (nvarchar) - Product description
--   @Price (decimal) - Product price
--   @StockQuantity (int) - Stock quantity
-- Transaction Context: BEGIN TRANSACTION / COMMIT
-- SQL Type: INSERT with transaction, SCOPE_IDENTITY(), GETDATE()
-- T-SQL Specific: SCOPE_IDENTITY(), GETDATE(), BEGIN TRANSACTION/COMMIT syntax
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
-- ============================================================================
-- Source Method: UpdateProductAsync(Product product)
-- Line Number: ~162-189
-- Description: Transaction with variable declarations, UPDATE, and history logging
-- Parameters:
--   @ProductId (int) - Product ID to update
--   @Name (nvarchar) - New product name
--   @Description (nvarchar) - New product description
--   @Price (decimal) - New product price
--   @StockQuantity (int) - New stock quantity
-- Transaction Context: BEGIN TRANSACTION / COMMIT
-- SQL Type: UPDATE with transaction, variable declarations, GETDATE()
-- T-SQL Specific: DECLARE syntax, GETDATE(), BEGIN TRANSACTION/COMMIT syntax
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
-- ============================================================================
-- Source Method: DeleteProductAsync(int productId)
-- Line Number: ~201-230
-- Description: Transaction with DELETE, history logging, and conditional statistics update
-- Parameters:
--   @ProductId (int) - Product ID to delete
-- Transaction Context: BEGIN TRANSACTION / COMMIT
-- SQL Type: DELETE with transaction, variable declarations, GETDATE()
-- T-SQL Specific: DECLARE syntax, GETDATE(), BEGIN TRANSACTION/COMMIT syntax
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
-- ============================================================================
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Number: ~241-267
-- Description: CTE with RANK and PERCENT_RANK window functions for price range analysis
-- Parameters:
--   @MinPrice (decimal) - Minimum price in range
--   @MaxPrice (decimal) - Maximum price in range
-- Transaction Context: No transaction
-- SQL Type: SELECT with CTE, RANK(), PERCENT_RANK() window functions
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
ORDER BY rp.PriceRank

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- ============================================================================
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Line Number: ~278-305
-- Description: CTE with aggregate window functions (AVG, MIN, MAX) for stock analysis
-- Parameters:
--   @Threshold (int) - Stock quantity threshold
-- Transaction Context: No transaction
-- SQL Type: SELECT with CTE, aggregate window functions (AVG OVER, MIN OVER, MAX OVER)
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
ORDER BY StockQuantity

-- ============================================================================
-- EXTRACTION SUMMARY
-- ============================================================================
-- Total Statements Extracted: 7 (Note: Plan mentioned 6 but found 7)
-- Statements with Parameters: 6 (all except GetAllProductsAsync)
-- Statements with Transactions: 3 (InsertProductAsync, UpdateProductAsync, DeleteProductAsync)
-- Statements with Window Functions: 4 (GetAllProductsAsync, GetProductByIdAsync, GetProductsByPriceRangeAsync, GetLowStockProductsAsync)
-- T-SQL Specific Features:
--   - SCOPE_IDENTITY() (InsertProductAsync)
--   - GETDATE() (InsertProductAsync, UpdateProductAsync, DeleteProductAsync)
--   - BEGIN TRANSACTION/COMMIT (InsertProductAsync, UpdateProductAsync, DeleteProductAsync)
--   - DECLARE variables (InsertProductAsync, UpdateProductAsync, DeleteProductAsync)
--   - LAG() window function (GetProductByIdAsync)
--   - RANK(), PERCENT_RANK() window functions (GetProductsByPriceRangeAsync)
--   - AVG/MIN/MAX OVER() window functions (GetAllProductsAsync, GetLowStockProductsAsync)
-- ============================================================================
