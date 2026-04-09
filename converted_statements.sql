-- ============================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Target: PostgreSQL (via Npgsql)
-- All 7 SQL statements converted from MS SQL Server
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Unknown metadata model creation status: RECEIVED
-- Schema Mapping Source: DMS Schema Mapping Tool
--   dbo.Products -> productmanagement_dbo.products (all columns lowercase)
--   dbo.ProductHistory -> productmanagement_dbo.producthistory (all columns lowercase)
--   dbo.ProductStats -> productmanagement_dbo.productstats (all columns lowercase)
-- ============================================

-- ============================================
-- Statement 1: GetAllProductsAsync (Converted)
-- Original: CTE with AVG/COUNT window functions, CASE, ROUND, INNER JOIN
-- Changes: Table/column names to lowercase, schema prefix added
-- ============================================
WITH productstats_cte AS (
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
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================
-- Statement 2: GetProductByIdAsync (Converted)
-- Original: CTE with LAG window functions, CASE, ROUND, LEFT JOIN, parameterized @ProductId
-- Changes: Table/column names to lowercase, schema prefix added
-- ============================================
WITH producthistory_cte AS (
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
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================
-- Statement 3: InsertProductAsync (Converted)
-- Original: DECLARE, BEGIN TRANSACTION/COMMIT, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE, SELECT
-- Changes: Converted to CTE-based DML with RETURNING; GETDATE()->clock_timestamp(); 
--          SCOPE_IDENTITY() replaced with RETURNING; lowercase schema objects
-- ============================================
WITH new_product AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid, price, stockquantity
),
log_insertion AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, price, NULL, stockquantity, clock_timestamp()
    FROM new_product
),
update_stats AS (
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1
)
SELECT productid FROM new_product;

-- ============================================
-- Statement 4: UpdateProductAsync (Converted)
-- Original: BEGIN TRANSACTION/COMMIT, DECLARE, SELECT into variables, UPDATE with GETDATE(), INSERT
-- Changes: Converted to CTE-based DML; GETDATE()->clock_timestamp(); lowercase schema objects
-- ============================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
),
do_update AS (
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = clock_timestamp()
    WHERE productid = @ProductId
),
log_changes AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', ov.oldprice, @Price, ov.oldstock, @StockQuantity, clock_timestamp()
    FROM old_values ov
)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================
-- Statement 5: DeleteProductAsync (Converted)
-- Original: BEGIN TRANSACTION/COMMIT, DECLARE, SELECT into variables, INSERT, DELETE, UPDATE with CASE/GETDATE()
-- Changes: Converted to CTE-based DML; GETDATE()->clock_timestamp(); lowercase schema objects
-- ============================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
),
log_deletion AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', ov.oldprice, NULL, ov.oldstock, NULL, clock_timestamp()
    FROM old_values ov
),
do_delete AS (
    DELETE FROM products 
    WHERE productid = @ProductId
)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted)
-- Original: CTE with RANK/PERCENT_RANK window functions, BETWEEN, CASE, parameterized @MinPrice/@MaxPrice
-- Changes: Table/column names to lowercase, schema prefix added
-- ============================================
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

-- ============================================
-- Statement 7: GetLowStockProductsAsync (Converted)
-- Original: CTE with AVG/MIN/MAX window functions, CASE, ROUND, parameterized @Threshold
-- Changes: Table/column names to lowercase, schema prefix added,
--          ROUND division cast to NUMERIC for proper decimal division
-- ============================================
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
    ROUND((stockquantity::NUMERIC / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
