-- Create ProductManagement Database
-- Note: In PostgreSQL, database creation is done outside of script context
-- Use: CREATE DATABASE productmanagement; from psql or admin connection

-- Connect to database (PostgreSQL equivalent of USE)
-- \c productmanagement

-- Create Products Table
CREATE TABLE IF NOT EXISTS products(
    productid SERIAL PRIMARY KEY,
    name varchar(100) NOT NULL,
    description varchar(500) NULL,
    price numeric(18, 2) NOT NULL,
    stockquantity integer NOT NULL,
    createddate timestamp NOT NULL DEFAULT NOW(),
    modifieddate timestamp NULL
);

-- Create Stored Function for Getting All Products
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE(
    productid integer,
    name varchar(100),
    description varchar(500),
    price numeric(18,2),
    stockquantity integer,
    createddate timestamp,
    modifieddate timestamp
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

-- Create Stored Function for Getting Product by ID
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid integer)
RETURNS TABLE(
    productid integer,
    name varchar(100),
    description varchar(500),
    price numeric(18,2),
    stockquantity integer,
    createddate timestamp,
    modifieddate timestamp
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

-- Create Stored Function for Inserting Product
CREATE OR REPLACE FUNCTION sp_insertproduct(
    p_name varchar(100),
    p_description varchar(500),
    p_price numeric(18,2),
    p_stockquantity integer
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_productid integer;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING products.productid INTO v_productid;
    
    RETURN v_productid;
END;
$$;

-- Create Stored Function for Updating Product
CREATE OR REPLACE FUNCTION sp_updateproduct(
    p_productid integer,
    p_name varchar(100),
    p_description varchar(500),
    p_price numeric(18,2),
    p_stockquantity integer
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stockquantity = p_stockquantity,
        modifieddate = NOW()
    WHERE productid = p_productid;
END;
$$;

-- Create Stored Function for Deleting Product
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid integer)
RETURNS void
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
        PERFORM sp_insertproduct('Laptop', 'High-performance laptop', 999.99, 10);
        PERFORM sp_insertproduct('Mouse', 'Wireless gaming mouse', 49.99, 20);
        PERFORM sp_insertproduct('Keyboard', 'Mechanical keyboard', 129.99, 15);
    END IF;
END;
$$;
