-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Equivalents
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- All 7 statements failed DMS conversion - manual conversion applied with lowercase schema
-- ============================================================================

-- ============================================================================
-- S1: GetAllProductsAsync - PostgreSQL Conversion
-- Original Method: GetAllProductsAsync in ProductRepository.cs
-- Conversion: CTE, window functions, CASE, ROUND - all compatible in PostgreSQL
-- Schema objects lowercased: Products->products, ProductId->productid, etc.
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
-- S2: GetProductByIdAsync - PostgreSQL Conversion
-- Original Method: GetProductByIdAsync in ProductRepository.cs
-- Conversion: CTE, LAG, CASE, ROUND - all compatible in PostgreSQL
-- Schema objects lowercased
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
-- S3: InsertProductAsync - PostgreSQL Conversion
-- Original Method: InsertProductAsync in ProductRepository.cs
-- Conversion: SCOPE_IDENTITY()->RETURNING+LASTVAL(), GETDATE()->NOW(),
--   BEGIN TRANSACTION->BEGIN, DECLARE removed (use DO block or inline)
--   For ADO.NET inline SQL, restructured to use INSERT...RETURNING
-- Schema objects lowercased
-- ============================================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following statements are executed separately in the C# code
-- after capturing the new productid from the RETURNING clause:
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
-- UPDATE productstats SET totalproducts = totalproducts + 1,
--   averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--   lastupdated = NOW() WHERE statid = 1;

-- Full transaction block (used in C# code):
-- BEGIN;
--     INSERT INTO products (name, description, price, stockquantity)
--     VALUES (@Name, @Description, @Price, @StockQuantity)
--     RETURNING productid INTO newproductid;
--     INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
--     VALUES (newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
--     UPDATE productstats SET totalproducts = totalproducts + 1,
--         averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--         lastupdated = NOW() WHERE statid = 1;
-- COMMIT;

-- ============================================================================
-- S4: UpdateProductAsync - PostgreSQL Conversion
-- Original Method: UpdateProductAsync in ProductRepository.cs
-- Conversion: GETDATE()->NOW(), DECLARE->removed (variables managed in C#),
--   BEGIN TRANSACTION->BEGIN
-- For ADO.NET: Transaction managed by C# code, SQL broken into individual statements
-- Schema objects lowercased
-- ============================================================================
SELECT price, stockquantity
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
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- S5: DeleteProductAsync - PostgreSQL Conversion
-- Original Method: DeleteProductAsync in ProductRepository.cs
-- Conversion: GETDATE()->NOW(), DECLARE->removed, BEGIN TRANSACTION->BEGIN
-- For ADO.NET: Transaction managed by C# code, SQL broken into individual statements
-- Schema objects lowercased
-- ============================================================================
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

DELETE FROM products 
WHERE productid = @ProductId;

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

-- ============================================================================
-- S6: GetProductsByPriceRangeAsync - PostgreSQL Conversion
-- Original Method: GetProductsByPriceRangeAsync in ProductRepository.cs
-- Conversion: CTE, RANK, PERCENT_RANK, BETWEEN, CASE - all compatible
-- Schema objects lowercased
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
-- S7: GetLowStockProductsAsync - PostgreSQL Conversion
-- Original Method: GetLowStockProductsAsync in ProductRepository.cs
-- Conversion: CTE, AVG/MIN/MAX OVER(), CASE, ROUND - all compatible
-- Note: Added ::numeric cast for integer division in PostgreSQL
-- Schema objects lowercased
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
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
