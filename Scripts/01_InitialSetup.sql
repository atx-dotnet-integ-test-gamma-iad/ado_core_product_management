-- ========================================
-- PostgreSQL Database Initialization Script
-- Converted from SQL Server to PostgreSQL
-- ========================================

-- Create ProductManagement Database (run separately if needed)
-- CREATE DATABASE productmanagement;
-- \c productmanagement;

-- Create Products Table
CREATE TABLE IF NOT EXISTS products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP
);

-- Create ProductHistory Table (referenced in repository code)
CREATE TABLE IF NOT EXISTS producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(50) NOT NULL,
    oldprice NUMERIC(18, 2),
    newprice NUMERIC(18, 2),
    oldstock INTEGER,
    newstock INTEGER,
    actiondate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create ProductStats Table (referenced in repository code)
CREATE TABLE IF NOT EXISTS productstats (
    statid SERIAL PRIMARY KEY,
    totalproducts INTEGER NOT NULL DEFAULT 0,
    averageprice NUMERIC(18, 2) NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Initialize ProductStats with default record
INSERT INTO productstats (statid, totalproducts, averageprice, lastupdated)
VALUES (1, 0, 0, CURRENT_TIMESTAMP)
ON CONFLICT (statid) DO NOTHING;

-- Create Function: sp_getallproducts
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE(
    productid INTEGER,
    name VARCHAR(100),
    description VARCHAR(500),
    price NUMERIC(18, 2),
    stockquantity INTEGER,
    createddate TIMESTAMP,
    modifieddate TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    ORDER BY p.name;
END;
$$;

-- Create Function: sp_getproductbyid
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INTEGER)
RETURNS TABLE(
    productid INTEGER,
    name VARCHAR(100),
    description VARCHAR(500),
    price NUMERIC(18, 2),
    stockquantity INTEGER,
    createddate TIMESTAMP,
    modifieddate TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    WHERE p.productid = p_productid;
END;
$$;

-- Create Function: sp_insertproduct
CREATE OR REPLACE FUNCTION sp_insertproduct(
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18, 2),
    p_stockquantity INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_productid INTEGER;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING productid INTO v_productid;
    
    RETURN v_productid;
END;
$$;

-- Create Function: sp_updateproduct
CREATE OR REPLACE FUNCTION sp_updateproduct(
    p_productid INTEGER,
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18, 2),
    p_stockquantity INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stockquantity = p_stockquantity,
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = p_productid;
END;
$$;

-- Create Function: sp_deleteproduct
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid INTEGER)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM products
    WHERE productid = p_productid;
END;
$$;

-- Insert Sample Data
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM products LIMIT 1) THEN
        INSERT INTO products (name, description, price, stockquantity)
        VALUES 
            ('Laptop', 'High-performance laptop', 999.99, 10),
            ('Mouse', 'Wireless gaming mouse', 49.99, 20),
            ('Keyboard', 'Mechanical keyboard', 129.99, 15);
        
        -- Update stats after initial insert
        UPDATE productstats
        SET totalproducts = 3,
            averageprice = (999.99 + 49.99 + 129.99) / 3,
            lastupdated = CURRENT_TIMESTAMP
        WHERE statid = 1;
    END IF;
END $$;

-- ========================================
-- Conversion Notes:
-- ========================================
-- 1. Database: ProductManagement → productmanagement (lowercase)
-- 2. Table: Products → products (lowercase)
-- 3. IDENTITY(1,1) → SERIAL
-- 4. NVARCHAR → VARCHAR
-- 5. DECIMAL → NUMERIC
-- 6. DATETIME → TIMESTAMP
-- 7. GETDATE() → CURRENT_TIMESTAMP
-- 8. GO batch separators removed
-- 9. [dbo] schema prefix removed
-- 10. Brackets around identifiers removed
-- 11. Stored procedures → Functions with appropriate return types
-- 12. SET NOCOUNT ON removed (PostgreSQL-specific)
-- 13. SCOPE_IDENTITY() → RETURNING clause
-- 14. IF NOT EXISTS → CREATE TABLE IF NOT EXISTS
-- 15. EXEC → Direct INSERT or SELECT function_name()
-- 16. Added ProductHistory and ProductStats tables (referenced in code)
-- ========================================
