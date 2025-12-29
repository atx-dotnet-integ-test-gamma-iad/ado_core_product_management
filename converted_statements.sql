-- ============================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Conversion Date: 2024-12-29
-- Purpose: PostgreSQL-compatible SQL statements converted via DMS MCP Tool
-- ============================================================

-- ============================================================
-- STATEMENT #1: GetAllProductsAsync
-- SOURCE: DataAccess/ProductRepository.cs, Lines 39-69
-- CONVERSION: DMS_TOOL - SUCCESS
-- SCHEMA CHANGES: Products -> productmanagement_dbo.products
-- ============================================================
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

-- ============================================================
-- STATEMENT #2: GetProductByIdAsync
-- SOURCE: DataAccess/ProductRepository.cs, Lines 80-108
-- CONVERSION: DMS_TOOL - SUCCESS
-- SCHEMA CHANGES: Products -> productmanagement_dbo.products
-- NOTES: Parameter @ProductId remains, needs positional parameter conversion in code
-- ============================================================
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

-- ============================================================
-- STATEMENT #3: InsertProductAsync
-- SOURCE: DataAccess/ProductRepository.cs, Lines 121-144
-- CONVERSION: MANUAL_AFTER_DMS_FAILURE
-- DMS ERROR: Statement definition is not valid (transaction blocks not supported)
-- MANUAL CONVERSION NOTES:
--   - Removed DECLARE/SET pattern, use RETURNING instead
--   - SCOPE_IDENTITY() replaced with RETURNING productid
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION -> BEGIN
--   - Transaction handling moved to application code
--   - Split into separate statements for application execution
-- ============================================================

-- Statement 3a: Insert Product with RETURNING
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Insert Product History (to be executed in same transaction)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 3c: Update Product Statistics (to be executed in same transaction)
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================
-- STATEMENT #4: UpdateProductAsync
-- SOURCE: DataAccess/ProductRepository.cs, Lines 157-186
-- CONVERSION: MANUAL_AFTER_DMS_FAILURE
-- DMS ERROR: Statement definition is not valid (transaction blocks not supported)
-- MANUAL CONVERSION NOTES:
--   - Removed DECLARE, capture old values in application code
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Transaction handling moved to application code
--   - Split into separate statements for application execution
-- ============================================================

-- Statement 4a: Get old values (execute first to capture in application)
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 4b: Update Product (to be executed in transaction)
UPDATE productmanagement_dbo.products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Statement 4c: Insert Product History (to be executed in same transaction)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4d: Update Product Statistics (to be executed in same transaction)
UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================
-- STATEMENT #5: DeleteProductAsync
-- SOURCE: DataAccess/ProductRepository.cs, Lines 199-227
-- CONVERSION: MANUAL_AFTER_DMS_FAILURE
-- DMS ERROR: Statement definition is not valid (transaction blocks not supported)
-- MANUAL CONVERSION NOTES:
--   - Removed DECLARE, capture old values in application code
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Transaction handling moved to application code
--   - Split into separate statements for application execution
-- ============================================================

-- Statement 5a: Get old values (execute first to capture in application)
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 5b: Insert Product History (to be executed in transaction)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 5c: Delete Product (to be executed in same transaction)
DELETE FROM productmanagement_dbo.products 
WHERE productid = @ProductId;

-- Statement 5d: Update Product Statistics (to be executed in same transaction)
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================
-- STATEMENT #6: GetProductsByPriceRangeAsync
-- SOURCE: DataAccess/ProductRepository.cs, Lines 239-260
-- CONVERSION: DMS_TOOL - SUCCESS
-- SCHEMA CHANGES: Products -> productmanagement_dbo.products
-- NOTES: Parameters @MinPrice, @MaxPrice remain, need positional conversion in code
-- ============================================================
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

-- ============================================================
-- STATEMENT #7: GetLowStockProductsAsync
-- SOURCE: DataAccess/ProductRepository.cs, Lines 273-296
-- CONVERSION: DMS_TOOL - SUCCESS
-- SCHEMA CHANGES: Products -> productmanagement_dbo.products
-- NOTES: Parameter @Threshold remains, needs positional parameter conversion in code
-- ============================================================
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

-- ============================================================
-- CONVERSION SUMMARY FOR ProductRepository.cs
-- ============================================================
-- Total Statements: 7
-- DMS Tool Success: 4 statements (1, 2, 6, 7)
-- Manual Conversion: 3 statements (3, 4, 5) - transaction blocks
-- Schema Changes: All table references converted to productmanagement_dbo.* schema
-- Column Name Changes: All column names converted to lowercase
-- Key PostgreSQL Changes:
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - SCOPE_IDENTITY() -> RETURNING clause
--   - Transaction blocks split into individual statements
--   - LEFT JOIN -> LEFT OUTER JOIN
--   - Added NULLS FIRST to ORDER BY clauses
--   - Window functions syntax compatible
--   - PERCENT_RANK() -> percent_rank() (lowercase function)
--   - LAG() -> lag() (lowercase function)
-- ============================================================

-- ============================================================
-- NOTE: Database Schema DDL Statements
-- ============================================================
-- The database setup script (01_InitialSetup.sql) contains 23+ DDL/DML statements
-- that need to be converted. These include:
-- - CREATE DATABASE
-- - CREATE TABLE statements (5 tables)
-- - CREATE INDEX statements (5 indexes)
-- - ALTER TABLE for foreign keys
-- - INSERT statements for seed data
-- - CREATE TRIGGER
-- - CREATE STORED PROCEDURES (5 procedures)
--
-- These statements are primarily for database setup and are not directly
-- used in the application code. The key schema transformations are:
-- - Schema: dbo -> productmanagement_dbo
-- - Tables and columns: PascalCase -> lowercase
-- - IDENTITY columns -> SERIAL or GENERATED AS IDENTITY
-- - NVARCHAR -> VARCHAR
-- - GETDATE() -> CURRENT_TIMESTAMP or NOW()
-- - SCOPE_IDENTITY() -> RETURNING clause
-- ============================================================
