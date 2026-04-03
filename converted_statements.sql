-- ============================================================
-- Converted SQL Statements for PostgreSQL (from ProductRepository.cs)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model conversion/creation did not complete after 15 attempts (timeout)
-- Schema Mapping Source: DMS schema_mapping_tool
--   dbo.Products -> products (lowercase columns)
--   dbo.ProductHistory -> producthistory (lowercase columns)
--   dbo.ProductStats -> productstats (lowercase columns)
-- Total Statements: 7
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (converted)
-- Conversion: Table/column names to lowercase, CTE renamed to avoid conflict with productstats table
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
-- Conversion: Table/column names to lowercase, CTE renamed to avoid conflict with producthistory table
-- Parameters: @ProductId (preserved for Npgsql compatibility)
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
-- Conversion: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> NOW(),
--   BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT,
--   Transaction split into individual statements for Npgsql execution
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Note: In C# code, this will be split into individual commands within an NpgsqlTransaction
-- ============================================================
-- Individual statements to execute in a C#-level transaction:
-- Statement 3a: Insert product and get new ID
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Log the insertion (using returned productid as @NewProductId)
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
-- Conversion: DECLARE/SELECT into -> SELECT INTO, GETDATE() -> NOW(),
--   BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Note: In C# code, this will be split into individual commands within an NpgsqlTransaction
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
    modifieddate = NOW()
WHERE productid = @ProductId;

-- Statement 4c: Log the changes (using retrieved old values as parameters)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Statement 4d: Update product statistics (using retrieved old values as parameters)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================
-- Statement 5: DeleteProductAsync (converted)
-- Conversion: DECLARE/SELECT into -> SELECT INTO, GETDATE() -> NOW(),
--   BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT
-- Parameters: @ProductId
-- Note: In C# code, this will be split into individual commands within an NpgsqlTransaction
-- ============================================================
-- Statement 5a: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Statement 5b: Log the deletion (using retrieved old values as parameters)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Statement 5c: Delete the product
DELETE FROM products 
WHERE productid = @ProductId;

-- Statement 5d: Update product statistics (using retrieved old values as parameters)
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
-- Conversion: Table/column names to lowercase
-- Parameters: @MinPrice, @MaxPrice
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
-- Conversion: Table/column names to lowercase, CAST for integer division
-- Parameters: @Threshold
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
    ROUND(CAST(stockquantity AS NUMERIC) / avgstock * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
