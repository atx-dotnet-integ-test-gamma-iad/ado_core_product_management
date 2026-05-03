-- =============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: AdoCore .NET Application
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mappings from DMS Schema Mapping Tool:
--   Products -> products (schema: productmanagement_dbo)
--   ProductHistory -> producthistory
--   ProductStats -> productstats
--   All column names -> lowercase
--   GETDATE() -> clock_timestamp()
--   SCOPE_IDENTITY() -> LASTVAL()
--   datetime -> TIMESTAMP WITHOUT TIME ZONE
--   decimal -> NUMERIC
--   nvarchar -> VARCHAR
-- =============================================================================

-- ---------------------------------------------------------------------------
-- STATEMENT 1: GetAllProductsAsync() - PostgreSQL Version
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- STATEMENT 2: GetProductByIdAsync() - PostgreSQL Version
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- STATEMENT 3: InsertProductAsync() - PostgreSQL Version
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Notes: Removed DECLARE/SET @NewProductId, replaced SCOPE_IDENTITY() with LASTVAL(),
--        replaced GETDATE() with clock_timestamp(), removed BEGIN TRANSACTION/COMMIT
--        (handled by ADO.NET), used LASTVAL() for cross-statement identity reference
-- ---------------------------------------------------------------------------
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity);

INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (LASTVAL(), 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

SELECT LASTVAL();

-- ---------------------------------------------------------------------------
-- STATEMENT 4: UpdateProductAsync() - PostgreSQL Version
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Notes: Replaced DECLARE/variable assignment with subqueries, replaced GETDATE()
--        with clock_timestamp(), removed BEGIN TRANSACTION/COMMIT (handled by ADO.NET).
--        Reordered operations: INSERT history first (to capture old values via subquery),
--        then UPDATE productstats (to use old price), then UPDATE products.
-- ---------------------------------------------------------------------------
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE',
    (SELECT price FROM products WHERE productid = @ProductId),
    @Price,
    (SELECT stockquantity FROM products WHERE productid = @ProductId),
    @StockQuantity,
    clock_timestamp());

UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

-- ---------------------------------------------------------------------------
-- STATEMENT 5: DeleteProductAsync() - PostgreSQL Version
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Notes: Replaced DECLARE/variable assignment with subqueries, replaced GETDATE()
--        with clock_timestamp(), removed BEGIN TRANSACTION/COMMIT (handled by ADO.NET).
--        Reordered operations: INSERT history first, UPDATE productstats, DELETE last.
-- ---------------------------------------------------------------------------
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE',
    (SELECT price FROM products WHERE productid = @ProductId),
    NULL,
    (SELECT stockquantity FROM products WHERE productid = @ProductId),
    NULL,
    clock_timestamp());

UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = clock_timestamp()
WHERE statid = 1;

DELETE FROM products 
WHERE productid = @ProductId;

-- ---------------------------------------------------------------------------
-- STATEMENT 6: GetProductsByPriceRangeAsync() - PostgreSQL Version
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- STATEMENT 7: GetLowStockProductsAsync() - PostgreSQL Version
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ---------------------------------------------------------------------------
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

-- =============================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total statements converted: 7
-- All converted via: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed (all 7 statements)
-- =============================================================================
