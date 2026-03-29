-- ============================================================
-- Converted SQL Statements for PostgreSQL
-- Target: PostgreSQL
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model conversion timed out / Command execution timed out after 300 seconds
-- All schema object names converted to lowercase per PostgreSQL convention
-- Note: Statements designed to work with Npgsql parameterized queries via ADO.NET
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (converted)
-- Conversion: Schema objects lowercased. SQL syntax compatible with PostgreSQL.
-- ============================================================

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

-- ============================================================
-- Statement 2: GetProductByIdAsync (converted)
-- Conversion: Schema objects lowercased. SQL syntax compatible with PostgreSQL.
-- ============================================================

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

-- ============================================================
-- Statement 3: InsertProductAsync (converted)
-- Conversion: SCOPE_IDENTITY() replaced with INSERT...RETURNING via CTE approach.
--             GETDATE() replaced with NOW().
--             DECLARE/SET variable replaced with CTE for capturing new ID.
--             Transaction handled by C# code (BeginTransactionAsync).
--             Schema objects lowercased.
-- Note: This is split into multiple statements executed in a C# transaction:
--   3a: INSERT INTO products ... RETURNING productid
--   3b: INSERT INTO producthistory ...
--   3c: UPDATE productstats ...
-- ============================================================

-- Statement 3a: Insert product and return new ID
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Log the insertion (executed after capturing newproductid)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Statement 3c: Update product statistics
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================
-- Statement 4: UpdateProductAsync (converted)
-- Conversion: DECLARE variables replaced with subqueries.
--             GETDATE() replaced with NOW().
--             Transaction handled by C# code (BeginTransactionAsync).
--             Schema objects lowercased.
-- Note: Split into multiple statements executed in a C# transaction:
--   4a: UPDATE products
--   4b: INSERT INTO producthistory using subquery for old values
--   4c: UPDATE productstats using subquery for old price
-- ============================================================

-- Statement 4a: Update the product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- Statement 4b: Log the changes (uses subquery to get old values from producthistory or direct params)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Statement 4c: Update product statistics
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- Statement 4-pre: Get old values before update
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- ============================================================
-- Statement 5: DeleteProductAsync (converted)
-- Conversion: DECLARE variables replaced with subqueries.
--             GETDATE() replaced with NOW().
--             Transaction handled by C# code (BeginTransactionAsync).
--             Schema objects lowercased.
-- Note: Split into multiple statements executed in a C# transaction:
--   5-pre: SELECT old values
--   5a: INSERT INTO producthistory (log deletion)
--   5b: DELETE FROM products
--   5c: UPDATE productstats
-- ============================================================

-- Statement 5-pre: Get old values before delete
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Statement 5a: Log the deletion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Statement 5b: Delete the product
DELETE FROM products 
WHERE productid = @ProductId;

-- Statement 5c: Update product statistics
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

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync (converted)
-- Conversion: Schema objects lowercased. SQL syntax compatible with PostgreSQL.
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
-- Conversion: Schema objects lowercased. 
--             ROUND with integer division: cast to NUMERIC for proper division.
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
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
