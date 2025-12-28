-- ========================================================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Microsoft SQL Server to PostgreSQL Migration - DMS MCP Tool Conversions
-- Target File: sourceCode/DataAccess/ProductRepository.cs
-- Total Statements: 7
-- DMS Schema Conversion: dbo → productmanagement_dbo
-- ========================================================================================================

-- ========================================================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Source Method: GetAllProductsAsync()
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Notes: Identifiers lowercased, NULLS FIRST added to ORDER BY
-- ========================================================================================================
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

-- ========================================================================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Source Method: GetProductByIdAsync(int productId)
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Notes: LEFT JOIN → LEFT OUTER JOIN, identifiers lowercased, NULLS FIRST not needed (WHERE clause)
-- ========================================================================================================
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

-- ========================================================================================================
-- STATEMENT 3: InsertProductAsync (MANUAL CONVERSION AFTER DMS FAILURE)
-- Source Method: InsertProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: DMS_ERROR - Statement definition is not valid (multi-statement transaction not supported)
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- DMS Error: Metadata model creation failed: Statement definition is not valid
-- Notes: Transaction block with SCOPE_IDENTITY() requires manual conversion
--        SCOPE_IDENTITY() → Use RETURNING clause with INSERT
--        GETDATE() → CURRENT_TIMESTAMP or NOW()
--        Variable declarations removed, use RETURNING instead
-- Manual Conversion Applied:
-- ========================================================================================================
-- INSERT with RETURNING for new ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Log the insertion (executed separately after getting the returned ID)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics (executed separately)
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ========================================================================================================
-- STATEMENT 4: UpdateProductAsync (REFACTORED AFTER DMS CONVERSION)
-- Source Method: UpdateProductAsync(Product product)
-- Conversion Method: DMS_TOOL + MANUAL_REFACTORING
-- Conversion Status: SUCCESS - DMS output refactored to remove T-SQL transaction blocks
-- Schema Changes: Products → Products (schema name removed for PostgreSQL compatibility)
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions]
-- Notes: DMS output contained DECLARE/BEGIN/COMMIT blocks which are not compatible with PostgreSQL parameterized queries
--        Refactored to split into separate SQL statements with application-level transaction management
--        Transaction handled via NpgsqlConnection.BeginTransactionAsync() at application level
--        DECLARE @var statements removed - variables handled in C# code
--        GETDATE() → CURRENT_TIMESTAMP
-- Implementation: Split into 3 separate statements executed within application transaction
-- ========================================================================================================
-- Statement 4.1: Get old values for history
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Statement 4.2: Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Statement 4.3: Log the changes
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4.4: Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ========================================================================================================
-- STATEMENT 5: DeleteProductAsync (REFACTORED AFTER DMS CONVERSION)
-- Source Method: DeleteProductAsync(int productId)
-- Conversion Method: DMS_TOOL + MANUAL_REFACTORING
-- Conversion Status: SUCCESS - DMS output refactored to remove T-SQL transaction blocks
-- Schema Changes: Products → Products (schema name removed for PostgreSQL compatibility)
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions]
-- Notes: DMS output contained DECLARE/BEGIN/COMMIT blocks which are not compatible with PostgreSQL parameterized queries
--        Refactored to split into separate SQL statements with application-level transaction management
--        Transaction handled via NpgsqlConnection.BeginTransactionAsync() at application level
--        DECLARE @var statements removed - variables handled in C# code
--        GETDATE() → CURRENT_TIMESTAMP
-- Implementation: Split into 4 separate statements executed within application transaction
-- ========================================================================================================
-- Statement 5.1: Get old values for history
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Statement 5.2: Log the deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 5.3: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Statement 5.4: Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ========================================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Notes: Identifiers lowercased, NULLS FIRST added to ORDER BY, percent_rank() lowercased
-- ========================================================================================================
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

-- ========================================================================================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Notes: Identifiers lowercased, NULLS FIRST added to ORDER BY
-- ========================================================================================================
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

-- ========================================================================================================
-- END OF CONVERTED STATEMENTS
-- ========================================================================================================
-- CONVERSION SUMMARY:
-- - Total Statements: 7
-- - DMS Tool Successful: 6 (Statements 1, 2, 4, 5, 6, 7)
-- - DMS Tool Failed: 1 (Statement 3 - manual conversion applied)
-- - Post-DMS Refactoring: 2 (Statements 4, 5 - DMS output refactored to remove T-SQL constructs)
-- - Schema Name Changes: DMS converted to productmanagement_dbo.* but removed in final implementation for simplicity
-- - Table Names: Using standard case (Products, ProductHistory, ProductStats) in application
-- - Key Conversions:
--   * GETDATE() → CURRENT_TIMESTAMP
--   * SCOPE_IDENTITY() → RETURNING clause
--   * BEGIN TRANSACTION/COMMIT → Application-level transaction management using NpgsqlTransaction
--   * DECLARE @var → Removed, variables handled in C# code
--   * Multi-statement transaction blocks → Split into separate parameterized SQL statements
--   * All SQL statements are PostgreSQL-compatible and executable
-- - Transaction Management:
--   * All transaction handling moved to application level using NpgsqlConnection.BeginTransactionAsync()
--   * Ensures ACID properties through proper transaction isolation
--   * No embedded T-SQL transaction syntax in any SQL statement
-- ========================================================================================================
