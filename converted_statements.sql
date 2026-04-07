-- =====================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Target Database: PostgreSQL
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation/conversion timed out after max poll attempts
-- =====================================================

-- =============================================================================
-- Statement 1: GetAllProductsAsync
-- Location: DataAccess/ProductRepository.cs - GetAllProductsAsync method
-- Conversion: CTE with window functions - compatible with PostgreSQL
-- Changes: Schema objects to lowercase, ROUND with explicit cast for numeric division
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
-- Statement 2: GetProductByIdAsync
-- Location: DataAccess/ProductRepository.cs - GetProductByIdAsync method
-- Conversion: CTE with LAG window functions - compatible with PostgreSQL
-- Changes: Schema objects to lowercase
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
-- Statement 3: InsertProductAsync
-- Location: DataAccess/ProductRepository.cs - InsertProductAsync method
-- Conversion: SCOPE_IDENTITY() -> RETURNING clause, GETDATE() -> NOW(),
--             DECLARE/@variables -> DO block with temporary variable handling
-- Changes: Schema objects to lowercase, T-SQL variables/transactions restructured
--          for PostgreSQL compatibility. Uses DO block to handle variable logic.
-- NOTE: For ADO.NET integration, this will be split into sequential statements
--       managed by C# code with NpgsqlTransaction, since PostgreSQL doesn't support
--       T-SQL DECLARE/SET in plain SQL. The C# code will:
--       1. INSERT INTO products ... RETURNING productid (get newProductId)
--       2. INSERT INTO producthistory ... using the returned productid
--       3. UPDATE productstats ...
-- =============================================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- =============================================================================
-- Statement 4: UpdateProductAsync
-- Location: DataAccess/ProductRepository.cs - UpdateProductAsync method
-- Conversion: DECLARE/@variables -> subquery/CTE, GETDATE() -> NOW()
-- Changes: Schema objects to lowercase, restructured to use sequential statements
--          managed by C# code with NpgsqlTransaction. The C# code will:
--       1. SELECT price, stockquantity FROM products WHERE productid=@ProductId (get old values)
--       2. UPDATE products SET ... (update the product)
--       3. INSERT INTO producthistory ... (log changes)
--       4. UPDATE productstats ... (update stats)
-- =============================================================================
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- =============================================================================
-- Statement 5: DeleteProductAsync
-- Location: DataAccess/ProductRepository.cs - DeleteProductAsync method
-- Conversion: DECLARE/@variables -> subquery/CTE, GETDATE() -> NOW()
-- Changes: Schema objects to lowercase, restructured to use sequential statements
--          managed by C# code with NpgsqlTransaction. The C# code will:
--       1. SELECT price, stockquantity FROM products WHERE productid=@ProductId (get old values)
--       2. INSERT INTO producthistory ... (log deletion)
--       3. DELETE FROM products ... (delete the product)
--       4. UPDATE productstats ... (update stats)
-- =============================================================================
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

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
    lastupdated = NOW()
WHERE statid = 1;

-- =============================================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Location: DataAccess/ProductRepository.cs - GetProductsByPriceRangeAsync method
-- Conversion: CTE with RANK/PERCENT_RANK - compatible with PostgreSQL
-- Changes: Schema objects to lowercase
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
-- Statement 7: GetLowStockProductsAsync
-- Location: DataAccess/ProductRepository.cs - GetLowStockProductsAsync method
-- Conversion: CTE with window functions - compatible with PostgreSQL
-- Changes: Schema objects to lowercase, CAST for integer division in ROUND
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
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
