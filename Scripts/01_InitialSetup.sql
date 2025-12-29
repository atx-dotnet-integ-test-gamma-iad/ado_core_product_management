-- Create ProductManagement Database
-- Note: Connect to 'postgres' or 'template1' database before running this section
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'ProductManagement') THEN
        -- This must be run outside a transaction block
        -- Execute: CREATE DATABASE ProductManagement WITH ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';
        RAISE NOTICE 'Database ProductManagement does not exist. Please create it manually.';
    END IF;
END
$$;

-- Connect to ProductManagement database before proceeding
-- \c ProductManagement

-- Create Products Table
CREATE TABLE IF NOT EXISTS public.products(
    ProductId INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(500) NULL,
    Price NUMERIC(18, 2) NOT NULL,
    StockQuantity INTEGER NOT NULL,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ModifiedDate TIMESTAMP NULL
);

-- Create Function for Getting All Products
CREATE OR REPLACE FUNCTION public.sp_GetAllProducts()
RETURNS TABLE(
    ProductId INTEGER,
    Name VARCHAR(100),
    Description VARCHAR(500),
    Price NUMERIC(18, 2),
    StockQuantity INTEGER,
    CreatedDate TIMESTAMP,
    ModifiedDate TIMESTAMP
)
AS $$
BEGIN
    RETURN QUERY
    SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate
    FROM public.products p
    ORDER BY p.Name;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Getting Product by ID
CREATE OR REPLACE FUNCTION public.sp_GetProductById(
    p_ProductId INTEGER
)
RETURNS TABLE(
    ProductId INTEGER,
    Name VARCHAR(100),
    Description VARCHAR(500),
    Price NUMERIC(18, 2),
    StockQuantity INTEGER,
    CreatedDate TIMESTAMP,
    ModifiedDate TIMESTAMP
)
AS $$
BEGIN
    RETURN QUERY
    SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate
    FROM public.products p
    WHERE p.ProductId = p_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Inserting Product
CREATE OR REPLACE FUNCTION public.sp_InsertProduct(
    p_Name VARCHAR(100),
    p_Description VARCHAR(500),
    p_Price NUMERIC(18,2),
    p_StockQuantity INTEGER
)
RETURNS TABLE(ProductId INTEGER)
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO public.products (Name, Description, Price, StockQuantity)
    VALUES (p_Name, p_Description, p_Price, p_StockQuantity)
    RETURNING public.products.ProductId;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Updating Product
CREATE OR REPLACE FUNCTION public.sp_UpdateProduct(
    p_ProductId INTEGER,
    p_Name VARCHAR(100),
    p_Description VARCHAR(500),
    p_Price NUMERIC(18,2),
    p_StockQuantity INTEGER
)
RETURNS VOID
AS $$
BEGIN
    UPDATE public.products
    SET Name = p_Name,
        Description = p_Description,
        Price = p_Price,
        StockQuantity = p_StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = p_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Deleting Product
CREATE OR REPLACE FUNCTION public.sp_DeleteProduct(
    p_ProductId INTEGER
)
RETURNS VOID
AS $$
BEGIN
    DELETE FROM public.products
    WHERE ProductId = p_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Insert Sample Data
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.products LIMIT 1) THEN
        INSERT INTO public.products (Name, Description, Price, StockQuantity)
        VALUES 
            ('Laptop', 'High-performance laptop', 999.99, 10),
            ('Mouse', 'Wireless gaming mouse', 49.99, 20),
            ('Keyboard', 'Mechanical keyboard', 129.99, 15);
    END IF;
END
$$;
