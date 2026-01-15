-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Project: AdoCore - SQL Server to PostgreSQL Migration
-- Generated: Step 2 - DMS MCP Tool Conversion
-- ============================================================================
-- Purpose: Complete catalog of all SQL statements converted by DMS MCP tool
-- Total Statements Processed: 7
-- Successfully Converted by DMS: 6
-- Failed DMS Conversion (manual required): 1
-- ============================================================================

-- ============================================================================
-- STATEMENT #1: GetAllProductsAsync
-- ============================================================================
-- Conversion Status: DMS_TOOL_SUCCESS
-- DMS Conversion Timestamp: 2026-01-15T12:24:35.980677
-- Schema Name Changes: Products → productmanagement_dbo.products
-- Column Name Changes: All column names lowercased (ProductId → productid, etc.)
-- Notable DMS Changes: Added NULLS FIRST to ORDER BY clauses
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT (DMS):
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

-- ============================================================================
-- STATEMENT #2: GetProductByIdAsync
-- ============================================================================
-- Conversion Status: DMS_TOOL_SUCCESS
-- DMS Conversion Timestamp: 2026-01-15T12:26:27.401653
-- Schema Name Changes: Products → productmanagement_dbo.products
-- Column Name Changes: All column names lowercased
-- Notable DMS Changes: LEFT JOIN → LEFT OUTER JOIN, lag() function lowercased
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT (DMS):
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

-- ============================================================================
-- STATEMENT #3: InsertProductAsync
-- ============================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: "Statement definition is not valid"
-- DMS Conversion Timestamp: 2026-01-15T12:28:18.510324
-- Reason for Manual Conversion: DMS cannot process multi-statement transactions 
--                                with DECLARE variables and SCOPE_IDENTITY()
-- Manual Conversion Notes: 
--   - SCOPE_IDENTITY() → RETURNING clause for INSERT
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Transaction management handled in C# code layer, not in SQL
--   - Simplified to core INSERT with RETURNING for new ID
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT (MANUAL - after DMS failure):
-- Transaction #1: Insert product and get new ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity, createddate)
VALUES (@Name, @Description, @Price, @StockQuantity, CURRENT_TIMESTAMP)
RETURNING productid;

-- Transaction #2: Log to history (executed separately with returned ID)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Transaction #3: Update statistics (executed separately)
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT #4: UpdateProductAsync
-- ============================================================================
-- Conversion Status: DMS_TOOL_SUCCESS_WITH_WARNING
-- DMS Conversion Timestamp: 2026-01-15T12:28:44.729853
-- DMS Warning: "[7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--               transaction management commands such as BEGIN TRAN, SAVE TRAN in 
--               functions. Convert your source code manually.]"
-- Schema Name Changes: Products → productmanagement_dbo.products, 
--                      ProductHistory → productmanagement_dbo.producthistory,
--                      ProductStats → productmanagement_dbo.productstats
-- Column Name Changes: All column names lowercased
-- Notable DMS Changes: GETDATE() → clock_timestamp(), 
--                      DECLARE @OldPrice → DECLARE var_OldPrice,
--                      Transaction management needs manual handling
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT (DMS - transaction handling to be managed in C# code):
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT #5: DeleteProductAsync
-- ============================================================================
-- Conversion Status: DMS_TOOL_SUCCESS_WITH_WARNING
-- DMS Conversion Timestamp: 2026-01-15T12:30:35.706027
-- DMS Warning: "[7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--               transaction management commands such as BEGIN TRAN, SAVE TRAN in 
--               functions. Convert your source code manually.]"
-- Schema Name Changes: Products → productmanagement_dbo.products,
--                      ProductHistory → productmanagement_dbo.producthistory,
--                      ProductStats → productmanagement_dbo.productstats
-- Column Name Changes: All column names lowercased
-- Notable DMS Changes: GETDATE() → clock_timestamp(),
--                      Transaction management needs manual handling
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT (DMS - transaction handling to be managed in C# code):
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, 
    averageprice = CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, 
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT #6: GetProductsByPriceRangeAsync
-- ============================================================================
-- Conversion Status: DMS_TOOL_SUCCESS
-- DMS Conversion Timestamp: 2026-01-15T12:32:25.892076
-- Schema Name Changes: Products → productmanagement_dbo.products
-- Column Name Changes: All column names lowercased
-- Notable DMS Changes: percent_rank() function lowercased, added NULLS FIRST to ORDER BY
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT (DMS):
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

-- ============================================================================
-- STATEMENT #7: GetLowStockProductsAsync
-- ============================================================================
-- Conversion Status: DMS_TOOL_SUCCESS
-- DMS Conversion Timestamp: 2026-01-15T12:34:16.244848
-- Schema Name Changes: Products → productmanagement_dbo.products
-- Column Name Changes: All column names lowercased (StockQuantity → stockquantity, etc.)
-- Notable DMS Changes: Added NULLS FIRST to ORDER BY
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT (DMS):
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

-- ============================================================================
-- CONVERSION SUMMARY
-- ============================================================================
-- Total Statements: 7
-- DMS Tool Success: 6 (Statements 1, 2, 4, 5, 6, 7)
-- DMS Tool Failure: 1 (Statement 3 - InsertProductAsync)
-- Manual Conversion Required: 1 (Statement 3)
-- 
-- Key Schema Changes by DMS:
-- - Table Name: Products → productmanagement_dbo.products
-- - Table Name: ProductHistory → productmanagement_dbo.producthistory
-- - Table Name: ProductStats → productmanagement_dbo.productstats
-- - All column names converted to lowercase
-- - CTE names converted to lowercase
-- - Alias names converted to lowercase
--
-- Key T-SQL to PostgreSQL Conversions:
-- - GETDATE() → CURRENT_TIMESTAMP (manual adjustment for consistency)
-- - SCOPE_IDENTITY() → RETURNING clause (manual conversion)
-- - @Parameter syntax retained (supported by Npgsql)
-- - BEGIN TRANSACTION/COMMIT → Managed in C# code layer
-- - DECLARE @Variable → Not needed in simple queries, managed in C# for transactions
-- - Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX OVER) → Directly compatible
-- - CTEs (WITH clauses) → Directly compatible
-- - CASE expressions → Directly compatible
-- - ROUND function → Directly compatible
-- - ORDER BY with NULLS FIRST → Added by DMS for PostgreSQL compatibility
--
-- Transaction Management Note:
-- DMS converted procedural transaction logic but with warnings. For ADO.NET usage,
-- transaction management will be handled at the C# code level using 
-- NpgsqlConnection.BeginTransactionAsync() rather than embedded in SQL strings.
-- ============================================================================
