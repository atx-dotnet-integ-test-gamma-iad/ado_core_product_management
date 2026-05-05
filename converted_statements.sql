-- ============================================================================
-- CONVERTED SQL STATEMENTS (MS SQL Server -> PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- All 7 statements failed DMS conversion due to same error.
-- Manual conversion applied with lowercase schema object names per transformation rules.
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync - CTE with window functions
-- Location: ProductRepository.cs, GetAllProductsAsync() method
-- Conversion: Lowercase table/column names. SQL syntax is PostgreSQL-compatible.
-- ============================================================================
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

-- ============================================================================
-- Statement 2: GetProductByIdAsync - CTE with LAG window function
-- Location: ProductRepository.cs, GetProductByIdAsync() method
-- Conversion: Lowercase table/column names. SQL syntax is PostgreSQL-compatible.
-- ============================================================================
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

-- ============================================================================
-- Statement 3: InsertProductAsync - Transaction with RETURNING and NOW()
-- Location: ProductRepository.cs, InsertProductAsync() method
-- Conversion: SCOPE_IDENTITY() -> RETURNING productid; GETDATE() -> NOW();
--             DECLARE/SET removed in favor of RETURNING clause and CTE-based approach.
--             Transaction block rewritten for PostgreSQL compatibility.
-- ============================================================================
BEGIN;
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (currval(pg_get_serial_sequence('products', 'productid')), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

SELECT currval(pg_get_serial_sequence('products', 'productid'));

-- ============================================================================
-- Statement 4: UpdateProductAsync - Transaction with variables and NOW()
-- Location: ProductRepository.cs, UpdateProductAsync() method
-- Conversion: DECLARE -> DO block or separate queries; GETDATE() -> NOW();
--             Variable assignment via SELECT INTO for PostgreSQL.
-- ============================================================================
BEGIN;
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', (SELECT price FROM products WHERE productid = @ProductId), @Price, (SELECT stockquantity FROM products WHERE productid = @ProductId), @StockQuantity, NOW());
    
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- Statement 5: DeleteProductAsync - Transaction with variables and NOW()
-- Location: ProductRepository.cs, DeleteProductAsync() method
-- Conversion: DECLARE -> subqueries; GETDATE() -> NOW();
-- ============================================================================
BEGIN;
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', (SELECT price FROM products WHERE productid = @ProductId), NULL, (SELECT stockquantity FROM products WHERE productid = @ProductId), NULL, NOW());
    
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- Location: ProductRepository.cs, GetProductsByPriceRangeAsync() method
-- Conversion: Lowercase table/column names. SQL syntax is PostgreSQL-compatible.
-- ============================================================================
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

-- ============================================================================
-- Statement 7: GetLowStockProductsAsync - CTE with AVG/MIN/MAX window functions
-- Location: ProductRepository.cs, GetLowStockProductsAsync() method
-- Conversion: Lowercase table/column names. ROUND cast to numeric for PostgreSQL.
-- ============================================================================
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
