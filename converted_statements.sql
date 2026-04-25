-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Target Database: PostgreSQL (ProductManagement)
-- Conversion Date: 2026-04-25
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mapping Source: DMS Schema Mapping Tool (successful)
--   - Products -> products (schema: productmanagement_dbo)
--   - ProductHistory -> producthistory (schema: productmanagement_dbo)
--   - ProductStats -> productstats (schema: productmanagement_dbo)
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (converted)
-- Conversion Notes: 
--   - Table/column names lowercased per DMS schema mapping
--   - ROUND() and CASE syntax compatible with PostgreSQL
--   - Added ::numeric cast for proper decimal division
-- ============================================================================
WITH ProductStats AS (
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
INNER JOIN ProductStats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync (converted)
-- Conversion Notes:
--   - Table/column names lowercased per DMS schema mapping
--   - LAG() window function compatible with PostgreSQL
--   - Parameter @ProductId retained for Npgsql compatibility
-- ============================================================================
WITH ProductHistory AS (
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
LEFT JOIN ProductHistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync (converted)
-- Conversion Notes:
--   - SCOPE_IDENTITY() replaced with RETURNING clause
--   - GETDATE() replaced with NOW()
--   - Transaction block split into multiple statements managed by C# code
--   - Statement 3a: Insert product and get new ID via RETURNING
--   - Statement 3b: Insert history record
--   - Statement 3c: Update statistics
-- ============================================================================

-- Statement 3a: Insert product (returns new productid via RETURNING)
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Insert history record (uses @NewProductId from 3a result)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Statement 3c: Update statistics
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (converted)
-- Conversion Notes:
--   - DECLARE @var / SELECT INTO @var replaced with separate SELECT query
--   - GETDATE() replaced with NOW()
--   - Transaction block split into multiple statements managed by C# code
--   - Statement 4a: Select old values
--   - Statement 4b: Update product
--   - Statement 4c: Insert history
--   - Statement 4d: Update statistics
-- ============================================================================

-- Statement 4a: Select old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Statement 4b: Update product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- Statement 4c: Insert history
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Statement 4d: Update statistics
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (converted)
-- Conversion Notes:
--   - DECLARE @var / SELECT INTO @var replaced with separate SELECT query
--   - GETDATE() replaced with NOW()
--   - Transaction block split into multiple statements managed by C# code
--   - Statement 5a: Select old values
--   - Statement 5b: Insert history
--   - Statement 5c: Delete product
--   - Statement 5d: Update statistics
-- ============================================================================

-- Statement 5a: Select old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Statement 5b: Insert history
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Statement 5c: Delete product
DELETE FROM products 
WHERE productid = @ProductId;

-- Statement 5d: Update statistics
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

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (converted)
-- Conversion Notes:
--   - Table/column names lowercased per DMS schema mapping
--   - RANK(), PERCENT_RANK() window functions compatible with PostgreSQL
--   - BETWEEN syntax compatible with PostgreSQL
-- ============================================================================
WITH RankedProducts AS (
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
FROM RankedProducts rp
ORDER BY rp.pricerank;

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync (converted)
-- Conversion Notes:
--   - Table/column names lowercased per DMS schema mapping
--   - AVG/MIN/MAX window functions compatible with PostgreSQL
--   - Added ::numeric cast for integer division to avoid truncation
-- ============================================================================
WITH StockAnalysis AS (
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
FROM StockAnalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
