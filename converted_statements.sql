-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: MS SQL Server to PostgreSQL Migration
-- Project: AdoCore - Product Management System
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Schema Mapping: dbo -> productmanagement_dbo (from DMS schema_mapping_tool)
-- DMS Failure Reason: Metadata model creation/conversion failed after 15 attempts
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (Converted)
-- Original: CTE with AVG/COUNT OVER, JOIN, CASE, ROUND
-- Changes: All table/column names converted to lowercase per DMS schema mapping
-- ============================================================================
-- CONVERTED_START: 1_GetAllProductsAsync
WITH productstats AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;
-- CONVERTED_END: 1_GetAllProductsAsync

-- ============================================================================
-- Statement 2: GetProductByIdAsync (Converted)
-- Original: CTE with LAG OVER, LEFT JOIN, CASE, ROUND
-- Changes: All table/column names converted to lowercase per DMS schema mapping
-- ============================================================================
-- CONVERTED_START: 2_GetProductByIdAsync
WITH producthistory AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = @ProductId
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    ph.previousprice,
    ph.previousstock,
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;
-- CONVERTED_END: 2_GetProductByIdAsync

-- ============================================================================
-- Statement 3: InsertProductAsync (Converted)
-- Original: DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(), GETDATE()
-- Changes: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> clock_timestamp(),
--          Transaction handled at connection level in Npgsql,
--          All names lowercase per DMS schema mapping
-- NOTE: For Npgsql, transactions are managed at the connection level.
--       The multi-statement batch is split into individual commands.
-- ============================================================================
-- CONVERTED_START: 3_InsertProductAsync
-- Sub-statement 3a: Insert product and return new ID
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Sub-statement 3b: Log the insertion (uses @NewProductId from 3a)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- Sub-statement 3c: Update product statistics
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;
-- CONVERTED_END: 3_InsertProductAsync

-- ============================================================================
-- Statement 4: UpdateProductAsync (Converted)
-- Original: BEGIN TRANSACTION, DECLARE, SELECT into variables, UPDATE, INSERT, UPDATE
-- Changes: GETDATE() -> clock_timestamp(), DECLARE removed (handled in app code),
--          Transaction handled at connection level in Npgsql,
--          All names lowercase per DMS schema mapping
-- NOTE: For Npgsql, transactions are managed at the connection level.
--       The multi-statement batch is split into individual commands.
-- ============================================================================
-- CONVERTED_START: 4_UpdateProductAsync
-- Sub-statement 4a: Get old values
SELECT price as oldprice, stockquantity as oldstock
FROM products
WHERE productid = @ProductId;

-- Sub-statement 4b: Update the product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

-- Sub-statement 4c: Log the changes
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- Sub-statement 4d: Update product statistics
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;
-- CONVERTED_END: 4_UpdateProductAsync

-- ============================================================================
-- Statement 5: DeleteProductAsync (Converted)
-- Original: BEGIN TRANSACTION, DECLARE, SELECT into variables, INSERT, DELETE, UPDATE with CASE
-- Changes: GETDATE() -> clock_timestamp(), DECLARE removed (handled in app code),
--          Transaction handled at connection level in Npgsql,
--          All names lowercase per DMS schema mapping
-- NOTE: For Npgsql, transactions are managed at the connection level.
--       The multi-statement batch is split into individual commands.
-- ============================================================================
-- CONVERTED_START: 5_DeleteProductAsync
-- Sub-statement 5a: Get old values
SELECT price as oldprice, stockquantity as oldstock
FROM products
WHERE productid = @ProductId;

-- Sub-statement 5b: Log the deletion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- Sub-statement 5c: Delete the product
DELETE FROM products 
WHERE productid = @ProductId;

-- Sub-statement 5d: Update product statistics
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = clock_timestamp()
WHERE statid = 1;
-- CONVERTED_END: 5_DeleteProductAsync

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted)
-- Original: CTE with RANK/PERCENT_RANK OVER, BETWEEN, CASE
-- Changes: All table/column names converted to lowercase per DMS schema mapping
-- ============================================================================
-- CONVERTED_START: 6_GetProductsByPriceRangeAsync
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
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
-- CONVERTED_END: 6_GetProductsByPriceRangeAsync

-- ============================================================================
-- Statement 7: GetLowStockProductsAsync (Converted)
-- Original: CTE with AVG/MIN/MAX OVER, CASE, ROUND
-- Changes: All table/column names converted to lowercase per DMS schema mapping,
--          Added CAST for integer division to avoid truncation in ROUND
-- ============================================================================
-- CONVERTED_START: 7_GetLowStockProductsAsync
WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT 
    sa.*,
    CASE 
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
-- CONVERTED_END: 7_GetLowStockProductsAsync

-- ============================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total Statements Converted: 7
-- DMS Tool Status: FAILED for all 7 statements
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
-- ============================================================================
