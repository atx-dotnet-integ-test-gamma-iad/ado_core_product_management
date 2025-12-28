-- =====================================================================
-- SQL Server to PostgreSQL Migration - Converted SQL Statements Catalog
-- =====================================================================
-- Project: AdoCore - Microsoft SQL Server to PostgreSQL Migration
-- Conversion Date: 2024-12-28
-- Source: extracted_statements.sql
-- Conversion Tool: AWS DMS MCP Statement Conversion Tool
-- Total Statements: 7
-- Successfully Converted: 6
-- Manual Conversion Required: 1
-- =====================================================================

-- =====================================================================
-- CONVERTED STATEMENT 1: Get All Products with Window Functions and CTE
-- =====================================================================
-- Original Source: DataAccess/ProductRepository.cs - GetAllProductsAsync()
-- Conversion Status: SUCCESS (DMS TOOL)
-- Conversion Timestamp: 2025-12-28T08:24:29.164707
-- Schema Changes: Products → productmanagement_dbo.products
-- Notable Conversions:
--   - CTE name converted to lowercase: ProductStats → productstats
--   - Column names converted to lowercase
--   - ORDER BY adds NULLS FIRST clauses (PostgreSQL best practice)
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
-- CONVERTED STATEMENT 2: Get Product By ID with LAG Window Function
-- =====================================================================
-- Original Source: DataAccess/ProductRepository.cs - GetProductByIdAsync()
-- Conversion Status: SUCCESS (DMS TOOL)
-- Conversion Timestamp: 2025-12-28T08:25:09.966745
-- Schema Changes: Products → productmanagement_dbo.products
-- Notable Conversions:
--   - LAG function preserved (PostgreSQL compatible)
--   - LEFT JOIN converted to LEFT OUTER JOIN (explicit)
--   - Parameter @ProductId preserved (Npgsql compatible)
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
-- CONVERTED STATEMENT 3: Insert Product with Transaction Block
-- =====================================================================
-- Original Source: DataAccess/ProductRepository.cs - InsertProductAsync()
-- Conversion Status: FAILED (DMS TOOL ERROR - Manual Conversion Required)
-- Conversion Timestamp: 2025-12-28T08:25:51.104857
-- DMS Error: "Statement definition is not valid"
-- Manual Conversion Applied: YES
-- Schema Changes: Products → productmanagement_dbo.products
--                 ProductHistory → productmanagement_dbo.producthistory
--                 ProductStats → productmanagement_dbo.productstats
-- Notable Conversions:
--   - SCOPE_IDENTITY() → RETURNING clause (must be applied in C# code)
--   - GETDATE() → CURRENT_TIMESTAMP or NOW()
--   - BEGIN TRANSACTION/COMMIT handled at application level (C# transaction)
--   - DECLARE @NewProductId removed (use RETURNING productid)
-- =====================================================================

-- Note: Transaction management (BEGIN/COMMIT) will be handled by C# code using
-- NpgsqlConnection.BeginTransaction(). The SQL statements below execute within
-- that transaction context.

-- Insert the new product and return the ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Log the insertion (NewProductId will come from RETURNING clause above)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- =====================================================================
-- CONVERTED STATEMENT 4: Update Product with Transaction Block
-- =====================================================================
-- Original Source: DataAccess/ProductRepository.cs - UpdateProductAsync()
-- Conversion Status: SUCCESS WITH WARNINGS (DMS TOOL)
-- Conversion Timestamp: 2025-12-28T08:26:16.893165
-- DMS Warning: [7807 - CRITICAL] PostgreSQL does not support explicit transaction
--              management commands such as BEGIN TRAN, SAVE TRAN in functions
-- Schema Changes: Products → productmanagement_dbo.products
--                 ProductHistory → productmanagement_dbo.producthistory
--                 ProductStats → productmanagement_dbo.productstats
-- Notable Conversions:
--   - DECLARE @OldPrice → var_OldPrice (local variable)
--   - GETDATE() → clock_timestamp()
--   - BEGIN TRANSACTION commented out (handle in C# code)
--   - SELECT INTO syntax adjusted for PostgreSQL
-- =====================================================================

-- Note: Transaction management will be handled by C# code
-- Store old values for history
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    
    -- Update the product
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId;
    
    -- Log the changes
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', var_OldPrice, @Price, var_OldStock, @StockQuantity, clock_timestamp());
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - var_OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
        WHERE statid = 1;
END $$;

-- =====================================================================
-- CONVERTED STATEMENT 5: Delete Product with Transaction Block
-- =====================================================================
-- Original Source: DataAccess/ProductRepository.cs - DeleteProductAsync()
-- Conversion Status: SUCCESS WITH WARNINGS (DMS TOOL)
-- Conversion Timestamp: 2025-12-28T08:26:57.663618
-- DMS Warning: [7807 - CRITICAL] PostgreSQL does not support explicit transaction
--              management commands such as BEGIN TRAN, SAVE TRAN in functions
-- Schema Changes: Products → productmanagement_dbo.products
--                 ProductHistory → productmanagement_dbo.producthistory
--                 ProductStats → productmanagement_dbo.productstats
-- Notable Conversions:
--   - DECLARE @OldPrice → var_OldPrice (local variable)
--   - GETDATE() → clock_timestamp()
--   - CASE WHEN preserved (PostgreSQL compatible)
--   - BEGIN TRANSACTION commented out (handle in C# code)
-- =====================================================================

-- Note: Transaction management will be handled by C# code
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    -- Store product info for history
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    
    -- Log the deletion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', var_OldPrice, NULL, var_OldStock, NULL, clock_timestamp());
    
    -- Delete the product
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - var_OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = clock_timestamp()
        WHERE statid = 1;
END $$;

-- =====================================================================
-- CONVERTED STATEMENT 6: Get Products By Price Range with Window Functions
-- =====================================================================
-- Original Source: DataAccess/ProductRepository.cs - GetProductsByPriceRangeAsync()
-- Conversion Status: SUCCESS (DMS TOOL)
-- Conversion Timestamp: 2025-12-28T08:27:41.384273
-- Schema Changes: Products → productmanagement_dbo.products
-- Notable Conversions:
--   - RANK() and PERCENT_RANK() preserved (PostgreSQL compatible)
--   - CTE name converted to lowercase
--   - BETWEEN clause preserved
--   - ORDER BY adds NULLS FIRST
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
-- CONVERTED STATEMENT 7: Get Low Stock Products with Window Functions
-- =====================================================================
-- Original Source: DataAccess/ProductRepository.cs - GetLowStockProductsAsync()
-- Conversion Status: SUCCESS (DMS TOOL)
-- Conversion Timestamp: 2025-12-28T08:28:12.474513
-- Schema Changes: Products → productmanagement_dbo.products
-- Notable Conversions:
--   - AVG/MIN/MAX OVER() preserved (PostgreSQL compatible)
--   - CTE name converted to lowercase
--   - Multiple window functions handled correctly
--   - ORDER BY adds NULLS FIRST
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
-- END OF CONVERTED STATEMENTS CATALOG
-- Summary:
-- - Total Statements: 7
-- - DMS Tool Success: 6
-- - DMS Tool Failed (Manual): 1
-- - Key Schema Change: dbo schema → productmanagement_dbo schema
-- - Transaction Handling: Moved from SQL to C# application level
-- =====================================================================
