-- ============================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: ProductRepository.cs (converted from MS SQL Server)
-- Conversion method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema mapping obtained from DMS schema_mapping_tool (successful)
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (CONVERTED)
-- Original method: GetAllProductsAsync()
-- Conversion: Lowercase all schema objects per DMS mapping
-- Changes: Table/column names lowercased, CTE name changed to avoid
--          conflict with productstats table
-- ============================================================
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

-- ============================================================
-- Statement 2: GetProductByIdAsync (CONVERTED)
-- Original method: GetProductByIdAsync()
-- Conversion: Lowercase all schema objects, CTE name changed
-- Parameters: @ProductId (unchanged for Npgsql compatibility)
-- ============================================================
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

-- ============================================================
-- Statement 3: InsertProductAsync (CONVERTED)
-- Original method: InsertProductAsync()
-- Conversion: SCOPE_IDENTITY() -> RETURNING clause
--             GETDATE() -> clock_timestamp()
--             Transaction blocks managed by C# code
--             Restructured as sequential statements for ADO.NET
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- ============================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- (Separate command in C# for history logging)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- (Separate command in C# for stats update)
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================
-- Statement 4: UpdateProductAsync (CONVERTED)
-- Original method: UpdateProductAsync()
-- Conversion: DECLARE @var -> subquery/CTE approach
--             GETDATE() -> clock_timestamp()
--             Transaction blocks managed by C# code
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- ============================================================
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================
-- Statement 5: DeleteProductAsync (CONVERTED)
-- Original method: DeleteProductAsync()
-- Conversion: DECLARE @var -> subquery/CTE approach
--             GETDATE() -> clock_timestamp()
--             Transaction blocks managed by C# code
-- Parameters: @ProductId
-- ============================================================
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

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
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Original method: GetProductsByPriceRangeAsync()
-- Conversion: Lowercase all schema objects
-- Parameters: @MinPrice, @MaxPrice (unchanged for Npgsql)
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
-- Statement 7: GetLowStockProductsAsync (CONVERTED)
-- Original method: GetLowStockProductsAsync()
-- Conversion: Lowercase all schema objects, CAST for integer division
-- Parameters: @Threshold (unchanged for Npgsql)
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

-- ============================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total statements converted: 7
-- Conversion method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS schema_mapping_tool used for schema name resolution
-- Key conversions applied:
--   - All table/column names lowercased per DMS schema mapping
--   - SCOPE_IDENTITY() -> RETURNING clause
--   - GETDATE() -> clock_timestamp()
--   - DECLARE @var -> Separate queries with C# variable handling
--   - Transaction blocks -> Managed by C# code with Npgsql
--   - CTE names adjusted to avoid table name conflicts
--   - Integer division CAST for ROUND calculations
-- ============================================================
