-- ============================================================
-- Converted PostgreSQL Statements from ProductRepository.cs
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Schema Mapping Source: DMS Schema Mapping Tool (productmanagement_dbo)
-- Note: DMS statement_conversion_tool failed with timeout errors.
--       Schema object names derived from DMS schema_mapping_tool results.
--       All table/column names converted to lowercase per DMS schema mapping.
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (converted)
-- Original constructs: CTE, AVG() OVER(), COUNT() OVER(), CASE, ROUND, INNER JOIN
-- Conversion notes: 
--   - CTE name changed from ProductStats to productstats_cte to avoid conflict with productstats table
--   - All column/table names lowercased per DMS schema mapping
--   - ROUND and CASE syntax compatible with PostgreSQL
-- ============================================================
WITH productstats_cte AS (
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
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================================
-- Statement 2: GetProductByIdAsync (converted)
-- Original constructs: CTE, LAG() OVER(), parameterized, LEFT JOIN, CASE with NULL
-- Conversion notes:
--   - CTE name changed from ProductHistory to producthistory_cte to avoid conflict with producthistory table
--   - LAG window function syntax identical in PostgreSQL
--   - All column/table names lowercased per DMS schema mapping
--   - @ProductId parameter preserved for ADO.NET parameterization
-- ============================================================
WITH producthistory_cte AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
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
FROM products p
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================================
-- Statement 3: InsertProductAsync (converted)
-- Original constructs: DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(), GETDATE()
-- Conversion notes:
--   - SCOPE_IDENTITY() replaced with INSERT...RETURNING productid
--   - GETDATE() replaced with clock_timestamp() (per DMS schema mapping defaults)
--   - BEGIN TRANSACTION/COMMIT replaced with PostgreSQL DO block
--   - DECLARE @NewProductId INT replaced with PostgreSQL variable declaration
--   - All column/table names lowercased per DMS schema mapping
-- ============================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The ProductHistory insert and ProductStats update must be handled
-- as separate commands in the C# code since PostgreSQL's RETURNING clause
-- returns the new ID directly. The transaction is handled by Npgsql in code.

-- ============================================================
-- Statement 4: UpdateProductAsync (converted)
-- Original constructs: BEGIN TRANSACTION, DECLARE, SELECT into vars, UPDATE, GETDATE()
-- Conversion notes:
--   - GETDATE() replaced with clock_timestamp()
--   - Transaction handling moved to C# code (Npgsql BeginTransaction)
--   - DECLARE/SELECT into variables pattern requires DO block or separate queries
--   - All column/table names lowercased per DMS schema mapping
-- ============================================================
-- (Implemented as multi-statement in C# with transaction handling)
-- Select old values:
SELECT price, stockquantity FROM products WHERE productid = @ProductId;
-- Update product:
UPDATE products SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp() WHERE productid = @ProductId;
-- Insert history:
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());
-- Update stats:
UPDATE productstats SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp() WHERE statid = 1;

-- ============================================================
-- Statement 5: DeleteProductAsync (converted)
-- Original constructs: BEGIN TRANSACTION, DECLARE, DELETE, CASE, GETDATE()
-- Conversion notes:
--   - GETDATE() replaced with clock_timestamp()
--   - Transaction handling moved to C# code
--   - All column/table names lowercased per DMS schema mapping
-- ============================================================
-- (Implemented as multi-statement in C# with transaction handling)
-- Select old values:
SELECT price, stockquantity FROM products WHERE productid = @ProductId;
-- Insert history:
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());
-- Delete product:
DELETE FROM products WHERE productid = @ProductId;
-- Update stats:
UPDATE productstats SET totalproducts = totalproducts - 1, averageprice = CASE WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1) ELSE 0 END, lastupdated = clock_timestamp() WHERE statid = 1;

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync (converted)
-- Original constructs: CTE, RANK() OVER(), PERCENT_RANK() OVER(), BETWEEN, CASE
-- Conversion notes:
--   - RANK and PERCENT_RANK window functions identical in PostgreSQL
--   - BETWEEN syntax identical
--   - All column/table names lowercased per DMS schema mapping
-- ============================================================
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
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
-- Statement 7: GetLowStockProductsAsync (converted)
-- Original constructs: CTE, AVG() OVER(), MIN() OVER(), MAX() OVER(), CASE, ROUND
-- Conversion notes:
--   - Window functions identical in PostgreSQL
--   - Added ::NUMERIC cast for integer division to produce correct ROUND results
--   - All column/table names lowercased per DMS schema mapping
-- ============================================================
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
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((stockquantity::NUMERIC / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
