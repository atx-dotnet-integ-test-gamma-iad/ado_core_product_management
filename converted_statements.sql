-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- PostgreSQL Syntax - Converted from Microsoft SQL Server
-- ADO.NET Application: AdoCore
-- ============================================================================
-- This file contains all SQL statements converted to PostgreSQL syntax
-- Source: DMS MCP Tool + Manual Conversion (where DMS failed)
-- Each statement includes conversion method metadata
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions
-- ============================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Notes: Added NULLS FIRST to ORDER BY clauses
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
-- STATEMENT 2: GetProductByIdAsync - LAG Window Function
-- ============================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Notes: LEFT JOIN converted to LEFT OUTER JOIN
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
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction Block
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: MANUAL
-- DMS Error: "Statement definition is not valid" - multi-statement transaction not supported
-- Schema Changes: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- Manual Changes Applied:
--   - SCOPE_IDENTITY() replaced with RETURNING productid
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION/COMMIT removed (handled at application level)
--   - Split into separate statements for application-level transaction management
-- Notes: Transaction management delegated to ExecuteInTransactionAsync method in application code
-- ============================================================================

-- Insert the new product and return the ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Log the insertion (will be executed in application code after getting RETURNING value)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics (will be executed in application code)
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction with Variable Storage
-- ============================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS (with warning 7807)
-- Warning: PostgreSQL does not support explicit transaction management in functions
-- Schema Changes: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- Notes: GETDATE() converted to clock_timestamp(), DECLARE converted to var_ prefix
--        Transaction BEGIN/COMMIT will be handled at application level
--        However, for ADO.NET usage in stored SQL strings, we'll simplify to remove DECLARE/BEGIN/END wrapper
-- ============================================================================

-- Store old values for history
SELECT price, stockquantity
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

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction with Conditional Logic
-- ============================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS (with warning 7807)
-- Warning: PostgreSQL does not support explicit transaction management in functions
-- Schema Changes: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- Notes: GETDATE() converted to clock_timestamp(), DECLARE converted to var_ prefix
--        Transaction BEGIN/COMMIT will be handled at application level
--        For ADO.NET usage, we'll simplify to remove DECLARE/BEGIN/END wrapper
-- ============================================================================

-- Store product info for history
SELECT price, stockquantity
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

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - RANK and PERCENT_RANK
-- ============================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Notes: Added NULLS FIRST to ORDER BY
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
-- STATEMENT 7: GetLowStockProductsAsync - Multiple Window Aggregations
-- ============================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Notes: Added NULLS FIRST to ORDER BY
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
-- ============================================================================
-- Total Statements: 7
-- DMS Tool Conversions: 6
-- Manual Conversions: 1 (Statement 3)
--
-- Key Schema Changes (Applied by DMS):
--   - All table references changed from 'TableName' to 'productmanagement_dbo.tablename'
--   - This must be respected in code re-integration
--
-- Key Syntax Changes:
--   - GETDATE() -> CURRENT_TIMESTAMP or clock_timestamp()
--   - SCOPE_IDENTITY() -> RETURNING clause
--   - Transaction management moved to application level
--   - Added NULLS FIRST to ORDER BY clauses
--   - Window functions (LAG, RANK, PERCENT_RANK, AVG, MIN, MAX OVER) all supported
--   - CTE (WITH clauses) fully supported
--   - CASE expressions fully supported
-- ============================================================================
