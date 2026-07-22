-- Converted SQL Statements for PostgreSQL
-- Target: PostgreSQL 13
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: AccessDeniedException - not authorized to perform dms:StartMetadataModelCreation
-- Total Statements: 7

-- ============================================================
-- Statement 1: GetAllProductsAsync (SELECT with CTE and window functions)
-- Source File: DataAccess/ProductRepository.cs
-- ============================================================
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

-- ============================================================
-- Statement 2: GetProductByIdAsync (SELECT with CTE and LAG window function)
-- Source File: DataAccess/ProductRepository.cs
-- ============================================================
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

-- ============================================================
-- Statement 3: InsertProductAsync (Writable CTE with RETURNING - replaces SCOPE_IDENTITY)
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Notes: T-SQL DECLARE/SCOPE_IDENTITY/GETDATE replaced with
--   PostgreSQL writable CTEs with RETURNING clause and NOW()
-- ============================================================
WITH new_product AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
), history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM new_product
    RETURNING 1 as dummy
), stats_update AS (
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1
    RETURNING 1 as dummy
)
SELECT productid FROM new_product;

-- ============================================================
-- Statement 4: UpdateProductAsync (Writable CTE - replaces T-SQL transaction block)
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Notes: T-SQL DECLARE/variable assignment/GETDATE replaced with
--   PostgreSQL writable CTEs referencing old_values CTE and NOW()
-- ============================================================
WITH old_values AS (
    SELECT price AS oldprice, stockquantity AS oldstock
    FROM products
    WHERE productid = @ProductId
), product_update AS (
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId
    RETURNING 1 as dummy
), history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', ov.oldprice, @Price, ov.oldstock, @StockQuantity, NOW()
    FROM old_values ov
    RETURNING 1 as dummy
), stats_update AS (
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1
    RETURNING 1 as dummy
)
SELECT 1;

-- ============================================================
-- Statement 5: DeleteProductAsync (Writable CTE - replaces T-SQL transaction block)
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Notes: T-SQL DECLARE/variable assignment/GETDATE replaced with
--   PostgreSQL writable CTEs referencing old_values CTE and NOW()
-- ============================================================
WITH old_values AS (
    SELECT price AS oldprice, stockquantity AS oldstock
    FROM products
    WHERE productid = @ProductId
), history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', ov.oldprice, NULL, ov.oldstock, NULL, NOW()
    FROM old_values ov
    RETURNING 1 as dummy
), product_delete AS (
    DELETE FROM products
    WHERE productid = @ProductId
    RETURNING 1 as dummy
), stats_update AS (
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1
    RETURNING 1 as dummy
)
SELECT 1;

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync (SELECT with CTE, RANK, PERCENT_RANK)
-- Source File: DataAccess/ProductRepository.cs
-- ============================================================
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

-- ============================================================
-- Statement 7: GetLowStockProductsAsync (SELECT with CTE and aggregate window functions)
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Notes: Added CAST(stockquantity AS NUMERIC) to avoid integer division
-- ============================================================
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
