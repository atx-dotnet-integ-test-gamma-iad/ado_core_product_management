-- Create ProductManagement Database (run as superuser)
-- PostgreSQL equivalent: CREATE DATABASE is run outside of a transaction
-- Run this command separately: CREATE DATABASE ProductManagement;

-- Connect to ProductManagement database before running the rest

-- Create schema for migrated objects
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;

-- Create Products Table
CREATE TABLE IF NOT EXISTS productmanagement_dbo.products(
    productid INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE
);

-- Create function equivalent for sp_GetAllProducts
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getallproducts()
RETURNS TABLE(productid INTEGER, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP)
AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM productmanagement_dbo.products p
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- Create function equivalent for sp_GetProductById
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getproductbyid(p_productid INTEGER)
RETURNS TABLE(productid INTEGER, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP)
AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM productmanagement_dbo.products p
    WHERE p.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Create function equivalent for sp_InsertProduct
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_insertproduct(
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18,2),
    p_stockquantity INTEGER
)
RETURNS INTEGER
AS $$
DECLARE
    v_productid INTEGER;
BEGIN
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING productmanagement_dbo.products.productid INTO v_productid;

    RETURN v_productid;
END;
$$ LANGUAGE plpgsql;

-- Create function equivalent for sp_UpdateProduct
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_updateproduct(
    p_productid INTEGER,
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18,2),
    p_stockquantity INTEGER
)
RETURNS VOID
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
$$ LANGUAGE plpgsql;

-- Create function equivalent for sp_DeleteProduct
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_deleteproduct(p_productid INTEGER)
RETURNS VOID
AS $$
BEGIN
    DELETE FROM productmanagement_dbo.products
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

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
