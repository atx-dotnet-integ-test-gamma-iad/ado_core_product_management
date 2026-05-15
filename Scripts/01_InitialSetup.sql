-- =============================================================================
-- PostgreSQL Migration: ProductManagement Database Setup (Simple)
-- Converted from SQL Server T-SQL to PostgreSQL
-- Source: SQL Server 2019  |  Target: PostgreSQL 13
-- Note: DMS statement conversion unavailable; converted using documented
--       T-SQL → PostgreSQL mapping rules.
-- =============================================================================

-- NOTE: PostgreSQL does not support CREATE DATABASE inside a transaction block.
-- Run this command as a superuser OUTSIDE of any transaction if the database
-- does not already exist:
--   CREATE DATABASE "ProductManagement";
-- Then connect to it (\ c "ProductManagement") before running this script.

-- =============================================================================
-- Create Products Table (if not already present)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public."Products" (
    "ProductId"     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Name"          VARCHAR(100)   NOT NULL,
    "Description"   VARCHAR(500)   NULL,
    "Price"         NUMERIC(18, 2) NOT NULL,
    "StockQuantity" INTEGER        NOT NULL,
    "CreatedDate"   TIMESTAMP      NOT NULL DEFAULT NOW(),
    "ModifiedDate"  TIMESTAMP      NULL
);

-- =============================================================================
-- Stored Procedure: sp_GetAllProducts
-- CREATE OR ALTER PROCEDURE converted to CREATE OR REPLACE FUNCTION.
-- SET NOCOUNT ON removed (not applicable in PostgreSQL).
-- Returns a result set via RETURNS TABLE.
-- =============================================================================
CREATE OR REPLACE FUNCTION public.sp_getallproducts()
RETURNS TABLE (
    "ProductId"     INTEGER,
    "Name"          VARCHAR(100),
    "Description"   VARCHAR(500),
    "Price"         NUMERIC(18, 2),
    "StockQuantity" INTEGER,
    "CreatedDate"   TIMESTAMP,
    "ModifiedDate"  TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."ProductId",
        p."Name",
        p."Description",
        p."Price",
        p."StockQuantity",
        p."CreatedDate",
        p."ModifiedDate"
    FROM public."Products" p
    ORDER BY p."Name";
END;
$$;

-- =============================================================================
-- Stored Procedure: sp_GetProductById
-- @ProductId parameter becomes p_productid (no @ prefix in PostgreSQL).
-- =============================================================================
CREATE OR REPLACE FUNCTION public.sp_getproductbyid(
    p_productid INTEGER
)
RETURNS TABLE (
    "ProductId"     INTEGER,
    "Name"          VARCHAR(100),
    "Description"   VARCHAR(500),
    "Price"         NUMERIC(18, 2),
    "StockQuantity" INTEGER,
    "CreatedDate"   TIMESTAMP,
    "ModifiedDate"  TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."ProductId",
        p."Name",
        p."Description",
        p."Price",
        p."StockQuantity",
        p."CreatedDate",
        p."ModifiedDate"
    FROM public."Products" p
    WHERE p."ProductId" = p_productid;
END;
$$;

-- =============================================================================
-- Stored Procedure: sp_InsertProduct
-- SCOPE_IDENTITY() replaced with INSERT ... RETURNING captured via INTO.
-- Returns the new ProductId as INTEGER.
-- =============================================================================
CREATE OR REPLACE FUNCTION public.sp_insertproduct(
    p_name          VARCHAR(100),
    p_description   VARCHAR(500),
    p_price         NUMERIC(18, 2),
    p_stockquantity INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_product_id INTEGER;
BEGIN
    INSERT INTO public."Products" ("Name", "Description", "Price", "StockQuantity")
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING "ProductId" INTO v_new_product_id;

    RETURN v_new_product_id;
END;
$$;

-- =============================================================================
-- Stored Procedure: sp_UpdateProduct
-- GETDATE() replaced with NOW().
-- =============================================================================
CREATE OR REPLACE FUNCTION public.sp_updateproduct(
    p_productid     INTEGER,
    p_name          VARCHAR(100),
    p_description   VARCHAR(500),
    p_price         NUMERIC(18, 2),
    p_stockquantity INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE public."Products"
    SET
        "Name"          = p_name,
        "Description"   = p_description,
        "Price"         = p_price,
        "StockQuantity" = p_stockquantity,
        "ModifiedDate"  = NOW()
    WHERE "ProductId" = p_productid;
END;
$$;

-- =============================================================================
-- Stored Procedure: sp_DeleteProduct
-- =============================================================================
CREATE OR REPLACE FUNCTION public.sp_deleteproduct(
    p_productid INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM public."Products"
    WHERE "ProductId" = p_productid;
END;
$$;

-- =============================================================================
-- Insert Sample Data
-- "IF NOT EXISTS (SELECT TOP 1 1 FROM Products)" converted to a DO $$ block.
-- EXEC sp_InsertProduct converted to SELECT sp_insertproduct(...).
-- TOP 1 replaced with LIMIT 1.
-- Stored procedure calls (EXEC) replaced with SELECT function calls.
-- =============================================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Products" LIMIT 1) THEN
        PERFORM public.sp_insertproduct('Laptop',   'High-performance laptop',  999.99, 10);
        PERFORM public.sp_insertproduct('Mouse',    'Wireless gaming mouse',     49.99, 20);
        PERFORM public.sp_insertproduct('Keyboard', 'Mechanical keyboard',      129.99, 15);
    END IF;
END;
$$;
