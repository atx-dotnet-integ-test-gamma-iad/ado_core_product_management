-- Converted PostgreSQL Statements from ProductRepository.cs
-- All conversions done manually due to DMS tool failure (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)

-- Statement 1: GetAllProductsAsync
WITH productstats AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT 
    p.productid AS "ProductId",
    p.name AS "Name",
    p.description AS "Description",
    p.price AS "Price",
    p.stockquantity AS "StockQuantity",
    p.createddate AS "CreatedDate",
    p.modifieddate AS "ModifiedDate",
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as "PriceCategory",
    ROUND((p.price / ps.avgprice) * 100, 2) as "PricePercentageOfAverage"
FROM products p
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- Statement 2: GetProductByIdAsync
WITH producthistory AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = @ProductId
)
SELECT 
    p.productid AS "ProductId",
    p.name AS "Name",
    p.description AS "Description",
    p.price AS "Price",
    p.stockquantity AS "StockQuantity",
    p.createddate AS "CreatedDate",
    p.modifieddate AS "ModifiedDate",
    ph.previousprice AS "PreviousPrice",
    ph.previousstock AS "PreviousStock",
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END as "PriceChangePercentage"
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- Statement 3: InsertProductAsync (restructured using writable CTEs)
WITH new_product AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM new_product
    RETURNING 1
),
stats_update AS (
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1
    RETURNING 1
)
SELECT productid FROM new_product;

-- Statement 4: UpdateProductAsync (restructured using writable CTEs)
WITH old_values AS (
    SELECT price, stockquantity FROM products WHERE productid = @ProductId
),
product_update AS (
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId
    RETURNING 1
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', ov.price, @Price, ov.stockquantity, @StockQuantity, NOW()
    FROM old_values ov
    RETURNING 1
)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT price FROM old_values) + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- Statement 5: DeleteProductAsync (restructured using writable CTEs)
WITH old_values AS (
    SELECT price, stockquantity FROM products WHERE productid = @ProductId
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', ov.price, NULL, ov.stockquantity, NULL, NOW()
    FROM old_values ov
    RETURNING 1
),
product_delete AS (
    DELETE FROM products 
    WHERE productid = @ProductId
    RETURNING 1
)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT price FROM old_values)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = NOW()
WHERE statid = 1;

-- Statement 6: GetProductsByPriceRangeAsync
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
    END as "PriceSegment"
FROM rankedproducts rp
ORDER BY rp.pricerank;

-- Statement 7: GetLowStockProductsAsync
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
    END as "StockStatus",
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as "StockPercentageOfAverage"
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
