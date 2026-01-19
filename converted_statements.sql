-- ==================================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Microsoft SQL Server to PostgreSQL Migration
-- Total Statements: 7
-- DMS Tool Successful Conversions: 4
-- Manual Conversions After DMS Failure: 3
-- ==================================================================================

-- ==================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Schema: productmanagement_dbo (converted from dbo)
-- Note: DMS converted table references to use productmanagement_dbo schema prefix
-- ==================================================================================
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

-- ==================================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Schema: productmanagement_dbo (converted from dbo)
-- Note: LAG window function syntax compatible, parameter @ProductId preserved
-- ==================================================================================
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

-- ==================================================================================
-- STATEMENT 3: InsertProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Status: MANUAL_REQUIRED
-- DMS Error: Statement definition is not valid
-- Note: Manual conversion required. DMS cannot handle multi-statement transaction with 
--       variable assignment and SCOPE_IDENTITY(). Converted to use RETURNING clause.
--       Transaction management will be handled at application level (ADO.NET).
-- ==================================================================================
-- Insert the new product and return the ID using RETURNING clause
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following statements need to be executed separately in the application code
-- after retrieving the returned productid:

-- Log the insertion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ==================================================================================
-- STATEMENT 4: UpdateProductAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS_WITH_WARNING
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--              transaction management commands such as BEGIN TRAN, SAVE TRAN in functions.]
-- Note: Transaction management (BEGIN/COMMIT) will be handled at application level (ADO.NET).
--       Variable declarations converted to PostgreSQL syntax but not needed when executed
--       as separate statements from C#. GETDATE() converted to clock_timestamp().
-- ==================================================================================
-- Store old values for history
SELECT price AS var_OldPrice, stockquantity AS var_OldStock
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Update the product
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Log the changes
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ==================================================================================
-- STATEMENT 5: DeleteProductAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS_WITH_WARNING
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--              transaction management commands such as BEGIN TRAN, SAVE TRAN in functions.]
-- Note: Transaction management (BEGIN/COMMIT) will be handled at application level (ADO.NET).
--       GETDATE() converted to clock_timestamp().
-- ==================================================================================
-- Store product info for history
SELECT price AS var_OldPrice, stockquantity AS var_OldStock
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Log the deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Delete the product
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
    ELSE 0
END, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ==================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Status: MANUAL_REQUIRED
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- Note: Manual conversion. Window functions RANK() and PERCENT_RANK() are compatible
--       with PostgreSQL. Converting to use productmanagement_dbo schema.
-- ==================================================================================
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM productmanagement_dbo.products p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as pricesegment
FROM rankedproducts rp
ORDER BY rp.pricerank;

-- ==================================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Status: MANUAL_REQUIRED
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- Note: Manual conversion. Window functions AVG, MIN, MAX OVER() are compatible
--       with PostgreSQL. Converting to use productmanagement_dbo schema.
-- ==================================================================================
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
ORDER BY stockquantity;

-- ==================================================================================
-- CONVERSION SUMMARY
-- Total Statements: 7
-- DMS Tool Successful: 4 (Statements 1, 2, 4, 5)
-- Manual After DMS Failure: 3 (Statements 3, 6, 7)
-- Key Changes:
--   - Schema prefix: dbo → productmanagement_dbo
--   - GETDATE() → CURRENT_TIMESTAMP
--   - SCOPE_IDENTITY() → RETURNING clause
--   - Transaction management moved to application level
--   - Column/table names converted to lowercase per PostgreSQL conventions
-- ==================================================================================
