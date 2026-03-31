-- =====================================================
-- Converted SQL Statements for PostgreSQL
-- Source: MS SQL Server → Target: PostgreSQL 13
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Total Statements: 7
-- =====================================================

-- =====================================================
-- Statement 1: GetAllProductsAsync
-- CTE with window functions, CASE, ROUND, INNER JOIN
-- Conversion: Lowercase schema objects, syntax is compatible
-- =====================================================
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

-- =====================================================
-- Statement 2: GetProductByIdAsync
-- CTE with LAG window function, ROUND, LEFT JOIN
-- Conversion: Lowercase schema objects, syntax is compatible
-- =====================================================
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

-- =====================================================
-- Statement 3: InsertProductAsync
-- Transaction block: SCOPE_IDENTITY() → RETURNING + C#-managed transaction, GETDATE() → NOW()
-- Conversion: Refactored to separate parameterized commands within C#-managed transaction
-- NOTE: DO NOT use BEGIN/COMMIT in SQL - transaction is managed via C# BeginTransactionAsync/CommitAsync
-- =====================================================
-- Command 3a: Insert product (ExecuteScalar to get new id)
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Command 3b: Log insertion history
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Command 3c: Update statistics
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================
-- Statement 4: UpdateProductAsync
-- Transaction block: Refactored from DO $ block to separate parameterized commands
-- Conversion: Separate SQL commands within C#-managed transaction (BeginTransactionAsync/CommitAsync)
-- NOTE: DO $ blocks cannot receive Npgsql @parameters - must use separate commands
-- =====================================================
-- Command 4a: Select old values
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Command 4b: Update the product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- Command 4c: Log the changes
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Command 4d: Update product statistics
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================
-- Statement 5: DeleteProductAsync
-- Transaction block: Refactored from DO $ block to separate parameterized commands
-- Conversion: Separate SQL commands within C#-managed transaction (BeginTransactionAsync/CommitAsync)
-- NOTE: DO $ blocks cannot receive Npgsql @parameters - must use separate commands
-- =====================================================
-- Command 5a: Select old values
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Command 5b: Log the deletion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Command 5c: Delete the product
DELETE FROM products 
WHERE productid = @ProductId;

-- Command 5d: Update product statistics
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

-- =====================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- CTE with RANK() and PERCENT_RANK(), BETWEEN, CASE
-- Conversion: Lowercase schema objects, syntax is compatible
-- =====================================================
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

-- =====================================================
-- Statement 7: GetLowStockProductsAsync
-- CTE with AVG/MIN/MAX window functions, CASE, ROUND
-- Conversion: Lowercase schema objects, added ::NUMERIC cast for integer division
-- =====================================================
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
