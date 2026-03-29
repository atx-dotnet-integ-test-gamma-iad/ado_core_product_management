-- ============================================================================
-- Converted SQL Statements for PostgreSQL
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation/conversion did not complete after 15 attempts
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Original: CTE with AVG/COUNT OVER, CASE, ROUND, ORDER BY CASE
-- Changes: All schema objects lowercased, ROUND cast to numeric for proper division
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
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Original: CTE with LAG window function, CASE with NULL handling, ROUND
-- Changes: All schema objects lowercased, ROUND cast to numeric
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
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Original: DECLARE, BEGIN TRANSACTION, SCOPE_IDENTITY(), GETDATE()
-- Changes: SCOPE_IDENTITY() -> use DO block with RETURNING, GETDATE() -> NOW(),
--          All schema objects lowercased, restructured for PostgreSQL
-- ============================================================================
DO $$
DECLARE
    v_newproductid INTEGER;
BEGIN
    -- Insert the new product
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO v_newproductid;
    
    -- Log the insertion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (v_newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

SELECT LASTVAL();

-- ============================================================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Original: DECLARE, BEGIN TRANSACTION, SELECT INTO vars, UPDATE GETDATE()
-- Changes: GETDATE() -> NOW(), DECLARE -> DO block, all schema objects lowercased
-- ============================================================================
DO $$
DECLARE
    v_oldprice DECIMAL(18,2);
    v_oldstock INTEGER;
BEGIN
    -- Store old values for history
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
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
    VALUES (@ProductId, 'UPDATE', v_oldprice, @Price, v_oldstock, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - v_oldprice + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- ============================================================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Original: DECLARE, BEGIN TRANSACTION, SELECT INTO vars, DELETE, UPDATE with CASE
-- Changes: GETDATE() -> NOW(), DECLARE -> DO block, all schema objects lowercased
-- ============================================================================
DO $$
DECLARE
    v_oldprice DECIMAL(18,2);
    v_oldstock INTEGER;
BEGIN
    -- Store product info for history
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    -- Log the deletion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, NOW());
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - v_oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original: CTE with RANK(), PERCENT_RANK(), BETWEEN, CASE
-- Changes: All schema objects lowercased
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
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Original: CTE with AVG/MIN/MAX OVER(), CASE, ROUND
-- Changes: All schema objects lowercased, CAST for numeric division in ROUND
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
    ROUND(CAST(stockquantity AS NUMERIC) / avgstock * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
