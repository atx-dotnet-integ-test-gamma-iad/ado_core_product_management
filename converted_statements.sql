-- ======================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source File: ProductRepository.cs
-- Total Statements: 7
-- Database: PostgreSQL (Target)
-- Conversion Date: 2024-12-30
-- DMS Tool: Used for all 7 statements
-- Schema Transformation: Products → productmanagement_dbo.products
-- ======================================================================

-- ======================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED - DMS TOOL SUCCESS)
-- Method: GetAllProductsAsync()
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products
-- Notes: Window functions and CTE converted successfully, NULLS FIRST added to ORDER BY
-- ======================================================================
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

-- ======================================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED - DMS TOOL SUCCESS)
-- Method: GetProductByIdAsync(int productId)
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products
-- Notes: LAG window function and LEFT JOIN converted successfully
-- ======================================================================
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

-- ======================================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED - MANUAL AFTER DMS FAILURE)
-- Method: InsertProductAsync(Product product)
-- Conversion Status: DMS FAILURE - Manual Conversion Applied
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- DMS Error: "Statement definition is not valid" - DMS unable to process DECLARE/BEGIN TRANSACTION/SCOPE_IDENTITY/SELECT pattern
-- Manual Conversion Notes: 
--   - SCOPE_IDENTITY() → RETURNING clause in INSERT
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Transaction management removed from SQL (handled at ADO.NET level)
--   - Variable declarations removed, using RETURNING to get new ID
-- ======================================================================
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (currval(pg_get_serial_sequence('productmanagement_dbo.products', 'productid')), 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ======================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED - DMS TOOL SUCCESS WITH WARNING)
-- Method: UpdateProductAsync(Product product)
-- Conversion Status: SUCCESS WITH WARNING
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- DMS Warning: [7807 - CRITICAL] PostgreSQL does not support explicit transaction management in functions
-- Notes: GETDATE() → clock_timestamp(), transaction blocks need ADO.NET handling
-- ======================================================================
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
        WHERE statid = 1;
    COMMIT;
END;

-- ======================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED - DMS TOOL SUCCESS WITH WARNING)
-- Method: DeleteProductAsync(int productId)
-- Conversion Status: SUCCESS WITH WARNING
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- DMS Warning: [7807 - CRITICAL] PostgreSQL does not support explicit transaction management in functions
-- Notes: GETDATE() → clock_timestamp(), transaction blocks need ADO.NET handling
-- ======================================================================
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = clock_timestamp()
        WHERE statid = 1;
    COMMIT;
END;

-- ======================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED - DMS TOOL SUCCESS)
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products
-- Notes: RANK and PERCENT_RANK window functions converted successfully, NULLS FIRST added
-- ======================================================================
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

-- ======================================================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED - DMS TOOL SUCCESS)
-- Method: GetLowStockProductsAsync(int threshold)
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products
-- Notes: AVG/MIN/MAX window functions converted successfully, NULLS FIRST added
-- ======================================================================
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

-- ======================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total SQL Statements Converted: 7
-- DMS Tool Success: 6 statements
-- Manual Conversion After DMS Failure: 1 statement (InsertProductAsync)
-- Schema Object Transformations: Products → productmanagement_dbo.products
-- ======================================================================
