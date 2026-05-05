-- =============================================================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Source: Manual conversion from MS SQL Server (DMS tool failed for all statements)
-- DMS Error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Total Statements: 7
-- =============================================================================

-- =============================================================================
-- Statement 1: GetAllProductsAsync (converted)
-- Original Location: DataAccess/ProductRepository.cs, GetAllProductsAsync() method
-- Conversion Notes: CTE with window functions - compatible with PostgreSQL.
--   Applied lowercase schema objects. ROUND with numeric cast for proper division.
-- =============================================================================
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

-- =============================================================================
-- Statement 2: GetProductByIdAsync (converted)
-- Original Location: DataAccess/ProductRepository.cs, GetProductByIdAsync() method
-- Conversion Notes: CTE with LAG window function - compatible with PostgreSQL.
--   Applied lowercase schema objects. ROUND with numeric division.
-- =============================================================================
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

-- =============================================================================
-- Statement 3: InsertProductAsync (converted)
-- Original Location: DataAccess/ProductRepository.cs, InsertProductAsync() method
-- Conversion Notes: 
--   - SCOPE_IDENTITY() replaced with RETURNING clause and separate queries
--   - GETDATE() replaced with NOW()
--   - DECLARE/SET pattern restructured for PostgreSQL compatibility
--   - Transaction managed by application code (Npgsql)
--   - Split into multiple statements executed sequentially
-- =============================================================================
-- Statement 3a: Insert product and get new ID
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Log the insertion (uses @NewProductId from RETURNING above)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Statement 3c: Update product statistics
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- =============================================================================
-- Statement 4: UpdateProductAsync (converted)
-- Original Location: DataAccess/ProductRepository.cs, UpdateProductAsync() method
-- Conversion Notes:
--   - DECLARE/SELECT INTO variables restructured to SELECT INTO temp vars
--   - GETDATE() replaced with NOW()
--   - Transaction managed by application code (Npgsql)
--   - Split into multiple statements executed sequentially
-- =============================================================================
-- Statement 4a: Get old values
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Statement 4b: Update the product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- Statement 4c: Log the changes
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Statement 4d: Update product statistics
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- =============================================================================
-- Statement 5: DeleteProductAsync (converted)
-- Original Location: DataAccess/ProductRepository.cs, DeleteProductAsync() method
-- Conversion Notes:
--   - DECLARE/SELECT INTO variables restructured
--   - GETDATE() replaced with NOW()
--   - Transaction managed by application code (Npgsql)
--   - Split into multiple statements executed sequentially
-- =============================================================================
-- Statement 5a: Get old values
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Statement 5b: Log the deletion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

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
    lastupdated = NOW()
WHERE statid = 1;

-- =============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (converted)
-- Original Location: DataAccess/ProductRepository.cs, GetProductsByPriceRangeAsync() method
-- Conversion Notes: CTE with RANK and PERCENT_RANK - compatible with PostgreSQL.
--   Applied lowercase schema objects.
-- =============================================================================
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

-- =============================================================================
-- Statement 7: GetLowStockProductsAsync (converted)
-- Original Location: DataAccess/ProductRepository.cs, GetLowStockProductsAsync() method
-- Conversion Notes: CTE with AVG/MIN/MAX OVER - compatible with PostgreSQL.
--   Applied lowercase schema objects. ROUND with CAST for integer division.
-- =============================================================================
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
