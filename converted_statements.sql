-- Converted SQL Statements for PostgreSQL
-- Target: PostgreSQL 13
-- Conversion Date: 2026-05-05
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}

-- =============================================
-- Statement 1: GetAllProductsAsync
-- Method: GetAllProductsAsync()
-- Location: DataAccess/ProductRepository.cs
-- =============================================
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

-- =============================================
-- Statement 2: GetProductByIdAsync
-- Method: GetProductByIdAsync(int productId)
-- Location: DataAccess/ProductRepository.cs
-- =============================================
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

-- =============================================
-- Statement 3: InsertProductAsync
-- Method: InsertProductAsync(Product product)
-- Location: DataAccess/ProductRepository.cs
-- PostgreSQL: Uses INSERT...RETURNING instead of SCOPE_IDENTITY()
--             Uses NOW() instead of GETDATE()
--             Transaction managed by application code (Npgsql)
-- =============================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- (Separate statement in transaction - log insertion)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- (Separate statement in transaction - update stats)
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- =============================================
-- Statement 4: UpdateProductAsync
-- Method: UpdateProductAsync(Product product)
-- Location: DataAccess/ProductRepository.cs
-- PostgreSQL: Uses subquery or separate SELECT for old values
--             Uses NOW() instead of GETDATE()
--             Transaction managed by application code (Npgsql)
-- =============================================
-- (Get old values)
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- (Update the product)
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- (Log the changes)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- (Update product statistics)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- =============================================
-- Statement 5: DeleteProductAsync
-- Method: DeleteProductAsync(int productId)
-- Location: DataAccess/ProductRepository.cs
-- PostgreSQL: Uses subquery or separate SELECT for old values
--             Uses NOW() instead of GETDATE()
--             Transaction managed by application code (Npgsql)
-- =============================================
-- (Get old values)
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- (Log the deletion)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- (Delete the product)
DELETE FROM products 
WHERE productid = @ProductId;

-- (Update product statistics)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = NOW()
WHERE statid = 1;

-- =============================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Location: DataAccess/ProductRepository.cs
-- =============================================
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

-- =============================================
-- Statement 7: GetLowStockProductsAsync
-- Method: GetLowStockProductsAsync(int threshold)
-- Location: DataAccess/ProductRepository.cs
-- =============================================
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
