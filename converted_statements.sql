-- =============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Source File: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- All statements were passed through DMS MCP tool first, which failed.
-- Manual conversion applied with lowercase schema object names per transformation rules.
-- =============================================================================

-- =============================================================================
-- Statement 1: GetAllProductsAsync (converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Table/column names to lowercase, ROUND cast to numeric for PostgreSQL
-- =============================================================================
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

-- =============================================================================
-- Statement 2: GetProductByIdAsync (converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Table/column names to lowercase, LAG window functions compatible
-- =============================================================================
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

-- =============================================================================
-- Statement 3: InsertProductAsync (converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> NOW(),
--          DECLARE/SET removed, transaction restructured for PostgreSQL,
--          Table/column names to lowercase
-- =============================================================================
BEGIN;
    -- Insert the new product and get new ID
    WITH new_product AS (
        INSERT INTO products (name, description, price, stockquantity)
        VALUES (@Name, @Description, @Price, @StockQuantity)
        RETURNING productid
    ),
    -- Log the insertion
    log_insert AS (
        INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
        SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
        FROM new_product
    )
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

SELECT lastval();

-- =============================================================================
-- Statement 4: UpdateProductAsync (converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: DECLARE/@var removed, GETDATE() -> NOW(), 
--          SELECT INTO vars restructured using subquery,
--          Table/column names to lowercase
-- =============================================================================
BEGIN;
    -- Store old values for history using a CTE
    WITH old_values AS (
        SELECT price as oldprice, stockquantity as oldstock
        FROM products
        WHERE productid = @ProductId
    ),
    -- Update the product
    do_update AS (
        UPDATE products
        SET 
            name = @Name,
            description = @Description,
            price = @Price,
            stockquantity = @StockQuantity,
            modifieddate = NOW()
        WHERE productid = @ProductId
        RETURNING productid
    )
    -- Log the changes
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', old_values.oldprice, @Price, old_values.oldstock, @StockQuantity, NOW()
    FROM old_values;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- =============================================================================
-- Statement 5: DeleteProductAsync (converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: DECLARE/@var removed, GETDATE() -> NOW(),
--          SELECT INTO vars restructured using subquery,
--          Table/column names to lowercase
-- =============================================================================
BEGIN;
    -- Store product info for history using subquery
    WITH old_values AS (
        SELECT price as oldprice, stockquantity as oldstock
        FROM products
        WHERE productid = @ProductId
    )
    -- Log the deletion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', old_values.oldprice, NULL, old_values.oldstock, NULL, NOW()
    FROM old_values;
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT oldprice FROM (SELECT price as oldprice FROM products WHERE productid = @ProductId) sub)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- =============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Table/column names to lowercase, RANK/PERCENT_RANK compatible
-- =============================================================================
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

-- =============================================================================
-- Statement 7: GetLowStockProductsAsync (converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Table/column names to lowercase, ROUND with cast for integer division
-- =============================================================================
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
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
