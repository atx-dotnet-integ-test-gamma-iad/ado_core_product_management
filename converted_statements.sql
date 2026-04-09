-- =====================================================================
-- Converted SQL Statements for PostgreSQL
-- Source Database: Microsoft SQL Server (ProductManagement)
-- Target Database: PostgreSQL (postgres)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Unknown metadata model creation status: RECEIVED
-- Schema mapping from DMS schema_mapping_tool was used for all lowercase conversions.
-- =====================================================================

-- =====================================================================
-- STATEMENT 1: GetAllProductsAsync() - CONVERTED
-- Conversion: Table/column names to lowercase per DMS schema mapping
-- Changes: Products→products, ProductId→productid, Name→name, etc.
-- =====================================================================

WITH ProductStats AS (
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
INNER JOIN ProductStats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- =====================================================================
-- STATEMENT 2: GetProductByIdAsync() - CONVERTED
-- Conversion: Table/column names to lowercase per DMS schema mapping
-- Changes: Products→products, ProductId→productid, Price→price, etc.
-- Parameter: @ProductId (kept as-is for Npgsql compatibility)
-- =====================================================================

WITH ProductHistory AS (
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
LEFT JOIN ProductHistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- =====================================================================
-- STATEMENT 3: InsertProductAsync() - CONVERTED
-- Conversion: SCOPE_IDENTITY()→RETURNING, GETDATE()→NOW(),
--             BEGIN TRANSACTION→BEGIN, DECLARE removed,
--             Table/column names to lowercase
-- Note: Restructured to use INSERT...RETURNING for new ID,
--       followed by subquery-based inserts/updates in a single batch
-- =====================================================================

WITH new_product AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM new_product
),
update_stats AS (
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1
)
SELECT productid FROM new_product;

-- =====================================================================
-- STATEMENT 4: UpdateProductAsync() - CONVERTED
-- Conversion: GETDATE()→NOW(), BEGIN TRANSACTION→removed,
--             DECLARE @var→CTE subquery, Table/column names to lowercase
-- Note: Restructured as CTE-based approach for Npgsql parameter compatibility
-- =====================================================================

WITH old_values AS (
    SELECT price as old_price, stockquantity as old_stock
    FROM products
    WHERE productid = @ProductId
),
update_product AS (
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId
    RETURNING productid
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', ov.old_price, @Price, ov.old_stock, @StockQuantity, NOW()
    FROM old_values ov
)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT old_price FROM old_values) + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================================
-- STATEMENT 5: DeleteProductAsync() - CONVERTED
-- Conversion: GETDATE()→NOW(), BEGIN TRANSACTION→removed,
--             DECLARE @var→CTE subquery, Table/column names to lowercase
-- Note: Restructured as CTE-based approach for Npgsql parameter compatibility
-- =====================================================================

WITH old_values AS (
    SELECT price as old_price, stockquantity as old_stock
    FROM products
    WHERE productid = @ProductId
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', ov.old_price, NULL, ov.old_stock, NULL, NOW()
    FROM old_values ov
    RETURNING productid
),
delete_product AS (
    DELETE FROM products 
    WHERE productid = @ProductId
    RETURNING productid
)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT old_price FROM old_values)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync() - CONVERTED
-- Conversion: Table/column names to lowercase per DMS schema mapping
-- Parameters: @MinPrice, @MaxPrice (kept as-is for Npgsql)
-- =====================================================================

WITH RankedProducts AS (
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
FROM RankedProducts rp
ORDER BY rp.pricerank;

-- =====================================================================
-- STATEMENT 7: GetLowStockProductsAsync() - CONVERTED
-- Conversion: Table/column names to lowercase per DMS schema mapping
-- Parameter: @Threshold (kept as-is for Npgsql)
-- =====================================================================

WITH StockAnalysis AS (
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
FROM StockAnalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
