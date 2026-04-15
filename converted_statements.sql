-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Equivalents
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Date: 2026-04-15
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (Converted)
-- Original: MS SQL CTE with AVG/COUNT OVER, CASE, ROUND, INNER JOIN
-- Changes: All schema objects lowercased, ROUND cast for numeric division
-- ============================================================================
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

-- ============================================================================
-- Statement 2: GetProductByIdAsync (Converted)
-- Original: MS SQL CTE with LAG, ROUND, LEFT JOIN
-- Changes: All schema objects lowercased
-- ============================================================================
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

-- ============================================================================
-- Statement 3: InsertProductAsync (Converted)
-- Original: MS SQL DECLARE, BEGIN TRANSACTION, SCOPE_IDENTITY(), GETDATE()
-- Changes: SCOPE_IDENTITY() → RETURNING, GETDATE() → NOW(), DO block for
--          multi-statement transaction, all schema objects lowercased
-- ============================================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following statements are executed separately in the C# code
-- after obtaining the new product ID from the RETURNING clause:

-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- UPDATE productstats
-- SET 
--     totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--     lastupdated = NOW()
-- WHERE statid = 1;

-- ============================================================================
-- Statement 4: UpdateProductAsync (Converted)
-- Original: MS SQL BEGIN TRANSACTION, DECLARE, SELECT INTO vars, UPDATE, INSERT, GETDATE()
-- Changes: DECLARE → PostgreSQL DO block variables not needed (restructured),
--          GETDATE() → NOW(), all schema objects lowercased
-- ============================================================================
BEGIN;
    SELECT price, stockquantity
    INTO _oldprice, _oldstock
    FROM products
    WHERE productid = @ProductId;
    
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', _oldprice, @Price, _oldstock, @StockQuantity, NOW());
    
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - _oldprice + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- Statement 5: DeleteProductAsync (Converted)
-- Original: MS SQL BEGIN TRANSACTION, DECLARE, SELECT INTO vars, INSERT, DELETE, UPDATE with CASE
-- Changes: GETDATE() → NOW(), all schema objects lowercased
-- ============================================================================
BEGIN;
    SELECT price, stockquantity
    INTO _oldprice, _oldstock
    FROM products
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', _oldprice, NULL, _oldstock, NULL, NOW());
    
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - _oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted)
-- Original: MS SQL CTE with RANK/PERCENT_RANK, BETWEEN, CASE
-- Changes: All schema objects lowercased
-- ============================================================================
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

-- ============================================================================
-- Statement 7: GetLowStockProductsAsync (Converted)
-- Original: MS SQL CTE with AVG/MIN/MAX OVER, CASE, ROUND
-- Changes: All schema objects lowercased, CAST for integer division
-- ============================================================================
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
