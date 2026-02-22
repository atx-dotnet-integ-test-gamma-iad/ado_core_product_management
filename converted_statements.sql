-- ============================================================================
-- CONVERTED SQL STATEMENTS - POSTGRESQL
-- Microsoft SQL Server to PostgreSQL Migration
-- Total Statements: 8
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- All statements manually converted due to DMS tool metadata model creation errors
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED TO POSTGRESQL)
-- Source Method: GetAllProductsAsync()
-- Conversion Method: Manual (DMS Error: Metadata model creation failed)
-- Changes Applied:
--   - All table/column names converted to lowercase (products, productid, name, etc.)
--   - Window functions (AVG OVER, COUNT OVER) - Compatible with PostgreSQL
--   - CASE expressions - Compatible with PostgreSQL
--   - ROUND function - Compatible with PostgreSQL
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
-- STATEMENT 2: GetProductByIdAsync (CONVERTED TO POSTGRESQL)
-- Source Method: GetProductByIdAsync(int productId)
-- Conversion Method: Manual (DMS Error: Metadata model creation failed)
-- Changes Applied:
--   - All table/column names converted to lowercase
--   - LAG window function - Compatible with PostgreSQL
--   - Parameter syntax @ProductId remains same (will use $ notation in actual PostgreSQL queries)
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
-- STATEMENT 3: InsertProductAsync (CONVERTED TO POSTGRESQL)
-- Source Method: InsertProductAsync(Product product)
-- Conversion Method: Manual (DMS Error: Metadata model creation failed)
-- Changes Applied:
--   - All table/column names converted to lowercase
--   - DECLARE removed (PostgreSQL uses DO blocks or handles within functions)
--   - BEGIN TRANSACTION -> BEGIN
--   - SCOPE_IDENTITY() -> RETURNING clause on INSERT
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - Transaction simplified for PostgreSQL
-- NOTE: This will be adapted in C# to use separate queries with RETURNING clause
-- ============================================================================
-- PostgreSQL version (will be executed as separate statements in ADO.NET):
-- First INSERT with RETURNING:
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Then in subsequent statements use the returned productid:
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;


-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED TO POSTGRESQL)
-- Source Method: UpdateProductAsync(Product product)
-- Conversion Method: Manual (DMS Error: Metadata model creation failed)
-- Changes Applied:
--   - All table/column names converted to lowercase
--   - BEGIN TRANSACTION -> BEGIN
--   - Variable declarations adapted (will use DO block or function in PostgreSQL)
--   - GETDATE() -> CURRENT_TIMESTAMP
-- NOTE: In ADO.NET, this will be handled with NpgsqlTransaction
-- ============================================================================
DO $$
DECLARE 
    v_oldprice DECIMAL(18,2);
    v_oldstock INT;
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
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', v_oldprice, @Price, v_oldstock, @StockQuantity, CURRENT_TIMESTAMP);
    
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - v_oldprice + @Price) / totalproducts,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
END $$;


-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED TO POSTGRESQL)
-- Source Method: DeleteProductAsync(int productId)
-- Conversion Method: Manual (DMS Error: Metadata model creation failed)
-- Changes Applied:
--   - All table/column names converted to lowercase
--   - Variable declarations adapted for PostgreSQL DO block
--   - GETDATE() -> CURRENT_TIMESTAMP
-- ============================================================================
DO $$
DECLARE 
    v_oldprice DECIMAL(18,2);
    v_oldstock INT;
BEGIN
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, CURRENT_TIMESTAMP);
    
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
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
END $$;


-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED TO POSTGRESQL)
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Method: Manual (DMS Error: Metadata model creation failed)
-- Changes Applied:
--   - All table/column names converted to lowercase
--   - RANK() and PERCENT_RANK() window functions - Compatible with PostgreSQL
--   - BETWEEN operator - Compatible with PostgreSQL
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
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED TO POSTGRESQL)
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Conversion Method: Manual (DMS Error: Metadata model creation failed)
-- Changes Applied:
--   - All table/column names converted to lowercase
--   - AVG/MIN/MAX window functions - Compatible with PostgreSQL
--   - ROUND function - Compatible with PostgreSQL
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
    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;


-- ============================================================================
-- STATEMENT 8: ExecuteInTransactionAsync - Transaction Management Pattern
-- Source Method: ExecuteInTransactionAsync(Func<Task> action)
-- Conversion: Use NpgsqlTransaction instead of SqlTransaction
-- Changes Applied:
--   - SqlConnection -> NpgsqlConnection
--   - SqlTransaction -> NpgsqlTransaction
--   - await connection.BeginTransactionAsync() returns NpgsqlTransaction
-- ============================================================================
-- Pattern remains at C# ADO.NET level:
-- using var transaction = await connection.BeginTransactionAsync();
-- await transaction.CommitAsync();
-- await transaction.RollbackAsync();


-- ============================================================================
-- CONVERSION SUMMARY
-- ============================================================================
-- Total SQL Statements Converted: 8
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error for All Statements: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
--
-- Key Conversions Applied:
-- 1. Schema Object Names: All converted to lowercase (Products -> products, ProductId -> productid, etc.)
-- 2. SCOPE_IDENTITY() -> RETURNING clause pattern
-- 3. GETDATE() -> CURRENT_TIMESTAMP or NOW()
-- 4. BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT (or handled via NpgsqlTransaction in C#)
-- 5. DECLARE variables -> DO $$ DECLARE blocks (for complex transactions)
-- 6. Window Functions: AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK, MIN/MAX OVER - All compatible
-- 7. CTEs (WITH clauses) - Fully compatible with PostgreSQL
-- 8. CASE expressions - Fully compatible
-- 9. ROUND function - Fully compatible
--
-- PostgreSQL Compatibility Notes:
-- - Window functions are fully supported and syntax-compatible
-- - CTEs are fully supported with same syntax
-- - Parameter syntax in ADO.NET will use $ notation ($1, $2) or named parameters
-- - Transaction management handled at ADO.NET level with NpgsqlTransaction
-- - RETURNING clause is PostgreSQL-specific for getting generated IDs
-- ============================================================================
