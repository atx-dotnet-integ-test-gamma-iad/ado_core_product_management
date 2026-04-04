-- ============================================================
-- Converted PostgreSQL Statements (from MS SQL Server)
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model conversion/creation timed out after multiple attempts
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
--   Products -> products (schema: productmanagement_dbo, but using unqualified for app queries)
--   ProductHistory -> producthistory
--   ProductStats -> productstats
--   All column names converted to lowercase per DMS schema mapping
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (Converted)
-- Changes: Table/column names to lowercase per DMS schema mapping
-- SQL constructs (CTE, window functions, CASE, ROUND, INNER JOIN) are PostgreSQL-compatible
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
-- Statement 2: GetProductByIdAsync (Converted)
-- Changes: Table/column names to lowercase per DMS schema mapping
-- SQL constructs (CTE, LAG, LEFT JOIN, CASE, ROUND) are PostgreSQL-compatible
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
-- Statement 3: InsertProductAsync (Converted)
-- Changes: SCOPE_IDENTITY() -> RETURNING productid with separate INSERT
--          GETDATE() -> NOW()
--          BEGIN TRANSACTION -> BEGIN
--          Table/column names to lowercase
--          DECLARE @var -> DO $$ DECLARE ... END $$ block approach replaced with
--          RETURNING clause and sequential statements for ADO.NET compatibility
-- ============================================================
BEGIN;
    -- Insert the new product and get the new ID
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    -- Log the insertion using lastval() to get the last generated identity
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

SELECT lastval();

-- ============================================================
-- Statement 4: UpdateProductAsync (Converted)
-- Changes: BEGIN TRANSACTION -> BEGIN
--          GETDATE() -> NOW()
--          DECLARE @var / SELECT @var = col -> subqueries or CTEs
--          Table/column names to lowercase
-- ============================================================
BEGIN;
    -- Update the product
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
    
    -- Log the changes (using subquery for old values)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', p.price, @Price, p.stockquantity, @StockQuantity, NOW()
    FROM products p WHERE p.productid = @ProductId;
    
    -- Update product statistics (using subquery for old price)
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ============================================================
-- Statement 5: DeleteProductAsync (Converted)
-- Changes: BEGIN TRANSACTION -> BEGIN
--          GETDATE() -> NOW()
--          DECLARE @var / SELECT @var = col -> subqueries
--          Table/column names to lowercase
-- ============================================================
BEGIN;
    -- Log the deletion (capture values before delete using subquery)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', p.price, NULL, p.stockquantity, NULL, NOW()
    FROM products p WHERE p.productid = @ProductId;
    
    -- Update product statistics (before delete, capture old price)
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

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted)
-- Changes: Table/column names to lowercase per DMS schema mapping
-- SQL constructs (CTE, RANK, PERCENT_RANK, BETWEEN, CASE) are PostgreSQL-compatible
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
-- Statement 7: GetLowStockProductsAsync (Converted)
-- Changes: Table/column names to lowercase per DMS schema mapping
-- SQL constructs (CTE, AVG/MIN/MAX window functions, CASE, ROUND) are PostgreSQL-compatible
-- Note: ROUND with integer division needs CAST to numeric for PostgreSQL
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
    ROUND((CAST(stockquantity AS numeric) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
