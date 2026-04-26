-- =====================================================================
-- Converted SQL Statements for PostgreSQL
-- Target: PostgreSQL (via manual conversion with DMS schema mapping)
-- Schema Mapping (from DMS schema_mapping_tool):
--   dbo.Products -> productmanagement_dbo.products (columns lowercase)
--   dbo.ProductHistory -> productmanagement_dbo.producthistory (columns lowercase)
--   dbo.ProductStats -> productmanagement_dbo.productstats (columns lowercase)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed: Unknown metadata model creation status: RECEIVED
-- Total Statements: 7
-- =====================================================================

-- ==============================================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Original Location: DataAccess/ProductRepository.cs, GetAllProductsAsync method
-- ==============================================================
WITH ProductStats AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM productmanagement_dbo.products
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
FROM productmanagement_dbo.products p
INNER JOIN ProductStats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ==============================================================
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Original Location: DataAccess/ProductRepository.cs, GetProductByIdAsync method
-- ==============================================================
WITH ProductHistory AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM productmanagement_dbo.products
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
FROM productmanagement_dbo.products p
LEFT JOIN ProductHistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ==============================================================
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Original Location: DataAccess/ProductRepository.cs, InsertProductAsync method
-- Key changes: SCOPE_IDENTITY() -> RETURNING productid, GETDATE() -> clock_timestamp(),
--              Transaction handled in C# code via NpgsqlTransaction,
--              Multiple statements executed separately with RETURNING for ID capture
-- ==============================================================
-- Part 3a: Insert product and return new ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Part 3b: Log the insertion (uses returned product ID passed as parameter)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- Part 3c: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ==============================================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Original Location: DataAccess/ProductRepository.cs, UpdateProductAsync method
-- Key changes: DECLARE/SET variables -> separate SELECT + C# variables,
--              GETDATE() -> clock_timestamp(), transaction in C# code
-- ==============================================================
-- Part 4a: Get old values (executed first, results captured in C#)
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Part 4b: Update the product
UPDATE productmanagement_dbo.products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

-- Part 4c: Log the changes
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- Part 4d: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ==============================================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Original Location: DataAccess/ProductRepository.cs, DeleteProductAsync method
-- Key changes: DECLARE/SET variables -> separate SELECT + C# variables,
--              GETDATE() -> clock_timestamp(), transaction in C# code
-- ==============================================================
-- Part 5a: Get old values (executed first, results captured in C#)
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Part 5b: Log the deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- Part 5c: Delete the product
DELETE FROM productmanagement_dbo.products 
WHERE productid = @ProductId;

-- Part 5d: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ==============================================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original Location: DataAccess/ProductRepository.cs, GetProductsByPriceRangeAsync method
-- ==============================================================
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM productmanagement_dbo.products p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as pricesegment
FROM RankedProducts rp
ORDER BY rp.pricerank;

-- ==============================================================
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Original Location: DataAccess/ProductRepository.cs, GetLowStockProductsAsync method
-- ==============================================================
WITH StockAnalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM productmanagement_dbo.products p
)
SELECT 
    sa.*,
    CASE 
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM StockAnalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
