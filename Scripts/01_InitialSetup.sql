-- Create ProductManagement Database (PostgreSQL version)
-- Note: In PostgreSQL, databases are created separately. This script assumes the database already exists.
-- Run: CREATE DATABASE ProductManagement; before executing this script.

-- Create Schema
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;

-- Create Products Table
CREATE TABLE IF NOT EXISTS productmanagement_dbo.products(
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE NULL
);

-- Create Stored Function for Getting All Products
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getallproducts()
RETURNS TABLE(productid INTEGER, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM productmanagement_dbo.products p
    ORDER BY p.name;
END;
$$;

-- Create Stored Function for Getting Product by ID
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getproductbyid(p_productid INTEGER)
RETURNS TABLE(productid INTEGER, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM productmanagement_dbo.products p
    WHERE p.productid = p_productid;
END;
$$;

-- Create Stored Function for Inserting Product
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_insertproduct(
    p_name VARCHAR,
    p_description VARCHAR,
    p_price NUMERIC,
    p_stockquantity INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_productid INTEGER;
BEGIN
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING productmanagement_dbo.products.productid INTO v_productid;
    
    RETURN v_productid;
END;
$$;

-- Create Stored Function for Updating Product
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_updateproduct(
    p_productid INTEGER,
    p_name VARCHAR,
    p_description VARCHAR,
    p_price NUMERIC,
    p_stockquantity INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE productmanagement_dbo.products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stockquantity = p_stockquantity,
        modifieddate = clock_timestamp()
    WHERE productid = p_productid;
END;
$$;

-- Create Stored Function for Deleting Product
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_deleteproduct(p_productid INTEGER)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM productmanagement_dbo.products
    WHERE productid = p_productid;
END;
$$;

-- Insert Sample Data
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
SELECT 'Laptop', 'High-performance laptop', 999.99, 10
WHERE NOT EXISTS (SELECT 1 FROM productmanagement_dbo.products LIMIT 1);

INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
SELECT 'Mouse', 'Wireless gaming mouse', 49.99, 20
WHERE NOT EXISTS (SELECT 1 FROM productmanagement_dbo.products WHERE name = 'Mouse');

INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
SELECT 'Keyboard', 'Mechanical keyboard', 129.99, 15
WHERE NOT EXISTS (SELECT 1 FROM productmanagement_dbo.products WHERE name = 'Keyboard');
