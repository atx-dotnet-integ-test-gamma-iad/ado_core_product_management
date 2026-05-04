-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Source: AdoCore .NET Application - MS SQL Server to PostgreSQL Migration
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- Schema mappings obtained from DMS schema_mapping_tool (successful)
-- ============================================================================
-- All statements were attempted through DMS statement_conversion_tool first.
-- DMS consistently failed with metadata model creation error.
-- Manual conversions follow DMS schema_mapping_tool output for naming conventions.
-- Key conversion rules applied:
--   - All table/column names → lowercase (per DMS schema mapping)
--   - GETDATE() → clock_timestamp() (per DMS schema mapping)
--   - SCOPE_IDENTITY() → RETURNING productid (PostgreSQL idiom)
--   - CAST(x AS NUMERIC) → x::numeric (PostgreSQL shorthand)
--   - IDENTITY(1,1) → GENERATED ALWAYS AS IDENTITY
--   - nvarchar → VARCHAR, decimal → NUMERIC, datetime → TIMESTAMP WITHOUT TIME ZONE
--   - bit → NUMERIC(1,0)
-- ============================================================================

-- ============================================================================
-- REPO_01: GetAllProductsAsync - CTE with window functions
-- ORIGINAL MS SQL:
-- ============================================================================
-- WITH ProductStats AS (
--     SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts
--     FROM Products
-- )
-- SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
--     CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average' WHEN p.Price < ps.AvgPrice THEN 'Below Average' ELSE 'Average' END as PriceCategory,
--     ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
-- FROM Products p INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
-- ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name
-- CONVERTED PostgreSQL:
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
-- REPO_02: GetProductByIdAsync - CTE with LAG window function
-- CONVERTED PostgreSQL:
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
-- REPO_03: InsertProductAsync - INSERT with RETURNING
-- CONVERTED PostgreSQL:
-- ============================================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- ============================================================================
-- REPO_04: InsertProductAsync - INSERT into producthistory (INSERT action)
-- CONVERTED PostgreSQL:
-- ============================================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- ============================================================================
-- REPO_05: InsertProductAsync - UPDATE productstats
-- CONVERTED PostgreSQL:
-- ============================================================================
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- REPO_06: UpdateProductAsync - SELECT old values
-- CONVERTED PostgreSQL:
-- ============================================================================
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- ============================================================================
-- REPO_07: UpdateProductAsync - UPDATE products
-- CONVERTED PostgreSQL:
-- ============================================================================
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

-- ============================================================================
-- REPO_08: UpdateProductAsync - INSERT into producthistory (UPDATE action)
-- CONVERTED PostgreSQL:
-- ============================================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- ============================================================================
-- REPO_09: UpdateProductAsync - UPDATE productstats
-- CONVERTED PostgreSQL:
-- ============================================================================
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- REPO_10: DeleteProductAsync - SELECT old values
-- CONVERTED PostgreSQL:
-- ============================================================================
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- ============================================================================
-- REPO_11: DeleteProductAsync - INSERT into producthistory (DELETE action)
-- CONVERTED PostgreSQL:
-- ============================================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- ============================================================================
-- REPO_12: DeleteProductAsync - DELETE from products
-- CONVERTED PostgreSQL:
-- ============================================================================
DELETE FROM products 
WHERE productid = @ProductId;

-- ============================================================================
-- REPO_13: DeleteProductAsync - UPDATE productstats
-- CONVERTED PostgreSQL:
-- ============================================================================
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

-- ============================================================================
-- REPO_14: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- CONVERTED PostgreSQL:
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
-- REPO_15: GetLowStockProductsAsync - CTE with stock analysis
-- CONVERTED PostgreSQL:
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
    ROUND(stockquantity::numeric / avgstock * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;

-- ============================================================================
-- END OF CONVERTED REPOSITORY STATEMENTS (15 total)
-- ============================================================================
