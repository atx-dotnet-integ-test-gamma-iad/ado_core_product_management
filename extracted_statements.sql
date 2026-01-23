/*
================================================================================
EXTRACTED SQL STATEMENTS FOR DMS MCP TOOL CONVERSION
================================================================================
Source File: DataAccess/ProductRepository.cs
Extraction Date: 2026-01-23
Total Statements: 7
Purpose: Comprehensive catalog of all SQL statements for SQL Server to PostgreSQL migration
================================================================================
*/

/*
================================================================================
STATEMENT 1: GetAllProductsAsync
================================================================================
Source Method: GetAllProductsAsync()
Source File: DataAccess/ProductRepository.cs
Line Numbers: Approximately 38-71
Statement Type: SELECT with CTE, Window Functions, CASE expressions
Complexity: High
Parameters: None
Transaction: No
Description: Retrieves all products with price analysis using CTE, AVG/COUNT OVER window functions,
             CASE expressions, and ROUND function for calculating price percentages relative to average
================================================================================
*/

-- STATEMENT 1 (GetAllProductsAsync):
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

/*
================================================================================
STATEMENT 2: GetProductByIdAsync
================================================================================
Source Method: GetProductByIdAsync(int productId)
Source File: DataAccess/ProductRepository.cs
Line Numbers: Approximately 87-112
Statement Type: SELECT with CTE, LAG Window Function, CASE with NULL handling
Complexity: High
Parameters: @ProductId (INT)
Transaction: No
Description: Retrieves a single product by ID with historical price/stock comparison using LAG
             window function, LEFT JOIN, and CASE expressions for percentage calculation with NULL handling
================================================================================
*/

-- STATEMENT 2 (GetProductByIdAsync):
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

/*
================================================================================
STATEMENT 3: InsertProductAsync
================================================================================
Source Method: InsertProductAsync(Product product)
Source File: DataAccess/ProductRepository.cs
Line Numbers: Approximately 127-157
Statement Type: Transaction Block with INSERT, SCOPE_IDENTITY(), UPDATE, GETDATE()
Complexity: High
Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
Transaction: Yes (BEGIN TRANSACTION / COMMIT)
Description: Inserts a new product within a transaction, uses SCOPE_IDENTITY() to get the new ID,
             logs the insertion to ProductHistory with GETDATE(), updates ProductStats table with
             calculated average, and returns the new product ID
SQL Server Specific Functions: SCOPE_IDENTITY(), GETDATE(), BEGIN TRANSACTION/COMMIT
================================================================================
*/

-- STATEMENT 3 (InsertProductAsync):
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

/*
================================================================================
STATEMENT 4: UpdateProductAsync
================================================================================
Source Method: UpdateProductAsync(Product product)
Source File: DataAccess/ProductRepository.cs
Line Numbers: Approximately 167-203
Statement Type: Transaction Block with DECLARE, SELECT, UPDATE, INSERT
Complexity: High
Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
Transaction: Yes (BEGIN TRANSACTION / COMMIT)
Description: Updates an existing product within a transaction, uses DECLARE to store old values,
             SELECTs old values into variables, UPDATEs the product with GETDATE(), INSERTs history record,
             and UPDATEs ProductStats with recalculated average
SQL Server Specific Functions: GETDATE(), DECLARE statements, BEGIN TRANSACTION/COMMIT
================================================================================
*/

-- STATEMENT 4 (UpdateProductAsync):
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

/*
================================================================================
STATEMENT 5: DeleteProductAsync
================================================================================
Source Method: DeleteProductAsync(int productId)
Source File: DataAccess/ProductRepository.cs
Line Numbers: Approximately 213-247
Statement Type: Transaction Block with DECLARE, SELECT, INSERT, DELETE, UPDATE with CASE
Complexity: High
Parameters: @ProductId (INT)
Transaction: Yes (BEGIN TRANSACTION / COMMIT)
Description: Deletes a product within a transaction, uses DECLARE to store old values, SELECTs old
             values into variables, INSERTs history record, DELETEs the product, and UPDATEs ProductStats
             with CASE expression to handle division by zero
SQL Server Specific Functions: GETDATE(), DECLARE statements, BEGIN TRANSACTION/COMMIT
================================================================================
*/

-- STATEMENT 5 (DeleteProductAsync):
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

/*
================================================================================
STATEMENT 6: GetProductsByPriceRangeAsync
================================================================================
Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
Source File: DataAccess/ProductRepository.cs
Line Numbers: Approximately 257-284
Statement Type: SELECT with CTE, RANK() and PERCENT_RANK() Window Functions, BETWEEN clause
Complexity: High
Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
Transaction: No
Description: Retrieves products within a price range using CTE with RANK() and PERCENT_RANK() window
             functions for price ranking and percentile calculation, BETWEEN clause for range filtering,
             and CASE expression for price segment categorization (Budget/Mid-Range/Premium)
================================================================================
*/

-- STATEMENT 6 (GetProductsByPriceRangeAsync):
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

/*
================================================================================
STATEMENT 7: GetLowStockProductsAsync
================================================================================
Source Method: GetLowStockProductsAsync(int threshold)
Source File: DataAccess/ProductRepository.cs
Line Numbers: Approximately 294-325
Statement Type: SELECT with CTE, Multiple Window Functions (AVG, MIN, MAX OVER), CASE expressions
Complexity: High
Parameters: @Threshold (INT)
Transaction: No
Description: Retrieves low stock products using CTE with multiple window functions (AVG, MIN, MAX OVER)
             for stock analysis, WHERE clause filtering by threshold, CASE expressions for stock status
             categorization (Critical/Low/Adequate), and ROUND function for percentage calculation
================================================================================
*/

-- STATEMENT 7 (GetLowStockProductsAsync):
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

/*
================================================================================
EXTRACTION SUMMARY
================================================================================
Total Statements Extracted: 7
Statements with CTEs: 5 (Statements 1, 2, 6, 7)
Statements with Window Functions: 4 (Statements 1, 2, 6, 7)
Statements with Transactions: 3 (Statements 3, 4, 5)
Statements with Parameters: 6 (All except Statement 1)
SQL Server Specific Functions to Convert:
  - SCOPE_IDENTITY() -> PostgreSQL RETURNING clause or currval()
  - GETDATE() -> NOW() or CURRENT_TIMESTAMP
  - BEGIN TRANSACTION -> BEGIN
  - COMMIT; -> COMMIT (without semicolon in transaction syntax)
  - DECLARE @var syntax -> DECLARE var syntax
  - @param syntax -> $1, $2, etc. (or keep named parameters with Npgsql)
  
Next Step: Pass each statement through DMS MCP tool for conversion
================================================================================
*/
