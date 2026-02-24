-- ===========================================================================
-- CONVERTED SQL STATEMENTS - SQL SERVER TO POSTGRESQL
-- Source File: extracted_statements.sql
-- Conversion Date: 2026-02-24
-- Total Statements: 7
-- DMS Tool Status: FAILED for all statements
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- STATEMENT ID: STMT-001
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- DMS Error Timestamp: 2026-02-24T20:40:12.940053
-- ---------------------------------------------------------------------------

-- ORIGINAL SQL SERVER STATEMENT:
/*
WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name
*/

-- CONVERTED POSTGRESQL STATEMENT:
WITH productstats AS (
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
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ---------------------------------------------------------------------------
-- STATEMENT ID: STMT-002
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- DMS Error Timestamp: 2026-02-24T20:40:28.418576
-- ---------------------------------------------------------------------------

-- ORIGINAL SQL SERVER STATEMENT:
/*
WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = @ProductId
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    ph.PreviousPrice,
    ph.PreviousStock,
    CASE 
        WHEN ph.PreviousPrice IS NOT NULL THEN 
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
*/

-- CONVERTED POSTGRESQL STATEMENT:
WITH producthistory AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = $1
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
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = $1;

-- ---------------------------------------------------------------------------
-- STATEMENT ID: STMT-003
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- DMS Error Timestamp: 2026-02-24T20:40:42.494882
-- NOTE: SCOPE_IDENTITY() converted to RETURNING clause
--       GETDATE() converted to CURRENT_TIMESTAMP
--       Transaction syntax updated to PostgreSQL format
--       Variable declarations removed (handled by RETURNING)
-- ---------------------------------------------------------------------------

-- ORIGINAL SQL SERVER STATEMENT:
/*
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;
*/

-- CONVERTED POSTGRESQL STATEMENT:
-- Note: This is converted to use PostgreSQL's WITH CTE and RETURNING clause
WITH inserted_product AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES ($1, $2, $3, $4)
    RETURNING productid
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, $3, NULL, $4, CURRENT_TIMESTAMP
    FROM inserted_product
    RETURNING productid
)
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + $3) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1
RETURNING (SELECT productid FROM inserted_product);

-- ---------------------------------------------------------------------------
-- STATEMENT ID: STMT-004
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed (same error as above)
-- NOTE: DECLARE variables converted to PostgreSQL DO block with variables
--       GETDATE() converted to CURRENT_TIMESTAMP
--       Transaction syntax updated to PostgreSQL format
-- ---------------------------------------------------------------------------

-- ORIGINAL SQL SERVER STATEMENT:
/*
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
*/

-- CONVERTED POSTGRESQL STATEMENT:
-- Note: Using WITH CTEs to capture old values and perform updates
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = $1
),
product_update AS (
    UPDATE products
    SET 
        name = $2,
        description = $3,
        price = $4,
        stockquantity = $5,
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = $1
    RETURNING productid
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT $1, 'UPDATE', ov.oldprice, $4, ov.oldstock, $5, CURRENT_TIMESTAMP
    FROM old_values ov
    RETURNING productid
)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + $4) / totalproducts,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ---------------------------------------------------------------------------
-- STATEMENT ID: STMT-005
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed (same error as above)
-- NOTE: DECLARE variables converted to CTEs
--       GETDATE() converted to CURRENT_TIMESTAMP
--       Transaction syntax updated to PostgreSQL format
-- ---------------------------------------------------------------------------

-- ORIGINAL SQL SERVER STATEMENT:
/*
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
*/

-- CONVERTED POSTGRESQL STATEMENT:
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = $1
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT $1, 'DELETE', oldprice, NULL, oldstock, NULL, CURRENT_TIMESTAMP
    FROM old_values
    RETURNING productid
),
product_delete AS (
    DELETE FROM products 
    WHERE productid = $1
    RETURNING productid
)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ---------------------------------------------------------------------------
-- STATEMENT ID: STMT-006
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed (same error as above)
-- ---------------------------------------------------------------------------

-- ORIGINAL SQL SERVER STATEMENT:
/*
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as PriceSegment
FROM RankedProducts rp
ORDER BY rp.PriceRank
*/

-- CONVERTED POSTGRESQL STATEMENT:
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN $1 AND $2
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as pricesegment
FROM rankedproducts rp
ORDER BY rp.pricerank;

-- ---------------------------------------------------------------------------
-- STATEMENT ID: STMT-007
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed (same error as above)
-- ---------------------------------------------------------------------------

-- ORIGINAL SQL SERVER STATEMENT:
/*
WITH StockAnalysis AS (
    SELECT 
        p.*,
        AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock,
        MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT 
    sa.*,
    CASE 
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity
*/

-- CONVERTED POSTGRESQL STATEMENT:
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
        WHEN stockquantity <= $1 THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= $1
ORDER BY stockquantity;

-- ===========================================================================
-- END OF CONVERTED STATEMENTS
-- ===========================================================================
-- 
-- CONVERSION SUMMARY:
-- - Total statements processed: 7
-- - DMS Tool conversions: 0 (all failed with metadata model creation error)
-- - Manual conversions: 7 (all using lowercase schema naming conventions)
-- - Conversion method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- 
-- KEY CONVERSIONS APPLIED:
-- 1. All schema object names (tables, columns) converted to lowercase
-- 2. @Parameter syntax → $1, $2, $3, etc. (PostgreSQL positional parameters)
-- 3. SCOPE_IDENTITY() → RETURNING clause in INSERT statements
-- 4. GETDATE() → CURRENT_TIMESTAMP
-- 5. DECLARE @Variable → WITH CTEs or DO blocks (context dependent)
-- 6. BEGIN TRANSACTION/COMMIT → PostgreSQL transaction syntax (implicit in CTEs)
-- 7. Window functions (LAG, AVG, COUNT, RANK, PERCENT_RANK, MIN, MAX) → kept as-is (PostgreSQL compatible)
-- 8. CTEs → kept structure, converted names to lowercase
-- 9. CASE expressions → kept as-is (PostgreSQL compatible)
-- 10. ROUND function → kept as-is (PostgreSQL compatible)
-- 
-- DMS TOOL ERROR:
-- All statements failed DMS conversion with error:
-- "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- 
-- This error indicates an issue with the DMS service metadata model creation,
-- not with the SQL statements themselves. Manual conversion was applied using
-- standard SQL Server to PostgreSQL conversion patterns and lowercase schema
-- naming conventions as specified in the transformation definition.
-- ===========================================================================
