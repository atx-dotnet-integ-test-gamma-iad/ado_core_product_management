-- ============================================================================
-- Converted PostgreSQL Statements
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mapping Source: DMS schema_mapping_tool
--   Products -> productmanagement_dbo.products
--   ProductHistory -> productmanagement_dbo.producthistory
--   ProductStats -> productmanagement_dbo.productstats
-- Conversion Date: 2026-04-15
-- ============================================================================

-- ==========================================================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Conversions applied:
--   - Table: Products -> productmanagement_dbo.products
--   - Column names lowercased
--   - CTE name changed to avoid conflict with table name (productstats_cte)
--   - ROUND function compatible as-is
--   - CASE expressions compatible as-is
--   - Window functions (AVG OVER, COUNT OVER) compatible as-is
-- ==========================================================================
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

-- ==========================================================================
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Conversions applied:
--   - Table: Products -> productmanagement_dbo.products
--   - Column names lowercased
--   - CTE name changed to avoid conflict (producthistory_cte)
--   - LAG window functions compatible as-is
--   - @ProductId parameter kept (Npgsql supports @-prefixed params)
-- ==========================================================================
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

-- ==========================================================================
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Conversions applied:
--   - Tables: Products -> productmanagement_dbo.products,
--             ProductHistory -> productmanagement_dbo.producthistory,
--             ProductStats -> productmanagement_dbo.productstats
--   - Column names lowercased
--   - SCOPE_IDENTITY() -> RETURNING productid
--   - GETDATE() -> clock_timestamp()
--   - BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT (handled by Npgsql)
--   - DECLARE/SET removed, uses RETURNING INTO pattern
--   - For ADO.NET: restructured as individual statements executed in C# transaction
-- ==========================================================================
-- Note: This transaction block is restructured for Npgsql ADO.NET execution.
-- The C# code will manage the transaction and use RETURNING clause.

-- Sub-statement 3a: Insert product and get new ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Sub-statement 3b: Log the insertion (executed after getting newProductId)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- Sub-statement 3c: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ==========================================================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Conversions applied:
--   - Tables lowercased with schema prefix
--   - Column names lowercased
--   - GETDATE() -> clock_timestamp()
--   - DECLARE/SET removed, restructured for C# ADO.NET transaction
--   - SELECT INTO variables -> separate SELECT + C# variable handling
-- ==========================================================================
-- Note: This transaction block is restructured for Npgsql ADO.NET execution.
-- The C# code will manage the transaction and variables.

-- Sub-statement 4a: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Sub-statement 4b: Update the product
UPDATE productmanagement_dbo.products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

-- Sub-statement 4c: Log the changes
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- Sub-statement 4d: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ==========================================================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Conversions applied:
--   - Tables lowercased with schema prefix
--   - Column names lowercased
--   - GETDATE() -> clock_timestamp()
--   - DECLARE/SET removed, restructured for C# ADO.NET transaction
--   - CASE expression compatible as-is
-- ==========================================================================
-- Note: This transaction block is restructured for Npgsql ADO.NET execution.

-- Sub-statement 5a: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Sub-statement 5b: Log the deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- Sub-statement 5c: Delete the product
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Sub-statement 5d: Update product statistics
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

-- ==========================================================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Conversions applied:
--   - Table: Products -> productmanagement_dbo.products
--   - Column names lowercased
--   - RANK(), PERCENT_RANK() window functions compatible as-is
--   - BETWEEN compatible as-is
--   - CASE expressions compatible as-is
-- ==========================================================================
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

-- ==========================================================================
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Conversions applied:
--   - Table: Products -> productmanagement_dbo.products
--   - Column names lowercased
--   - AVG/MIN/MAX window functions compatible as-is
--   - CASE expressions compatible as-is
--   - ROUND with integer division: added CAST to NUMERIC for proper division
-- ==========================================================================
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
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
