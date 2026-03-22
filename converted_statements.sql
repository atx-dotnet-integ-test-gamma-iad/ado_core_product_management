-- ============================================================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Source: DataAccess/ProductRepository.cs  
-- Target Database: PostgreSQL
-- Conversion Date: 2026-03-22
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed for all attempts
-- Schema Mapping Source: DMS Schema Mapping Tool (dms-mcp___schema_mapping_tool)
--   Products -> productmanagement_dbo.products (columns: productid, name, description, price, stockquantity, createddate, modifieddate)
--   ProductHistory -> productmanagement_dbo.producthistory (columns: historyid, productid, action, oldprice, newprice, oldstock, newstock, actiondate)
--   ProductStats -> productmanagement_dbo.productstats (columns: statid, totalproducts, averageprice, lastupdated)
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (Converted)
-- Original: CTE with window functions, INNER JOIN, CASE, ROUND, ORDER BY
-- Changes: Lowercase schema objects per DMS schema mapping
-- ============================================================================

WITH productstats_cte AS (
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
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================================================
-- Statement 2: GetProductByIdAsync (Converted)
-- Original: CTE with LAG window function, LEFT JOIN, CASE, ROUND, parameterized
-- Changes: Lowercase schema objects per DMS schema mapping
-- Parameters: @ProductId
-- ============================================================================

WITH producthistory_cte AS (
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
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================================================
-- Statement 3: InsertProductAsync (Converted)
-- Original: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE()
-- Changes: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> clock_timestamp(),
--          lowercase schema objects, restructured for Npgsql compatibility
--          Split into multiple commands executed within C# NpgsqlTransaction
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- ============================================================================

-- Command 3a: Insert product and return new ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Command 3b: Log the insertion (uses @NewProductId from C# code)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- Command 3c: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- Statement 4: UpdateProductAsync (Converted)
-- Original: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT
-- Changes: GETDATE() -> clock_timestamp(), lowercase schema objects
--          Split into multiple commands executed within C# NpgsqlTransaction
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- ============================================================================

-- Command 4a: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Command 4b: Update the product
UPDATE productmanagement_dbo.products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

-- Command 4c: Log the changes (uses @OldPrice and @OldStock from C# code)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- Command 4d: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- Statement 5: DeleteProductAsync (Converted)
-- Original: Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE
-- Changes: GETDATE() -> clock_timestamp(), lowercase schema objects
--          Split into multiple commands executed within C# NpgsqlTransaction
-- Parameters: @ProductId
-- ============================================================================

-- Command 5a: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Command 5b: Log the deletion (uses @OldPrice and @OldStock from C# code)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- Command 5c: Delete the product
DELETE FROM productmanagement_dbo.products 
WHERE productid = @ProductId;

-- Command 5d: Update product statistics
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

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted)
-- Original: CTE with RANK() and PERCENT_RANK() window functions, BETWEEN, CASE
-- Changes: Lowercase schema objects per DMS schema mapping
-- Parameters: @MinPrice, @MaxPrice
-- ============================================================================

WITH rankedproducts AS (
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
FROM rankedproducts rp
ORDER BY rp.pricerank;

-- ============================================================================
-- Statement 7: GetLowStockProductsAsync (Converted)
-- Original: CTE with AVG/MIN/MAX window functions, CASE, ROUND, parameterized
-- Changes: Lowercase schema objects, cast integer to numeric for division
-- Parameters: @Threshold
-- ============================================================================

WITH stockanalysis AS (
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
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
