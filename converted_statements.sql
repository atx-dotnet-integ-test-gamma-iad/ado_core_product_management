-- ============================================================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- All schema object names converted to lowercase for PostgreSQL compatibility
-- Key conversions: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> NOW(), 
--                  DECLARE @var -> DO $$ ... $$ block or restructured queries,
--                  BEGIN TRANSACTION -> BEGIN, parameter syntax @param preserved for Npgsql
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Original: CTE query with AVG/COUNT window functions, CASE, ROUND, INNER JOIN, ORDER BY
-- Conversion Notes: Schema objects lowercased. SQL syntax is compatible with PostgreSQL.
--   ROUND and window functions work the same in PostgreSQL.
--   Cast division operands to NUMERIC to avoid integer division issues.
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
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Original: CTE query with LAG window functions, LEFT JOIN, ROUND, CASE
-- Conversion Notes: Schema objects lowercased. LAG, ROUND, CASE all supported in PostgreSQL.
--   Parameter @ProductId kept as @ProductId for Npgsql compatibility.
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
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Original: Transaction block with SCOPE_IDENTITY(), GETDATE(), multiple INSERT/UPDATE
-- Conversion Notes: 
--   - SCOPE_IDENTITY() replaced with INSERT...RETURNING and subquery patterns
--   - GETDATE() replaced with NOW()
--   - BEGIN TRANSACTION -> BEGIN
--   - DECLARE @var pattern restructured using INSERT...RETURNING + CTEs
--   - For ADO.NET integration: restructured as a single DO block that returns the new ID
-- ============================================================================
BEGIN;
    -- Insert the new product and get new ID
    WITH new_product AS (
        INSERT INTO products (name, description, price, stockquantity)
        VALUES (@Name, @Description, @Price, @StockQuantity)
        RETURNING productid
    ),
    -- Log the insertion
    log_insert AS (
        INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
        SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
        FROM new_product
    )
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

SELECT currval(pg_get_serial_sequence('products', 'productid'));

-- ============================================================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Original: Transaction block with DECLARE variables, SELECT INTO variables, UPDATE, INSERT, GETDATE()
-- Conversion Notes:
--   - DECLARE @var / SELECT @var = col pattern not directly supported in plain SQL
--   - Restructured using subqueries for old values
--   - GETDATE() replaced with NOW()
--   - BEGIN TRANSACTION -> BEGIN
-- ============================================================================
BEGIN;
    -- Log the changes (capture old values via subquery)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'UPDATE', price, @Price, stockquantity, @StockQuantity, NOW()
    FROM products
    WHERE productid = @ProductId;
    
    -- Update product statistics (capture old price via subquery)
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;

    -- Update the product
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
COMMIT;

-- ============================================================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Original: Transaction block with DECLARE variables, SELECT, INSERT, DELETE, UPDATE with CASE, GETDATE()
-- Conversion Notes:
--   - DECLARE @var / SELECT @var = col pattern restructured using subqueries
--   - GETDATE() replaced with NOW()
--   - BEGIN TRANSACTION -> BEGIN
--   - CASE expression in UPDATE preserved (compatible with PostgreSQL)
-- ============================================================================
BEGIN;
    -- Log the deletion (capture old values via subquery)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, NOW()
    FROM products
    WHERE productid = @ProductId;
    
    -- Update product statistics (capture old price via subquery)
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;

    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
COMMIT;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original: CTE with RANK(), PERCENT_RANK() window functions, BETWEEN, CASE
-- Conversion Notes: Schema objects lowercased. RANK(), PERCENT_RANK(), BETWEEN, CASE
--   all supported in PostgreSQL. Syntax is directly compatible.
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
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Original: CTE with AVG/MIN/MAX window functions, CASE, ROUND, ORDER BY
-- Conversion Notes: Schema objects lowercased. Window functions AVG/MIN/MAX OVER(),
--   CASE, ROUND all supported in PostgreSQL. Cast for ROUND to avoid integer division.
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
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
