-- ============================================================================
-- Converted PostgreSQL Statements from ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed - did not complete after 15 attempts
-- Schema mapping obtained from DMS schema_mapping_tool:
--   Products -> products (schema: productmanagement_dbo)
--   ProductHistory -> producthistory (schema: productmanagement_dbo)
--   ProductStats -> productstats (schema: productmanagement_dbo)
--   All column names converted to lowercase
--   GETDATE() -> NOW()
--   SCOPE_IDENTITY() -> RETURNING clause
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Table/column names to lowercase, CTE name changed to avoid
--          conflict with productstats table name
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
-- Statement 2: GetProductByIdAsync (converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Table/column names to lowercase, CTE name changed to avoid
--          conflict with producthistory table name
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
-- Statement 3: InsertProductAsync (converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: SCOPE_IDENTITY() -> RETURNING productid
--          GETDATE() -> NOW()
--          Transaction block restructured for PostgreSQL compatibility
--          DECLARE @var -> uses RETURNING clause instead
-- ============================================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The ProductHistory insert and ProductStats update are handled
-- as separate statements in the C# code using the returned productid.
-- ProductHistory insert:
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
-- ProductStats update:
-- UPDATE productstats SET totalproducts = totalproducts + 1,
--   averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--   lastupdated = NOW() WHERE statid = 1;

-- ============================================================================
-- Statement 4: UpdateProductAsync (converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: DECLARE @var -> subquery or separate SELECT INTO
--          GETDATE() -> NOW()
--          Transaction handled by C# code via BeginTransaction
-- ============================================================================
-- Fetch old values (separate query executed in C#):
-- SELECT price, stockquantity FROM products WHERE productid = @ProductId;
-- Then update:
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- Log changes:
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Update stats:
-- UPDATE productstats SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
--   lastupdated = NOW() WHERE statid = 1;

-- ============================================================================
-- Statement 5: DeleteProductAsync (converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: DECLARE @var -> subquery or separate SELECT INTO
--          GETDATE() -> NOW()
--          Transaction handled by C# code via BeginTransaction
-- ============================================================================
-- Fetch old values (separate query executed in C#):
-- SELECT price, stockquantity FROM products WHERE productid = @ProductId;
-- Log deletion:
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());
-- Delete:
DELETE FROM products 
WHERE productid = @ProductId;

-- Update stats:
-- UPDATE productstats SET totalproducts = totalproducts - 1,
--   averageprice = CASE WHEN totalproducts > 1
--     THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1) ELSE 0 END,
--   lastupdated = NOW() WHERE statid = 1;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Table/column names to lowercase
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
-- Statement 7: GetLowStockProductsAsync (converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Table/column names to lowercase
--          Added CAST for integer division to avoid truncation
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
