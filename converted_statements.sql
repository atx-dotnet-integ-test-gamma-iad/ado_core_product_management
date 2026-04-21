-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: Microsoft SQL Server to PostgreSQL Migration
-- Date: 2026-04-21
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema mapping obtained from DMS schema_mapping_tool (successful)
-- Target Schema: productmanagement_dbo (all lowercase table/column names)
-- ============================================================================

-- ============================================================================
-- CONVERTED STATEMENT 1: GetAllProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Conversion: Schema objects lowercased per DMS schema mapping
-- ============================================================================

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

-- ============================================================================
-- CONVERTED STATEMENT 2: GetProductByIdAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Conversion: Schema objects lowercased per DMS schema mapping
-- ============================================================================

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

-- ============================================================================
-- CONVERTED STATEMENT 3: InsertProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Conversion: SCOPE_IDENTITY() -> RETURNING productid
--             GETDATE() -> clock_timestamp()
--             DECLARE/BEGIN TRANSACTION -> restructured for PostgreSQL
--             Schema objects lowercased per DMS schema mapping
-- NOTE: This is a multi-statement transaction. For Npgsql execution via
--       ExecuteScalarAsync, we restructure to use multiple statements.
--       The RETURNING clause replaces SCOPE_IDENTITY().
-- ============================================================================

INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following statements are part of the transaction but need to be
-- executed separately in the C# code since PostgreSQL doesn't support
-- DECLARE @var in the same way. The C# code will handle the transaction.
-- After getting the new productid from RETURNING:

-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (<newProductId>, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- UPDATE productstats
-- SET 
--     totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--     lastupdated = clock_timestamp()
-- WHERE statid = 1;

-- ============================================================================
-- CONVERTED STATEMENT 4: UpdateProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Conversion: GETDATE() -> clock_timestamp()
--             DECLARE @var -> PostgreSQL variable handling in C# code
--             Schema objects lowercased per DMS schema mapping
-- NOTE: Transaction is managed in C# code. DECLARE variables become
--       separate SELECT query + C# variables.
-- ============================================================================

-- First: get old values (separate query in C#)
-- SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Then: update product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

-- Then: insert history
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@ProductId, 'UPDATE', <oldPrice>, @Price, <oldStock>, @StockQuantity, clock_timestamp());

-- Then: update stats
-- UPDATE productstats
-- SET 
--     averageprice = (averageprice * totalproducts - <oldPrice> + @Price) / totalproducts,
--     lastupdated = clock_timestamp()
-- WHERE statid = 1;

-- ============================================================================
-- CONVERTED STATEMENT 5: DeleteProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Conversion: GETDATE() -> clock_timestamp()
--             DECLARE @var -> PostgreSQL variable handling in C# code
--             Schema objects lowercased per DMS schema mapping
-- NOTE: Transaction is managed in C# code. DECLARE variables become
--       separate SELECT query + C# variables.
-- ============================================================================

-- First: get old values (separate query in C#)
-- SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Then: insert history
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@ProductId, 'DELETE', <oldPrice>, NULL, <oldStock>, NULL, clock_timestamp());

-- Then: delete product
DELETE FROM products 
WHERE productid = @ProductId;

-- Then: update stats
-- UPDATE productstats
-- SET 
--     totalproducts = totalproducts - 1,
--     averageprice = CASE 
--         WHEN totalproducts > 1 
--         THEN (averageprice * totalproducts - <oldPrice>) / (totalproducts - 1)
--         ELSE 0
--     END,
--     lastupdated = clock_timestamp()
-- WHERE statid = 1;

-- ============================================================================
-- CONVERTED STATEMENT 6: GetProductsByPriceRangeAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion: Schema objects lowercased per DMS schema mapping
-- ============================================================================

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

-- ============================================================================
-- CONVERTED STATEMENT 7: GetLowStockProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Conversion: Schema objects lowercased per DMS schema mapping
--             Added CAST for integer division fix in PostgreSQL
-- ============================================================================

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
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;

-- ============================================================================
-- END OF CONVERTED STATEMENTS FROM ProductRepository.cs
-- Total: 7 SQL statements converted
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (all 7)
-- DMS schema_mapping_tool used for accurate schema mapping
-- ============================================================================
