-- ============================================================================
-- CONVERTED SQL STATEMENTS - SQL Server to PostgreSQL
-- Conversion Date: 2026-02-20
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Total Statements Converted: 7
-- DMS Tool Status: All 7 statements failed DMS conversion - metadata model creation error
-- Manual Conversion Applied: Lowercase schema object names for PostgreSQL compatibility
-- ============================================================================

-- ============================================================================
-- CONVERTED STATEMENT 1 of 7
-- Source Method: GetAllProductsAsync()
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Notes:
-- - Table names converted to lowercase: Products -> products
-- - Column names converted to lowercase: ProductId -> productid, Name -> name, etc.
-- - Window functions (AVG, COUNT OVER) are compatible with PostgreSQL
-- - ROUND function syntax is compatible
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
-- CONVERTED STATEMENT 2 of 7
-- Source Method: GetProductByIdAsync(int productId)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Notes:
-- - Table names converted to lowercase: Products -> products
-- - Column names converted to lowercase
-- - LAG window function is compatible with PostgreSQL
-- - Parameter names remain @ProductId (Npgsql supports this syntax)
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
-- CONVERTED STATEMENT 3 of 7
-- Source Method: InsertProductAsync(Product product)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Notes:
-- - Removed explicit transaction block (to be handled by ADO.NET transaction)
-- - Table names converted to lowercase: Products -> products, ProductHistory -> producthistory, ProductStats -> productstats
-- - Column names converted to lowercase
-- - SCOPE_IDENTITY() replaced with RETURNING clause (PostgreSQL standard)
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- - Variables removed as RETURNING handles new ID capture
-- ============================================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following statements would be executed separately in the transaction:
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (currval('products_productid_seq'), 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- CONVERTED STATEMENT 4 of 7
-- Source Method: UpdateProductAsync(Product product)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Notes:
-- - Transaction blocks removed (handled by ADO.NET)
-- - Table names converted to lowercase
-- - Column names converted to lowercase
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- - Multi-statement transaction must be handled separately via NpgsqlTransaction
-- ============================================================================
-- Statement 1: Get old values
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Statement 2: Update the product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Statement 3: Log the changes
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4: Update statistics
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- CONVERTED STATEMENT 5 of 7
-- Source Method: DeleteProductAsync(int productId)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Notes:
-- - Transaction blocks removed (handled by ADO.NET)
-- - Table names converted to lowercase
-- - Column names converted to lowercase
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- ============================================================================
-- Statement 1: Get product info
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Statement 2: Log the deletion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 3: Delete the product
DELETE FROM products 
WHERE productid = @ProductId;

-- Statement 4: Update statistics
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

-- ============================================================================
-- CONVERTED STATEMENT 6 of 7
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Notes:
-- - Table names converted to lowercase: Products -> products
-- - Column names converted to lowercase
-- - RANK() and PERCENT_RANK() window functions are compatible with PostgreSQL
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
-- CONVERTED STATEMENT 7 of 7
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Notes:
-- - Table names converted to lowercase: Products -> products
-- - Column names converted to lowercase
-- - Window functions (AVG, MIN, MAX OVER) are compatible with PostgreSQL
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
-- END OF CONVERTED SQL STATEMENTS
-- ============================================================================
-- CONVERSION SUMMARY:
-- - All 7 statements attempted through DMS MCP tool
-- - All 7 statements failed with metadata model creation error
-- - Manual conversion applied to all 7 statements
-- - Key PostgreSQL conversions:
--   * All schema objects (tables, columns) converted to lowercase
--   * GETDATE() -> CURRENT_TIMESTAMP
--   * SCOPE_IDENTITY() -> RETURNING clause
--   * Transaction blocks removed (handled by ADO.NET NpgsqlTransaction)
--   * Window functions (LAG, RANK, PERCENT_RANK, AVG/COUNT/MIN/MAX OVER) are compatible
-- ============================================================================
