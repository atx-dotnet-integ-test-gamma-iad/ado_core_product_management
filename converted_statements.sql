-- ============================================================================
-- Converted SQL Statements Catalog (PostgreSQL)
-- Source: AdoCore Application - Microsoft SQL Server to PostgreSQL Migration
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
-- DMS statement_conversion_tool Status: FAILED for all 7 statements
-- DMS Error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (PostgreSQL)
-- Original Source: DataAccess/ProductRepository.cs - GetAllProductsAsync()
-- Conversion: Manual with lowercase schema from DMS schema_mapping_tool
-- Key Changes: Table/column names lowercased, CTE name changed to avoid conflict
-- ============================================================================

-- [PGSQL_STATEMENT_1]
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
    p.name
-- [/PGSQL_STATEMENT_1]

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync (PostgreSQL)
-- Original Source: DataAccess/ProductRepository.cs - GetProductByIdAsync()
-- Conversion: Manual with lowercase schema from DMS schema_mapping_tool
-- Key Changes: Table/column names lowercased, CTE name changed to avoid conflict
-- ============================================================================

-- [PGSQL_STATEMENT_2]
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
WHERE p.productid = @ProductId
-- [/PGSQL_STATEMENT_2]

-- ============================================================================
-- STATEMENT 3: InsertProductAsync (PostgreSQL)
-- Original Source: DataAccess/ProductRepository.cs - InsertProductAsync()
-- Conversion: Manual with lowercase schema from DMS schema_mapping_tool
-- Key Changes: SCOPE_IDENTITY() -> lastval(), GETDATE() -> clock_timestamp(),
--   table/column names lowercased, used INSERT RETURNING for new ID retrieval
--   Transaction handling moved to C# code (NpgsqlTransaction)
-- ============================================================================

-- [PGSQL_STATEMENT_3]
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;
-- [/PGSQL_STATEMENT_3]

-- Note: The following companion statements are executed separately within the C# transaction:
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());
--
-- UPDATE productstats SET totalproducts = totalproducts + 1,
--   averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--   lastupdated = clock_timestamp() WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (PostgreSQL)
-- Original Source: DataAccess/ProductRepository.cs - UpdateProductAsync()
-- Conversion: Manual with lowercase schema from DMS schema_mapping_tool
-- Key Changes: DECLARE/@variables replaced with SELECT INTO + separate statements,
--   GETDATE() -> clock_timestamp(), table/column names lowercased
--   Transaction handling moved to C# code (NpgsqlTransaction)
-- ============================================================================

-- [PGSQL_STATEMENT_4]
-- Part 4a: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;
-- Part 4b: Update product
UPDATE products SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp() WHERE productid = @ProductId;
-- Part 4c: Log changes
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());
-- Part 4d: Update stats
UPDATE productstats SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp() WHERE statid = 1;
-- [/PGSQL_STATEMENT_4]

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (PostgreSQL)
-- Original Source: DataAccess/ProductRepository.cs - DeleteProductAsync()
-- Conversion: Manual with lowercase schema from DMS schema_mapping_tool
-- Key Changes: Same as Statement 4 - variables managed in C# code,
--   GETDATE() -> clock_timestamp(), table/column names lowercased
--   Transaction handling moved to C# code (NpgsqlTransaction)
-- ============================================================================

-- [PGSQL_STATEMENT_5]
-- Part 5a: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;
-- Part 5b: Log deletion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());
-- Part 5c: Delete product
DELETE FROM products WHERE productid = @ProductId;
-- Part 5d: Update stats
UPDATE productstats SET totalproducts = totalproducts - 1, averageprice = CASE WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1) ELSE 0 END, lastupdated = clock_timestamp() WHERE statid = 1;
-- [/PGSQL_STATEMENT_5]

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original Source: DataAccess/ProductRepository.cs - GetProductsByPriceRangeAsync()
-- Conversion: Manual with lowercase schema from DMS schema_mapping_tool
-- Key Changes: Table/column names lowercased
-- ============================================================================

-- [PGSQL_STATEMENT_6]
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
ORDER BY rp.pricerank
-- [/PGSQL_STATEMENT_6]

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync (PostgreSQL)
-- Original Source: DataAccess/ProductRepository.cs - GetLowStockProductsAsync()
-- Conversion: Manual with lowercase schema from DMS schema_mapping_tool
-- Key Changes: Table/column names lowercased, CAST for integer division
-- ============================================================================

-- [PGSQL_STATEMENT_7]
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
ORDER BY stockquantity
-- [/PGSQL_STATEMENT_7]

-- ============================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (all 7)
-- DMS schema_mapping_tool: Used successfully for schema/column name mappings
-- ============================================================================
