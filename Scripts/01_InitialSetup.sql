-- ============================================================================
-- PostgreSQL Initial Setup Script (converted from MS SQL Server T-SQL)
-- Original: Scripts/01_InitialSetup.sql
-- Conversion: DMS MCP Tool + Manual lowercase schema mapping
-- ============================================================================

-- Create schema if not exists
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

-- Create Function equivalent to sp_GetAllProducts stored procedure
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getallproducts()
RETURNS TABLE(productid INT, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INT, createddate TIMESTAMP, modifieddate TIMESTAMP) AS $$
BEGIN
    RETURN QUERY SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM productmanagement_dbo.products p
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- Create Function equivalent to sp_GetProductById stored procedure
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getproductbyid(p_productid INT)
RETURNS TABLE(productid INT, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INT, createddate TIMESTAMP, modifieddate TIMESTAMP) AS $$
BEGIN
    RETURN QUERY SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM productmanagement_dbo.products p
    WHERE p.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Create Function equivalent to sp_InsertProduct stored procedure
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_insertproduct(p_name VARCHAR, p_description VARCHAR, p_price NUMERIC, p_stockquantity INT)
RETURNS INT AS $$
DECLARE v_productid INT;
BEGIN
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING productid INTO v_productid;
    RETURN v_productid;
END;
$$ LANGUAGE plpgsql;

-- Create Function equivalent to sp_UpdateProduct stored procedure
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_updateproduct(p_productid INT, p_name VARCHAR, p_description VARCHAR, p_price NUMERIC, p_stockquantity INT)
RETURNS VOID AS $$
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

-- Create Function equivalent to sp_DeleteProduct stored procedure
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_deleteproduct(p_productid INT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM productmanagement_dbo.products
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Insert Sample Data using function calls
SELECT productmanagement_dbo.sp_insertproduct('Laptop', 'High-performance laptop', 999.99, 10);
SELECT productmanagement_dbo.sp_insertproduct('Mouse', 'Wireless gaming mouse', 49.99, 20);
SELECT productmanagement_dbo.sp_insertproduct('Keyboard', 'Mechanical keyboard', 129.99, 15);
