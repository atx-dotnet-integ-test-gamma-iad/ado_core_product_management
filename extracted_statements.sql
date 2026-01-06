-- ================================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- Purpose: Catalog of all original SQL Server statements for DMS conversion
-- Source: ProductRepository.cs
-- Total Statements: 6
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetAllProductsAsync
-- Line Numbers: Approximately 38-66
-- Statement Type: SELECT with CTE
-- Complexity: HIGH - Uses CTE, window functions (AVG OVER, COUNT OVER), CASE expressions
-- Parameters: None
-- Key SQL Server Features:
--   - Common Table Expression (WITH)
--   - Window functions: AVG() OVER(), COUNT() OVER()
--   - CASE expressions
--   - ROUND function
--   - INNER JOIN
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 2: GetProductByIdAsync
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetProductByIdAsync
-- Line Numbers: Approximately 81-110
-- Statement Type: SELECT with CTE
-- Complexity: HIGH - Uses CTE, LAG window function, parameterized query
-- Parameters: @ProductId (int)
-- Key SQL Server Features:
--   - Common Table Expression (WITH)
--   - Window function: LAG() OVER (ORDER BY)
--   - CASE expressions
--   - ROUND function
--   - LEFT JOIN
--   - Parameterized query
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 3: InsertProductAsync
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: InsertProductAsync
-- Line Numbers: Approximately 125-151
-- Statement Type: TRANSACTION (INSERT with history and statistics update)
-- Complexity: VERY HIGH - Transaction block with multiple statements
-- Parameters: @Name (nvarchar), @Description (nvarchar), @Price (decimal), @StockQuantity (int)
-- Key SQL Server Features:
--   - BEGIN TRANSACTION / COMMIT
--   - DECLARE variable (@NewProductId)
--   - SCOPE_IDENTITY() for retrieving inserted ID
--   - Multiple INSERT statements
--   - UPDATE statement
--   - GETDATE() function (appears 3 times)
--   - Variable assignment with SET
--   - Parameterized queries
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 4: UpdateProductAsync
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: UpdateProductAsync
-- Line Numbers: Approximately 166-201
-- Statement Type: TRANSACTION (UPDATE with history and statistics)
-- Complexity: VERY HIGH - Transaction block with variables and multiple statements
-- Parameters: @ProductId (int), @Name (nvarchar), @Description (nvarchar), @Price (decimal), @StockQuantity (int)
-- Key SQL Server Features:
--   - BEGIN TRANSACTION / COMMIT
--   - DECLARE statements for variables (@OldPrice, @OldStock)
--   - SELECT into variables
--   - UPDATE statements (2 total)
--   - INSERT statement for history
--   - GETDATE() function (appears 3 times)
--   - Parameterized queries
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 5: DeleteProductAsync
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: DeleteProductAsync
-- Line Numbers: Approximately 216-246
-- Statement Type: TRANSACTION (DELETE with history and statistics)
-- Complexity: VERY HIGH - Transaction block with variables, CASE expression
-- Parameters: @ProductId (int)
-- Key SQL Server Features:
--   - BEGIN TRANSACTION / COMMIT
--   - DECLARE statements for variables (@OldPrice, @OldStock)
--   - SELECT into variables
--   - INSERT statement for history
--   - DELETE statement
--   - UPDATE statement with CASE expression
--   - GETDATE() function (appears 2 times)
--   - Parameterized query
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetProductsByPriceRangeAsync
-- Line Numbers: Approximately 261-282
-- Statement Type: SELECT with CTE
-- Complexity: HIGH - Uses CTE, window functions (RANK, PERCENT_RANK)
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Key SQL Server Features:
--   - Common Table Expression (WITH)
--   - Window functions: RANK() OVER, PERCENT_RANK() OVER
--   - BETWEEN clause
--   - CASE expressions
--   - Parameterized queries
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetLowStockProductsAsync
-- Line Numbers: Approximately 297-324
-- Statement Type: SELECT with CTE
-- Complexity: HIGH - Uses CTE, window functions (AVG OVER, MIN OVER, MAX OVER)
-- Parameters: @Threshold (int)
-- Key SQL Server Features:
--   - Common Table Expression (WITH)
--   - Window functions: AVG() OVER(), MIN() OVER(), MAX() OVER()
--   - CASE expressions
--   - ROUND function
--   - Parameterized query
-- ================================================================================

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

-- ================================================================================
-- EXTRACTION SUMMARY
-- ================================================================================
-- Total Statements Extracted: 7 (Note: Plan mentioned 6, but there are actually 7 methods)
-- Statement Types:
--   - SELECT with CTE: 4 statements (GetAllProductsAsync, GetProductByIdAsync, GetProductsByPriceRangeAsync, GetLowStockProductsAsync)
--   - TRANSACTION INSERT: 1 statement (InsertProductAsync)
--   - TRANSACTION UPDATE: 1 statement (UpdateProductAsync)
--   - TRANSACTION DELETE: 1 statement (DeleteProductAsync)
--
-- SQL Server Features Used:
--   - Common Table Expressions (CTE): 4 occurrences
--   - Window Functions: LAG, AVG OVER, COUNT OVER, RANK, PERCENT_RANK, MIN OVER, MAX OVER
--   - Transactions: BEGIN TRANSACTION, COMMIT
--   - SCOPE_IDENTITY(): 1 occurrence
--   - GETDATE(): 8 occurrences total
--   - CASE expressions: Multiple occurrences
--   - ROUND function: 4 occurrences
--   - DECLARE statements: 6 variables
--   - Parameterized queries: All statements use parameters
--
-- Parameters Used:
--   - @ProductId: Used in GetProductByIdAsync, UpdateProductAsync, DeleteProductAsync
--   - @Name: Used in InsertProductAsync, UpdateProductAsync
--   - @Description: Used in InsertProductAsync, UpdateProductAsync
--   - @Price: Used in InsertProductAsync, UpdateProductAsync
--   - @StockQuantity: Used in InsertProductAsync, UpdateProductAsync
--   - @MinPrice: Used in GetProductsByPriceRangeAsync
--   - @MaxPrice: Used in GetProductsByPriceRangeAsync
--   - @Threshold: Used in GetLowStockProductsAsync
-- ================================================================================
