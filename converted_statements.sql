-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Date: 2026-03-31
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed for all 7 statements
-- Schema mapping sourced from DMS schema_mapping_tool:
--   dbo.Products -> productmanagement_dbo.products (all columns lowercase)
--   dbo.ProductHistory -> productmanagement_dbo.producthistory (all columns lowercase)
--   dbo.ProductStats -> productmanagement_dbo.productstats (all columns lowercase)
-- Key conversions: GETDATE() -> clock_timestamp(), SCOPE_IDENTITY() -> RETURNING,
--   ROUND integer division -> explicit CAST to NUMERIC
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (converted)
-- DMS Status: FAILED - Metadata model creation failed
-- Manual Conversion: Applied lowercase schema mapping per DMS schema_mapping_tool
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
    ROUND(CAST(p.price AS NUMERIC) / ps.avgprice * 100, 2) as pricepercentageofaverage
FROM productmanagement_dbo.products p
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync (converted)
-- DMS Status: FAILED - Metadata model creation failed
-- Manual Conversion: Applied lowercase schema mapping per DMS schema_mapping_tool
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
            ROUND(CAST((p.price - ph.previousprice) AS NUMERIC) / ph.previousprice * 100, 2)
        ELSE NULL
    END as pricechangepercentage
FROM productmanagement_dbo.products p
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync (converted)
-- DMS Status: FAILED - Metadata model creation failed
-- Manual Conversion: Applied lowercase schema mapping per DMS schema_mapping_tool
-- Key changes: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> clock_timestamp(),
--   BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT, DECLARE removed (use RETURNING)
-- ============================================================================
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The ProductHistory insert and ProductStats update are handled separately
-- after capturing the returned productid in the application code.

-- ProductHistory insert (part of InsertProductAsync transaction):
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- ProductStats update (part of InsertProductAsync transaction):
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (converted)
-- DMS Status: FAILED - Metadata model creation failed
-- Manual Conversion: Applied lowercase schema mapping per DMS schema_mapping_tool
-- Key changes: GETDATE() -> clock_timestamp(), DECLARE/SELECT INTO -> 
--   subquery or application-level handling
-- ============================================================================
BEGIN;
    -- Store old values for history
    -- In PostgreSQL, use a CTE or handle at application level
    
    -- Update the product
    UPDATE productmanagement_dbo.products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = clock_timestamp()
    WHERE productid = @ProductId;
    
    -- Log the changes
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (converted)
-- DMS Status: FAILED - Metadata model creation failed
-- Manual Conversion: Applied lowercase schema mapping per DMS schema_mapping_tool
-- Key changes: GETDATE() -> clock_timestamp(), BEGIN TRANSACTION -> BEGIN
-- ============================================================================
BEGIN;
    -- Store product info for history (handled at application level with separate SELECT)
    
    -- Log the deletion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());
    
    -- Delete the product
    DELETE FROM productmanagement_dbo.products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (converted)
-- DMS Status: FAILED - Metadata model creation failed
-- Manual Conversion: Applied lowercase schema mapping per DMS schema_mapping_tool
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
-- STATEMENT 7: GetLowStockProductsAsync (converted)
-- DMS Status: FAILED - Metadata model creation failed
-- Manual Conversion: Applied lowercase schema mapping per DMS schema_mapping_tool
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
    ROUND(CAST(stockquantity AS NUMERIC) / avgstock * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
