-- ========================================================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration - DMS MCP Tool Output
-- Conversion Date: 2025-12-31
-- Total Statements: 7
-- Successfully Converted: 6 (Statements 1, 2, 4, 5, 6, 7)
-- Failed Conversion: 1 (Statement 3 - DMS error "Statement definition is not valid")
-- ========================================================================================================

-- ========================================================================================================
-- STATEMENT 1: GetAllProductsAsync - SUCCESSFULLY CONVERTED
-- Original Location: DataAccess/ProductRepository.cs, Lines 43-70
-- Conversion Status: SUCCESS
-- DMS Schema Transformations: 
--   - Products → productmanagement_dbo.products
--   - All column names converted to lowercase
--   - Added NULLS FIRST to ORDER BY clauses
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 2: GetProductByIdAsync - SUCCESSFULLY CONVERTED
-- Original Location: DataAccess/ProductRepository.cs, Lines 88-115
-- Conversion Status: SUCCESS
-- DMS Schema Transformations:
--   - Products → productmanagement_dbo.products
--   - All column names converted to lowercase
--   - LAG() function syntax preserved
--   - Parameter @ProductId preserved
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 3: InsertProductAsync - MANUAL CONVERSION (DMS FAILED)
-- Original Location: DataAccess/ProductRepository.cs, Lines 132-160
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: "Metadata model creation failed: Statement definition is not valid"
-- Reason: DMS cannot handle multi-statement batch with DECLARE variables and transactions
-- Manual Conversion: Split into separate statements, use RETURNING clause for SCOPE_IDENTITY replacement
-- ========================================================================================================

-- Primary INSERT with RETURNING (replaces SCOPE_IDENTITY())
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- NOTE: The following statements need to be executed separately in application code
-- after obtaining the returned productid from the INSERT above

-- Log the insertion
-- INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Update product statistics
-- UPDATE productmanagement_dbo.productstats
-- SET 
--     totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--     lastupdated = NOW()
-- WHERE statid = 1;

-- ========================================================================================================
-- STATEMENT 4: UpdateProductAsync - SUCCESSFULLY CONVERTED WITH WARNING
-- Original Location: DataAccess/ProductRepository.cs, Lines 170-206
-- Conversion Status: SUCCESS (with CRITICAL warning about transaction management)
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN in functions
-- DMS Schema Transformations:
--   - DECLARE @var → DECLARE var_var syntax
--   - GETDATE() → clock_timestamp()
--   - All table/column names to lowercase with productmanagement_dbo schema
-- ========================================================================================================

DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /*
    [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
    BEGIN TRANSACTION;
    */
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

-- ========================================================================================================
-- STATEMENT 5: DeleteProductAsync - SUCCESSFULLY CONVERTED WITH WARNING
-- Original Location: DataAccess/ProductRepository.cs, Lines 216-248
-- Conversion Status: SUCCESS (with CRITICAL warning about transaction management)
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN in functions
-- DMS Schema Transformations:
--   - DECLARE @var → DECLARE var_var syntax
--   - GETDATE() → clock_timestamp()
--   - All table/column names to lowercase with productmanagement_dbo schema
-- ========================================================================================================

DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /*
    [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
    BEGIN TRANSACTION;
    */
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

-- ========================================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - SUCCESSFULLY CONVERTED
-- Original Location: DataAccess/ProductRepository.cs, Lines 258-283
-- Conversion Status: SUCCESS
-- DMS Schema Transformations:
--   - Products → productmanagement_dbo.products
--   - All column names converted to lowercase
--   - RANK() and PERCENT_RANK() functions preserved
--   - Added NULLS FIRST to ORDER BY
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - SUCCESSFULLY CONVERTED
-- Original Location: DataAccess/ProductRepository.cs, Lines 295-320
-- Conversion Status: SUCCESS
-- DMS Schema Transformations:
--   - Products → productmanagement_dbo.products
--   - All column names converted to lowercase
--   - Window functions (AVG, MIN, MAX OVER) preserved
--   - Added NULLS FIRST to ORDER BY
-- ========================================================================================================

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

-- ========================================================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- ========================================================================================================
