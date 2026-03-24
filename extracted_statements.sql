-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: DataAccess/ProductRepository.cs
-- Extraction Date: 2026-03-24
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Range: ~47-72
-- Type: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), CASE, JOIN
-- Parameters: None
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
    ROUND(CAST(p.price AS NUMERIC) / ps.avgprice * 100, 2) as pricepercentageofaverage
FROM productmanagement_dbo.products p
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Range: ~81-107
-- Type: SELECT with CTE, Window Function (LAG), LEFT JOIN, CASE, parameterized WHERE
-- Parameters: @ProductId (int)
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
-- STATEMENT 3: InsertProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Range: ~117-136
-- Type: Transaction block (BEGIN/COMMIT) with INSERT, INSERT, UPDATE, SELECT lastval()
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- ============================================================================

BEGIN;
    -- Insert the new product
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    -- Log the insertion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1;
COMMIT;

SELECT lastval();

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Range: ~151-174
-- Type: Transaction block (BEGIN/COMMIT) with INSERT (via subquery), UPDATE, UPDATE (with subquery)
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- ============================================================================

BEGIN;
    -- Log the changes (capture old values before update via subquery)
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', p.price, @Price, p.stockquantity, @StockQuantity, clock_timestamp()
    FROM productmanagement_dbo.products p
    WHERE p.productid = @ProductId;

    -- Update the product
    UPDATE productmanagement_dbo.products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = clock_timestamp()
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT oldprice FROM productmanagement_dbo.producthistory WHERE productid = @ProductId AND action = 'UPDATE' ORDER BY actiondate DESC LIMIT 1) + @Price) / totalproducts,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Range: ~189-213
-- Type: Transaction block (BEGIN/COMMIT) with INSERT (via subquery), DELETE, UPDATE (with subquery and CASE)
-- Parameters: @ProductId (int)
-- ============================================================================

BEGIN;
    -- Log the deletion (capture values before delete via subquery)
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, clock_timestamp()
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;
    
    -- Delete the product
    DELETE FROM productmanagement_dbo.products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT COALESCE(oldprice, 0) FROM productmanagement_dbo.producthistory WHERE productid = @ProductId AND action = 'DELETE' ORDER BY actiondate DESC LIMIT 1)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Range: ~222-242
-- Type: SELECT with CTE, Window Functions (RANK, PERCENT_RANK), BETWEEN, CASE
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
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
-- STATEMENT 7: GetLowStockProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Range: ~257-276
-- Type: SELECT with CTE, Window Functions (AVG, MIN, MAX), CASE, parameterized WHERE
-- Parameters: @Threshold (int)
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
    ROUND(CAST(stockquantity AS NUMERIC) / avgstock * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
