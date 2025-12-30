-- ======================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source File: ProductRepository.cs
-- Total Statements: 8
-- Database: Microsoft SQL Server (Source)
-- Extraction Date: 2024-12-30
-- ======================================================================

-- ======================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Method: GetAllProductsAsync()
-- Line Range: ~38-68
-- Purpose: Retrieve all products with CTE, window functions (AVG, COUNT, OVER)
-- Parameters: None
-- Transaction Context: No
-- SQL Server Features: CTE, Window Functions (AVG OVER, COUNT OVER), CASE expressions
-- ======================================================================
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

-- ======================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Method: GetProductByIdAsync(int productId)
-- Line Range: ~78-108
-- Purpose: Retrieve product by ID with CTE and LAG window function
-- Parameters: @ProductId (int)
-- Transaction Context: No
-- SQL Server Features: CTE, LAG window function, CASE expressions
-- ======================================================================
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

-- ======================================================================
-- STATEMENT 3: InsertProductAsync
-- Method: InsertProductAsync(Product product)
-- Line Range: ~118-147
-- Purpose: Insert new product with transaction, history logging, and statistics update
-- Parameters: @Name (string), @Description (string/null), @Price (decimal), @StockQuantity (int)
-- Transaction Context: YES - BEGIN TRANSACTION / COMMIT
-- SQL Server Features: DECLARE, BEGIN TRANSACTION, SCOPE_IDENTITY(), GETDATE(), COMMIT
-- ======================================================================
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

-- ======================================================================
-- STATEMENT 4: UpdateProductAsync
-- Method: UpdateProductAsync(Product product)
-- Line Range: ~156-191
-- Purpose: Update product with transaction, history logging, and statistics update
-- Parameters: @ProductId (int), @Name (string), @Description (string/null), @Price (decimal), @StockQuantity (int)
-- Transaction Context: YES - BEGIN TRANSACTION / COMMIT
-- SQL Server Features: DECLARE, BEGIN TRANSACTION, GETDATE(), COMMIT
-- ======================================================================
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

-- ======================================================================
-- STATEMENT 5: DeleteProductAsync
-- Method: DeleteProductAsync(int productId)
-- Line Range: ~199-231
-- Purpose: Delete product with transaction, history logging, and statistics update
-- Parameters: @ProductId (int)
-- Transaction Context: YES - BEGIN TRANSACTION / COMMIT
-- SQL Server Features: DECLARE, BEGIN TRANSACTION, GETDATE(), COMMIT, CASE in UPDATE
-- ======================================================================
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

-- ======================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Range: ~239-264
-- Purpose: Get products by price range with CTE, RANK and PERCENT_RANK window functions
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Transaction Context: No
-- SQL Server Features: CTE, RANK() OVER, PERCENT_RANK() OVER, CASE expressions
-- ======================================================================
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

-- ======================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Range: ~272-298
-- Purpose: Get low stock products with CTE and aggregate window functions
-- Parameters: @Threshold (int)
-- Transaction Context: No
-- SQL Server Features: CTE, AVG/MIN/MAX window functions (OVER), CASE expressions
-- ======================================================================
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

-- ======================================================================
-- STATEMENT 8: ExecuteInTransactionAsync (Transaction Pattern)
-- Method: ExecuteInTransactionAsync(Func<Task> action)
-- Line Range: ~306-318
-- Purpose: Execute arbitrary actions within a transaction with rollback handling
-- Parameters: None (transaction boundary only)
-- Transaction Context: YES - BeginTransactionAsync, CommitAsync, RollbackAsync
-- SQL Server Features: Transaction management pattern (ADO.NET level, not SQL)
-- Note: This is a transaction boundary pattern, not a SQL statement to convert
-- ======================================================================
-- Transaction Pattern: connection.BeginTransactionAsync() / CommitAsync() / RollbackAsync()
-- No specific SQL statement to extract - this is a transaction wrapper method
-- The actual SQL statements executed within transactions are already captured above (statements 3, 4, 5)

-- ======================================================================
-- END OF EXTRACTED STATEMENTS CATALOG
-- Total SQL Statements Extracted: 7 (Statement 8 is a transaction pattern wrapper)
-- Statements Requiring DMS Conversion: 7
-- ======================================================================
