/*
===============================================================================
SQL STATEMENT EXTRACTION CATALOG
Microsoft SQL Server to PostgreSQL Migration
Source File: DataAccess/ProductRepository.cs
Extraction Date: 2024
Total Statements: 7
===============================================================================
*/

/*
===============================================================================
STATEMENT ID: 1
METHOD: GetAllProductsAsync
TYPE: SELECT (Complex CTE with Window Functions)
SOURCE FILE: DataAccess/ProductRepository.cs
LINE NUMBERS: 38-68
PARAMETERS: None
STRING CONSTRUCTION: Inline SQL constant string
DESCRIPTION: CTE with AVG() and COUNT() window functions, CASE expressions
===============================================================================
*/
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
===============================================================================
STATEMENT ID: 2
METHOD: GetProductByIdAsync
TYPE: SELECT (CTE with LAG Window Function)
SOURCE FILE: DataAccess/ProductRepository.cs
LINE NUMBERS: 84-108
PARAMETERS: @ProductId (INT)
STRING CONSTRUCTION: Inline SQL constant string
DESCRIPTION: CTE with LAG window function for historical comparison
===============================================================================
*/
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
===============================================================================
STATEMENT ID: 3
METHOD: InsertProductAsync
TYPE: TRANSACTION BLOCK (INSERT operations with SCOPE_IDENTITY)
SOURCE FILE: DataAccess/ProductRepository.cs
LINE NUMBERS: 124-148
PARAMETERS: @Name (VARCHAR), @Description (VARCHAR), @Price (DECIMAL), @StockQuantity (INT)
STRING CONSTRUCTION: Inline SQL constant string
DESCRIPTION: Transaction block with variable declaration, INSERT with SCOPE_IDENTITY(), 
             history logging, statistics update, and SELECT to return new ID.
             Contains GETDATE() function and SQL Server specific transaction syntax.
===============================================================================
*/
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
===============================================================================
STATEMENT ID: 4
METHOD: UpdateProductAsync
TYPE: TRANSACTION BLOCK (UPDATE operations with variable declarations)
SOURCE FILE: DataAccess/ProductRepository.cs
LINE NUMBERS: 158-188
PARAMETERS: @ProductId (INT), @Name (VARCHAR), @Description (VARCHAR), @Price (DECIMAL), @StockQuantity (INT)
STRING CONSTRUCTION: Inline SQL constant string
DESCRIPTION: Transaction block with DECLARE statements, SELECT to capture old values,
             UPDATE main table, INSERT into history, UPDATE statistics.
             Contains GETDATE() function and SQL Server specific transaction syntax.
===============================================================================
*/
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
===============================================================================
STATEMENT ID: 5
METHOD: DeleteProductAsync
TYPE: TRANSACTION BLOCK (DELETE operations with variable declarations)
SOURCE FILE: DataAccess/ProductRepository.cs
LINE NUMBERS: 198-227
PARAMETERS: @ProductId (INT)
STRING CONSTRUCTION: Inline SQL constant string
DESCRIPTION: Transaction block with DECLARE statements, SELECT to capture values,
             INSERT into history, DELETE from main table, UPDATE statistics with CASE.
             Contains GETDATE() function and SQL Server specific transaction syntax.
===============================================================================
*/
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
===============================================================================
STATEMENT ID: 6
METHOD: GetProductsByPriceRangeAsync
TYPE: SELECT (CTE with RANK and PERCENT_RANK Window Functions)
SOURCE FILE: DataAccess/ProductRepository.cs
LINE NUMBERS: 237-260
PARAMETERS: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
STRING CONSTRUCTION: Inline SQL constant string
DESCRIPTION: CTE with RANK() and PERCENT_RANK() window functions, BETWEEN clause,
             CASE expression for price segmentation
===============================================================================
*/
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
===============================================================================
STATEMENT ID: 7
METHOD: GetLowStockProductsAsync
TYPE: SELECT (CTE with Multiple Window Functions)
SOURCE FILE: DataAccess/ProductRepository.cs
LINE NUMBERS: 270-297
PARAMETERS: @Threshold (INT)
STRING CONSTRUCTION: Inline SQL constant string
DESCRIPTION: CTE with AVG(), MIN(), MAX() window functions, complex CASE expressions,
             arithmetic calculations with window function results
===============================================================================
*/
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
===============================================================================
EXTRACTION SUMMARY
===============================================================================
Total SQL Statements Extracted: 7
- SELECT Statements: 4 (IDs: 1, 2, 6, 7)
- TRANSACTION BLOCKS: 3 (IDs: 3, 4, 5)

SQL Server Specific Features Identified:
- SCOPE_IDENTITY() function (Statement 3)
- GETDATE() function (Statements 3, 4, 5)
- BEGIN TRANSACTION/COMMIT syntax (Statements 3, 4, 5)
- DECLARE variable syntax (Statements 3, 4, 5)
- SET variable assignments (Statement 3)
- @parameter syntax (All parameterized statements)
- Window Functions: AVG() OVER(), COUNT() OVER(), LAG() OVER(), RANK() OVER(), 
                    PERCENT_RANK() OVER(), MIN() OVER(), MAX() OVER()

Files Referenced:
- DataAccess/ProductRepository.cs (Primary source file)

Next Steps:
- Convert each statement using DMS MCP tool (dms-mcp____statement_conversion_tool)
- Validate each statement pair using SQL Equivalency tool (sql-equivalency___validate_sql_equivalence)
- Create converted_statements.sql catalog
- Create dms_conversion_log.txt
- Create sql_equivalency_validation_report.json
===============================================================================
*/
