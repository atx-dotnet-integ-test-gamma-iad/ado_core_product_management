-- ============================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Date: 2026-04-17
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mapping Source: DMS Schema Mapping Tool (successful)
--   Products -> productmanagement_dbo.products (all columns lowercase)
--   ProductHistory -> productmanagement_dbo.producthistory (all columns lowercase)
--   ProductStats -> productmanagement_dbo.productstats (all columns lowercase)
-- Total Statements: 7
-- ============================================================

-- ============================================================
-- STATEMENT 1: GetAllProductsAsync (PostgreSQL)
-- Original: CTE with AVG/COUNT OVER(), INNER JOIN, CASE, ROUND
-- Changes: All identifiers lowercased, CAST for integer division
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
-- STATEMENT 2: GetProductByIdAsync (PostgreSQL)
-- Original: CTE with LAG, LEFT JOIN, CASE, ROUND
-- Changes: All identifiers lowercased
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
-- STATEMENT 3: InsertProductAsync (PostgreSQL)
-- Original: DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(), INSERT, UPDATE, GETDATE()
-- Changes: Removed DECLARE/SET, use RETURNING, clock_timestamp() for GETDATE(),
--          split into individual statements (transaction managed by C# code),
--          all identifiers lowercased
-- NOTE: This is split into 4 separate SQL commands executed sequentially in C# code:
--   3a: INSERT with RETURNING for new product ID
--   3b: INSERT into producthistory
--   3c: UPDATE productstats
--   3d: (no separate SELECT needed - RETURNING handles it)
-- ============================================================

-- Statement 3a: Insert product and get new ID via RETURNING
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Log the insertion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- Statement 3c: Update product statistics
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================
-- STATEMENT 4: UpdateProductAsync (PostgreSQL)
-- Original: BEGIN TRANSACTION, DECLARE, SELECT INTO vars, UPDATE, INSERT, UPDATE, GETDATE()
-- Changes: Split into individual statements, clock_timestamp() for GETDATE(),
--          SELECT INTO replaced with SELECT for reading into C# variables,
--          all identifiers lowercased
-- NOTE: Transaction managed by C# code
--   4a: SELECT old values
--   4b: UPDATE product
--   4c: INSERT history
--   4d: UPDATE stats
-- ============================================================

-- Statement 4a: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Statement 4b: Update the product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

-- Statement 4c: Log the changes
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- Statement 4d: Update product statistics
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================
-- STATEMENT 5: DeleteProductAsync (PostgreSQL)
-- Original: BEGIN TRANSACTION, DECLARE, SELECT INTO vars, INSERT, DELETE, UPDATE with CASE, GETDATE()
-- Changes: Split into individual statements, clock_timestamp() for GETDATE(),
--          all identifiers lowercased
-- NOTE: Transaction managed by C# code
--   5a: SELECT old values
--   5b: INSERT history
--   5c: DELETE product
--   5d: UPDATE stats
-- ============================================================

-- Statement 5a: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Statement 5b: Log the deletion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- Statement 5c: Delete the product
DELETE FROM products 
WHERE productid = @ProductId;

-- Statement 5d: Update product statistics
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

-- ============================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original: CTE with RANK(), PERCENT_RANK(), CASE, BETWEEN
-- Changes: All identifiers lowercased
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
-- STATEMENT 7: GetLowStockProductsAsync (PostgreSQL)
-- Original: CTE with AVG/MIN/MAX OVER(), CASE, ROUND
-- Changes: All identifiers lowercased, added ::numeric cast for integer division
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
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
