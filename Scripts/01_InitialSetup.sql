-- Create ProductManagement Database (PostgreSQL)
-- Note: In PostgreSQL, database creation is typically done outside of scripts
-- Use: CREATE DATABASE ProductManagement; from psql or admin tool

-- Create Schema
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;

-- Create Products Table
CREATE TABLE IF NOT EXISTS productmanagement_dbo.products(
    productid BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE NULL
);

-- Create Function for Getting All Products (replaces stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getallproducts()
RETURNS TABLE (
    productid BIGINT,
    name VARCHAR(100),
    description VARCHAR(500),
    price NUMERIC(18, 2),
    stockquantity INTEGER,
    createddate TIMESTAMP WITHOUT TIME ZONE,
    modifieddate TIMESTAMP WITHOUT TIME ZONE
) AS $BODY$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM productmanagement_dbo.products p
    ORDER BY p.name;
END;
$BODY$ LANGUAGE plpgsql;

-- Create Function for Getting Product by ID (replaces stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getproductbyid(
    par_productid INTEGER
) RETURNS TABLE (
    productid BIGINT,
    name VARCHAR(100),
    description VARCHAR(500),
    price NUMERIC(18, 2),
    stockquantity INTEGER,
    createddate TIMESTAMP WITHOUT TIME ZONE,
    modifieddate TIMESTAMP WITHOUT TIME ZONE
) AS $BODY$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM productmanagement_dbo.products p
    WHERE p.productid = par_productid;
END;
$BODY$ LANGUAGE plpgsql;

-- Create Function for Inserting Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_insertproduct(
    par_name VARCHAR(100),
    par_description VARCHAR(500),
    par_price NUMERIC(18,2),
    par_stockquantity INTEGER
) RETURNS BIGINT AS $BODY$
DECLARE
    var_productid BIGINT;
BEGIN
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (par_name, par_description, par_price, par_stockquantity)
    RETURNING productmanagement_dbo.products.productid INTO var_productid;

    RETURN var_productid;
END;
$BODY$ LANGUAGE plpgsql;

-- Create Function for Updating Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_updateproduct(
    par_productid INTEGER,
    par_name VARCHAR(100),
    par_description VARCHAR(500),
    par_price NUMERIC(18,2),
    par_stockquantity INTEGER
) RETURNS VOID AS $BODY$
BEGIN
    UPDATE productmanagement_dbo.products
    SET name = par_name,
        description = par_description,
        price = par_price,
        stockquantity = par_stockquantity,
        modifieddate = clock_timestamp()
    WHERE productid = par_productid;
END;
$BODY$ LANGUAGE plpgsql;

-- Create Function for Deleting Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_deleteproduct(
    par_productid INTEGER
) RETURNS VOID AS $BODY$
BEGIN
    DELETE FROM productmanagement_dbo.products
    WHERE productid = par_productid;
END;
$BODY$ LANGUAGE plpgsql;

-- Insert Sample Data
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM productmanagement_dbo.products LIMIT 1) THEN
        PERFORM productmanagement_dbo.sp_insertproduct('Laptop', 'High-performance laptop', 999.99, 10);
        PERFORM productmanagement_dbo.sp_insertproduct('Mouse', 'Wireless gaming mouse', 49.99, 20);
        PERFORM productmanagement_dbo.sp_insertproduct('Keyboard', 'Mechanical keyboard', 129.99, 15);
    END IF;
END $$;
