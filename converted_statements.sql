-- ============================================================================
-- SQL Statement Conversion Catalog
-- Source: Microsoft SQL Server
-- Target: PostgreSQL
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Date: Migration Phase
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions
-- ============================================================================
-- Conversion Status: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Applied: Lowercase schema object names, PostgreSQL syntax
-- ============================================================================

-- ORIGINAL MS SQL SERVER STATEMENT:
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
    p.Name;

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

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync - LAG Window Function
-- ============================================================================
-- Conversion Status: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Applied: Lowercase schema object names, PostgreSQL parameter syntax ($1)
-- ============================================================================

-- ORIGINAL MS SQL SERVER STATEMENT:
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
WHERE p.ProductId = @ProductId;

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

-- ============================================================================
-- STATEMENT 3: InsertProductAsync - Transaction Block with Multiple Statements
-- ============================================================================
-- Conversion Status: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Applied: 
--   - BEGIN TRANSACTION -> BEGIN
--   - SCOPE_IDENTITY() -> RETURNING clause
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - @param -> $1, $2, $3, $4 positional parameters
--   - Lowercase schema object names
-- Critical: Transaction block restructured for PostgreSQL, RETURNING used instead of SCOPE_IDENTITY
-- ============================================================================

-- ORIGINAL MS SQL SERVER STATEMENT:
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    -- Insert the new product
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;

-- CONVERTED POSTGRESQL STATEMENT:
-- Note: This requires code-level changes to handle the RETURNING clause in ADO.NET
-- The transaction block is handled at the connection level in PostgreSQL with Npgsql
BEGIN;
    -- Insert the new product and get the ID
    INSERT INTO products (name, description, price, stockquantity)
    VALUES ($1, $2, $3, $4)
    RETURNING productid;
    
    -- Log the insertion (Note: $5 will be the returned productid from previous statement)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES ($5, 'INSERT', NULL, $3, NULL, $4, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + $3) / (totalproducts + 1),
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction Block with Variable Storage
-- ============================================================================
-- Conversion Status: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Applied:
--   - BEGIN TRANSACTION -> BEGIN
--   - DECLARE -> Removed (handled in code or via CTEs)
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - @param -> $1, $2, $3, $4, $5 positional parameters
--   - Lowercase schema object names
-- ============================================================================

-- ORIGINAL MS SQL SERVER STATEMENT:
BEGIN TRANSACTION;
    -- Store old values for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Update the product
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

-- CONVERTED POSTGRESQL STATEMENT:
-- Note: Variables handled via CTE to capture old values before update
BEGIN;
    -- Capture old values and update in one operation using CTE
    WITH oldvalues AS (
        SELECT price as oldprice, stockquantity as oldstock
        FROM products
        WHERE productid = $1
    )
    UPDATE products
    SET 
        name = $2,
        description = $3,
        price = $4,
        stockquantity = $5,
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = $1;
    
    -- Log the changes (Note: old values need to be passed from code after retrieval)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES ($1, 'UPDATE', $6, $4, $7, $5, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - $6 + $4) / totalproducts,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction Block with Cascading Updates
-- ============================================================================
-- Conversion Status: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Applied:
--   - BEGIN TRANSACTION -> BEGIN
--   - DECLARE -> Removed (values passed from code)
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - @param -> $1, $2, $3 positional parameters
--   - Lowercase schema object names
-- ============================================================================

-- ORIGINAL MS SQL SERVER STATEMENT:
BEGIN TRANSACTION;
    -- Store product info for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    -- Update product statistics
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

-- CONVERTED POSTGRESQL STATEMENT:
-- Note: Old values need to be retrieved in code first and passed as parameters
BEGIN;
    -- Log the deletion (old values passed as $2 and $3 from code)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES ($1, 'DELETE', $2, NULL, $3, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = $1;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - $2) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - RANK and PERCENT_RANK Window Functions
-- ============================================================================
-- Conversion Status: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Applied: Lowercase schema object names, @param -> $1, $2
-- ============================================================================

-- ORIGINAL MS SQL SERVER STATEMENT:
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
ORDER BY rp.PriceRank;

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

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - Multiple Window Aggregate Functions
-- ============================================================================
-- Conversion Status: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Applied: Lowercase schema object names, @Threshold -> $1
-- ============================================================================

-- ORIGINAL MS SQL SERVER STATEMENT:
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
ORDER BY StockQuantity;

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

-- ============================================================================
-- CONVERSION SUMMARY
-- ============================================================================
-- Total Statements Processed: 7
-- DMS Tool Success: 0
-- DMS Tool Failures: 7
-- Manual Conversions Applied: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
--
-- Key Transformations Applied:
-- 1. All schema object names (tables, columns) converted to lowercase
-- 2. BEGIN TRANSACTION -> BEGIN
-- 3. COMMIT; -> COMMIT;
-- 4. GETDATE() -> CURRENT_TIMESTAMP
-- 5. SCOPE_IDENTITY() -> RETURNING clause
-- 6. @parameter -> $1, $2, $3... positional parameters
-- 7. DECLARE statements handled in code or removed (PostgreSQL doesn't support in same way)
-- 8. Window functions (LAG, RANK, PERCENT_RANK, AVG OVER, etc.) - syntax compatible
-- 9. CTE syntax - compatible between SQL Server and PostgreSQL
-- 10. CASE expressions - compatible
--
-- DMS Error (all statements): 
-- "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- ============================================================================
