-- =====================================================
-- Converted SQL Statements for PostgreSQL
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- All schema object names converted to lowercase for PostgreSQL compatibility
-- =====================================================

-- =====================================================
-- Statement 1: GetAllProductsAsync (Converted to PostgreSQL)
-- Original Location: ProductRepository.cs, GetAllProductsAsync method
-- Changes: Schema objects to lowercase, ROUND cast to numeric
-- =====================================================
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
    ROUND((p.price / ps.avgprice * 100)::numeric, 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- =====================================================
-- Statement 2: GetProductByIdAsync (Converted to PostgreSQL)
-- Original Location: ProductRepository.cs, GetProductByIdAsync method
-- Changes: Schema objects to lowercase, ROUND cast to numeric
-- =====================================================
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
            ROUND(((p.price - ph.previousprice) / ph.previousprice * 100)::numeric, 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- =====================================================
-- Statement 3: InsertProductAsync (Converted to PostgreSQL)
-- Original Location: ProductRepository.cs, InsertProductAsync method
-- Changes: SCOPE_IDENTITY() -> INSERT RETURNING + currval,
--          GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN,
--          DECLARE @var -> eliminated (uses INSERT...RETURNING with CTE),
--          lowercase schema objects
-- Note: In C# code, transaction is managed via BEGIN/COMMIT in SQL.
--       The INSERT...RETURNING pattern replaces SCOPE_IDENTITY().
-- =====================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- (Executed separately after getting productid)
-- INSERT INTO producthistory ...
-- UPDATE productstats ...

-- =====================================================
-- Statement 4: UpdateProductAsync (Converted to PostgreSQL)
-- Original Location: ProductRepository.cs, UpdateProductAsync method
-- Changes: DECLARE @var -> subquery, GETDATE() -> NOW(),
--          BEGIN TRANSACTION -> BEGIN, lowercase schema objects
-- Note: Variables replaced with subqueries. Transaction managed in C# code.
-- =====================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
SELECT @ProductId, 'UPDATE', price, @Price, stockquantity, @StockQuantity, NOW()
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

UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================
-- Statement 5: DeleteProductAsync (Converted to PostgreSQL)
-- Original Location: ProductRepository.cs, DeleteProductAsync method
-- Changes: DECLARE @var -> subquery, GETDATE() -> NOW(),
--          BEGIN TRANSACTION -> BEGIN, lowercase schema objects
-- Note: Variables replaced with subqueries. Transaction managed in C# code.
-- =====================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
SELECT @ProductId, 'DELETE', price, NULL, stockquantity, NULL, NOW()
FROM products
WHERE productid = @ProductId;

DELETE FROM products 
WHERE productid = @ProductId;

UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - COALESCE((SELECT price FROM products WHERE productid = @ProductId), 0)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted to PostgreSQL)
-- Original Location: ProductRepository.cs, GetProductsByPriceRangeAsync method
-- Changes: Schema objects to lowercase
-- =====================================================
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

-- =====================================================
-- Statement 7: GetLowStockProductsAsync (Converted to PostgreSQL)
-- Original Location: ProductRepository.cs, GetLowStockProductsAsync method
-- Changes: Schema objects to lowercase, ROUND cast to numeric
-- =====================================================
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
    ROUND((stockquantity::numeric / avgstock * 100)::numeric, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
