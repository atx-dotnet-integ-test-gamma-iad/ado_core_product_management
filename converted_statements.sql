-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Migration: Microsoft SQL Server to PostgreSQL
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Schema Mapping: dbo -> productmanagement_dbo (from DMS schema_mapping_tool)
-- Table Mappings: Products->products, ProductHistory->producthistory, ProductStats->productstats
-- All column names converted to lowercase per DMS schema mapping
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (PostgreSQL)
-- ============================================================================
WITH productstats_cte AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM productmanagement_dbo.products
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
FROM productmanagement_dbo.products p
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync (PostgreSQL)
-- ============================================================================
WITH producthistory_cte AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM productmanagement_dbo.products
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
FROM productmanagement_dbo.products p
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync (PostgreSQL)
-- Restructured for Npgsql parameterization: uses WITH ... INSERT pattern
-- and separate statements with lastval() for identity retrieval
-- ============================================================================
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity);

INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

SELECT lastval();

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (PostgreSQL)
-- Restructured as sequential statements for Npgsql parameterization
-- History INSERT comes first to capture old values before UPDATE
-- ============================================================================
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
SELECT @ProductId, 'UPDATE', p.price, @Price, p.stockquantity, @StockQuantity, clock_timestamp()
FROM productmanagement_dbo.products p
WHERE p.productid = @ProductId;

UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT price FROM productmanagement_dbo.products WHERE productid = @ProductId) + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

UPDATE productmanagement_dbo.products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (PostgreSQL)
-- Restructured as sequential statements for Npgsql parameterization
-- History INSERT and stats UPDATE come first to capture old values before DELETE
-- ============================================================================
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
SELECT @ProductId, 'DELETE', p.price, NULL, p.stockquantity, NULL, clock_timestamp()
FROM productmanagement_dbo.products p
WHERE p.productid = @ProductId;

UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT price FROM productmanagement_dbo.products WHERE productid = @ProductId)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = clock_timestamp()
WHERE statid = 1;

DELETE FROM productmanagement_dbo.products 
WHERE productid = @ProductId;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- ============================================================================
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM productmanagement_dbo.products p
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
-- STATEMENT 7: GetLowStockProductsAsync (PostgreSQL)
-- ============================================================================
WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM productmanagement_dbo.products p
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
