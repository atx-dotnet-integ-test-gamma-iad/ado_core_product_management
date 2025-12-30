-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Conversion Tool: AWS DMS MCP Statement Conversion Tool
-- Target Database: PostgreSQL
-- Source Schema: dbo (SQL Server) → productmanagement_dbo (PostgreSQL)
-- Date: Migration Phase 2 - SQL Statement Conversion
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Conversion Method: DMS_TOOL
-- Source: Statement 1 from extracted_statements.sql
-- Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Key Conversions: lowercase identifiers, NULLS FIRST in ORDER BY
-- ============================================================================
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
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Conversion Method: DMS_TOOL
-- Source: Statement 2 from extracted_statements.sql
-- Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Key Conversions: LAG function preserved, LEFT JOIN → LEFT OUTER JOIN, lowercase identifiers
-- ============================================================================
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
-- STATEMENT 3: InsertProductAsync (MANUALLY CONVERTED AFTER DMS FAILURE)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Source: Statement 3 from extracted_statements.sql
-- Status: DMS tool failed with error: "Statement definition is not valid."
-- DMS Error: Metadata model creation failed for full transaction block
-- Resolution: Converted using PostgreSQL RETURNING clause to replace SCOPE_IDENTITY()
--             Transaction management handled by application code (BeginTransactionAsync)
--             Component statements converted through DMS tool for schema verification
-- Schema Changes: 
--   - Products → productmanagement_dbo.products
--   - ProductHistory → productmanagement_dbo.producthistory
--   - ProductStats → productmanagement_dbo.productstats
-- Key Conversions:
--   - SCOPE_IDENTITY() → RETURNING productid
--   - GETDATE() → clock_timestamp()
--   - BEGIN TRANSACTION/COMMIT removed (handled by application)
--   - Lowercase identifiers
-- ============================================================================
-- Insert the new product and get the ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Log the insertion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED WITH WARNINGS)
-- Conversion Method: DMS_TOOL
-- Source: Statement 4 from extracted_statements.sql
-- Status: SUCCESS with CRITICAL warning about transaction management
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--               transaction management commands such as BEGIN TRAN in functions]
-- Resolution: Transaction management will be handled by application code
--             Transaction block syntax removed, SQL commands preserved
-- Schema Changes: 
--   - Products → productmanagement_dbo.products
--   - ProductHistory → productmanagement_dbo.producthistory
--   - ProductStats → productmanagement_dbo.productstats
-- Key Conversions:
--   - DECLARE @var → var_name (handled by app, variables removed)
--   - GETDATE() → clock_timestamp()
--   - Lowercase identifiers
-- ============================================================================
-- Store old values for history
SELECT
    price AS oldprice_val, stockquantity AS oldstock_val
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

-- Update the product
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
    WHERE productid = @ProductId;

-- Log the changes
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
    WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED WITH WARNINGS)
-- Conversion Method: DMS_TOOL
-- Source: Statement 5 from extracted_statements.sql
-- Status: SUCCESS with CRITICAL warning about transaction management
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--               transaction management commands such as BEGIN TRAN in functions]
-- Resolution: Transaction management will be handled by application code
--             Transaction block syntax removed, SQL commands preserved
-- Schema Changes: 
--   - Products → productmanagement_dbo.products
--   - ProductHistory → productmanagement_dbo.producthistory
--   - ProductStats → productmanagement_dbo.productstats
-- Key Conversions:
--   - DECLARE @var → var_name (handled by app, variables removed)
--   - GETDATE() → clock_timestamp()
--   - Lowercase identifiers
-- ============================================================================
-- Store product info for history
SELECT
    price AS oldprice_val, stockquantity AS oldstock_val
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

-- Log the deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- Delete the product
DELETE FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
    ELSE 0
END, lastupdated = clock_timestamp()
    WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Conversion Method: DMS_TOOL
-- Source: Statement 6 from extracted_statements.sql
-- Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Key Conversions: RANK() and PERCENT_RANK() preserved, lowercase identifiers, NULLS FIRST
-- ============================================================================
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
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Conversion Method: DMS_TOOL
-- Source: Statement 7 from extracted_statements.sql
-- Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Key Conversions: AVG/MIN/MAX OVER preserved, lowercase identifiers, NULLS FIRST
-- ============================================================================
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
-- Total Statements: 7
-- Successfully Converted by DMS: 6 (Statements 1, 2, 4, 5, 6, 7)
-- Manually Converted After DMS Failure: 1 (Statement 3)
-- All statements processed through DMS MCP tool as required
-- ============================================================================
