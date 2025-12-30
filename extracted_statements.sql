/*
================================================================================
EXTRACTED SQL STATEMENTS CATALOG
Microsoft SQL Server to PostgreSQL Migration
================================================================================
This file contains all SQL statements extracted from the ADO.NET codebase
for subsequent conversion using the DMS MCP tool and equivalency validation.

Total Statements: 7
Source File: DataAccess/ProductRepository.cs
================================================================================
*/

/*
--------------------------------------------------------------------------------
STATEMENT 1: GetAllProductsAsync
--------------------------------------------------------------------------------
Method: GetAllProductsAsync()
File: DataAccess/ProductRepository.cs
Lines: 41-69
Construction Method: Inline const string with verbatim string literal (@"...")
SQL Syntax Type: SELECT with CTE, Window Functions (AVG, COUNT OVER), CASE expressions, ROUND function
Parameters: None
--------------------------------------------------------------------------------
*/
-- STATEMENT 1 BEGIN
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
-- STATEMENT 1 END

/*
--------------------------------------------------------------------------------
STATEMENT 2: GetProductByIdAsync
--------------------------------------------------------------------------------
Method: GetProductByIdAsync(int productId)
File: DataAccess/ProductRepository.cs
Lines: 82-109
Construction Method: Inline const string with verbatim string literal (@"...")
SQL Syntax Type: SELECT with CTE, LAG Window Function, CASE expression, ROUND function
Parameters: @ProductId (int)
--------------------------------------------------------------------------------
*/
-- STATEMENT 2 BEGIN
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
-- STATEMENT 2 END

/*
--------------------------------------------------------------------------------
STATEMENT 3: InsertProductAsync
--------------------------------------------------------------------------------
Method: InsertProductAsync(Product product)
File: DataAccess/ProductRepository.cs
Lines: 125-147
Construction Method: Inline const string with verbatim string literal (@"...")
SQL Syntax Type: Transaction block (BEGIN TRANSACTION/COMMIT) with INSERT, SCOPE_IDENTITY(), GETDATE(), variable declarations
Parameters: @Name, @Description, @Price, @StockQuantity
Dependencies: ProductHistory table, ProductStats table
--------------------------------------------------------------------------------
*/
-- STATEMENT 3 BEGIN
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
-- STATEMENT 3 END

/*
--------------------------------------------------------------------------------
STATEMENT 4: UpdateProductAsync
--------------------------------------------------------------------------------
Method: UpdateProductAsync(Product product)
File: DataAccess/ProductRepository.cs
Lines: 161-190
Construction Method: Inline const string with verbatim string literal (@"...")
SQL Syntax Type: Transaction block (BEGIN TRANSACTION/COMMIT) with UPDATE, INSERT, GETDATE(), variable declarations
Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
Dependencies: ProductHistory table, ProductStats table
--------------------------------------------------------------------------------
*/
-- STATEMENT 4 BEGIN
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
-- STATEMENT 4 END

/*
--------------------------------------------------------------------------------
STATEMENT 5: DeleteProductAsync
--------------------------------------------------------------------------------
Method: DeleteProductAsync(int productId)
File: DataAccess/ProductRepository.cs
Lines: 202-233
Construction Method: Inline const string with verbatim string literal (@"...")
SQL Syntax Type: Transaction block (BEGIN TRANSACTION/COMMIT) with DELETE, INSERT, UPDATE with CASE expression, GETDATE(), variable declarations
Parameters: @ProductId
Dependencies: ProductHistory table, ProductStats table
--------------------------------------------------------------------------------
*/
-- STATEMENT 5 BEGIN
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
-- STATEMENT 5 END

/*
--------------------------------------------------------------------------------
STATEMENT 6: GetProductsByPriceRangeAsync
--------------------------------------------------------------------------------
Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
File: DataAccess/ProductRepository.cs
Lines: 246-266
Construction Method: Inline const string with verbatim string literal (@"...")
SQL Syntax Type: SELECT with CTE, Window Functions (RANK, PERCENT_RANK OVER), CASE expression, BETWEEN clause
Parameters: @MinPrice, @MaxPrice
--------------------------------------------------------------------------------
*/
-- STATEMENT 6 BEGIN
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
-- STATEMENT 6 END

/*
--------------------------------------------------------------------------------
STATEMENT 7: GetLowStockProductsAsync
--------------------------------------------------------------------------------
Method: GetLowStockProductsAsync(int threshold)
File: DataAccess/ProductRepository.cs
Lines: 285-307
Construction Method: Inline const string with verbatim string literal (@"...")
SQL Syntax Type: SELECT with CTE, Multiple Window Functions (AVG, MIN, MAX OVER), CASE expression, ROUND function
Parameters: @Threshold
--------------------------------------------------------------------------------
*/
-- STATEMENT 7 BEGIN
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
-- STATEMENT 7 END

/*
================================================================================
EXTRACTION SUMMARY
================================================================================
Total SQL Statements Extracted: 7

1. GetAllProductsAsync - CTE with AVG/COUNT window functions, CASE, ROUND
2. GetProductByIdAsync - CTE with LAG window function, CASE, ROUND  
3. InsertProductAsync - Transaction with INSERT, SCOPE_IDENTITY(), GETDATE()
4. UpdateProductAsync - Transaction with UPDATE, INSERT, GETDATE()
5. DeleteProductAsync - Transaction with DELETE, UPDATE with CASE, GETDATE()
6. GetProductsByPriceRangeAsync - CTE with RANK/PERCENT_RANK window functions
7. GetLowStockProductsAsync - CTE with AVG/MIN/MAX window functions, CASE, ROUND

All statements are ready for DMS MCP tool conversion.
Schema: dbo (default SQL Server schema)
Target Schema: public (default PostgreSQL schema)
================================================================================
*/
