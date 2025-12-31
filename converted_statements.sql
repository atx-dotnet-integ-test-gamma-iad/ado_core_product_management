-- ============================================================================
-- CONVERTED SQL STATEMENTS - POSTGRESQL FORMAT
-- Converted via: DMS MCP Tool (dms-mcp____statement_conversion_tool)
-- Target Schema: productmanagement_dbo (DMS-converted schema name)
-- Total Statements: 7
-- Conversion Date: Migration Phase
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED
-- ============================================================================
-- Conversion Status: SUCCESS (DMS_TOOL)
-- Conversion Method: DMS MCP Tool
-- Schema Changes: Products → productmanagement_dbo.products
-- Key Conversions: CTE, AVG/COUNT OVER, CASE expressions, NULLS FIRST
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
-- STATEMENT 2: GetProductByIdAsync - CONVERTED
-- ============================================================================
-- Conversion Status: SUCCESS (DMS_TOOL)
-- Conversion Method: DMS MCP Tool
-- Schema Changes: Products → productmanagement_dbo.products
-- Key Conversions: CTE, LAG OVER, LEFT JOIN → LEFT OUTER JOIN, CASE with NULL, @ProductId parameter
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
-- STATEMENT 3: InsertProductAsync - MANUAL CONVERSION AFTER DMS FAILURE
-- ============================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- Conversion Method: Manual (DMS tool failed with "Statement definition is not valid")
-- DMS Error: Metadata model creation failed: Statement definition is not valid
-- Reason for Manual: Multi-statement transaction with SCOPE_IDENTITY() and DECLARE requires manual handling
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Key Manual Conversions:
--   - SCOPE_IDENTITY() → Use RETURNING clause in INSERT to get new ID
--   - GETDATE() → CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION/COMMIT → Handled at application level (ADO.NET transaction)
--   - @parameters remain as-is for ADO.NET parameterization
-- Notes: Transaction management done at application level, not in SQL statement itself
-- ============================================================================

-- Insert the new product and get the ID via RETURNING
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following statements would be executed as separate commands within the transaction:
-- Log the insertion (using returned productid as @NewProductId)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED WITH WARNINGS
-- ============================================================================
-- Conversion Status: SUCCESS (DMS_TOOL with CRITICAL warning)
-- Conversion Method: DMS MCP Tool
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Key Conversions:
--   - DECLARE @var → DECLARE var_var (variable names prefixed with var_)
--   - GETDATE() → clock_timestamp()
--   - BEGIN TRANSACTION/COMMIT → Handled at application level
--   - SELECT @var = col → SELECT col AS var_var
-- Notes: Transaction blocks handled at application level; DMS converted inner statements correctly
-- ============================================================================

-- Application-level transaction wraps these statements:
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store old values for history */
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update the product */
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId;
    /* Log the changes */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
        WHERE statid = 1;
    COMMIT;
END;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED WITH WARNINGS
-- ============================================================================
-- Conversion Status: SUCCESS (DMS_TOOL with CRITICAL warning)
-- Conversion Method: DMS MCP Tool
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Key Conversions:
--   - DECLARE @var → DECLARE var_var
--   - GETDATE() → clock_timestamp()
--   - BEGIN TRANSACTION/COMMIT → Handled at application level
--   - CASE expression maintained
-- ============================================================================

DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store product info for history */
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Log the deletion */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());
    /* Delete the product */
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = clock_timestamp()
        WHERE statid = 1;
    COMMIT;
END;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED
-- ============================================================================
-- Conversion Status: SUCCESS (DMS_TOOL)
-- Conversion Method: DMS MCP Tool
-- Schema Changes: Products → productmanagement_dbo.products
-- Key Conversions: CTE, RANK() OVER, PERCENT_RANK() OVER, BETWEEN, NULLS FIRST
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
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED
-- ============================================================================
-- Conversion Status: SUCCESS (DMS_TOOL)
-- Conversion Method: DMS MCP Tool
-- Schema Changes: Products → productmanagement_dbo.products
-- Key Conversions: CTE, AVG/MIN/MAX OVER, CASE expression, NULLS FIRST
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
-- DMS Tool Success: 6 (Statements 1, 2, 4, 5, 6, 7)
-- DMS Tool Failure: 1 (Statement 3 - manual conversion required)
-- Manual Conversions: 1 (Statement 3)
-- 
-- CRITICAL SCHEMA CHANGE FROM DMS:
-- All tables converted from simple names to schema-qualified:
--   Products → productmanagement_dbo.products
--   ProductHistory → productmanagement_dbo.producthistory
--   ProductStats → productmanagement_dbo.productstats
--
-- These schema names MUST be used in the re-integrated code!
-- ============================================================================
