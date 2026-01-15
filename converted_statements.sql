-- =====================================================================
-- PostgreSQL Converted SQL Statements Catalog
-- Project: ADO.NET Core Product Management - SQL Server to PostgreSQL Migration
-- Date Converted: 2026-01-15
-- Total Statements: 7
-- DMS Tool Success: 6
-- Manual Conversion After DMS Failure: 1
-- =====================================================================

-- =====================================================================
-- STATEMENT 1: GetAllProductsAsync - DMS_TOOL_SUCCESS
-- =====================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: GetAllProductsAsync
-- Conversion Method: DMS_TOOL_SUCCESS
-- DMS Conversion Timestamp: 2026-01-15T21:46:06.821113
-- Schema Transformation: Products -> productmanagement_dbo.products
-- Notable Changes:
--   - Table qualified with schema: productmanagement_dbo.products
--   - Column names lowercase: productid, name, description, etc.
--   - CTE name lowercase: productstats
--   - Added NULLS FIRST to ORDER BY clauses (PostgreSQL explicit null handling)
-- =====================================================================

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

-- =====================================================================
-- STATEMENT 2: GetProductByIdAsync - DMS_TOOL_SUCCESS
-- =====================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: GetProductByIdAsync
-- Conversion Method: DMS_TOOL_SUCCESS
-- DMS Conversion Timestamp: 2026-01-15T21:48:03.485953
-- Schema Transformation: Products -> productmanagement_dbo.products
-- Notable Changes:
--   - Table qualified with schema: productmanagement_dbo.products
--   - Column names lowercase
--   - CTE name lowercase: producthistory
--   - LAG window function preserved (PostgreSQL compatible)
--   - LEFT JOIN changed to LEFT OUTER JOIN (explicit)
--   - Parameters remain with @ syntax (to be updated in code to $1 style)
-- =====================================================================

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

-- =====================================================================
-- STATEMENT 3: InsertProductAsync - MANUAL_AFTER_DMS_FAILURE
-- =====================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: InsertProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Error: "Metadata model creation failed: {'default_error_details': {'message': 'Statement definition is not valid.'}}"
-- Manual Conversion Reasoning:
--   DMS tool cannot process complex transaction blocks with DECLARE/SET/SCOPE_IDENTITY
--   and procedural logic. Manual conversion applies PostgreSQL best practices:
--   1. Use RETURNING clause instead of SCOPE_IDENTITY()
--   2. GETDATE() -> CURRENT_TIMESTAMP
--   3. Transaction management handled at ADO.NET connection level
--   4. Multiple statements will be executed separately within a transaction
-- Schema Transformation: Products -> productmanagement_dbo.products
--                       ProductHistory -> productmanagement_dbo.producthistory
--                       ProductStats -> productmanagement_dbo.productstats
-- 
-- NOTE: This will require THREE separate commands in a transaction:
--   Command 1: INSERT into products with RETURNING
--   Command 2: INSERT into producthistory 
--   Command 3: UPDATE productstats
-- =====================================================================

-- Command 1: Insert product and return new ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity, createddate)
VALUES (@Name, @Description, @Price, @StockQuantity, CURRENT_TIMESTAMP)
RETURNING productid;

-- Command 2: Insert product history (executed after getting returned productid)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Command 3: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- =====================================================================
-- STATEMENT 4: UpdateProductAsync - DMS_TOOL_SUCCESS_WITH_WARNINGS
-- =====================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: UpdateProductAsync
-- Conversion Method: DMS_TOOL_SUCCESS_WITH_WARNINGS
-- DMS Conversion Timestamp: 2026-01-15T21:50:26.262624
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--              transaction management commands such as BEGIN TRAN, SAVE TRAN in 
--              functions. Convert your source code manually.]
-- Schema Transformation: Products -> productmanagement_dbo.products
--                       ProductHistory -> productmanagement_dbo.producthistory
--                       ProductStats -> productmanagement_dbo.productstats
-- Notable Changes:
--   - DECLARE variables changed to PostgreSQL format (var_OldPrice, var_OldStock)
--   - BEGIN TRANSACTION converted to BEGIN/END block (transaction handled in code)
--   - GETDATE() -> clock_timestamp()
--   - SELECT to populate variables uses AS alias
--   - All table/column names lowercase and schema qualified
--
-- NOTE: Since this is embedded in ADO.NET code (not a stored function), we can
--       ignore the transaction warning and handle transactions at connection level.
--       The variable declarations and BEGIN/END block need to be removed, and
--       multiple statements executed separately within a C# transaction.
-- =====================================================================

-- Command 1: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Command 2: Update product
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, 
    stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Command 3: Log history
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Command 4: Update statistics
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, 
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- =====================================================================
-- STATEMENT 5: DeleteProductAsync - DMS_TOOL_SUCCESS_WITH_WARNINGS
-- =====================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: DeleteProductAsync
-- Conversion Method: DMS_TOOL_SUCCESS_WITH_WARNINGS
-- DMS Conversion Timestamp: 2026-01-15T21:52:23.787935
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--              transaction management commands such as BEGIN TRAN, SAVE TRAN in 
--              functions. Convert your source code manually.]
-- Schema Transformation: Products -> productmanagement_dbo.products
--                       ProductHistory -> productmanagement_dbo.producthistory
--                       ProductStats -> productmanagement_dbo.productstats
-- Notable Changes:
--   - Similar to Statement 4, procedural block structure needs adaptation
--   - GETDATE() -> clock_timestamp()
--   - CASE expression for preventing division by zero preserved
--   - All table/column names lowercase and schema qualified
--
-- NOTE: Multiple statements will be executed separately within a C# transaction.
-- =====================================================================

-- Command 1: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Command 2: Log deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Command 3: Delete product
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Command 4: Update statistics
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, 
    averageprice = CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, 
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- =====================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - DMS_TOOL_SUCCESS
-- =====================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: GetProductsByPriceRangeAsync
-- Conversion Method: DMS_TOOL_SUCCESS
-- DMS Conversion Timestamp: 2026-01-15T21:54:20.741739
-- Schema Transformation: Products -> productmanagement_dbo.products
-- Notable Changes:
--   - Table qualified with schema
--   - Column names lowercase
--   - CTE name lowercase: rankedproducts
--   - RANK() and PERCENT_RANK() window functions preserved (PostgreSQL compatible)
--   - BETWEEN operator preserved
--   - Added NULLS FIRST to ORDER BY
-- =====================================================================

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

-- =====================================================================
-- STATEMENT 7: GetLowStockProductsAsync - DMS_TOOL_SUCCESS
-- =====================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: GetLowStockProductsAsync
-- Conversion Method: DMS_TOOL_SUCCESS
-- DMS Conversion Timestamp: 2026-01-15T21:56:18.179502
-- Schema Transformation: Products -> productmanagement_dbo.products
-- Notable Changes:
--   - Table qualified with schema
--   - Column names lowercase
--   - CTE name lowercase: stockanalysis
--   - AVG/MIN/MAX window functions preserved (PostgreSQL compatible)
--   - ROUND function preserved
--   - Added NULLS FIRST to ORDER BY
-- =====================================================================

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

-- =====================================================================
-- END OF CONVERSION CATALOG
-- =====================================================================
-- Summary:
-- - Total Statements Converted: 7
-- - DMS Tool Success: 6 (Statements 1, 2, 4, 5, 6, 7)
-- - DMS Tool Success with Warnings: 2 (Statements 4, 5 - transaction warnings)
-- - Manual Conversion After DMS Failure: 1 (Statement 3)
-- - Common Transformations Applied:
--   * Schema qualification: Products -> productmanagement_dbo.products
--   * Column name case: ProductId -> productid
--   * CTE name case: ProductStats -> productstats
--   * Date function: GETDATE() -> CURRENT_TIMESTAMP (or clock_timestamp())
--   * Transaction handling: Moved to ADO.NET connection level
--   * SCOPE_IDENTITY() -> RETURNING clause
--   * Parameters: Remain with @ syntax (will be updated to $1, $2, etc. in C# code)
--   * NULL handling: Added NULLS FIRST to ORDER BY clauses
-- - Key Schema Object Name Changes by DMS:
--   * dbo.Products -> productmanagement_dbo.products
--   * dbo.ProductHistory -> productmanagement_dbo.producthistory
--   * dbo.ProductStats -> productmanagement_dbo.productstats
-- =====================================================================
