-- ================================================================
-- Converted SQL Statement Catalog - PostgreSQL
-- ADO.NET SQL Server to PostgreSQL Migration
-- Source: DMS MCP Tool + Manual Conversion
-- Total Statements: 7
-- DMS Successful: 6
-- Manual Conversions: 1 (Statement 3)
-- ================================================================

-- ================================================================
-- Statement ID: 1
-- Method: GetAllProductsAsync()
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- ================================================================
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

-- ================================================================
-- Statement ID: 2
-- Method: GetProductByIdAsync(int productId)
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- ================================================================
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

-- ================================================================
-- Statement ID: 3
-- Method: InsertProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: SUCCESS (Manual)
-- Schema Changes: Products → productmanagement_dbo.products,
--                 ProductHistory → productmanagement_dbo.producthistory,
--                 ProductStats → productmanagement_dbo.productstats
-- Notes: DMS failed on complex multi-statement transaction
--        Manual conversion splits into 3 separate statements
--        Transaction management handled by C# code
-- ================================================================
-- Statement 3a: INSERT with RETURNING (replaces SCOPE_IDENTITY())
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Log the insertion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 3c: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ================================================================
-- Statement ID: 4
-- Method: UpdateProductAsync(Product product)
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS (with warnings about transaction management)
-- Schema Changes: Products → productmanagement_dbo.products,
--                 ProductHistory → productmanagement_dbo.producthistory,
--                 ProductStats → productmanagement_dbo.productstats
-- DMS Warning: [7807 - CRITICAL - PostgreSQL does not support explicit transaction management in functions]
-- Notes: Transaction management handled by C# code
--        Variable declarations converted to PostgreSQL syntax
--        GETDATE() converted to clock_timestamp()
-- ================================================================
-- Variable declarations removed (handled differently in C# context)
-- Transaction BEGIN/COMMIT removed (handled by C# BeginTransactionAsync)

-- Store old values for history
SELECT
    price AS var_OldPrice, stockquantity AS var_OldStock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

-- Update the product
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
    WHERE productid = @ProductId;

-- Log the changes
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;

-- ================================================================
-- Statement ID: 5
-- Method: DeleteProductAsync(int productId)
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS (with warnings about transaction management)
-- Schema Changes: Products → productmanagement_dbo.products,
--                 ProductHistory → productmanagement_dbo.producthistory,
--                 ProductStats → productmanagement_dbo.productstats
-- DMS Warning: [7807 - CRITICAL - PostgreSQL does not support explicit transaction management in functions]
-- Notes: Transaction management handled by C# code
--        GETDATE() converted to clock_timestamp()
-- ================================================================
-- Variable declarations removed (handled differently in C# context)
-- Transaction BEGIN/COMMIT removed (handled by C# BeginTransactionAsync)

-- Store product info for history
SELECT
    price AS var_OldPrice, stockquantity AS var_OldStock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

-- Log the deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Delete the product
DELETE FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
    ELSE 0
END, lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;

-- ================================================================
-- Statement ID: 6
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- ================================================================
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

-- ================================================================
-- Statement ID: 7
-- Method: GetLowStockProductsAsync(int threshold)
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- ================================================================
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

-- ================================================================
-- SCHEMA OBJECT NAME MAPPINGS (Critical for code re-integration)
-- ================================================================
-- SQL Server → PostgreSQL
-- Products → productmanagement_dbo.products
-- ProductHistory → productmanagement_dbo.producthistory
-- ProductStats → productmanagement_dbo.productstats
--
-- All column names converted to lowercase by DMS
-- GETDATE() → CURRENT_TIMESTAMP (or clock_timestamp() in DMS output)
-- SCOPE_IDENTITY() → RETURNING clause
-- Parameters retained @ParamName format (compatible with Npgsql)
-- ================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- ================================================================
