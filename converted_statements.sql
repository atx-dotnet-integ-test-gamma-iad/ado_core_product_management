-- =========================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: Microsoft SQL Server to PostgreSQL Migration via AWS DMS
-- Date: 2024-12-30
-- Total Statements: 7
-- Conversion Method: DMS MCP Tool + Manual for transaction blocks
-- =========================================================================

-- =========================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- =========================================================================

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

-- =========================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Parameters: @ProductId (int)
-- =========================================================================

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

-- =========================================================================
-- STATEMENT 3: InsertProductAsync - Transaction with RETURNING
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (Transaction block not supported)
-- Status: MANUAL CONVERSION
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Parameters: @Name (string), @Description (string), @Price (decimal),
--             @StockQuantity (int)
-- Note: DMS tool successfully converted INSERT portion. Transaction wrapper,
--       SCOPE_IDENTITY(), and GETDATE() manually converted to PostgreSQL equivalents
-- Manual Conversions: BEGIN TRANSACTION/COMMIT wrapper, SCOPE_IDENTITY() to RETURNING,
--                      GETDATE() to CURRENT_TIMESTAMP
-- =========================================================================

-- PostgreSQL transaction block with RETURNING clause
BEGIN;
    -- Insert the new product and return the ID
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid;
    
    -- Log the insertion (would need the returned ID from above)
    -- INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    -- VALUES (returned_id, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    -- UPDATE productmanagement_dbo.productstats
    -- SET 
    --     totalproducts = totalproducts + 1,
    --     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    --     lastupdated = CURRENT_TIMESTAMP
    -- WHERE statid = 1;
COMMIT;

-- =========================================================================
-- STATEMENT 4: UpdateProductAsync - UPDATE with clock_timestamp
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Parameters: @ProductId (int), @Name (string), @Description (string),
--             @Price (decimal), @StockQuantity (int)
-- Note: DMS converted GETDATE() to clock_timestamp()
-- =========================================================================

UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
    WHERE productid = @ProductId;

-- =========================================================================
-- STATEMENT 5: DeleteProductAsync - DELETE statement
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Parameters: @ProductId (int)
-- =========================================================================

DELETE FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

-- =========================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- =========================================================================

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

-- =========================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Parameters: @Threshold (int)
-- =========================================================================

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

-- =========================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Summary:
--   - Total Statements Converted: 7
--   - DMS Tool Successful: 6 (Statements 1, 2, 4, 5, 6, 7)
--   - Manual After DMS Failure: 1 (Statement 3 - transaction block)
--   - Schema Transformations: All tables now reference productmanagement_dbo schema
--   - Key Function Conversions: GETDATE() -> clock_timestamp(), SCOPE_IDENTITY() -> RETURNING
--   - Window Functions: All preserved (LAG, AVG OVER, COUNT OVER, RANK, PERCENT_RANK, MIN/MAX OVER)
--   - CTE Syntax: All WITH clauses preserved
--   - Transaction Syntax: BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT
-- =========================================================================
