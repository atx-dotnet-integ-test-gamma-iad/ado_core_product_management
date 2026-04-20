-- ============================================================
-- Converted SQL Statements for PostgreSQL (from ProductRepository.cs)
-- Source Schema: dbo -> productmanagement_dbo
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema mappings obtained from DMS schema_mapping_tool:
--   Products -> productmanagement_dbo.products
--   ProductHistory -> productmanagement_dbo.producthistory
--   ProductStats -> productmanagement_dbo.productstats
-- Total Statements: 7
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Original Location: ProductRepository.cs, GetAllProductsAsync() method
-- Conversion: CTE name changed to avoid conflict with table name productstats
--   Products -> productmanagement_dbo.products
--   Column names -> lowercase
-- ============================================================
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

-- ============================================================
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Original Location: ProductRepository.cs, GetProductByIdAsync() method
-- Conversion: CTE name changed to avoid conflict with table name producthistory
--   Products -> productmanagement_dbo.products
--   Column names -> lowercase
-- ============================================================
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

-- ============================================================
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Original Location: ProductRepository.cs, InsertProductAsync() method
-- Conversion:
--   SCOPE_IDENTITY() -> RETURNING clause with CTE
--   GETDATE() -> clock_timestamp()
--   BEGIN TRANSACTION -> BEGIN
--   DECLARE @var -> removed, using CTE with RETURNING
--   Products -> productmanagement_dbo.products
--   ProductHistory -> productmanagement_dbo.producthistory
--   ProductStats -> productmanagement_dbo.productstats
-- ============================================================
BEGIN;
    -- Insert the new product and capture the new id
    WITH new_product AS (
        INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
        VALUES (@Name, @Description, @Price, @StockQuantity)
        RETURNING productid
    )
    -- Log the insertion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp()
    FROM new_product;
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1;
COMMIT;

SELECT lastval();

-- ============================================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Original Location: ProductRepository.cs, UpdateProductAsync() method
-- Conversion:
--   DECLARE @OldPrice / @OldStock -> subquery approach
--   GETDATE() -> clock_timestamp()
--   BEGIN TRANSACTION -> BEGIN
--   Products -> productmanagement_dbo.products
--   ProductHistory -> productmanagement_dbo.producthistory
--   ProductStats -> productmanagement_dbo.productstats
-- ============================================================
BEGIN;
    -- Insert history record with old values before update
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'UPDATE', price, @Price, stockquantity, @StockQuantity, clock_timestamp()
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;
    
    -- Update product statistics using old price
    UPDATE productmanagement_dbo.productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM productmanagement_dbo.products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
    
    -- Update the product
    UPDATE productmanagement_dbo.products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = clock_timestamp()
    WHERE productid = @ProductId;
COMMIT;

-- ============================================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Original Location: ProductRepository.cs, DeleteProductAsync() method
-- Conversion:
--   DECLARE @OldPrice / @OldStock -> subquery approach
--   GETDATE() -> clock_timestamp()
--   BEGIN TRANSACTION -> BEGIN
--   Products -> productmanagement_dbo.products
--   ProductHistory -> productmanagement_dbo.producthistory
--   ProductStats -> productmanagement_dbo.productstats
-- ============================================================
BEGIN;
    -- Log the deletion with old values
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, clock_timestamp()
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT price FROM productmanagement_dbo.products WHERE productid = @ProductId)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
    
    -- Delete the product
    DELETE FROM productmanagement_dbo.products 
    WHERE productid = @ProductId;
COMMIT;

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original Location: ProductRepository.cs, GetProductsByPriceRangeAsync() method
-- Conversion:
--   Products -> productmanagement_dbo.products
--   Column names -> lowercase
-- ============================================================
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

-- ============================================================
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Original Location: ProductRepository.cs, GetLowStockProductsAsync() method
-- Conversion:
--   Products -> productmanagement_dbo.products
--   Column names -> lowercase
--   Added CAST for integer division to NUMERIC for proper ROUND behavior
-- ============================================================
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
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
