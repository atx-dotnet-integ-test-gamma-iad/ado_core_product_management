-- ================================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Purpose: Catalog of all converted PostgreSQL statements from DMS MCP tool
-- Target: PostgreSQL 13+
-- Total Statements: 7
-- Successful DMS Conversions: 5
-- Failed DMS Conversions (Manual): 2
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED BY DMS - SUCCESS)
-- ================================================================================
-- Source Method: GetAllProductsAsync
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- DMS Model Name: sql-conversion-1767732250
-- Schema Transformation: Products → productmanagement_dbo.products
-- Key Changes:
--   - CTE name lowercased: ProductStats → productstats
--   - Column names lowercased: ProductId → productid, etc.
--   - Table reference: Products → productmanagement_dbo.products
--   - Added NULLS FIRST to ORDER BY clauses
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED BY DMS - SUCCESS)
-- ================================================================================
-- Source Method: GetProductByIdAsync
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- DMS Model Name: sql-conversion-1767732380
-- Schema Transformation: Products → productmanagement_dbo.products
-- Key Changes:
--   - CTE name lowercased: ProductHistory → producthistory
--   - Column names lowercased throughout
--   - LAG window function preserved (PostgreSQL compatible)
--   - LEFT JOIN → LEFT OUTER JOIN (explicit)
--   - Parameter @ProductId retained (needs C# code adjustment)
--   - Added semicolon at end
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 3: InsertProductAsync (MANUAL CONVERSION - DMS FAILED)
-- ================================================================================
-- Source Method: InsertProductAsync
-- Conversion Status: FAILED - Manual conversion applied
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: "Statement definition is not valid"
-- Schema Transformation: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Key Manual Changes:
--   - Removed DECLARE @NewProductId (variables handled in C# code)
--   - BEGIN TRANSACTION → BEGIN (transaction managed by C# code using NpgsqlConnection.BeginTransaction)
--   - SCOPE_IDENTITY() → RETURNING productid clause
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Column and table names lowercased
--   - Transaction will be handled at application level, not in SQL
-- Notes:
--   - This conversion splits the transaction into three separate statements
--   - Transaction boundaries will be managed by C# ExecuteInTransactionAsync method
--   - RETURNING clause provides the new product ID
-- ================================================================================

-- Part 1: Insert product and return ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity, createddate)
VALUES (@Name, @Description, @Price, @StockQuantity, CURRENT_TIMESTAMP)
RETURNING productid;

-- Part 2: Log the insertion (execute after Part 1 with returned ID)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Part 3: Update product statistics (execute after Part 2)
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ================================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED BY DMS - SUCCESS WITH WARNINGS)
-- ================================================================================
-- Source Method: UpdateProductAsync
-- Conversion Status: SUCCESS (with manual adjustments needed)
-- Conversion Method: DMS_TOOL (with application-level transaction management)
-- DMS Model Name: sql-conversion-1767732505
-- DMS Warning: [7807 - CRITICAL] PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.
-- Schema Transformation: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Key Changes:
--   - Variable names: @OldPrice → var_OldPrice, @OldStock → var_OldStock (DMS format)
--   - But we'll use CTEs instead of variables in final application code
--   - GETDATE() → clock_timestamp()
--   - Transaction management moved to application level
--   - Column and table names lowercased
-- Adjusted Version (without DECLARE/BEGIN/END block):
-- ================================================================================

-- Variables will be retrieved in application code first, then used in statements
-- Part 1: Retrieve old values (done in C# code)
-- SELECT price, stockquantity FROM productmanagement_dbo.products WHERE productid = @ProductId;

-- Part 2: Update the product
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Part 3: Log the changes
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Part 4: Update product statistics
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ================================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED BY DMS - SUCCESS WITH WARNINGS)
-- ================================================================================
-- Source Method: DeleteProductAsync
-- Conversion Status: SUCCESS (with manual adjustments needed)
-- Conversion Method: DMS_TOOL (with application-level transaction management)
-- DMS Model Name: sql-conversion-1767732610
-- DMS Warning: [7807 - CRITICAL] PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions.
-- Schema Transformation: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Key Changes:
--   - Variables moved to application level
--   - GETDATE() → clock_timestamp() / CURRENT_TIMESTAMP
--   - Transaction management moved to application level
--   - CASE expression preserved
--   - Column and table names lowercased
-- Adjusted Version (without DECLARE/BEGIN/END block):
-- ================================================================================

-- Part 1: Retrieve old values (done in C# code)
-- SELECT price, stockquantity FROM productmanagement_dbo.products WHERE productid = @ProductId;

-- Part 2: Log the deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Part 3: Delete the product
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Part 4: Update product statistics
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, 
    averageprice = CASE 
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, 
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED BY DMS - SUCCESS)
-- ================================================================================
-- Source Method: GetProductsByPriceRangeAsync
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- DMS Model Name: sql-conversion-1767732708
-- Schema Transformation: Products → productmanagement_dbo.products
-- Key Changes:
--   - CTE name lowercased: RankedProducts → rankedproducts
--   - Column names lowercased throughout
--   - RANK() and PERCENT_RANK() window functions preserved (PostgreSQL compatible)
--   - BETWEEN clause preserved
--   - Parameters @MinPrice and @MaxPrice retained
--   - Added NULLS FIRST to ORDER BY
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 7: GetLowStockProductsAsync (MANUAL CONVERSION - DMS FAILED)
-- ================================================================================
-- Source Method: GetLowStockProductsAsync
-- Conversion Status: FAILED - Manual conversion applied
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: "Unknown metadata model conversion status: RECEIVED" (timeout/service issue)
-- Schema Transformation: Products → productmanagement_dbo.products
-- Key Manual Changes:
--   - CTE name lowercased: StockAnalysis → stockanalysis
--   - Column names lowercased throughout
--   - AVG(), MIN(), MAX() window functions preserved (PostgreSQL compatible)
--   - CASE expression preserved
--   - ROUND function preserved (PostgreSQL compatible)
--   - Parameter @Threshold retained
--   - Added NULLS FIRST to ORDER BY for PostgreSQL best practices
-- ================================================================================

WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM productmanagement_dbo.products p
)
SELECT 
    sa.*,
    CASE 
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity NULLS FIRST;

-- ================================================================================
-- CONVERSION SUMMARY
-- ================================================================================
-- Total Statements Converted: 7
-- DMS Successful Conversions: 5
--   - Statement 1: GetAllProductsAsync (SUCCESS)
--   - Statement 2: GetProductByIdAsync (SUCCESS)
--   - Statement 4: UpdateProductAsync (SUCCESS with warnings - transaction management)
--   - Statement 5: DeleteProductAsync (SUCCESS with warnings - transaction management)
--   - Statement 6: GetProductsByPriceRangeAsync (SUCCESS)
--
-- DMS Failed Conversions (Manual): 2
--   - Statement 3: InsertProductAsync (FAILED - "Statement definition is not valid")
--   - Statement 7: GetLowStockProductsAsync (FAILED - DMS timeout/service issue)
--
-- Critical Schema Changes:
--   - ALL table references changed from "Products" to "productmanagement_dbo.products"
--   - ALL table references changed from "ProductHistory" to "productmanagement_dbo.producthistory"
--   - ALL table references changed from "ProductStats" to "productmanagement_dbo.productstats"
--   - ALL column names converted to lowercase
--   - ALL CTE names converted to lowercase
--
-- SQL Server to PostgreSQL Syntax Changes:
--   - GETDATE() → CURRENT_TIMESTAMP or clock_timestamp()
--   - SCOPE_IDENTITY() → RETURNING clause
--   - BEGIN TRANSACTION → BEGIN (managed at application level)
--   - Parameters @param format retained (Npgsql supports this format)
--   - Added NULLS FIRST to ORDER BY clauses
--   - LEFT JOIN → LEFT OUTER JOIN (more explicit)
--
-- Transaction Management:
--   - Statements 3, 4, 5 require transaction management at C# application level
--   - Use NpgsqlConnection.BeginTransaction() instead of SQL-level transactions
--   - Split complex transaction blocks into multiple statements
--   - Execute within try-catch blocks with commit/rollback logic
-- ================================================================================
