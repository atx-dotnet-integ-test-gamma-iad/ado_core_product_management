-- ============================================================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Target: PostgreSQL (ProductManagement database)
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================================================

-- ===========================================================================
-- Statement 1: GetAllProductsAsync (converted)
-- Conversion: Table/column names lowercased, syntax PostgreSQL-compatible
-- Note: CTE, window functions, CASE, ROUND all PostgreSQL-compatible
-- ===========================================================================
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

-- ===========================================================================
-- Statement 2: GetProductByIdAsync (converted)
-- Conversion: Table/column names lowercased, syntax PostgreSQL-compatible
-- Note: CTE, LAG window function, CASE, ROUND all PostgreSQL-compatible
-- ===========================================================================
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

-- ===========================================================================
-- Statement 3: InsertProductAsync (converted)
-- Conversion: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> NOW(),
--   BEGIN TRANSACTION -> BEGIN, COMMIT stays, lowercase schema
--   DECLARE @NewProductId removed - use INSERT...RETURNING with CTE approach
--   Note: For C# integration, this will be split into separate commands
--   within a NpgsqlTransaction, using RETURNING to get the new ID
-- ===========================================================================
-- Part A: Insert and get new ID
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Part B: Log the insertion (uses returned productid as @NewProductId from C#)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Part C: Update product statistics
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ===========================================================================
-- Statement 4: UpdateProductAsync (converted)
-- Conversion: DECLARE @var -> separate SELECT query, GETDATE() -> NOW(),
--   BEGIN TRANSACTION -> BEGIN, lowercase schema
--   Note: For C# integration, will use separate commands in NpgsqlTransaction
-- ===========================================================================
-- Part A: Get old values
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Part B: Update the product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- Part C: Log the changes
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Part D: Update product statistics
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ===========================================================================
-- Statement 5: DeleteProductAsync (converted)
-- Conversion: DECLARE @var -> separate SELECT query, GETDATE() -> NOW(),
--   BEGIN TRANSACTION -> BEGIN, lowercase schema
--   Note: For C# integration, will use separate commands in NpgsqlTransaction
-- ===========================================================================
-- Part A: Get old values
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Part B: Log the deletion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Part C: Delete the product
DELETE FROM products 
WHERE productid = @ProductId;

-- Part D: Update product statistics
UPDATE productstats
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
-- Statement 6: GetProductsByPriceRangeAsync (converted)
-- Conversion: Table/column names lowercased, syntax PostgreSQL-compatible
-- Note: CTE, RANK, PERCENT_RANK, BETWEEN, CASE all PostgreSQL-compatible
-- ===========================================================================
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

-- ===========================================================================
-- Statement 7: GetLowStockProductsAsync (converted)
-- Conversion: Table/column names lowercased, ROUND with explicit cast for integer division
-- Note: CTE, window functions, CASE all PostgreSQL-compatible
-- ===========================================================================
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
    ROUND((CAST(stockquantity AS DECIMAL) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
