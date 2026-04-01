-- ============================================================
-- Converted PostgreSQL Statements
-- Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Schema Mapping Source: DMS Schema Mapping Tool
-- Target Schema: productmanagement_dbo (not used in queries as app connects to target DB directly)
-- All identifiers converted to lowercase per DMS schema mapping
-- Total Statements: 7
-- ============================================================
-- DMS Failure Reason: Metadata model creation/conversion did not complete after max poll attempts
-- Schema mappings obtained from DMS schema_mapping_tool:
--   Products -> products (columns all lowercase)
--   ProductHistory -> producthistory (columns all lowercase)
--   ProductStats -> productstats (columns all lowercase)
--   GETDATE() -> clock_timestamp()
--   SCOPE_IDENTITY() -> RETURNING clause
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync - PostgreSQL Conversion
-- Conversion: CTE name changed to productstats_cte to avoid conflict with productstats table
-- All identifiers lowercased per schema mapping
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
-- Statement 2: GetProductByIdAsync - PostgreSQL Conversion
-- CTE name changed to producthistory_cte to avoid conflict with producthistory table
-- All identifiers lowercased per schema mapping
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
-- Statement 3: InsertProductAsync - PostgreSQL Conversion
-- SCOPE_IDENTITY() replaced with RETURNING clause
-- GETDATE() replaced with clock_timestamp()
-- Transaction block restructured for PostgreSQL compatibility
-- Uses INSERT ... RETURNING productid to capture new ID
-- Separate statements executed in sequence by Npgsql
-- ============================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The above returns the new product ID. The following statements
-- use the returned ID (captured in C# code) for subsequent operations:
-- INSERT INTO producthistory and UPDATE productstats are handled
-- by restructured C# code that captures the RETURNING value.

-- ============================================================
-- Statement 3a: InsertProductAsync - ProductHistory insert (separate command)
-- ============================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- ============================================================
-- Statement 3b: InsertProductAsync - ProductStats update (separate command)
-- ============================================================
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================
-- Statement 4: UpdateProductAsync - PostgreSQL Conversion
-- DECLARE variables replaced with SELECT INTO syntax
-- GETDATE() replaced with clock_timestamp()
-- All identifiers lowercased
-- Uses DO $$ block for variable support
-- ============================================================
DO $$
DECLARE
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;

    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = clock_timestamp()
    WHERE productid = @ProductId;

    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', v_oldprice, @Price, v_oldstock, @StockQuantity, clock_timestamp());

    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - v_oldprice + @Price) / totalproducts,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- ============================================================
-- Statement 5: DeleteProductAsync - PostgreSQL Conversion
-- DECLARE variables replaced with SELECT INTO syntax
-- GETDATE() replaced with clock_timestamp()
-- All identifiers lowercased
-- Uses DO $$ block for variable support
-- ============================================================
DO $$
DECLARE
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;

    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, clock_timestamp());

    DELETE FROM products 
    WHERE productid = @ProductId;

    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - v_oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync - PostgreSQL Conversion
-- All identifiers lowercased per schema mapping
-- Window functions RANK and PERCENT_RANK are PostgreSQL compatible
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
-- Statement 7: GetLowStockProductsAsync - PostgreSQL Conversion
-- All identifiers lowercased per schema mapping
-- Added ::NUMERIC cast for integer division to produce decimal result
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
    ROUND((stockquantity::NUMERIC / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
