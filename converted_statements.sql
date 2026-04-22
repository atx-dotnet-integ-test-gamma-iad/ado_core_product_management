-- ============================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mapping Source: DMS Schema Mapping Tool (successful)
--   Products -> products (columns lowercase)
--   ProductHistory -> producthistory (columns lowercase)
--   ProductStats -> productstats (columns lowercase)
--   GETDATE() -> clock_timestamp()
--   SCOPE_IDENTITY() -> RETURNING clause
-- ============================================================

-- ============================================================
-- STATEMENT 1: GetAllProductsAsync (PostgreSQL)
-- Original Method: GetAllProductsAsync()
-- Conversion: Table/column names lowercased per DMS schema mapping
-- ============================================================

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

-- ============================================================
-- STATEMENT 2: GetProductByIdAsync (PostgreSQL)
-- Original Method: GetProductByIdAsync(int productId)
-- Parameters: @ProductId (int)
-- Conversion: Table/column names lowercased per DMS schema mapping
-- ============================================================

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

-- ============================================================
-- STATEMENT 3: InsertProductAsync (PostgreSQL)
-- Original Method: InsertProductAsync(Product product)
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Conversion: SCOPE_IDENTITY() -> RETURNING productid
--   GETDATE() -> clock_timestamp()
--   DECLARE removed (not needed in PostgreSQL inline SQL)
--   Transaction block restructured for PostgreSQL/Npgsql
--   Note: Npgsql handles transactions at application level;
--   the SQL is restructured as sequential statements within
--   a C# managed transaction.
-- ============================================================

INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- (Subsequent statements executed separately in C# after capturing productid)
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- UPDATE productstats
-- SET totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--     lastupdated = clock_timestamp()
-- WHERE statid = 1;

-- ============================================================
-- STATEMENT 4: UpdateProductAsync (PostgreSQL)
-- Original Method: UpdateProductAsync(Product product)
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Conversion: DECLARE @var -> subquery/separate SELECT
--   GETDATE() -> clock_timestamp()
--   Transaction managed at application level
-- ============================================================

SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- (After capturing old values in C#)
-- UPDATE products SET name = @Name, description = @Description, price = @Price,
--   stockquantity = @StockQuantity, modifieddate = clock_timestamp()
-- WHERE productid = @ProductId;

-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- UPDATE productstats SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
--   lastupdated = clock_timestamp() WHERE statid = 1;

-- ============================================================
-- STATEMENT 5: DeleteProductAsync (PostgreSQL)
-- Original Method: DeleteProductAsync(int productId)
-- Parameters: @ProductId
-- Conversion: DECLARE @var -> subquery/separate SELECT
--   GETDATE() -> clock_timestamp()
--   CASE expression preserved
--   Transaction managed at application level
-- ============================================================

SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- (After capturing old values in C#)
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- DELETE FROM products WHERE productid = @ProductId;

-- UPDATE productstats SET totalproducts = totalproducts - 1,
--   averageprice = CASE WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1) ELSE 0 END,
--   lastupdated = clock_timestamp() WHERE statid = 1;

-- ============================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Parameters: @MinPrice, @MaxPrice
-- Conversion: Table/column names lowercased per DMS schema mapping
-- ============================================================

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

-- ============================================================
-- STATEMENT 7: GetLowStockProductsAsync (PostgreSQL)
-- Original Method: GetLowStockProductsAsync(int threshold)
-- Parameters: @Threshold
-- Conversion: Table/column names lowercased per DMS schema mapping
--   Added CAST for integer division to avoid truncation
-- ============================================================

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
