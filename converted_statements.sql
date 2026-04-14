-- ============================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Schema Mapping Used: dbo.Products -> products, dbo.ProductHistory -> producthistory, dbo.ProductStats -> productstats
-- All column names converted to lowercase per DMS schema mapping
-- Total Statements: 7
-- ============================================================

-- ============================================================
-- SQL1: GetAllProductsAsync (converted)
-- Original: CTE with AVG/COUNT OVER, INNER JOIN, CASE, ROUND
-- Changes: All identifiers lowercased per DMS schema mapping
-- ============================================================

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

-- ============================================================
-- SQL2: GetProductByIdAsync (converted)
-- Original: CTE with LAG, LEFT JOIN, CASE, ROUND
-- Changes: All identifiers lowercased per DMS schema mapping
-- ============================================================

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

-- ============================================================
-- SQL3: InsertProductAsync (converted)
-- Original: Transaction with DECLARE, SCOPE_IDENTITY(), GETDATE()
-- Changes: Removed DECLARE/variable, used RETURNING, GETDATE()->CURRENT_TIMESTAMP,
--          BEGIN TRANSACTION->BEGIN, lowercase identifiers
-- Note: PostgreSQL does not support inline DECLARE or SCOPE_IDENTITY().
--       The transaction structure is simplified for ADO.NET execution.
--       The INSERT...RETURNING replaces SCOPE_IDENTITY().
-- ============================================================

BEGIN;
    -- Insert the new product and return the new ID
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid;

-- Note: The following statements need the returned productid from the application layer.
-- In the C# code, the INSERT with RETURNING will be executed via ExecuteScalarAsync().
-- The ProductHistory and ProductStats updates will need to be handled separately
-- or the SQL restructured to use a DO block. For ADO.NET compatibility, we split:

-- ============================================================
-- SQL3b: InsertProductAsync - History logging (to be combined in code)
-- ============================================================

    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
COMMIT;

-- ============================================================
-- SQL4: UpdateProductAsync (converted)
-- Original: Transaction with DECLARE, SELECT INTO vars, UPDATE, INSERT, UPDATE
-- Changes: DECLARE @var -> subquery approach, GETDATE()->CURRENT_TIMESTAMP,
--          BEGIN TRANSACTION->BEGIN, lowercase identifiers
-- ============================================================

BEGIN;
    -- Update the product
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = @ProductId;
    
    -- Log the changes (using subquery for old values since we can't use DECLARE in PostgreSQL inline SQL)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
COMMIT;

-- ============================================================
-- SQL5: DeleteProductAsync (converted)
-- Original: Transaction with DECLARE, SELECT INTO vars, INSERT, DELETE, UPDATE with CASE
-- Changes: DECLARE @var -> subquery approach, GETDATE()->CURRENT_TIMESTAMP,
--          BEGIN TRANSACTION->BEGIN, lowercase identifiers
-- ============================================================

BEGIN;
    -- Log the deletion (using subquery for old values)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
COMMIT;

-- ============================================================
-- SQL6: GetProductsByPriceRangeAsync (converted)
-- Original: CTE with RANK, PERCENT_RANK, BETWEEN, CASE
-- Changes: All identifiers lowercased per DMS schema mapping
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
-- SQL7: GetLowStockProductsAsync (converted)
-- Original: CTE with AVG, MIN, MAX OVER, CASE, ROUND
-- Changes: All identifiers lowercased per DMS schema mapping
--          Added CAST for integer division in ROUND
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
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
