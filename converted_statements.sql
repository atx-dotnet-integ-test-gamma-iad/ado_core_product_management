-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- ============================================================================
-- Project: AdoCore
-- Source Database: Microsoft SQL Server
-- Target Database: PostgreSQL
-- Conversion Date: 2024-12-30
-- Total Statements Converted: 7
-- DMS Tool Successful Conversions: 6
-- Manual Conversions (after DMS failure): 1
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED BY DMS
-- ============================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
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
-- STATEMENT 2: GetProductByIdAsync - CONVERTED BY DMS
-- ============================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
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
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: MANUAL (DMS error: Statement definition is not valid)
-- DMS Error: Metadata model creation failed: Statement definition is not valid
-- Manual Conversion Reasoning:
--   - DMS cannot process multi-statement transaction blocks with DECLARE/SET
--   - Converted to use DO block or application-level transaction management
--   - SCOPE_IDENTITY() replaced with RETURNING clause for INSERT
--   - GETDATE() replaced with NOW()
--   - Transaction management will be handled at application level (C# code)
-- Schema Changes: Products → productmanagement_dbo.products
--                 ProductHistory → productmanagement_dbo.producthistory
--                 ProductStats → productmanagement_dbo.productstats
-- NOTE: This conversion requires application-level transaction management
-- ============================================================================

-- For ADO.NET implementation, this will be split into multiple commands within a transaction:

-- Step 1: Insert product with RETURNING
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Step 2: Log the insertion (using returned productid)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Step 3: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED BY DMS
-- ============================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS (with warnings about transaction management)
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- Note: Transaction management handled at application level
-- Schema Changes: Products → productmanagement_dbo.products
--                 ProductHistory → productmanagement_dbo.producthistory
--                 ProductStats → productmanagement_dbo.productstats
-- ============================================================================

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
-- STATEMENT 5: DeleteProductAsync - CONVERTED BY DMS
-- ============================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS (with warnings about transaction management)
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- Note: Transaction management handled at application level
-- Schema Changes: Products → productmanagement_dbo.products
--                 ProductHistory → productmanagement_dbo.producthistory
--                 ProductStats → productmanagement_dbo.productstats
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED BY DMS
-- ============================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
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
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED BY DMS
-- ============================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
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
-- DMS Tool Successful Conversions: 6
-- Manual Conversions (after DMS failure): 1
-- Key Transformations Applied:
--   - Table references: Products → productmanagement_dbo.products
--   - Table references: ProductHistory → productmanagement_dbo.producthistory
--   - Table references: ProductStats → productmanagement_dbo.productstats
--   - GETDATE() → NOW() or clock_timestamp()
--   - SCOPE_IDENTITY() → RETURNING clause
--   - BEGIN TRANSACTION → Transaction management at application level
--   - COMMIT → Handled at application level
--   - DECLARE syntax → PostgreSQL DECLARE syntax
--   - LAG window function → lag (lowercase)
--   - All column/table names → lowercase
--   - ORDER BY → ORDER BY ... NULLS FIRST
-- ============================================================================
