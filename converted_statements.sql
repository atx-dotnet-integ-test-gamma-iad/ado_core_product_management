-- =====================================================
-- Converted PostgreSQL Statements from ProductRepository.cs
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Conversion Date: 2026-04-27
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mapping Source: DMS schema_mapping_tool (dbo -> productmanagement_dbo, lowercase column/table names)
-- Total Statements: 7
-- =====================================================

-- =====================================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Original: CTE with Window Functions, CASE, ROUND, INNER JOIN
-- Changes: Lowercase table/column names, CTE alias renamed to avoid conflict with table productstats
-- =====================================================
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

-- =====================================================
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Original: CTE with LAG Window Function, LEFT JOIN, CASE, ROUND, Parameterized
-- Changes: Lowercase table/column names, CTE alias renamed to avoid conflict with table producthistory
-- =====================================================
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

-- =====================================================
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Original: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE, Parameterized
-- Changes: SCOPE_IDENTITY() -> RETURNING productid, GETDATE() -> clock_timestamp(),
--          Lowercase table/column names, DECLARE removed (variable handled via RETURNING INTO),
--          Transaction handled by application code (Npgsql), block restructured
-- =====================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- (Separate command in app code) Log the insertion:
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- (Separate command in app code) Update product statistics:
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- =====================================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Original: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE(), Parameterized
-- Changes: GETDATE() -> clock_timestamp(), Lowercase table/column names,
--          SELECT INTO for variables, Transaction handled by application code
-- =====================================================
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- (Separate command in app code) Update the product:
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

-- (Separate command in app code) Log the changes:
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- (Separate command in app code) Update product statistics:
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- =====================================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Original: Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE, GETDATE(), Parameterized
-- Changes: GETDATE() -> clock_timestamp(), Lowercase table/column names,
--          SELECT for variables, Transaction handled by application code
-- =====================================================
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- (Separate command in app code) Log the deletion:
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- (Separate command in app code) Delete the product:
DELETE FROM products 
WHERE productid = @ProductId;

-- (Separate command in app code) Update product statistics:
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- =====================================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original: CTE with RANK(), PERCENT_RANK(), BETWEEN, CASE, Parameterized
-- Changes: Lowercase table/column names
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
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Original: CTE with AVG/MIN/MAX OVER, CASE, ROUND, Parameterized
-- Changes: Lowercase table/column names, CAST for integer division
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
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
