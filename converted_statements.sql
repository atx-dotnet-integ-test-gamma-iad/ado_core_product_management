-- ============================================================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Converted from MS SQL Server (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
-- All 7 statements manually converted due to DMS tool failure
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================================================

-- =============================================================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Schema objects lowercased. SQL syntax is PostgreSQL-compatible as-is.
-- =============================================================================
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

-- =============================================================================
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Schema objects lowercased. SQL syntax is PostgreSQL-compatible as-is.
-- =============================================================================
WITH producthistory AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = @ProductId
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
WHERE p.productid = @ProductId;

-- =============================================================================
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: SCOPE_IDENTITY() replaced with RETURNING via writable CTE,
--          GETDATE() -> NOW(), DECLARE/SET removed, Schema objects lowercased.
-- Note: Uses writable CTEs (PostgreSQL 9.1+) for atomicity within single statement.
--       C# code uses ExecuteScalarAsync() to read the returned productid.
-- =============================================================================
WITH new_product AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM new_product
),
update_stats AS (
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1
)
SELECT productid FROM new_product;

-- =============================================================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: DECLARE/SET removed, GETDATE() -> NOW(), uses writable CTEs
--          with subquery for old values, Schema objects lowercased.
-- Note: C# code uses ExecuteNonQueryAsync().
-- =============================================================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
),
do_update AS (
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', ov.oldprice, @Price, ov.oldstock, @StockQuantity, NOW()
    FROM old_values ov
)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- =============================================================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: DECLARE/SET removed, GETDATE() -> NOW(), uses writable CTEs,
--          Schema objects lowercased.
-- Note: C# code uses ExecuteNonQueryAsync().
-- =============================================================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', ov.oldprice, NULL, ov.oldstock, NULL, NOW()
    FROM old_values ov
),
do_delete AS (
    DELETE FROM products 
    WHERE productid = @ProductId
)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = NOW()
WHERE statid = 1;

-- =============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Schema objects lowercased. SQL syntax is PostgreSQL-compatible as-is.
-- =============================================================================
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
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

-- =============================================================================
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Schema objects lowercased. Added CAST for integer division in ROUND.
-- =============================================================================
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
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((CAST(stockquantity AS DECIMAL) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;

-- =============================================================================
-- SCRIPT CONVERTED SQL STATEMENTS (PostgreSQL equivalents)
-- Converted from Database/Scripts/01_InitialSetup.sql
-- =============================================================================

-- =============================================================================
-- Statement 8: CREATE TABLE categories (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: INT IDENTITY -> SERIAL, NVARCHAR -> VARCHAR, DATETIME -> TIMESTAMP, GETDATE() -> NOW()
-- =============================================================================
CREATE TABLE categories(
    categoryid SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200) NULL,
    parentcategoryid INT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- Statement 9: CREATE TABLE suppliers (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: INT IDENTITY -> SERIAL, NVARCHAR -> VARCHAR, DATETIME -> TIMESTAMP, BIT -> BOOLEAN, GETDATE() -> NOW()
-- =============================================================================
CREATE TABLE suppliers(
    supplierid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contactname VARCHAR(100) NULL,
    email VARCHAR(100) NULL,
    phone VARCHAR(20) NULL,
    address VARCHAR(200) NULL,
    country VARCHAR(50) NULL,
    isactive BOOLEAN NOT NULL DEFAULT TRUE,
    createddate TIMESTAMP NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- Statement 10: CREATE TABLE products (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: INT IDENTITY -> SERIAL, NVARCHAR -> VARCHAR, DECIMAL preserved, BIT -> BOOLEAN, DATETIME -> TIMESTAMP, GETDATE() -> NOW()
-- =============================================================================
CREATE TABLE products(
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price DECIMAL(18, 2) NOT NULL,
    stockquantity INT NOT NULL,
    categoryid INT NULL,
    supplierid INT NULL,
    sku VARCHAR(50) NULL,
    weight DECIMAL(10, 2) NULL,
    dimensions VARCHAR(50) NULL,
    isdiscontinued BOOLEAN NOT NULL DEFAULT FALSE,
    reorderlevel INT NOT NULL DEFAULT 10,
    createddate TIMESTAMP NOT NULL DEFAULT NOW(),
    modifieddate TIMESTAMP NULL
);

-- =============================================================================
-- Statement 11: CREATE TABLE producthistory (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: INT IDENTITY -> SERIAL, VARCHAR preserved, NVARCHAR -> VARCHAR, DATETIME -> TIMESTAMP, GETDATE() -> NOW()
-- =============================================================================
CREATE TABLE producthistory(
    historyid SERIAL PRIMARY KEY,
    productid INT NOT NULL,
    action VARCHAR(10) NOT NULL,
    oldprice DECIMAL(18, 2) NULL,
    newprice DECIMAL(18, 2) NULL,
    oldstock INT NULL,
    newstock INT NULL,
    actiondate TIMESTAMP NOT NULL DEFAULT NOW(),
    modifiedby VARCHAR(100) NULL
);

-- =============================================================================
-- Statement 12: CREATE TABLE productstats (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: DATETIME -> TIMESTAMP, GETDATE() -> NOW()
-- =============================================================================
CREATE TABLE productstats(
    statid INT PRIMARY KEY DEFAULT 1,
    totalproducts INT NOT NULL DEFAULT 0,
    averageprice DECIMAL(18, 2) NOT NULL DEFAULT 0,
    totalstockvalue DECIMAL(18, 2) NOT NULL DEFAULT 0,
    lowstockcount INT NOT NULL DEFAULT 0,
    discontinuedcount INT NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- Statement 13: UPDATE productstats (initial statistics) (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Schema objects lowercased, GETDATE() -> NOW(), IsDiscontinued = 1 -> isdiscontinued = TRUE
-- =============================================================================
UPDATE productstats
SET 
    totalproducts = (SELECT COUNT(*) FROM products),
    averageprice = (SELECT AVG(price) FROM products),
    totalstockvalue = (SELECT SUM(price * stockquantity) FROM products),
    lowstockcount = (SELECT COUNT(*) FROM products WHERE stockquantity <= reorderlevel),
    discontinuedcount = (SELECT COUNT(*) FROM products WHERE isdiscontinued = TRUE),
    lastupdated = NOW()
WHERE statid = 1;

-- =============================================================================
-- Statement 14: sp_getallproducts Function (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: CREATE OR ALTER PROCEDURE -> CREATE OR REPLACE FUNCTION, SET NOCOUNT ON removed
-- =============================================================================
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE(
    productid INT,
    name VARCHAR(100),
    description VARCHAR(500),
    price DECIMAL(18,2),
    stockquantity INT,
    createddate TIMESTAMP,
    modifieddate TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Statement 15: sp_getproductbyid Function (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: CREATE OR ALTER PROCEDURE -> CREATE OR REPLACE FUNCTION, @param -> p_param
-- =============================================================================
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INT)
RETURNS TABLE(
    productid INT,
    name VARCHAR(100),
    description VARCHAR(500),
    price DECIMAL(18,2),
    stockquantity INT,
    createddate TIMESTAMP,
    modifieddate TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    WHERE p.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Statement 16: sp_insertproduct Function (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: CREATE OR ALTER PROCEDURE -> CREATE OR REPLACE FUNCTION, SCOPE_IDENTITY() -> RETURNING
-- =============================================================================
CREATE OR REPLACE FUNCTION sp_insertproduct(
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price DECIMAL(18,2),
    p_stockquantity INT
)
RETURNS INT AS $$
DECLARE
    v_productid INT;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING products.productid INTO v_productid;
    
    RETURN v_productid;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Statement 17: sp_updateproduct Function (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: CREATE OR ALTER PROCEDURE -> CREATE OR REPLACE FUNCTION, GETDATE() -> NOW()
-- =============================================================================
CREATE OR REPLACE FUNCTION sp_updateproduct(
    p_productid INT,
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price DECIMAL(18,2),
    p_stockquantity INT
)
RETURNS VOID AS $$
BEGIN
    UPDATE products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stockquantity = p_stockquantity,
        modifieddate = NOW()
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Statement 18: sp_deleteproduct Function (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: CREATE OR ALTER PROCEDURE -> CREATE OR REPLACE FUNCTION
-- =============================================================================
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid INT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM products
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

