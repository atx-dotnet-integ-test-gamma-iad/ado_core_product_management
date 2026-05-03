-- =============================================
-- Converted SQL Statements for PostgreSQL
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS schema mapping used as reference for all naming conventions
-- Schema: productmanagement_dbo (but inline SQL uses unqualified table names)
-- =============================================

-- =============================================
-- Statement 1: GetAllProductsAsync (converted)
-- Original: CTE with window functions, CASE, ROUND, INNER JOIN
-- Changes: All schema objects lowercase per DMS mapping
-- =============================================
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

-- =============================================
-- Statement 2: GetProductByIdAsync (converted)
-- Original: CTE with LAG window function, CASE, ROUND, LEFT JOIN
-- Changes: All schema objects lowercase per DMS mapping
-- =============================================
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

-- =============================================
-- Statement 3: InsertProductAsync (converted)
-- Original: Transaction with SCOPE_IDENTITY(), GETDATE()
-- Changes: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> clock_timestamp(),
--          DECLARE @var -> restructured for ADO.NET inline usage,
--          All schema objects lowercase per DMS mapping
-- Note: For ADO.NET inline SQL, the transaction is managed in C# code,
--       and we split into separate commands to handle RETURNING clause
-- =============================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- (Subsequent statements executed separately in C# with the returned productid)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- =============================================
-- Statement 4: UpdateProductAsync (converted)
-- Original: Transaction with DECLARE variables, SELECT INTO vars, UPDATE, INSERT
-- Changes: DECLARE @var -> restructured for ADO.NET,
--          GETDATE() -> clock_timestamp(),
--          All schema objects lowercase per DMS mapping
-- Note: Split into separate commands for ADO.NET execution
-- =============================================
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- =============================================
-- Statement 5: DeleteProductAsync (converted)
-- Original: Transaction with DECLARE variables, DELETE, CASE in UPDATE
-- Changes: DECLARE @var -> restructured for ADO.NET,
--          GETDATE() -> clock_timestamp(),
--          All schema objects lowercase per DMS mapping
-- Note: Split into separate commands for ADO.NET execution
-- =============================================
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

DELETE FROM products 
WHERE productid = @ProductId;

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

-- =============================================
-- Statement 6: GetProductsByPriceRangeAsync (converted)
-- Original: CTE with RANK, PERCENT_RANK, BETWEEN, CASE
-- Changes: All schema objects lowercase per DMS mapping
-- =============================================
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

-- =============================================
-- Statement 7: GetLowStockProductsAsync (converted)
-- Original: CTE with AVG/MIN/MAX window functions, CASE, ROUND
-- Changes: All schema objects lowercase per DMS mapping
--          Added ::NUMERIC cast for integer division fix in PostgreSQL
-- =============================================
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
