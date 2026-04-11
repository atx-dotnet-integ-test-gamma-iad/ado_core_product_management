-- =============================================================================
-- Converted SQL Statements for PostgreSQL (from MS SQL Server)
-- Target Database: PostgreSQL (ProductManagement)
-- Target Schema: productmanagement_dbo
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
--   Products -> productmanagement_dbo.products (columns all lowercase)
--   ProductHistory -> productmanagement_dbo.producthistory (columns all lowercase)
--   ProductStats -> productmanagement_dbo.productstats (columns all lowercase)
-- =============================================================================

-- ===========================================================================
-- Statement 1: GetAllProductsAsync (Converted)
-- Conversion: Table/column names lowercased per DMS schema mapping
-- CTE name changed from ProductStats to productstats_cte to avoid conflict 
-- with the productstats table
-- ===========================================================================
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

-- ===========================================================================
-- Statement 2: GetProductByIdAsync (Converted)
-- Conversion: Table/column names lowercased per DMS schema mapping
-- CTE name changed from ProductHistory to producthistory_cte to avoid conflict
-- with the producthistory table
-- ===========================================================================
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

-- ===========================================================================
-- Statement 3: InsertProductAsync (Converted)
-- Conversion Notes:
-- - SCOPE_IDENTITY() replaced with INSERT...RETURNING productid
-- - GETDATE() replaced with NOW()
-- - BEGIN TRANSACTION/COMMIT replaced with BEGIN/COMMIT
-- - DECLARE @var pattern removed (handled in C# code with separate commands)
-- - Transaction block split into separate commands managed by C# code
-- ===========================================================================
-- Command 3a: Insert product and return new ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Command 3b: Log the insertion (uses the productid returned from 3a)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Command 3c: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ===========================================================================
-- Statement 4: UpdateProductAsync (Converted)
-- Conversion Notes:
-- - DECLARE @var pattern removed (handled in C# code with separate commands)
-- - GETDATE() replaced with NOW()
-- - BEGIN TRANSACTION/COMMIT managed by C# code
-- - SELECT INTO variables replaced with C# reader for old values
-- ===========================================================================
-- Command 4a: Get old values (executed via C# reader)
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Command 4b: Update the product
UPDATE productmanagement_dbo.products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- Command 4c: Log the changes
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Command 4d: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ===========================================================================
-- Statement 5: DeleteProductAsync (Converted)
-- Conversion Notes:
-- - DECLARE @var pattern removed (handled in C# code with separate commands)
-- - GETDATE() replaced with NOW()
-- - BEGIN TRANSACTION/COMMIT managed by C# code
-- - SELECT INTO variables replaced with C# reader for old values
-- ===========================================================================
-- Command 5a: Get old values (executed via C# reader)
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Command 5b: Log the deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Command 5c: Delete the product
DELETE FROM productmanagement_dbo.products 
WHERE productid = @ProductId;

-- Command 5d: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = NOW()
WHERE statid = 1;

-- ===========================================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted)
-- Conversion: Table/column names lowercased per DMS schema mapping
-- ===========================================================================
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

-- ===========================================================================
-- Statement 7: GetLowStockProductsAsync (Converted)
-- Conversion: Table/column names lowercased per DMS schema mapping
-- Added ::numeric cast for integer division
-- ===========================================================================
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
