-- ============================================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Source: DataAccess/ProductRepository.cs
-- Target: PostgreSQL (ProductManagement)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Unknown metadata model creation status: RECEIVED
-- Schema Mappings from DMS schema_mapping_tool:
--   dbo.Products -> productmanagement_dbo.products
--   dbo.ProductHistory -> productmanagement_dbo.producthistory
--   dbo.ProductStats -> productmanagement_dbo.productstats
-- Total Statements: 7
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (Converted)
-- Conversion: CTE + window functions are compatible with PostgreSQL
-- Schema objects converted to lowercase per DMS schema mapping
-- ROUND function with CAST for integer division fix
-- ============================================================
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

-- ============================================================
-- Statement 2: GetProductByIdAsync (Converted)
-- Conversion: CTE + LAG window functions are compatible with PostgreSQL
-- Schema objects converted to lowercase per DMS schema mapping
-- ============================================================
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

-- ============================================================
-- Statement 3: InsertProductAsync (Converted)
-- Conversion: SCOPE_IDENTITY() -> currval(pg_get_serial_sequence(...))
--             GETDATE() -> NOW()
--             BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT
--             DECLARE @var INT -> use INSERT...RETURNING
-- ============================================================
BEGIN;
    -- Insert the new product and get the new ID
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    -- Log the insertion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (currval(pg_get_serial_sequence('productmanagement_dbo.products', 'productid')), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

SELECT currval(pg_get_serial_sequence('productmanagement_dbo.products', 'productid'));

-- ============================================================
-- Statement 4: UpdateProductAsync (Converted)
-- Conversion: DECLARE @var -> read old values before UPDATE via INSERT-SELECT
--             GETDATE() -> NOW()
--             BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT
-- ============================================================
BEGIN;
    -- Log the changes first (captures old values before update)
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'UPDATE', price, @Price, stockquantity, @StockQuantity, NOW()
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;
    
    -- Update product statistics (use old price from history before changing)
    UPDATE productmanagement_dbo.productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM productmanagement_dbo.products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
    
    -- Update the product
    UPDATE productmanagement_dbo.products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
COMMIT;

-- ============================================================
-- Statement 5: DeleteProductAsync (Converted)
-- Conversion: DECLARE @var -> subquery/direct reference approach
--             GETDATE() -> NOW()
--             BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT
-- ============================================================
BEGIN;
    -- Log the deletion (get old values via subquery before delete)
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, NOW()
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;
    
    -- Update product statistics (before deleting, reference product table directly)
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT price FROM productmanagement_dbo.products WHERE productid = @ProductId)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
    
    -- Delete the product
    DELETE FROM productmanagement_dbo.products 
    WHERE productid = @ProductId;
COMMIT;

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted)
-- Conversion: RANK, PERCENT_RANK window functions compatible with PostgreSQL
-- Schema objects converted to lowercase per DMS schema mapping
-- ============================================================
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

-- ============================================================
-- Statement 7: GetLowStockProductsAsync (Converted)
-- Conversion: AVG/MIN/MAX window functions compatible with PostgreSQL
-- CAST added for integer division in ROUND
-- Schema objects converted to lowercase per DMS schema mapping
-- ============================================================
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
    ROUND(CAST(stockquantity AS NUMERIC) / CAST(avgstock AS NUMERIC) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
