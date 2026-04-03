-- ============================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: MS SQL Server to PostgreSQL Migration
-- Date: 2026-04-03
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion/creation timeout after max poll attempts
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
-- ============================================================
-- Schema mappings used (from DMS schema_mapping_tool):
--   Products -> products (productmanagement_dbo schema)
--   ProductHistory -> producthistory (productmanagement_dbo schema)
--   ProductStats -> productstats (productmanagement_dbo schema)
--   All column names -> lowercase
--   GETDATE() -> clock_timestamp()
--   SCOPE_IDENTITY() -> RETURNING clause
--   DECLARE @var -> DO $$ DECLARE v_var ... END $$
-- ============================================================

-- ============================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- Changes: All identifiers lowercased, CTE name changed to avoid
--          conflict with table name productstats
-- ============================================================
WITH productstats_cte AS (
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
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- Changes: All identifiers lowercased, CTE name changed to avoid
--          conflict with table name producthistory
-- ============================================================
WITH producthistory_cte AS (
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
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation did not complete after 15 attempts
-- Changes: SCOPE_IDENTITY() -> RETURNING productid
--          GETDATE() -> clock_timestamp()
--          DECLARE/BEGIN TRANSACTION/COMMIT -> writable CTE with RETURNING
--          All identifiers lowercased
-- NOTE: PostgreSQL writable CTEs execute all in one statement atomically
-- ============================================================
WITH inserted_product AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp()
    FROM inserted_product
    RETURNING 1 as done
),
stats_update AS (
    UPDATE productstats
    SET totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1
    RETURNING 1 as done
)
SELECT productid FROM inserted_product;

-- ============================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation did not complete after 15 attempts
-- Changes: DECLARE @var -> DO $$ DECLARE v_var
--          GETDATE() -> clock_timestamp()
--          BEGIN TRANSACTION/COMMIT -> DO $$ BEGIN/END $$
--          All identifiers lowercased
-- NOTE: Using DO $$ block for variable declarations in procedural context
-- ============================================================
DO $$
DECLARE
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = clock_timestamp()
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', v_oldprice, @Price, v_oldstock, @StockQuantity, clock_timestamp());
    
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - v_oldprice + @Price) / totalproducts,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- ============================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation did not complete after 15 attempts
-- Changes: DECLARE @var -> DO $$ DECLARE v_var
--          GETDATE() -> clock_timestamp()
--          BEGIN TRANSACTION/COMMIT -> DO $$ BEGIN/END $$
--          All identifiers lowercased
-- ============================================================
DO $$
DECLARE
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, clock_timestamp());
    
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - v_oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- ============================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation did not complete after 15 attempts
-- Changes: All identifiers lowercased
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
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation did not complete after 15 attempts
-- Changes: All identifiers lowercased
--          Added CAST(stockquantity AS NUMERIC) for integer division fix
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
