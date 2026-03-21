-- ============================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Source: DataAccess/ProductRepository.cs
-- Date: 2026-03-21
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion failed: Metadata model conversion did not complete after 15 attempts
-- Note: DMS MCP tool was attempted for all statements but consistently failed.
--       Manual conversion applied lowercase schema object naming convention with
--       productmanagement_dbo schema prefix (matching existing PostgreSQL schema).
-- ============================================================

-- ============================================================
-- STATEMENT 1: GetAllProductsAsync (DMS FAILED - Manual Conversion)
-- Original MS SQL: Uses dbo.Products with PascalCase
-- Converted PostgreSQL: Uses productmanagement_dbo.products with lowercase
-- ============================================================
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

-- ============================================================
-- STATEMENT 2: GetProductByIdAsync (DMS FAILED - Manual Conversion)
-- Original MS SQL: Uses dbo.Products with PascalCase and LAG
-- Converted PostgreSQL: Uses productmanagement_dbo.products with lowercase and lag
-- ============================================================
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

-- ============================================================
-- STATEMENT 3: InsertProductAsync (DMS FAILED - Manual Conversion)
-- Original MS SQL: Uses SCOPE_IDENTITY(), GETDATE(), dbo schema
-- Converted PostgreSQL: Uses DO $$ block with RETURNING, NOW(), currval(), productmanagement_dbo schema
-- ============================================================
DO $$
DECLARE
    var_NewProductId INTEGER;
BEGIN
    -- Insert the new product
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO var_NewProductId;

    -- Log the insertion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (var_NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

SELECT currval(pg_get_serial_sequence('productmanagement_dbo.products', 'productid'));

-- ============================================================
-- STATEMENT 4: UpdateProductAsync (DMS FAILED - Manual Conversion)
-- Original MS SQL: Uses GETDATE(), dbo schema, variable assignment with SELECT @var = col
-- Converted PostgreSQL: Uses clock_timestamp(), productmanagement_dbo schema, SELECT INTO
-- ============================================================
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store old values for history */
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update the product */
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId;
    /* Log the changes */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', var_OldPrice, @Price, var_OldStock, @StockQuantity, clock_timestamp());
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - var_OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
        WHERE statid = 1;
END $$;

-- ============================================================
-- STATEMENT 5: DeleteProductAsync (DMS FAILED - Manual Conversion)
-- Original MS SQL: Uses GETDATE(), dbo schema, variable assignment
-- Converted PostgreSQL: Uses clock_timestamp(), productmanagement_dbo schema, SELECT INTO
-- ============================================================
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store product info for history */
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Log the deletion */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', var_OldPrice, NULL, var_OldStock, NULL, clock_timestamp());
    /* Delete the product */
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - var_OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = clock_timestamp()
        WHERE statid = 1;
END $$;

-- ============================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (DMS FAILED - Manual Conversion)
-- Original MS SQL: Uses dbo.Products with PascalCase, RANK, PERCENT_RANK
-- Converted PostgreSQL: Uses productmanagement_dbo.products with lowercase
-- ============================================================
WITH rankedproducts
AS (SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products AS p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice)
SELECT
    rp.productid, rp.name, rp.description, rp.price, rp.stockquantity, rp.createddate, rp.modifieddate, rp.pricerank, rp.pricepercentile,
    CASE
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS pricesegment
    FROM rankedproducts AS rp
    ORDER BY rp.pricerank NULLS FIRST;

-- ============================================================
-- STATEMENT 7: GetLowStockProductsAsync (DMS FAILED - Manual Conversion)
-- Original MS SQL: Uses dbo.Products with PascalCase, AVG/MIN/MAX OVER
-- Converted PostgreSQL: Uses productmanagement_dbo.products with lowercase
-- ============================================================
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

-- ============================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total: 7 SQL statements converted
-- Conversion Method: All 7 via DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Attempts: 3 total attempts (all failed with timeout errors)
-- ============================================================
