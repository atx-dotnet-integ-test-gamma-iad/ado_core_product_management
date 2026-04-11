-- ============================================================
-- Converted SQL Statements for PostgreSQL
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================================

-- ==============================================
-- Statement 1: GetAllProductsAsync (converted to PostgreSQL)
-- Original Location: ProductRepository.cs - GetAllProductsAsync method
-- Conversion: lowercase schema objects, syntax compatible with PostgreSQL
-- ==============================================
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

-- ==============================================
-- Statement 2: GetProductByIdAsync (converted to PostgreSQL)
-- Original Location: ProductRepository.cs - GetProductByIdAsync method
-- ==============================================
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

-- ==============================================
-- Statement 3: InsertProductAsync (converted to PostgreSQL)
-- Original Location: ProductRepository.cs - InsertProductAsync method
-- Key changes: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN
-- ==============================================
BEGIN;
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (LASTVAL(), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

SELECT LASTVAL();

-- ==============================================
-- Statement 4: UpdateProductAsync (converted to PostgreSQL)
-- Original Location: ProductRepository.cs - UpdateProductAsync method
-- Key changes: GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN
-- Note: PostgreSQL does not support SELECT INTO variables the same way, 
-- using subqueries instead within the ADO.NET context
-- ==============================================
BEGIN;
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', 
        (SELECT price FROM products WHERE productid = @ProductId), 
        @Price, 
        (SELECT stockquantity FROM products WHERE productid = @ProductId), 
        @StockQuantity, NOW());
    
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ==============================================
-- Statement 5: DeleteProductAsync (converted to PostgreSQL)
-- Original Location: ProductRepository.cs - DeleteProductAsync method
-- Key changes: GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN
-- ==============================================
BEGIN;
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', 
        (SELECT price FROM products WHERE productid = @ProductId), 
        NULL, 
        (SELECT stockquantity FROM products WHERE productid = @ProductId), 
        NULL, NOW());
    
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ==============================================
-- Statement 6: GetProductsByPriceRangeAsync (converted to PostgreSQL)
-- Original Location: ProductRepository.cs - GetProductsByPriceRangeAsync method
-- ==============================================
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

-- ==============================================
-- Statement 7: GetLowStockProductsAsync (converted to PostgreSQL)
-- Original Location: ProductRepository.cs - GetLowStockProductsAsync method
-- Key changes: Added CAST for integer division to get decimal result
-- ==============================================
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
    ROUND((CAST(stockquantity AS DECIMAL) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
