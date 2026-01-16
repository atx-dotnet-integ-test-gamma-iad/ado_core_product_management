-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Conversion Date: 2026-01-16
-- Tool: DMS MCP Statement Conversion Tool
-- Purpose: PostgreSQL converted statements for all SQL operations
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Original SQL Server statement converted to PostgreSQL
-- ============================================================================
WITH productstats
AS (SELECT
    productid, AVG(Price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM public.products)
SELECT
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    CASE
        WHEN p.Price > ps.avgprice THEN 'Above Average'
        WHEN p.Price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END AS pricecategory, ROUND((p.Price / ps.avgprice), 2) AS pricepercentageofaverage
    FROM public.products AS p
    INNER JOIN productstats AS ps
        ON p.ProductId = ps.productid
    ORDER BY
    CASE
        WHEN p.Price > ps.avgprice THEN 1
        ELSE 2
    END NULLS FIRST, p.Name NULLS FIRST;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Original SQL Server statement converted to PostgreSQL
-- ============================================================================
WITH producthistory
AS (SELECT
    productid, lag(Price) OVER (ORDER BY ModifiedDate) AS previousprice, lag(StockQuantity) OVER (ORDER BY ModifiedDate) AS previousstock
    FROM public.products
    WHERE productid = @ProductId)
SELECT
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, ph.previousprice, ph.previousstock,
    CASE
        WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.Price - ph.previousprice) / ph.previousprice), 2)
        ELSE NULL
    END AS pricechangepercentage
    FROM public.products AS p
    LEFT OUTER JOIN producthistory AS ph
        ON p.ProductId = ph.productid
    WHERE p.ProductId = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync - INSERT PART
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS (Partial - only INSERT statement converted)
-- Note: Full transaction block with DECLARE/BEGIN/COMMIT failed DMS conversion
-- Manual conversion applied for complete transaction logic
-- ============================================================================
INSERT INTO public.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity);

-- ============================================================================
-- STATEMENT 3B: InsertProductAsync - COMPLETE TRANSACTION
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Status: MANUAL CONVERSION
-- DMS Tool Error: "Statement definition is not valid" for DECLARE/BEGIN/COMMIT/SCOPE_IDENTITY
-- Manual PostgreSQL Conversion:
--   - DECLARE/SET removed (not needed with RETURNING)
--   - SCOPE_IDENTITY() replaced with RETURNING clause
--   - NOW() kept as-is (PostgreSQL compatible)
--   - Transaction logic should be handled at application level (ExecuteInTransactionAsync)
-- ============================================================================
-- Main INSERT with RETURNING
INSERT INTO public.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Companion statements to execute in same transaction:
-- Log the insertion
INSERT INTO public.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Update product statistics
UPDATE public.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - CORE UPDATE
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Note: Transaction and DECLARE blocks need manual handling at application level
-- ============================================================================
UPDATE public.products
SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = NOW()
    WHERE ProductId = @ProductId;

-- ============================================================================
-- STATEMENT 4B: UpdateProductAsync - COMPLETE TRANSACTION
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (for transaction logic)
-- Status: MANUAL CONVERSION
-- Transaction logic with DECLARE variables needs application-level handling
-- ============================================================================
-- First get old values
SELECT price, stockquantity FROM public.products WHERE productid = @ProductId;

-- Update the product
UPDATE public.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = NOW()
WHERE productid = @ProductId;

-- Log the changes (use values from SELECT)
INSERT INTO public.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Update product statistics
UPDATE public.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - CORE DELETE
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Note: Transaction and DECLARE blocks need manual handling at application level
-- ============================================================================
DELETE FROM public.products
    WHERE ProductId = @ProductId;

-- ============================================================================
-- STATEMENT 5B: DeleteProductAsync - COMPLETE TRANSACTION
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (for transaction logic)
-- Status: MANUAL CONVERSION
-- Transaction logic with DECLARE variables needs application-level handling
-- ============================================================================
-- First get product info
SELECT price, stockquantity FROM public.products WHERE productid = @ProductId;

-- Log the deletion (use values from SELECT)
INSERT INTO public.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Delete the product
DELETE FROM public.products WHERE productid = @ProductId;

-- Update product statistics
UPDATE public.productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Original SQL Server statement converted to PostgreSQL
-- ============================================================================
WITH rankedproducts
AS (SELECT
    p.*, RANK() OVER (ORDER BY p.Price) AS pricerank, percent_rank() OVER (ORDER BY p.Price) AS pricepercentile
    FROM public.products AS p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice)
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
-- STATEMENT 7: GetLowStockProductsAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS (with GenAI assistance)
-- Note: DMS tool used GenAI model for this conversion
-- ============================================================================
WITH stockanalysis
AS (SELECT p.*,
        AVG(StockQuantity) OVER () AS avgstock,
        MIN(StockQuantity) OVER () AS minstock,
        MAX(StockQuantity) OVER () AS maxstock
    FROM public.products AS p)
SELECT sa.*,
        CASE
            WHEN StockQuantity <= @Threshold THEN 'Critical'
            WHEN StockQuantity <= avgstock * 0.5 THEN 'Low'
            ELSE 'Adequate'
        END AS stockstatus,
        round((StockQuantity / avgstock) * 100, 2) AS stockpercentageofaverage
    FROM stockanalysis AS sa
    WHERE StockQuantity <= @Threshold
    ORDER BY StockQuantity;

-- ============================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total Statements: 7
-- DMS Tool Success: 6 (partial success on 1 - INSERT only, full transaction manual)
-- Manual Conversions: 3 (complete transaction blocks for INSERT, UPDATE, DELETE)
-- Conversion Notes:
--   - Window functions converted successfully
--   - CTE (WITH clauses) converted successfully
--   - DECLARE/BEGIN/COMMIT transactions require application-level handling
--   - SCOPE_IDENTITY() replaced with RETURNING clause pattern
--   - NOW() function is PostgreSQL compatible
--   - @parameter syntax retained (Npgsql supports this)
--   - Column names lowercased by DMS (PostgreSQL convention)
-- ============================================================================
