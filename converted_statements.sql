-- Converted SQL Statements for PostgreSQL
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Target Database: PostgreSQL 13
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}

-- Statement 1: GetAllProductsAsync
WITH productstats AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT 
    p.productid as "ProductId",
    p.name as "Name",
    p.description as "Description",
    p.price as "Price",
    p.stockquantity as "StockQuantity",
    p.createddate as "CreatedDate",
    p.modifieddate as "ModifiedDate",
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
    p.productid as "ProductId",
    p.name as "Name",
    p.description as "Description",
    p.price as "Price",
    p.stockquantity as "StockQuantity",
    p.createddate as "CreatedDate",
    p.modifieddate as "ModifiedDate",
    ph.previousprice as "PreviousPrice",
    ph.previousstock as "PreviousStock",
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END as "PriceChangePercentage"
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- Statement 3: InsertProductAsync
-- Converted from: DECLARE @var + SCOPE_IDENTITY() + GETDATE() + explicit transaction
-- To: PostgreSQL writable CTE with RETURNING + NOW()
WITH inserted AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM inserted
),
stats_update AS (
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1
)
SELECT productid FROM inserted;

-- Statement 4: UpdateProductAsync
-- Converted from: DECLARE @var + variable assignment + GETDATE() + explicit transaction
-- To: PostgreSQL writable CTE with subquery for old values + NOW()
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
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', price, @Price, stockquantity, @StockQuantity, NOW()
    FROM old_values
)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT price FROM old_values) + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- Statement 5: DeleteProductAsync
-- Converted from: DECLARE @var + variable assignment + GETDATE() + explicit transaction
-- To: PostgreSQL writable CTE with subquery for old values + NOW()
WITH old_values AS (
    SELECT price, stockquantity FROM products WHERE productid = @ProductId
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', price, NULL, stockquantity, NULL, NOW()
    FROM old_values
),
product_delete AS (
    DELETE FROM products WHERE productid = @ProductId
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
    rp.productid as "ProductId",
    rp.name as "Name",
    rp.description as "Description",
    rp.price as "Price",
    rp.stockquantity as "StockQuantity",
    rp.createddate as "CreatedDate",
    rp.modifieddate as "ModifiedDate",
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
    sa.productid as "ProductId",
    sa.name as "Name",
    sa.description as "Description",
    sa.price as "Price",
    sa.stockquantity as "StockQuantity",
    sa.createddate as "CreatedDate",
    sa.modifieddate as "ModifiedDate",
    CASE 
        WHEN sa.stockquantity <= @Threshold THEN 'Critical'
        WHEN sa.stockquantity <= sa.avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as "StockStatus",
    ROUND((CAST(sa.stockquantity AS NUMERIC) / sa.avgstock) * 100, 2) as "StockPercentageOfAverage"
FROM stockanalysis sa
WHERE sa.stockquantity <= @Threshold
ORDER BY sa.stockquantity;
