-- ============================================================================
-- Converted SQL Statements Catalog
-- Source: Microsoft SQL Server -> PostgreSQL via DMS MCP Tool
-- Generated: 2026-01-04
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions
-- Source Method: GetAllProductsAsync
-- Conversion Status: SUCCESS (DMS Tool)
-- Schema Conversion: Products -> productmanagement_dbo.products
-- ============================================================================

WITH productstats
AS (SELECT
    productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM productmanagement_dbo.products)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END AS pricecategory, ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
    FROM productmanagement_dbo.products AS p
    INNER JOIN productstats AS ps
        ON p.productid = ps.productid
    ORDER BY
    CASE
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END NULLS FIRST, p.name NULLS FIRST;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- Source Method: GetProductByIdAsync
-- Conversion Status: SUCCESS (DMS Tool)
-- Schema Conversion: Products -> productmanagement_dbo.products
-- ============================================================================

WITH producthistory
AS (SELECT
    productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE
        WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END AS pricechangepercentage
    FROM productmanagement_dbo.products AS p
    LEFT OUTER JOIN producthistory AS ph
        ON p.productid = ph.productid
    WHERE p.productid = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction Block
-- Source Method: InsertProductAsync
-- Conversion Status: MANUAL (DMS Tool Failed - Statement definition not valid)
-- Schema Conversion: Products -> productmanagement_dbo.products
--                    ProductHistory -> productmanagement_dbo.producthistory
--                    ProductStats -> productmanagement_dbo.productstats
-- Notes: Transaction syntax converted, SCOPE_IDENTITY() replaced with RETURNING,
--        GETDATE() replaced with CURRENT_TIMESTAMP
-- ============================================================================

INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- History logging (to be executed after INSERT with returned productid)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction Block
-- Source Method: UpdateProductAsync
-- Conversion Status: MANUAL (DMS Tool Failed - Complex transaction block)
-- Schema Conversion: Products -> productmanagement_dbo.products
--                    ProductHistory -> productmanagement_dbo.producthistory
--                    ProductStats -> productmanagement_dbo.productstats
-- Notes: Variable declarations moved to application code, GETDATE() replaced
--        with CURRENT_TIMESTAMP
-- ============================================================================

-- Get old values (to be executed first in application code)
-- SELECT price, stockquantity FROM productmanagement_dbo.products WHERE productid = @ProductId;

-- Update the product
UPDATE productmanagement_dbo.products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Log the changes
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction Block
-- Source Method: DeleteProductAsync
-- Conversion Status: MANUAL (DMS Tool Failed - Complex transaction block)
-- Schema Conversion: Products -> productmanagement_dbo.products
--                    ProductHistory -> productmanagement_dbo.producthistory
--                    ProductStats -> productmanagement_dbo.productstats
-- Notes: Variable declarations moved to application code, GETDATE() replaced
--        with CURRENT_TIMESTAMP
-- ============================================================================

-- Get old values (to be executed first in application code)
-- SELECT price, stockquantity FROM productmanagement_dbo.products WHERE productid = @ProductId;

-- Log the deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

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
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- Source Method: GetProductsByPriceRangeAsync
-- Conversion Status: SUCCESS (DMS Tool)
-- Schema Conversion: Products -> productmanagement_dbo.products
-- ============================================================================

WITH rankedproducts
AS (SELECT
    p.*, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products AS p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice)
SELECT
    rp.*,
    CASE
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS pricesegment
    FROM rankedproducts AS rp
    ORDER BY rp.pricerank NULLS FIRST;

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Aggregate Window Functions
-- Source Method: GetLowStockProductsAsync
-- Conversion Status: SUCCESS (DMS Tool)
-- Schema Conversion: Products -> productmanagement_dbo.products
-- ============================================================================

WITH stockanalysis
AS (SELECT
    p.*, AVG(stockquantity) OVER () AS avgstock, MIN(stockquantity) OVER () AS minstock, MAX(stockquantity) OVER () AS maxstock
    FROM productmanagement_dbo.products AS p)
SELECT
    sa.*,
    CASE
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS stockstatus, ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage
    FROM stockanalysis AS sa
    WHERE stockquantity <= @Threshold
    ORDER BY stockquantity NULLS FIRST;

-- ============================================================================
-- END OF CONVERSION CATALOG
-- Total Statements: 7
-- - Successfully converted by DMS: 4 (Statements 1, 2, 6, 7)
-- - Manually converted after DMS failure: 3 (Statements 3, 4, 5)
-- - Schema Changes: All table references updated to productmanagement_dbo schema
-- ============================================================================
