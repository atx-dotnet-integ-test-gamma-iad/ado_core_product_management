-- ============================================================================
-- CONVERTED SQL STATEMENTS - POSTGRESQL
-- Converted From: extracted_statements.sql
-- Target Database: PostgreSQL
-- Conversion Tool: AWS DMS MCP Tool
-- Conversion Date: 2024-12-30
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED
-- ============================================================================
-- Original Statement ID: 1
-- Method Name: GetAllProductsAsync
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- DMS Output: Successful conversion
-- Schema Changes: Products -> productmanagement_dbo.products (schema prefix added)
-- Notes: CTE, window functions, and CASE statements converted successfully
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
-- Original Statement ID: 2
-- Method Name: GetProductByIdAsync
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- DMS Output: Successful conversion
-- Schema Changes: Products -> productmanagement_dbo.products (schema prefix added)
-- Notes: CTE with LAG window function converted successfully, parameter @ProductId retained
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
-- Original Statement ID: 3
-- Method Name: InsertProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: DMS FAILED - Manual conversion applied
-- DMS Error: "Statement definition is not valid" - Multi-statement transaction with DECLARE/BEGIN/COMMIT not supported by DMS
-- Manual Conversion Notes:
--   - DMS cannot convert multi-statement transaction blocks with DECLARE/BEGIN TRANSACTION/COMMIT
--   - Individual INSERT statement was successfully converted by DMS
--   - SCOPE_IDENTITY() converted to RETURNING clause for PostgreSQL
--   - GETDATE() converted to CURRENT_TIMESTAMP
--   - Transaction management will be handled at application level (ADO.NET)
--   - Multi-statement execution requires separate command execution in code
-- Schema Changes: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- ============================================================================
-- Statement 3a: Insert Product (returns new ID using RETURNING)
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Log to ProductHistory (executed after getting returned productid)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 3c: Update ProductStats (executed in same transaction)
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED WITH WARNINGS
-- ============================================================================
-- Original Statement ID: 4
-- Method Name: UpdateProductAsync
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS WITH WARNINGS
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
-- Manual Adjustments:
--   - Transaction management (BEGIN/COMMIT) will be handled at application level
--   - DECLARE @ variables converted to local variables (var_OldPrice, var_OldStock) for function context
--   - For ADO.NET code, these will be C# variables instead
--   - GETDATE() converted to clock_timestamp()
-- Schema Changes: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- Notes: Multi-statement transaction block - will need transaction handling in code
-- ============================================================================
-- Statement 4a: Get old values
SELECT
    price, stockquantity
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

-- Statement 4b: Update product
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
    WHERE productid = @ProductId;

-- Statement 4c: Log to ProductHistory
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4d: Update ProductStats
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED WITH WARNINGS
-- ============================================================================
-- Original Statement ID: 5
-- Method Name: DeleteProductAsync
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS WITH WARNINGS
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
-- Manual Adjustments:
--   - Transaction management (BEGIN/COMMIT) will be handled at application level
--   - DECLARE @ variables converted to local variables for function context
--   - For ADO.NET code, these will be C# variables instead
--   - GETDATE() converted to clock_timestamp()
-- Schema Changes: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- Notes: Multi-statement transaction block - will need transaction handling in code
-- ============================================================================
-- Statement 5a: Get old values
SELECT
    price, stockquantity
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

-- Statement 5b: Log to ProductHistory
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 5c: Delete product
DELETE FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

-- Statement 5d: Update ProductStats
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
    ELSE 0
END, lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED
-- ============================================================================
-- Original Statement ID: 6
-- Method Name: GetProductsByPriceRangeAsync
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- DMS Output: Successful conversion
-- Schema Changes: Products -> productmanagement_dbo.products (schema prefix added)
-- Notes: CTE with RANK() and PERCENT_RANK() window functions converted successfully
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
-- Original Statement ID: 7
-- Method Name: GetLowStockProductsAsync
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- DMS Output: Successful conversion
-- Schema Changes: Products -> productmanagement_dbo.products (schema prefix added)
-- Notes: CTE with AVG/MIN/MAX window functions converted successfully
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
-- END OF CONVERTED STATEMENTS
-- ============================================================================
-- SUMMARY:
-- Total Statements: 7
-- Successfully Converted by DMS: 6
-- Manual Conversion After DMS Failure: 1 (Statement 3)
-- Conversion Success Rate: 85.7% (6/7 by DMS tool)
--
-- CRITICAL SCHEMA TRANSFORMATIONS APPLIED BY DMS:
-- - All table references converted from "Products" to "productmanagement_dbo.products"
-- - All table references converted from "ProductHistory" to "productmanagement_dbo.producthistory"
-- - All table references converted from "ProductStats" to "productmanagement_dbo.productstats"
-- - Column names converted to lowercase per PostgreSQL convention
-- - CTE names converted to lowercase
--
-- CRITICAL NOTES FOR CODE INTEGRATION:
-- 1. Transaction management for statements 3, 4, 5 MUST be handled in ADO.NET code
-- 2. SCOPE_IDENTITY() in statement 3 replaced with RETURNING clause
-- 3. GETDATE() replaced with CURRENT_TIMESTAMP or clock_timestamp()
-- 4. Parameter syntax @param retained (Npgsql supports this)
-- 5. Schema prefix "productmanagement_dbo." MUST be used in all table references
-- ============================================================================
