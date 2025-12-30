-- ============================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- Source: ProductRepository.cs
-- Total Statements: 7
-- Database: Microsoft SQL Server
-- Purpose: Master catalog for DMS conversion to PostgreSQL
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Statement ID: 1
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetAllProductsAsync
-- Statement Type: SELECT with CTE
-- Transaction Context: None (single query)
-- Parameters: None
-- Description: Retrieves all products with price analysis using window functions (AVG, COUNT OVER)
-- SQL Server Specific Features: CTE, OVER(), CASE statements, ROUND function
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
-- Statement ID: 2
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetProductByIdAsync
-- Statement Type: SELECT with CTE
-- Transaction Context: None (single query)
-- Parameters: @ProductId (int)
-- Description: Retrieves a single product by ID with historical comparison using LAG window function
-- SQL Server Specific Features: CTE, LAG() OVER(), LEFT JOIN, CASE with NULL handling
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
-- Statement ID: 3
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: InsertProductAsync
-- Statement Type: Multi-statement INSERT with transaction
-- Transaction Context: BEGIN TRANSACTION / COMMIT
-- Parameters: @Name (string), @Description (string, nullable), @Price (decimal), @StockQuantity (int)
-- Description: Inserts a new product, logs to history, and updates statistics
-- SQL Server Specific Features: SCOPE_IDENTITY(), GETDATE(), DECLARE, multi-statement transaction
-- CRITICAL: SCOPE_IDENTITY() needs PostgreSQL equivalent (RETURNING clause or currval)
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
-- Statement ID: 4
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: UpdateProductAsync
-- Statement Type: Multi-statement UPDATE with transaction
-- Transaction Context: BEGIN TRANSACTION / COMMIT
-- Parameters: @ProductId (int), @Name (string), @Description (string, nullable), @Price (decimal), @StockQuantity (int)
-- Description: Updates a product, stores old values, logs to history, updates statistics
-- SQL Server Specific Features: DECLARE variables, SELECT into variables, GETDATE(), multi-statement transaction
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
-- Statement ID: 5
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: DeleteProductAsync
-- Statement Type: Multi-statement DELETE with transaction
-- Transaction Context: BEGIN TRANSACTION / COMMIT
-- Parameters: @ProductId (int)
-- Description: Deletes a product, logs to history, updates statistics
-- SQL Server Specific Features: DECLARE variables, SELECT into variables, GETDATE(), CASE in UPDATE, multi-statement transaction
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
-- Statement ID: 6
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetProductsByPriceRangeAsync
-- Statement Type: SELECT with CTE
-- Transaction Context: None (single query)
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Description: Retrieves products within a price range with ranking and percentile analysis
-- SQL Server Specific Features: CTE, RANK() OVER(), PERCENT_RANK() OVER(), BETWEEN, CASE
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
-- Statement ID: 7
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetLowStockProductsAsync
-- Statement Type: SELECT with CTE
-- Transaction Context: None (single query)
-- Parameters: @Threshold (int)
-- Description: Retrieves products with low stock levels, including stock analysis using window functions
-- SQL Server Specific Features: CTE, AVG/MIN/MAX window functions OVER(), CASE, ROUND
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
-- END OF EXTRACTED STATEMENTS
-- ============================================================================
-- SUMMARY:
-- Total Statements: 7
-- SELECT Queries: 4 (Statements 1, 2, 6, 7)
-- INSERT Operations: 1 (Statement 3 - includes multiple inserts in transaction)
-- UPDATE Operations: 1 (Statement 4 - includes updates and insert in transaction)
-- DELETE Operations: 1 (Statement 5 - includes delete, insert, and update in transaction)
-- Statements with Transactions: 3 (Statements 3, 4, 5)
-- Statements with CTE: 5 (Statements 1, 2, 6, 7)
-- Statements with Window Functions: 5 (Statements 1, 2, 6, 7)
-- Statements with Parameters: 6 (All except Statement 1)
-- ============================================================================
