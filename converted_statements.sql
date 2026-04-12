-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
-- DMS Statement Conversion: All 7 statements FAILED with
--   "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- Date: 2026-04-12
-- ============================================================================
-- Schema Mapping Applied (from DMS schema_mapping_tool):
--   Products -> products (columns all lowercase)
--   ProductHistory -> producthistory (columns all lowercase)
--   ProductStats -> productstats (columns all lowercase)
--   GETDATE() -> clock_timestamp()
--   SCOPE_IDENTITY() -> RETURNING clause
--   DECLARE @var -> DO $$ DECLARE v_var ... END $$;
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (PostgreSQL)
-- Source Method: GetAllProductsAsync()
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Table/column names lowercased per DMS schema mapping
-- ============================================================================

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
    p.name;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync (PostgreSQL)
-- Source Method: GetProductByIdAsync(int productId)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Table/column names lowercased per DMS schema mapping
-- Parameters: @ProductId (kept for Npgsql compatibility)
-- ============================================================================

WITH producthistory AS (
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
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync (PostgreSQL)
-- Source Method: InsertProductAsync(Product product)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes:
--   - SCOPE_IDENTITY() replaced with RETURNING productid
--   - GETDATE() replaced with clock_timestamp()
--   - DECLARE/SET @NewProductId removed (using RETURNING + currval instead)
--   - Transaction block restructured for PostgreSQL
--   - Table/column names lowercased per DMS schema mapping
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- NOTE: For ADO.NET integration, the transaction block with DECLARE/variables
--        is replaced with individual statements managed by C# code with
--        RETURNING clause to get the new ID
-- ============================================================================

INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- (Executed separately in C# after getting newProductId from RETURNING)
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- UPDATE productstats
-- SET totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--     lastupdated = clock_timestamp()
-- WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (PostgreSQL)
-- Source Method: UpdateProductAsync(Product product)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes:
--   - DECLARE @var -> C# managed variables (SELECT INTO reader, then use in subsequent commands)
--   - GETDATE() -> clock_timestamp()
--   - Transaction managed by C# BeginTransactionAsync()
--   - Table/column names lowercased per DMS schema mapping
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- ============================================================================

-- Step 1: Get old values (in C#, read via ExecuteReader)
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Step 2: Update product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

-- Step 3: Log history
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- Step 4: Update stats
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (PostgreSQL)
-- Source Method: DeleteProductAsync(int productId)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes:
--   - DECLARE @var -> C# managed variables
--   - GETDATE() -> clock_timestamp()
--   - CASE expression preserved (PostgreSQL compatible)
--   - Transaction managed by C# BeginTransactionAsync()
--   - Table/column names lowercased per DMS schema mapping
-- Parameters: @ProductId
-- ============================================================================

-- Step 1: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Step 2: Log deletion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- Step 3: Delete product
DELETE FROM products WHERE productid = @ProductId;

-- Step 4: Update stats
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Table/column names lowercased per DMS schema mapping
-- Parameters: @MinPrice, @MaxPrice
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
-- STATEMENT 7: GetLowStockProductsAsync (PostgreSQL)
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes:
--   - Table/column names lowercased per DMS schema mapping
--   - Added CAST(stockquantity AS NUMERIC) for integer division fix in PostgreSQL
-- Parameters: @Threshold
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
-- END OF CONVERTED STATEMENTS CATALOG
-- Total Statements: 7
-- All converted via DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
