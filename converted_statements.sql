-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Total Statements: 7
-- Successfully Converted by DMS: 6
-- Manually Converted After DMS Failure: 1
-- Conversion Date: 2026-01-06
-- Target Schema: productmanagement_dbo
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED BY DMS
-- ============================================================================
-- Original Method: GetAllProductsAsync()
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products -> productmanagement_dbo.products
-- Notes: CTE and window functions converted successfully
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
-- STATEMENT 2: GetProductByIdAsync - CONVERTED BY DMS
-- ============================================================================
-- Original Method: GetProductByIdAsync(int productId)
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products -> productmanagement_dbo.products
-- Notes: LAG window function converted successfully
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
-- STATEMENT 3: InsertProductAsync - MANUALLY CONVERTED AFTER DMS FAILURE
-- ============================================================================
-- Original Method: InsertProductAsync(Product product)
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: "Statement definition is not valid." - Multi-statement batch with transaction not supported
-- Schema Changes: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- Notes: SCOPE_IDENTITY() replaced with RETURNING clause, GETDATE() -> CURRENT_TIMESTAMP, Transaction managed in C# code
-- Manual Conversion Approach: Split into individual statements, use RETURNING for ID retrieval, remove BEGIN TRANSACTION/COMMIT (managed by ADO.NET transaction)
-- ============================================================================

-- Insert the new product and return the ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following statements will be executed within the same transaction in C# code
-- Log the insertion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED BY DMS (with warnings)
-- ============================================================================
-- Original Method: UpdateProductAsync(Product product)
-- Conversion Status: SUCCESS_WITH_WARNINGS
-- Conversion Method: DMS_TOOL
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
-- Schema Changes: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- Notes: Transaction managed in C# code, GETDATE() -> clock_timestamp(), DECLARE statements converted
-- Code Integration Note: Remove DECLARE/BEGIN/END/COMMIT block, execute as individual statements within ADO.NET transaction
-- ============================================================================

-- Store old values for history
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Update the product
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Log the changes
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED BY DMS (with warnings)
-- ============================================================================
-- Original Method: DeleteProductAsync(int productId)
-- Conversion Status: SUCCESS_WITH_WARNINGS
-- Conversion Method: DMS_TOOL
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
-- Schema Changes: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- Notes: Transaction managed in C# code, GETDATE() -> clock_timestamp(), DECLARE statements converted
-- Code Integration Note: Remove DECLARE/BEGIN/END/COMMIT block, execute as individual statements within ADO.NET transaction
-- ============================================================================

-- Store product info for history
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Log the deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Delete the product
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
    ELSE 0
END, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED BY DMS
-- ============================================================================
-- Original Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products -> productmanagement_dbo.products
-- Notes: RANK and PERCENT_RANK window functions converted successfully
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
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED BY DMS
-- ============================================================================
-- Original Method: GetLowStockProductsAsync(int threshold)
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products -> productmanagement_dbo.products
-- Notes: Multiple window functions (AVG, MIN, MAX) converted successfully
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
-- END OF CONVERTED STATEMENTS
-- ============================================================================
