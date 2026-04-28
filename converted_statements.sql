-- ============================================
-- Converted SQL Statements for PostgreSQL
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- Schema mapping sourced from DMS schema_mapping_tool
-- ============================================

-- ==================================================
-- Statement 1: GetAllProductsAsync (converted)
-- Original Location: ProductRepository.cs, GetAllProductsAsync method
-- Conversion: table/column names lowercased, CTE name changed to avoid conflict with productstats table
-- ==================================================
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

-- ==================================================
-- Statement 2: GetProductByIdAsync (converted)
-- Original Location: ProductRepository.cs, GetProductByIdAsync method
-- Conversion: table/column names lowercased, CTE name changed to avoid conflict with producthistory table
-- ==================================================
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

-- ==================================================
-- Statement 3: InsertProductAsync (converted)
-- Original Location: ProductRepository.cs, InsertProductAsync method
-- Conversion: SCOPE_IDENTITY() replaced with RETURNING, GETDATE() with clock_timestamp(),
--   DECLARE/@var removed, restructured as CTE chain, table/column names lowercased
-- ==================================================
WITH inserted_product AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp()
    FROM inserted_product
    RETURNING 1 AS dummy
),
stats_update AS (
    UPDATE productstats
    SET totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1
    RETURNING 1 AS dummy
)
SELECT productid FROM inserted_product;

-- ==================================================
-- Statement 4: UpdateProductAsync (converted)
-- Original Location: ProductRepository.cs, UpdateProductAsync method
-- Conversion: DECLARE/@var removed, GETDATE() with clock_timestamp(),
--   restructured as CTE chain, table/column names lowercased
-- ==================================================
WITH old_values AS (
    SELECT price, stockquantity FROM products WHERE productid = @ProductId
),
update_product AS (
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = clock_timestamp()
    WHERE productid = @ProductId
    RETURNING 1 AS dummy
),
insert_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', ov.price, @Price, ov.stockquantity, @StockQuantity, clock_timestamp()
    FROM old_values ov
    RETURNING 1 AS dummy
),
update_stats AS (
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM old_values) + @Price) / totalproducts,
        lastupdated = clock_timestamp()
    WHERE statid = 1
    RETURNING 1 AS dummy
)
SELECT 1;

-- ==================================================
-- Statement 5: DeleteProductAsync (converted)
-- Original Location: ProductRepository.cs, DeleteProductAsync method
-- Conversion: DECLARE/@var removed, GETDATE() with clock_timestamp(),
--   restructured as CTE chain, table/column names lowercased
-- ==================================================
WITH old_values AS (
    SELECT price, stockquantity FROM products WHERE productid = @ProductId
),
insert_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', ov.price, NULL, ov.stockquantity, NULL, clock_timestamp()
    FROM old_values ov
    RETURNING 1 AS dummy
),
delete_product AS (
    DELETE FROM products 
    WHERE productid = @ProductId
    RETURNING 1 AS dummy
),
update_stats AS (
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT price FROM old_values)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = clock_timestamp()
    WHERE statid = 1
    RETURNING 1 AS dummy
)
SELECT 1;

-- ==================================================
-- Statement 6: GetProductsByPriceRangeAsync (converted)
-- Original Location: ProductRepository.cs, GetProductsByPriceRangeAsync method
-- Conversion: table/column names lowercased
-- ==================================================
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

-- ==================================================
-- Statement 7: GetLowStockProductsAsync (converted)
-- Original Location: ProductRepository.cs, GetLowStockProductsAsync method
-- Conversion: table/column names lowercased, added CAST for integer division
-- ==================================================
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
