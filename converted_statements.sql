-- ============================================================================
-- Converted SQL Statements for PostgreSQL (from MS SQL Server)
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Total Statements: 7
-- ============================================================================

-- ==========================================================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Original: CTE with AVG/COUNT window functions, CASE, ROUND, INNER JOIN, ORDER BY CASE
-- Changes: Schema objects lowercased (Products→products, ProductId→productid, etc.)
--          ROUND syntax compatible with PostgreSQL (cast to numeric for division)
-- ==========================================================================
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

-- ==========================================================================
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Original: CTE with LAG window function, parameterized with @ProductId, LEFT JOIN, ROUND, CASE
-- Changes: Schema objects lowercased, @ProductId parameter retained for Npgsql compatibility
-- ==========================================================================
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

-- ==========================================================================
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Original: Transaction block with DECLARE, BEGIN TRANSACTION/COMMIT, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
-- Changes: SCOPE_IDENTITY() → RETURNING productid + subquery approach
--          GETDATE() → NOW()
--          BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT
--          DECLARE @var → PostgreSQL DO block or restructured to use INSERT...RETURNING
--          Schema objects lowercased
-- ==========================================================================
DO $$
DECLARE
    var_newproductid INT;
BEGIN
    -- Insert the new product
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO var_newproductid;
    
    -- Log the insertion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (var_newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

SELECT lastval();

-- ==========================================================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Original: Transaction block with DECLARE, SELECT into variables, UPDATE, INSERT, GETDATE()
-- Changes: DECLARE syntax → DO $$ block
--          GETDATE() → NOW()
--          Schema objects lowercased
-- ==========================================================================
DO $$
DECLARE
    var_oldprice DECIMAL(18,2);
    var_oldstock INT;
BEGIN
    -- Store old values for history
    SELECT price, stockquantity INTO var_oldprice, var_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    -- Update the product
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
    
    -- Log the changes
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', var_oldprice, @Price, var_oldstock, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - var_oldprice + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- ==========================================================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Original: Transaction block with DECLARE, SELECT into variables, INSERT, DELETE, UPDATE with CASE, GETDATE()
-- Changes: DECLARE syntax → DO $$ block
--          GETDATE() → NOW()
--          Schema objects lowercased
-- ==========================================================================
DO $$
DECLARE
    var_oldprice DECIMAL(18,2);
    var_oldstock INT;
BEGIN
    -- Store product info for history
    SELECT price, stockquantity INTO var_oldprice, var_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    -- Log the deletion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', var_oldprice, NULL, var_oldstock, NULL, NOW());
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - var_oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- ==========================================================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original: CTE with RANK, PERCENT_RANK window functions, BETWEEN, CASE
-- Changes: Schema objects lowercased
--          RANK() and PERCENT_RANK() are supported in PostgreSQL
-- ==========================================================================
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

-- ==========================================================================
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Original: CTE with AVG/MIN/MAX OVER window functions, CASE, ROUND
-- Changes: Schema objects lowercased
--          ROUND and CAST for integer division in PostgreSQL
-- ==========================================================================
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
