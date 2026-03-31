-- ============================================================================
-- Converted SQL Statements - PostgreSQL equivalents
-- Migration: MS SQL Server to PostgreSQL
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation/conversion did not complete after 15 attempts
-- DMS Retry Attempts: 2 full passes (all 7 statements attempted each time)
-- DMS Last Attempt: 2026-03-31T10:34:39 - 2026-03-31T10:37:14 (all 7 failed)
-- Schema Mapping Source: DMS schema_mapping_tool (successfully retrieved)
--   dbo.Products -> productmanagement_dbo.products
--   dbo.ProductHistory -> productmanagement_dbo.producthistory
--   dbo.ProductStats -> productmanagement_dbo.productstats
-- Total Statements: 7
-- ============================================================================

-- ===========================================================================
-- Statement 1: GetAllProductsAsync (CONVERTED)
-- Original: MS SQL with CTE named ProductStats, AVG/COUNT OVER(), CASE, ROUND, INNER JOIN
-- Conversion Notes: 
--   - Table: Products -> productmanagement_dbo.products
--   - Columns: all lowercase
--   - CTE renamed to productstats_cte to avoid confusion with productstats table
--   - ROUND function compatible with PostgreSQL
-- ===========================================================================
-- ORIGINAL MS SQL:
-- WITH ProductStats AS (
--     SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts
--     FROM Products
-- )
-- SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate,
--     p.ModifiedDate, CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average' ... END as PriceCategory,
--     ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
-- FROM Products p INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
-- ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name
--
-- CONVERTED PostgreSQL:
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
-- Statement 2: GetProductByIdAsync (CONVERTED)
-- Original: MS SQL with CTE, LAG() window function, CASE/WHEN, ROUND, LEFT JOIN
-- Conversion Notes:
--   - Table: Products -> productmanagement_dbo.products
--   - CTE renamed to producthistory_cte to avoid confusion with producthistory table
--   - LAG() window function compatible with PostgreSQL
--   - Parameter @ProductId kept as-is for Npgsql compatibility
-- ===========================================================================
-- ORIGINAL MS SQL:
-- WITH ProductHistory AS (
--     SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice, ...
--     FROM Products WHERE ProductId = @ProductId
-- )
-- SELECT p.ProductId, ... FROM Products p LEFT JOIN ProductHistory ph ...
--
-- CONVERTED PostgreSQL:
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
-- Statement 3: InsertProductAsync (CONVERTED)
-- Original: Complex T-SQL with DECLARE, BEGIN TRANSACTION, SCOPE_IDENTITY(), GETDATE()
-- Conversion Notes:
--   - SCOPE_IDENTITY() -> RETURNING productid (PostgreSQL INSERT ... RETURNING)
--   - GETDATE() -> NOW()
--   - T-SQL transaction block split into individual statements for C# transaction handling
--   - Tables: Products->productmanagement_dbo.products, ProductHistory->productmanagement_dbo.producthistory,
--             ProductStats->productmanagement_dbo.productstats
-- ===========================================================================
-- ORIGINAL MS SQL:
-- DECLARE @NewProductId INT;
-- BEGIN TRANSACTION;
--     INSERT INTO Products ... SET @NewProductId = SCOPE_IDENTITY();
--     INSERT INTO ProductHistory ... GETDATE();
--     UPDATE ProductStats ... GETDATE();
-- COMMIT;
-- SELECT @NewProductId;
--
-- CONVERTED PostgreSQL (split into separate commands for C# NpgsqlTransaction):
-- Command 1: Insert product and get new ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;
-- Command 2: Insert history (use retrieved productid)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
-- Command 3: Update stats
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ===========================================================================
-- Statement 4: UpdateProductAsync (CONVERTED)
-- Original: Complex T-SQL with BEGIN TRANSACTION, DECLARE, SELECT INTO variables,
--           UPDATE, INSERT, GETDATE()
-- Conversion Notes:
--   - DECLARE @var / SELECT @var = ... -> Separate SELECT command to get old values in C#
--   - GETDATE() -> NOW()
--   - T-SQL transaction block split into individual statements for C# transaction handling
-- ===========================================================================
-- ORIGINAL MS SQL:
-- BEGIN TRANSACTION;
--     DECLARE @OldPrice ...; SELECT @OldPrice = Price, @OldStock = StockQuantity ...
--     UPDATE Products SET ... GETDATE(); INSERT INTO ProductHistory ...;
--     UPDATE ProductStats ...; COMMIT;
--
-- CONVERTED PostgreSQL (split into separate commands for C# NpgsqlTransaction):
-- Command 1: Get old values
SELECT price, stockquantity FROM productmanagement_dbo.products WHERE productid = @ProductId;
-- Command 2: Update product
UPDATE productmanagement_dbo.products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;
-- Command 3: Insert history
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());
-- Command 4: Update stats
UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ===========================================================================
-- Statement 5: DeleteProductAsync (CONVERTED)
-- Original: Complex T-SQL with BEGIN TRANSACTION, DECLARE, SELECT INTO variables,
--           INSERT history, DELETE, UPDATE stats with CASE/WHEN, GETDATE()
-- Conversion Notes:
--   - Same pattern as Update: split into separate commands
--   - GETDATE() -> NOW()
--   - CASE/WHEN compatible with PostgreSQL
-- ===========================================================================
-- ORIGINAL MS SQL:
-- BEGIN TRANSACTION;
--     DECLARE @OldPrice ...; SELECT @OldPrice = Price, @OldStock = StockQuantity ...
--     INSERT INTO ProductHistory ...; DELETE FROM Products ...;
--     UPDATE ProductStats SET ... CASE WHEN TotalProducts > 1 THEN ... END ...;
-- COMMIT;
--
-- CONVERTED PostgreSQL (split into separate commands for C# NpgsqlTransaction):
-- Command 1: Get old values
SELECT price, stockquantity FROM productmanagement_dbo.products WHERE productid = @ProductId;
-- Command 2: Insert history
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());
-- Command 3: Delete product
DELETE FROM productmanagement_dbo.products WHERE productid = @ProductId;
-- Command 4: Update stats
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
-- Statement 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Original: MS SQL with CTE, RANK(), PERCENT_RANK() window functions, BETWEEN, CASE/WHEN
-- Conversion Notes:
--   - Table: Products -> productmanagement_dbo.products
--   - All columns lowercase
--   - RANK(), PERCENT_RANK(), BETWEEN all compatible with PostgreSQL
-- ===========================================================================
-- ORIGINAL MS SQL:
-- WITH RankedProducts AS (
--     SELECT p.*, RANK() OVER (...), PERCENT_RANK() OVER (...)
--     FROM Products p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
-- )
-- SELECT rp.*, CASE ... END as PriceSegment FROM RankedProducts rp ORDER BY rp.PriceRank
--
-- CONVERTED PostgreSQL:
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
-- Statement 7: GetLowStockProductsAsync (CONVERTED)
-- Original: MS SQL with CTE, AVG/MIN/MAX window functions, CASE/WHEN, ROUND
-- Conversion Notes:
--   - Table: Products -> productmanagement_dbo.products
--   - All columns lowercase
--   - Added CAST(stockquantity AS NUMERIC) for integer division fix in PostgreSQL
--     (SQL Server does implicit decimal conversion, PostgreSQL integer division truncates)
-- ===========================================================================
-- ORIGINAL MS SQL:
-- WITH StockAnalysis AS (
--     SELECT p.*, AVG(StockQuantity) OVER() ..., MIN(...), MAX(...)
--     FROM Products p
-- )
-- SELECT sa.*, CASE ... END as StockStatus,
--     ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
-- FROM StockAnalysis sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity
--
-- CONVERTED PostgreSQL:
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
