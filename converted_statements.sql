-- =====================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- Source: Microsoft SQL Server ADO.NET Application
-- Target: PostgreSQL Database
-- Conversion Date: 2026-02-23
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- =====================================================================
-- NOTE: All statements failed DMS MCP tool conversion due to metadata
-- model creation errors. Manual conversions applied following lowercase
-- schema mapping rules as specified in transformation definition.
-- =====================================================================

-- =====================================================================
-- STATEMENT GROUP 1: GetAllProductsAsync
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Lines: 38-72
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- =====================================================================

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
    p.name

-- =====================================================================
-- STATEMENT GROUP 2: GetProductByIdAsync
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Lines: 84-112
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Parameters: $1 = productId (INT)
-- =====================================================================

WITH producthistory AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = $1
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
WHERE p.productid = $1

-- =====================================================================
-- STATEMENT GROUP 3: InsertProductAsync
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Lines: 126-149
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Parameters: $1 = name, $2 = description, $3 = price, $4 = stockquantity
-- NOTE: Converted to use RETURNING clause instead of SCOPE_IDENTITY()
-- =====================================================================

-- Insert the new product and get the ID
INSERT INTO products (name, description, price, stockquantity)
VALUES ($1, $2, $3, $4)
RETURNING productid;

-- Note: The following statements need to be executed separately in a transaction:
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (<returned_productid>, 'INSERT', NULL, $3, NULL, $4, CURRENT_TIMESTAMP);
-- 
-- UPDATE productstats
-- SET 
--     totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + $3) / (totalproducts + 1),
--     lastupdated = CURRENT_TIMESTAMP
-- WHERE statid = 1;

-- =====================================================================
-- STATEMENT GROUP 4: UpdateProductAsync
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Lines: 163-195
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Parameters: $1 = productId, $2 = name, $3 = description, $4 = price, $5 = stockquantity
-- NOTE: Multi-statement transaction - execute within a transaction block
-- =====================================================================

-- Store old values for history (first query)
SELECT price, stockquantity
FROM products
WHERE productid = $1;

-- Update the product (second query - use old values from first query)
UPDATE products
SET 
    name = $2,
    description = $3,
    price = $4,
    stockquantity = $5,
    modifieddate = CURRENT_TIMESTAMP
WHERE productid = $1;

-- Log the changes (third query - use old values from first query)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES ($1, 'UPDATE', <old_price>, $4, <old_stock>, $5, CURRENT_TIMESTAMP);

-- Update product statistics (fourth query - use old values from first query)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - <old_price> + $4) / totalproducts,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- =====================================================================
-- STATEMENT GROUP 5: DeleteProductAsync
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Lines: 209-243
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Parameters: $1 = productId
-- NOTE: Multi-statement transaction - execute within a transaction block
-- =====================================================================

-- Store product info for history (first query)
SELECT price, stockquantity
FROM products
WHERE productid = $1;

-- Log the deletion (second query - use old values from first query)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES ($1, 'DELETE', <old_price>, NULL, <old_stock>, NULL, CURRENT_TIMESTAMP);

-- Delete the product (third query)
DELETE FROM products 
WHERE productid = $1;

-- Update product statistics (fourth query - use old values from first query)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - <old_price>) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- =====================================================================
-- STATEMENT GROUP 6: GetProductsByPriceRangeAsync
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Lines: 257-279
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Parameters: $1 = minPrice, $2 = maxPrice
-- =====================================================================

WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN $1 AND $2
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as pricesegment
FROM rankedproducts rp
ORDER BY rp.pricerank

-- =====================================================================
-- STATEMENT GROUP 7: GetLowStockProductsAsync
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Lines: 293-320
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Parameters: $1 = threshold
-- =====================================================================

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
        WHEN stockquantity <= $1 THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= $1
ORDER BY stockquantity

-- =====================================================================
-- END OF CONVERTED SQL STATEMENTS
-- Total Statement Groups: 7
-- All conversions: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- =====================================================================
