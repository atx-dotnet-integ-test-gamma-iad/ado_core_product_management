-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Converted from: extracted_statements.sql (SQL Server)
-- Conversion Tool: AWS DMS MCP Statement Conversion Tool
-- Target Database: PostgreSQL
-- Total Statement Groups: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync Method (CONVERTED)
-- Conversion Status: SUCCESS via DMS Tool
-- Original Location: ProductRepository.cs, Lines 38-68
-- Type: SELECT with CTE and Window Functions
-- Parameters: None
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
-- STATEMENT 2: GetProductByIdAsync Method (CONVERTED)
-- Conversion Status: SUCCESS via DMS Tool
-- Original Location: ProductRepository.cs, Lines 78-106
-- Type: SELECT with CTE and LAG Window Function
-- Parameters: @ProductId (INT)
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
-- STATEMENT 3: InsertProductAsync Method (CONVERTED)
-- Conversion Status: SUCCESS via DMS Tool (after manual adjustment)
-- Original Location: ProductRepository.cs, Lines 116-141
-- Type: INSERT with multiple statements
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Schema Changes: All table references prefixed with productmanagement_dbo
-- Notes: 
--   - Original used DECLARE @NewProductId + BEGIN TRANSACTION + SCOPE_IDENTITY()
--   - Converted to use currval() for sequence value retrieval
--   - GETDATE() → NOW()
--   - Transaction management handled at application level
-- ============================================================================

INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity);
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES ((SELECT
    currval('products_productid_seq')), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts + 1, averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1), lastupdated = NOW()
    WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync Method (CONVERTED)
-- Conversion Status: SUCCESS via DMS Tool with WARNING
-- Original Location: ProductRepository.cs, Lines 151-182
-- Type: TRANSACTION BLOCK with UPDATE and INSERT
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Schema Changes: All table references prefixed with productmanagement_dbo
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--              transaction management commands such as BEGIN TRAN, SAVE TRAN in 
--              functions. Convert your source code manually.]
-- Notes:
--   - GETDATE() → clock_timestamp()
--   - Variable naming changed: @OldPrice → var_OldPrice, @OldStock → var_OldStock
--   - Transaction management handled at application level
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
-- STATEMENT 5: DeleteProductAsync Method (CONVERTED)
-- Conversion Status: SUCCESS via DMS Tool with WARNING
-- Original Location: ProductRepository.cs, Lines 192-222
-- Type: TRANSACTION BLOCK with DELETE and INSERT
-- Parameters: @ProductId
-- Schema Changes: All table references prefixed with productmanagement_dbo
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--              transaction management commands such as BEGIN TRAN, SAVE TRAN in 
--              functions. Convert your source code manually.]
-- Notes:
--   - GETDATE() → clock_timestamp()
--   - Variable naming changed: @OldPrice → var_OldPrice, @OldStock → var_OldStock
--   - Transaction management handled at application level
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
-- STATEMENT 6: GetProductsByPriceRangeAsync Method (CONVERTED)
-- Conversion Status: SUCCESS via DMS Tool
-- Original Location: ProductRepository.cs, Lines 232-259
-- Type: SELECT with CTE, RANK and PERCENT_RANK Window Functions
-- Parameters: @MinPrice, @MaxPrice
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
-- STATEMENT 7: GetLowStockProductsAsync Method (CONVERTED)
-- Conversion Status: SUCCESS via DMS Tool
-- Original Location: ProductRepository.cs, Lines 269-298
-- Type: SELECT with CTE and Multiple Window Functions
-- Parameters: @Threshold
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
-- Total Statement Groups Processed: 7
-- Successfully Converted: 7
-- Failed Conversions: 0
-- Conversions with Warnings: 2 (Statements 4 and 5 - transaction management)
--
-- Key Transformations Applied:
-- 1. Schema Prefix: All table references now use productmanagement_dbo schema
-- 2. Function Conversions:
--    - SCOPE_IDENTITY() → currval('products_productid_seq')
--    - GETDATE() → NOW() or clock_timestamp()
--    - LAG, RANK, PERCENT_RANK window functions: Natively supported in PostgreSQL
-- 3. Case Sensitivity: All identifiers converted to lowercase by DMS
-- 4. NULL Handling: ORDER BY clauses now include NULLS FIRST
-- 5. Transaction Management: BEGIN TRANSACTION/COMMIT noted for application-level handling
-- 6. Variable Naming: SQL Server @variables preserved as @parameters for ADO.NET compatibility
--
-- Manual Adjustments Required:
-- - Statement 3: Transaction block structure simplified for ADO.NET usage
-- - Statements 4 & 5: Transaction management must be handled in C# code using NpgsqlTransaction
-- ============================================================================
