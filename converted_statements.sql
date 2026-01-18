-- ============================================================================
-- Converted SQL Statements - PostgreSQL
-- Microsoft SQL Server to PostgreSQL Migration
-- Total Statements: 7
-- Successfully Converted by DMS: 5
-- Manually Converted After DMS Failure: 2
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (DMS CONVERTED)
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products
-- Column Changes: All identifiers lowercased
-- Other Changes: Added NULLS FIRST to ORDER BY clauses
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
-- Statement 2: GetProductByIdAsync (DMS CONVERTED)
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products
-- Column Changes: All identifiers lowercased
-- Other Changes: LAG function preserved, LEFT JOIN → LEFT OUTER JOIN
-- Parameter: @ProductId remains unchanged
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
-- Statement 3: InsertProductAsync (DMS CONVERTED - Core DML)
-- Conversion Method: DMS_TOOL (with manual transaction wrapper)
-- Schema Changes: Products → productmanagement_dbo.products, 
--                ProductHistory → productmanagement_dbo.producthistory,
--                ProductStats → productmanagement_dbo.productstats
-- Column Changes: All identifiers lowercased
-- TSQL Changes: GETDATE() → clock_timestamp()
-- Note: DMS failed on full transaction block, converted inner DML only
-- Transaction handling must be done in application code layer
-- Parameters: @Name, @Description, @Price, @StockQuantity, @NewProductId
-- ============================================================================
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity) RETURNING productid;

INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts + 1, averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1), lastupdated = clock_timestamp()
    WHERE statid = 1;

-- ============================================================================
-- Statement 4: UpdateProductAsync (DMS CONVERTED)
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products,
--                ProductHistory → productmanagement_dbo.producthistory,
--                ProductStats → productmanagement_dbo.productstats
-- Column Changes: All identifiers lowercased
-- TSQL Changes: GETDATE() → clock_timestamp()
--              @Variable → var_Variable for declared variables
--              BEGIN TRANSACTION/COMMIT removed, replaced with BEGIN/END block
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity, @OldPrice, @OldStock
-- ============================================================================
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
END;

-- ============================================================================
-- Statement 5: DeleteProductAsync (DMS CONVERTED)
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products,
--                ProductHistory → productmanagement_dbo.producthistory,
--                ProductStats → productmanagement_dbo.productstats
-- Column Changes: All identifiers lowercased
-- TSQL Changes: GETDATE() → clock_timestamp()
--              @Variable → var_Variable for declared variables
--              BEGIN TRANSACTION/COMMIT removed, replaced with BEGIN/END block
-- Parameters: @ProductId, @OldPrice, @OldStock
-- ============================================================================
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
END;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (MANUAL CONVERSION)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model conversion did not complete after 15 attempts (timeout)
-- Schema Changes: Products → productmanagement_dbo.products (following DMS pattern)
-- Column Changes: All identifiers lowercased (following DMS pattern)
-- Window Functions: RANK() and PERCENT_RANK() are PostgreSQL native, preserved
-- Parameters: @MinPrice, @MaxPrice
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
ORDER BY rp.pricerank NULLS FIRST;

-- ============================================================================
-- Statement 7: GetLowStockProductsAsync (MANUAL CONVERSION)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Command execution timed out after 300 seconds
-- Schema Changes: Products → productmanagement_dbo.products (following DMS pattern)
-- Column Changes: All identifiers lowercased (following DMS pattern)
-- Window Functions: AVG/MIN/MAX OVER() are PostgreSQL native, preserved
-- Parameter: @Threshold
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
    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity NULLS FIRST;

-- ============================================================================
-- End of Converted SQL Statements
-- ============================================================================
