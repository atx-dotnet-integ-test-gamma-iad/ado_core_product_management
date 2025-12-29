-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Microsoft SQL Server to PostgreSQL Migration via DMS MCP Tool
-- Generated: 2024-12-29
-- Total Statements: 7
-- Successfully Converted by DMS: 6
-- Manual Conversion Required: 1 (Statement 3)
-- ============================================================================
-- IMPORTANT: Schema transformed by DMS from 'dbo' to 'productmanagement_dbo'
-- All table names: Products → productmanagement_dbo.products
--                 ProductHistory → productmanagement_dbo.producthistory
--                 ProductStats → productmanagement_dbo.productstats
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (DMS_TOOL)
-- ============================================================================
-- Original: DataAccess/ProductRepository.cs, GetAllProductsAsync, Lines 38-68
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Transformation: Products → productmanagement_dbo.products
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
-- STATEMENT 2: GetProductByIdAsync (DMS_TOOL)
-- ============================================================================
-- Original: DataAccess/ProductRepository.cs, GetProductByIdAsync, Lines 81-108
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Transformation: Products → productmanagement_dbo.products
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
-- STATEMENT 3: InsertProductAsync (MANUAL_AFTER_DMS_FAILURE)
-- ============================================================================
-- Original: DataAccess/ProductRepository.cs, InsertProductAsync, Lines 122-148
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: MANUAL
-- DMS Error: Statement definition is not valid
-- Manual Conversion Notes:
--   - Transaction management removed (handled by C# ExecuteInTransactionAsync)
--   - SCOPE_IDENTITY() replaced with RETURNING clause
--   - GETDATE() replaced with NOW()
--   - Schema transformation applied: Products → productmanagement_dbo.products
-- ============================================================================

-- Insert the new product and return the ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Log the insertion (separate statement within transaction)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (LASTVAL(), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Update product statistics (separate statement within transaction)
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (DMS_TOOL)
-- ============================================================================
-- Original: DataAccess/ProductRepository.cs, UpdateProductAsync, Lines 161-192
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS_WITH_WARNING
-- DMS Warning: PostgreSQL does not support explicit transaction management commands
-- Note: Transaction wrapper removed (handled by C# ExecuteInTransactionAsync)
-- Schema Transformation: All tables → productmanagement_dbo.*
-- ============================================================================

-- Store old values for history
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    
    -- Update the product
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId;
    
    -- Log the changes
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
        WHERE statid = 1;
END;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (DMS_TOOL)
-- ============================================================================
-- Original: DataAccess/ProductRepository.cs, DeleteProductAsync, Lines 203-233
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS_WITH_WARNING
-- DMS Warning: PostgreSQL does not support explicit transaction management commands
-- Note: Transaction wrapper removed (handled by C# ExecuteInTransactionAsync)
-- Schema Transformation: All tables → productmanagement_dbo.*
-- ============================================================================

-- Store product info for history
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    
    -- Log the deletion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());
    
    -- Delete the product
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = clock_timestamp()
        WHERE statid = 1;
END;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (DMS_TOOL)
-- ============================================================================
-- Original: DataAccess/ProductRepository.cs, GetProductsByPriceRangeAsync, Lines 246-269
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Transformation: Products → productmanagement_dbo.products
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
-- STATEMENT 7: GetLowStockProductsAsync (DMS_TOOL)
-- ============================================================================
-- Original: DataAccess/ProductRepository.cs, GetLowStockProductsAsync, Lines 284-312
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Transformation: Products → productmanagement_dbo.products
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
-- END OF CONVERTED STATEMENTS CATALOG
-- ============================================================================
