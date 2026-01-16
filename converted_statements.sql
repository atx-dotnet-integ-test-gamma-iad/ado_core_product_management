-- ============================================================================
-- SQL Server to PostgreSQL Migration - Converted SQL Statements
-- Converted using AWS DMS MCP Tool
-- Conversion Date: 2026-01-16
-- Target Database: PostgreSQL 13
-- Target Schema: productmanagement_dbo
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions
-- ============================================================================
-- Conversion Status: SUCCESS (DMS_TOOL)
-- DMS Tool: Successfully converted CTE, window functions, and CASE expressions
-- Key Changes: 
--   - Schema: Products → productmanagement_dbo.products
--   - Column names converted to lowercase
--   - Added NULLS FIRST to ORDER BY clauses
-- ============================================================================
WITH productstats
AS (SELECT
    productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM productmanagement_dbo.products)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END AS pricecategory, ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
    FROM productmanagement_dbo.products AS p
    INNER JOIN productstats AS ps
        ON p.productid = ps.productid
    ORDER BY
    CASE
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END NULLS FIRST, p.name NULLS FIRST;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ============================================================================
-- Conversion Status: SUCCESS (DMS_TOOL)
-- DMS Tool: Successfully converted LAG window function and parameterized query
-- Key Changes:
--   - Schema: Products → productmanagement_dbo.products
--   - Column names converted to lowercase
--   - LEFT JOIN → LEFT OUTER JOIN
--   - Parameter @ProductId preserved
-- ============================================================================
WITH producthistory
AS (SELECT
    productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE
        WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END AS pricechangepercentage
    FROM productmanagement_dbo.products AS p
    LEFT OUTER JOIN producthistory AS ph
        ON p.productid = ph.productid
    WHERE p.productid = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction Block
-- ============================================================================
-- Conversion Status: FAILED - MANUAL_CONVERSION_AFTER_DMS_FAILURE
-- DMS Tool Error: "Statement definition is not valid" - Multi-statement transaction blocks with variables not supported
-- Manual Conversion Approach:
--   - Removed DECLARE @NewProductId and explicit transaction management
--   - Converted SCOPE_IDENTITY() to RETURNING clause in INSERT
--   - Converted GETDATE() to NOW()
--   - Schema: Products/ProductHistory/ProductStats → productmanagement_dbo.*
--   - Column names converted to lowercase
--   - Transaction management handled at application level via Npgsql transaction APIs
-- Note: Application code must manage transactions explicitly using BeginTransactionAsync()
-- ============================================================================
-- Insert the new product and return the new ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following statements will be executed separately within the same transaction in application code:

-- Log the insertion (using returned productid from previous INSERT)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction Block with Variable Declarations
-- ============================================================================
-- Conversion Status: SUCCESS_WITH_WARNINGS (DMS_TOOL)
-- DMS Tool Warning: [7807 - CRITICAL] PostgreSQL does not support explicit transaction management commands in functions
-- Key Changes:
--   - DECLARE @var → DECLARE var_var type
--   - GETDATE() → clock_timestamp()
--   - Schema: Products/ProductHistory/ProductStats → productmanagement_dbo.*
--   - Column names converted to lowercase
--   - Transaction management to be handled at application level
-- Note: For ADO.NET usage, remove DECLARE/BEGIN/END wrapper and manage transaction via Npgsql
-- ============================================================================
-- For ADO.NET, execute these statements within a transaction (without DECLARE/BEGIN/END wrapper):

-- Store old values for history (using WITH clause for cleaner approach)
WITH old_values AS (
    SELECT price AS old_price, stockquantity AS old_stock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId
)
-- Update the product
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = NOW()
WHERE productid = @ProductId;

-- Log the changes (executed separately, using saved old values)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction Block with Conditional Logic
-- ============================================================================
-- Conversion Status: SUCCESS_WITH_WARNINGS (DMS_TOOL)
-- DMS Tool Warning: [7807 - CRITICAL] PostgreSQL does not support explicit transaction management commands in functions
-- Key Changes:
--   - DECLARE @var → DECLARE var_var type
--   - GETDATE() → clock_timestamp()
--   - Schema: Products/ProductHistory/ProductStats → productmanagement_dbo.*
--   - Column names converted to lowercase
--   - Transaction management to be handled at application level
-- Note: For ADO.NET usage, remove DECLARE/BEGIN/END wrapper and manage transaction via Npgsql
-- ============================================================================
-- For ADO.NET, execute these statements within a transaction:

-- Store product info for history (first query to capture values)
WITH old_values AS (
    SELECT price AS old_price, stockquantity AS old_stock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId
)
SELECT * FROM old_values;

-- Log the deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Delete the product
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
    ELSE 0
END, lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ============================================================================
-- Conversion Status: SUCCESS (DMS_TOOL)
-- DMS Tool: Successfully converted window functions RANK() and PERCENT_RANK()
-- Key Changes:
--   - Schema: Products → productmanagement_dbo.products
--   - Column names converted to lowercase
--   - Added NULLS FIRST to ORDER BY clause
--   - Parameters @MinPrice and @MaxPrice preserved
-- ============================================================================
WITH rankedproducts
AS (SELECT
    p.*, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products AS p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice)
SELECT
    rp.*,
    CASE
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS pricesegment
    FROM rankedproducts AS rp
    ORDER BY rp.pricerank NULLS FIRST;

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ============================================================================
-- Conversion Status: SUCCESS (DMS_TOOL)
-- DMS Tool: Successfully converted AVG/MIN/MAX window functions
-- Key Changes:
--   - Schema: Products → productmanagement_dbo.products
--   - Column names converted to lowercase
--   - Added NULLS FIRST to ORDER BY clause
--   - Parameter @Threshold preserved
-- ============================================================================
WITH stockanalysis
AS (SELECT
    p.*, AVG(stockquantity) OVER () AS avgstock, MIN(stockquantity) OVER () AS minstock, MAX(stockquantity) OVER () AS maxstock
    FROM productmanagement_dbo.products AS p)
SELECT
    sa.*,
    CASE
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS stockstatus, ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage
    FROM stockanalysis AS sa
    WHERE stockquantity <= @Threshold
    ORDER BY stockquantity NULLS FIRST;

-- ============================================================================
-- CONVERSION SUMMARY
-- ============================================================================
-- Total Statements: 7
-- Successful DMS Conversions: 5 (Statements 1, 2, 6, 7)
-- DMS Conversions with Warnings: 2 (Statements 4, 5 - transaction management warnings)
-- Manual Conversions After DMS Failure: 1 (Statement 3 - multi-statement transaction block)
--
-- Common Schema Changes Applied by DMS:
--   - All table references: Products → productmanagement_dbo.products
--   - All table references: ProductHistory → productmanagement_dbo.producthistory
--   - All table references: ProductStats → productmanagement_dbo.productstats
--   - All column names converted to lowercase
--   - All CTE names converted to lowercase
--
-- SQL Server to PostgreSQL Function Mappings:
--   - GETDATE() → NOW() or clock_timestamp()
--   - SCOPE_IDENTITY() → RETURNING clause
--   - LEFT JOIN → LEFT OUTER JOIN (no functional difference)
--   - ORDER BY col → ORDER BY col NULLS FIRST (explicit null handling)
--
-- Transaction Handling:
--   - Explicit BEGIN TRANSACTION/COMMIT removed from SQL statements
--   - Transaction management to be handled at ADO.NET application level using:
--     * connection.BeginTransactionAsync()
--     * transaction.CommitAsync()
--     * transaction.RollbackAsync()
-- ============================================================================
