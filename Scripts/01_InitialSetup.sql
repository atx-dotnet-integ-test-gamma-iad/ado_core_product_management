-- ============================================================================
-- PostgreSQL Initial Setup Script for ProductManagement
-- Converted from SQL Server to PostgreSQL
-- ============================================================================

-- Create ProductManagement Database (run separately as superuser)
-- Note: PostgreSQL requires CREATE DATABASE to be run outside a transaction
-- SELECT 'CREATE DATABASE productmanagement' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'productmanagement');

-- Set search path
-- SET search_path TO productmanagement_dbo;

-- Create Products Table
CREATE TABLE IF NOT EXISTS products(
    productid INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE
);

-- Create Function sp_getallproducts (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE(productid INTEGER, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP) AS $$
BEGIN
    RETURN QUERY SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- Create Function sp_getproductbyid (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INTEGER)
RETURNS TABLE(productid INTEGER, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP) AS $$
BEGIN
    RETURN QUERY SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    WHERE p.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Create Function sp_insertproduct (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_insertproduct(p_name VARCHAR, p_description VARCHAR, p_price NUMERIC, p_stockquantity INTEGER)
RETURNS INTEGER AS $$
DECLARE v_productid INTEGER;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING products.productid INTO v_productid;
    RETURN v_productid;
END;
$$ LANGUAGE plpgsql;

-- Create Function sp_updateproduct (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_updateproduct(p_productid INTEGER, p_name VARCHAR, p_description VARCHAR, p_price NUMERIC, p_stockquantity INTEGER)
RETURNS VOID AS $$
BEGIN
    UPDATE products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stockquantity = p_stockquantity,
        modifieddate = clock_timestamp()
    WHERE products.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Create Function sp_deleteproduct (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid INTEGER)
RETURNS VOID AS $$
BEGIN
    DELETE FROM products WHERE products.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Insert Sample Data
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM products LIMIT 1) THEN
        PERFORM sp_insertproduct('Laptop', 'High-performance laptop', 999.99, 10);
        PERFORM sp_insertproduct('Mouse', 'Wireless gaming mouse', 49.99, 20);
        PERFORM sp_insertproduct('Keyboard', 'Mechanical keyboard', 129.99, 15);
    END IF;
END $$;
