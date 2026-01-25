-- ==================================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Source: ProductRepository.cs
-- Total Statements: 9 (6 SELECT queries + 3 transaction blocks)
-- ==================================================================================

-- ==================================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ==================================================================================
-- statement_id: STMT_001
-- source_file: sourceCode/DataAccess/ProductRepository.cs
-- source_method: GetAllProductsAsync
-- line_range: 38-66
-- statement_type: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER)
-- parameter_list: None
-- construction_method: Direct string constant
-- sql_text:
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

-- ==================================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ==================================================================================
-- statement_id: STMT_002
-- source_file: sourceCode/DataAccess/ProductRepository.cs
-- source_method: GetProductByIdAsync
-- line_range: 76-103
-- statement_type: SELECT with CTE, Window Functions (LAG OVER)
-- parameter_list: @ProductId (INT)
-- construction_method: Direct string constant with parameterized query
-- sql_text:
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

-- ==================================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction Block
-- ==================================================================================
-- statement_id: STMT_003
-- source_file: sourceCode/DataAccess/ProductRepository.cs
-- source_method: InsertProductAsync
-- line_range: 115-141
-- statement_type: TRANSACTION BLOCK (INSERT with SCOPE_IDENTITY, INSERT, UPDATE)
-- parameter_list: @Name (VARCHAR), @Description (VARCHAR/NULL), @Price (DECIMAL), @StockQuantity (INT)
-- construction_method: Direct string constant with multi-statement transaction
-- sql_text:
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

-- ==================================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction Block
-- ==================================================================================
-- statement_id: STMT_004
-- source_file: sourceCode/DataAccess/ProductRepository.cs
-- source_method: UpdateProductAsync
-- line_range: 156-188
-- statement_type: TRANSACTION BLOCK (SELECT, UPDATE, INSERT)
-- parameter_list: @ProductId (INT), @Name (VARCHAR), @Description (VARCHAR/NULL), @Price (DECIMAL), @StockQuantity (INT)
-- construction_method: Direct string constant with multi-statement transaction
-- sql_text:
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

-- ==================================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction Block
-- ==================================================================================
-- statement_id: STMT_005
-- source_file: sourceCode/DataAccess/ProductRepository.cs
-- source_method: DeleteProductAsync
-- line_range: 200-232
-- statement_type: TRANSACTION BLOCK (SELECT, INSERT, DELETE, UPDATE)
-- parameter_list: @ProductId (INT)
-- construction_method: Direct string constant with multi-statement transaction
-- sql_text:
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

-- ==================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ==================================================================================
-- statement_id: STMT_006
-- source_file: sourceCode/DataAccess/ProductRepository.cs
-- source_method: GetProductsByPriceRangeAsync
-- line_range: 244-270
-- statement_type: SELECT with CTE, Window Functions (RANK OVER, PERCENT_RANK OVER)
-- parameter_list: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- construction_method: Direct string constant with parameterized query
-- sql_text:
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

-- ==================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ==================================================================================
-- statement_id: STMT_007
-- source_file: sourceCode/DataAccess/ProductRepository.cs
-- source_method: GetLowStockProductsAsync
-- line_range: 283-312
-- statement_type: SELECT with CTE, Window Functions (AVG OVER, MIN OVER, MAX OVER)
-- parameter_list: @Threshold (INT)
-- construction_method: Direct string constant with parameterized query
-- sql_text:
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

-- ==================================================================================
-- END OF EXTRACTED STATEMENTS CATALOG
-- ==================================================================================
-- Total Statements Extracted: 7
-- Note: STMT_003, STMT_004, and STMT_005 are multi-statement transaction blocks
-- containing multiple SQL operations within each transaction
-- ==================================================================================
