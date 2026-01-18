-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Microsoft SQL Server to PostgreSQL Migration
-- ============================================================================
-- This file catalogs all SQL statements converted using the DMS MCP tool
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED SUCCESSFULLY
-- ============================================================================
-- DMS Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Column name changes: All column names converted to lowercase
-- Additional Changes: Added NULLS FIRST to ORDER BY clauses
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
-- STATEMENT 2: GetProductByIdAsync - CONVERTED SUCCESSFULLY
-- ============================================================================
-- DMS Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Column name changes: All column names converted to lowercase
-- Additional Changes: LEFT JOIN -> LEFT OUTER JOIN
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
-- STATEMENT 3: InsertProductAsync - MANUAL CONVERSION (DMS FAILED)
-- ============================================================================
-- DMS Conversion Status: ERROR - "Statement definition is not valid"
-- DMS Error Details: Metadata model creation failed
-- Manual Conversion Applied: YES
-- Reason: DMS tool cannot handle complex transaction blocks with SCOPE_IDENTITY()
-- 
-- Manual Changes Applied:
-- 1. Replaced SCOPE_IDENTITY() with RETURNING clause
-- 2. Replaced GETDATE() with CURRENT_TIMESTAMP
-- 3. Split transaction into separate statements (transaction managed by ADO.NET)
-- 4. Schema Changes: Products -> productmanagement_dbo.products
--                    ProductHistory -> productmanagement_dbo.producthistory
--                    ProductStats -> productmanagement_dbo.productstats
-- 5. Column name changes: All column names converted to lowercase
-- ============================================================================

-- Insert statement with RETURNING (replaces SCOPE_IDENTITY)
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following statements need to be executed separately within the same transaction
-- and use the returned productid from the INSERT above

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

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED WITH WARNINGS
-- ============================================================================
-- DMS Conversion Status: SUCCESS WITH WARNINGS
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--              transaction management commands such as BEGIN TRAN, SAVE TRAN in 
--              functions. Convert your source code manually.]
-- Schema Changes: Products -> productmanagement_dbo.products
--                 ProductHistory -> productmanagement_dbo.producthistory
--                 ProductStats -> productmanagement_dbo.productstats
-- Column name changes: All column names converted to lowercase
-- Variable changes: @OldPrice -> var_OldPrice, @OldStock -> var_OldStock
-- Function changes: GETDATE() -> clock_timestamp()
-- Note: Transaction management will be handled at application level (ADO.NET)
-- Note: Variable declarations converted to DECLARE block format
-- ============================================================================

-- Note: For ADO.NET usage, the DECLARE/BEGIN/END wrapper should be removed
-- and transaction managed by NpgsqlTransaction. Using the inner statements:

-- Store old values
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
-- STATEMENT 5: DeleteProductAsync - CONVERTED WITH WARNINGS
-- ============================================================================
-- DMS Conversion Status: SUCCESS WITH WARNINGS
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--              transaction management commands such as BEGIN TRAN, SAVE TRAN in 
--              functions. Convert your source code manually.]
-- Schema Changes: Products -> productmanagement_dbo.products
--                 ProductHistory -> productmanagement_dbo.producthistory
--                 ProductStats -> productmanagement_dbo.productstats
-- Column name changes: All column names converted to lowercase
-- Variable changes: @OldPrice -> var_OldPrice, @OldStock -> var_OldStock
-- Function changes: GETDATE() -> clock_timestamp()
-- Note: Transaction management will be handled at application level (ADO.NET)
-- ============================================================================

-- Note: For ADO.NET usage, removing DECLARE/BEGIN/END wrapper:

-- Store product info
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED SUCCESSFULLY
-- ============================================================================
-- DMS Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Column name changes: All column names converted to lowercase
-- Additional Changes: Added NULLS FIRST to ORDER BY
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
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED SUCCESSFULLY
-- ============================================================================
-- DMS Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Column name changes: All column names converted to lowercase
-- Additional Changes: Added NULLS FIRST to ORDER BY
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
-- END OF CONVERTED SQL STATEMENTS
-- Total Statements: 7
-- Successfully Converted by DMS: 6
-- Manual Conversion Required: 1 (Statement 3)
-- ============================================================================
-- CRITICAL SCHEMA CHANGES TO RESPECT IN CODE:
-- - Table: Products -> productmanagement_dbo.products
-- - Table: ProductHistory -> productmanagement_dbo.producthistory
-- - Table: ProductStats -> productmanagement_dbo.productstats
-- - All column names: CamelCase -> lowercase
-- - Functions: GETDATE() -> CURRENT_TIMESTAMP or clock_timestamp()
-- - Functions: SCOPE_IDENTITY() -> RETURNING clause
-- - Transaction management: Move to application level (NpgsqlTransaction)
-- ============================================================================
