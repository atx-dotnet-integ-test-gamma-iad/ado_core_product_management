-- ================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Microsoft SQL Server to PostgreSQL Migration
-- Conversion Date: 2026-01-02
-- Total Statements Converted: 7
-- DMS Tool Conversions: 6
-- Manual Conversions After DMS Failure: 1
-- ================================================================

-- ================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- CONVERSION STATUS: DMS_TOOL (SUCCESS)
-- ================================================================
-- Original SQL Server Statement:
/*
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
*/

-- Converted PostgreSQL Statement:
WITH productstats
AS (SELECT
    productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM productmanagement_dbo.products)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END AS pricecategory, ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
    FROM productmanagement_dbo.products AS p
    INNER JOIN productstats AS ps
        ON p.productid = ps.productid
    ORDER BY
    CASE
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END NULLS FIRST, p.name NULLS FIRST;

-- Schema Transformations:
-- Products → productmanagement_dbo.products
-- Column names → lowercase (productid, avgprice, etc.)

-- ================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- CONVERSION STATUS: DMS_TOOL (SUCCESS)
-- ================================================================
-- Original SQL Server Statement:
/*
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
*/

-- Converted PostgreSQL Statement:
WITH producthistory
AS (SELECT
    productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE
        WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END AS pricechangepercentage
    FROM productmanagement_dbo.products AS p
    LEFT OUTER JOIN producthistory AS ph
        ON p.productid = ph.productid
    WHERE p.productid = @ProductId;

-- Schema Transformations:
-- Products → productmanagement_dbo.products
-- LEFT JOIN → LEFT OUTER JOIN
-- Parameter: @ProductId (retained - will be handled in C# code)

-- ================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction
-- CONVERSION STATUS: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Statement definition is not valid (complex transaction block)
-- ================================================================
-- Original SQL Server Statement:
/*
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;
*/

-- Converted PostgreSQL Statement (Manual Conversion):
-- Note: This needs to be split into multiple statements in C# code
-- or use a DO block with proper variable handling

-- INSERT with RETURNING clause (replaces SCOPE_IDENTITY())
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Subsequent statements will use the returned productid:
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- Manual Conversion Notes:
-- 1. SCOPE_IDENTITY() → RETURNING clause on INSERT
-- 2. GETDATE() → CURRENT_TIMESTAMP (or NOW())
-- 3. BEGIN TRANSACTION/COMMIT handled by C# BeginTransactionAsync/CommitAsync
-- 4. @Variable declarations removed - handled in application code
-- 5. Schema: Products → productmanagement_dbo.products
-- 6. Schema: ProductHistory → productmanagement_dbo.producthistory
-- 7. Schema: ProductStats → productmanagement_dbo.productstats

-- ================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction
-- CONVERSION STATUS: DMS_TOOL (SUCCESS with warnings)
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- ================================================================
-- Original SQL Server Statement:
/*
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
*/

-- Converted PostgreSQL Statement (adapted for C# execution):
-- First, get old values:
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Then execute updates:
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- Conversion Notes:
-- 1. GETDATE() → CURRENT_TIMESTAMP (DMS suggested clock_timestamp(), using CURRENT_TIMESTAMP for consistency)
-- 2. DECIMAL(18,2) → NUMERIC(18,2)
-- 3. BEGIN TRANSACTION/COMMIT managed by C# code
-- 4. Variable declarations handled in C# code
-- 5. Schema transformations applied

-- ================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction
-- CONVERSION STATUS: DMS_TOOL (SUCCESS with warnings)
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- ================================================================
-- Original SQL Server Statement:
/*
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
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
*/

-- Converted PostgreSQL Statement (adapted for C# execution):
-- First, get old values:
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Then execute deletes/updates:
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
    ELSE 0
END, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- Conversion Notes:
-- 1. GETDATE() → CURRENT_TIMESTAMP
-- 2. BEGIN TRANSACTION/COMMIT managed by C# code
-- 3. CASE expression preserved correctly
-- 4. Schema transformations applied

-- ================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with Ranking Functions
-- CONVERSION STATUS: DMS_TOOL (SUCCESS)
-- ================================================================
-- Original SQL Server Statement:
/*
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
*/

-- Converted PostgreSQL Statement:
WITH rankedproducts
AS (SELECT
    p.*, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products AS p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice)
SELECT
    rp.*,
    CASE
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS pricesegment
    FROM rankedproducts AS rp
    ORDER BY rp.pricerank NULLS FIRST;

-- Schema Transformations:
-- Products → productmanagement_dbo.products
-- Parameters: @MinPrice, @MaxPrice (retained)
-- Added NULLS FIRST for PostgreSQL ordering

-- ================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- CONVERSION STATUS: DMS_TOOL (SUCCESS)
-- ================================================================
-- Original SQL Server Statement:
/*
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
*/

-- Converted PostgreSQL Statement:
WITH stockanalysis
AS (SELECT
    p.*, AVG(stockquantity) OVER () AS avgstock, MIN(stockquantity) OVER () AS minstock, MAX(stockquantity) OVER () AS maxstock
    FROM productmanagement_dbo.products AS p)
SELECT
    sa.*,
    CASE
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS stockstatus, ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage
    FROM stockanalysis AS sa
    WHERE stockquantity <= @Threshold
    ORDER BY stockquantity NULLS FIRST;

-- Schema Transformations:
-- Products → productmanagement_dbo.products
-- Parameter: @Threshold (retained)
-- Added NULLS FIRST for PostgreSQL ordering

-- ================================================================
-- CONVERSION SUMMARY
-- ================================================================
-- Total SQL Statements: 7
-- Successfully converted by DMS: 6
-- Manual conversion after DMS failure: 1 (STMT_003)
-- DMS conversion with warnings: 2 (STMT_004, STMT_005)
--
-- Key Transformations Applied:
-- 1. SCOPE_IDENTITY() → RETURNING clause (STMT_003)
-- 2. GETDATE() → CURRENT_TIMESTAMP (STMT_003, STMT_004, STMT_005)
-- 3. Schema: dbo.Products → productmanagement_dbo.products
-- 4. Schema: dbo.ProductHistory → productmanagement_dbo.producthistory
-- 5. Schema: dbo.ProductStats → productmanagement_dbo.productstats
-- 6. Column names → lowercase (all statements)
-- 7. CTE names → lowercase (all CTE statements)
-- 8. BEGIN TRANSACTION/COMMIT → Managed by C# transaction handling
-- 9. @Variable declarations → Managed in C# code
-- 10. ORDER BY → Added NULLS FIRST where appropriate
-- 11. LEFT JOIN → LEFT OUTER JOIN (STMT_002)
-- 12. DECIMAL(18,2) → NUMERIC(18,2) data type
--
-- Parameters retained in @ format - will be converted to Npgsql format in C# code
-- ================================================================
