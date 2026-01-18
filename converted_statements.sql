-- ==================================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Target Database: PostgreSQL
-- Schema: productmanagement_dbo
-- Total Statements Converted: 7
-- ==================================================================================

-- ==================================================================================
-- CONVERTED STATEMENT 1: GetAllProductsAsync
-- ==================================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Original Method: GetAllProductsAsync()
-- Schema Changes: Products -> productmanagement_dbo.products
-- Key Changes: Lowercase identifiers, schema prefix added, NULLS FIRST in ORDER BY
-- ==================================================================================

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

-- ==================================================================================
-- CONVERTED STATEMENT 2: GetProductByIdAsync
-- ==================================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Original Method: GetProductByIdAsync(int productId)
-- Schema Changes: Products -> productmanagement_dbo.products
-- Key Changes: Lowercase identifiers, schema prefix added, LEFT JOIN -> LEFT OUTER JOIN
-- ==================================================================================

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

-- ==================================================================================
-- CONVERTED STATEMENT 3: InsertProductAsync
-- ==================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: MANUAL (DMS Failed: Statement definition is not valid)
-- Original Method: InsertProductAsync(Product product)
-- Schema Changes: Products -> productmanagement_dbo.products, 
--                 ProductHistory -> productmanagement_dbo.producthistory,
--                 ProductStats -> productmanagement_dbo.productstats
-- Key Changes: 
--   - Removed DECLARE @NewProductId (not needed with RETURNING)
--   - Removed explicit BEGIN TRANSACTION/COMMIT (handled by ADO.NET)
--   - SCOPE_IDENTITY() -> RETURNING productid
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - Lowercase identifiers
--   - Schema prefix added
-- DMS Error: Metadata model creation failed: Statement definition is not valid
-- ==================================================================================

-- Insert the new product
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Log the insertion (executed separately in application code after getting returned productid)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics (executed separately in application code)
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ==================================================================================
-- CONVERTED STATEMENT 4: UpdateProductAsync
-- ==================================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS_WITH_WARNING
-- Original Method: UpdateProductAsync(Product product)
-- Schema Changes: Products -> productmanagement_dbo.products,
--                 ProductHistory -> productmanagement_dbo.producthistory,
--                 ProductStats -> productmanagement_dbo.productstats
-- Key Changes: 
--   - DECLARE @Variable -> var_Variable (PostgreSQL convention)
--   - GETDATE() -> clock_timestamp()
--   - Lowercase identifiers
--   - Schema prefix added
--   - BEGIN TRANSACTION/COMMIT removed (warning - handled at application level)
-- DMS Warning: [7807 - CRITICAL] PostgreSQL does not support explicit transaction 
--              management commands in functions. Convert source code manually.
-- Note: Transaction management handled by ADO.NET BeginTransactionAsync()
-- ==================================================================================

DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store old values for history */
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update the product */
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId;
    /* Log the changes */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
        WHERE statid = 1;
END;

-- ==================================================================================
-- CONVERTED STATEMENT 5: DeleteProductAsync
-- ==================================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS_WITH_WARNING
-- Original Method: DeleteProductAsync(int productId)
-- Schema Changes: Products -> productmanagement_dbo.products,
--                 ProductHistory -> productmanagement_dbo.producthistory,
--                 ProductStats -> productmanagement_dbo.productstats
-- Key Changes: 
--   - DECLARE @Variable -> var_Variable (PostgreSQL convention)
--   - GETDATE() -> clock_timestamp()
--   - Lowercase identifiers
--   - Schema prefix added
--   - BEGIN TRANSACTION/COMMIT removed (warning - handled at application level)
-- DMS Warning: [7807 - CRITICAL] PostgreSQL does not support explicit transaction 
--              management commands in functions. Convert source code manually.
-- Note: Transaction management handled by ADO.NET BeginTransactionAsync()
-- ==================================================================================

DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store product info for history */
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Log the deletion */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());
    /* Delete the product */
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = clock_timestamp()
        WHERE statid = 1;
END;

-- ==================================================================================
-- CONVERTED STATEMENT 6: GetProductsByPriceRangeAsync
-- ==================================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Original Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Schema Changes: Products -> productmanagement_dbo.products
-- Key Changes: Lowercase identifiers, schema prefix added, NULLS FIRST in ORDER BY
-- ==================================================================================

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

-- ==================================================================================
-- CONVERTED STATEMENT 7: GetLowStockProductsAsync
-- ==================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: MANUAL (DMS Failed: Conversion timeout after 15 attempts)
-- Original Method: GetLowStockProductsAsync(int threshold)
-- Schema Changes: Products -> productmanagement_dbo.products
-- Key Changes: Lowercase identifiers, schema prefix added, NULLS FIRST in ORDER BY
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- ==================================================================================

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

-- ==================================================================================
-- END OF CONVERSION CATALOG
-- ==================================================================================
-- Summary:
-- - Total Statements Converted: 7
-- - DMS Tool Successful: 4 (Statements 1, 2, 6)
-- - DMS Tool Success with Warnings: 2 (Statements 4, 5)
-- - Manual Conversion Required: 2 (Statements 3, 7)
-- - Schema Name: productmanagement_dbo (all Products, ProductHistory, ProductStats prefixed)
-- - Key PostgreSQL Adaptations:
--   * Lowercase identifiers throughout
--   * NULLS FIRST added to ORDER BY clauses
--   * GETDATE() -> clock_timestamp() or CURRENT_TIMESTAMP
--   * SCOPE_IDENTITY() -> RETURNING clause
--   * Transaction management delegated to ADO.NET
-- ==================================================================================
