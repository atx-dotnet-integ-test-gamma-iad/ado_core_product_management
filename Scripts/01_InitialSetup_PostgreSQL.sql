-- PostgreSQL Database Initialization Script
-- Create ProductManagement Database (run as superuser or database owner)

-- Create database if not exists
-- Note: This should be run separately as you cannot CREATE DATABASE inside a transaction
-- Run this first: CREATE DATABASE "ProductManagement";

-- Connect to ProductManagement database before running the rest
-- \c ProductManagement;

-- Create Products Table
CREATE TABLE IF NOT EXISTS Products (
    ProductId SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(500),
    Price DECIMAL(18, 2) NOT NULL,
    StockQuantity INTEGER NOT NULL,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ModifiedDate TIMESTAMP
);

-- Create ProductHistory Table (referenced in converted SQL statements)
CREATE TABLE IF NOT EXISTS ProductHistory (
    HistoryId SERIAL PRIMARY KEY,
    ProductId INTEGER NOT NULL,
    Action VARCHAR(50) NOT NULL,
    OldPrice DECIMAL(18, 2),
    NewPrice DECIMAL(18, 2),
    OldStock INTEGER,
    NewStock INTEGER,
    ActionDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId) ON DELETE CASCADE
);

-- Create ProductStats Table (referenced in converted SQL statements)
CREATE TABLE IF NOT EXISTS ProductStats (
    StatId INTEGER PRIMARY KEY,
    TotalProducts INTEGER NOT NULL DEFAULT 0,
    AveragePrice DECIMAL(18, 2) NOT NULL DEFAULT 0,
    LastUpdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Initialize ProductStats with default record
INSERT INTO ProductStats (StatId, TotalProducts, AveragePrice, LastUpdated)
VALUES (1, 0, 0, CURRENT_TIMESTAMP)
ON CONFLICT (StatId) DO NOTHING;

-- Create Function for Getting All Products (replacing stored procedure)
CREATE OR REPLACE FUNCTION sp_GetAllProducts()
RETURNS TABLE (
    ProductId INTEGER,
    Name VARCHAR(100),
    Description VARCHAR(500),
    Price DECIMAL(18, 2),
    StockQuantity INTEGER,
    CreatedDate TIMESTAMP,
    ModifiedDate TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate
    FROM Products p
    ORDER BY p.Name;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Getting Product by ID (replacing stored procedure)
CREATE OR REPLACE FUNCTION sp_GetProductById(p_ProductId INTEGER)
RETURNS TABLE (
    ProductId INTEGER,
    Name VARCHAR(100),
    Description VARCHAR(500),
    Price DECIMAL(18, 2),
    StockQuantity INTEGER,
    CreatedDate TIMESTAMP,
    ModifiedDate TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate
    FROM Products p
    WHERE p.ProductId = p_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Inserting Product (replacing stored procedure)
CREATE OR REPLACE FUNCTION sp_InsertProduct(
    p_Name VARCHAR(100),
    p_Description VARCHAR(500),
    p_Price DECIMAL(18, 2),
    p_StockQuantity INTEGER
)
RETURNS INTEGER AS $$
DECLARE
    v_ProductId INTEGER;
BEGIN
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (p_Name, p_Description, p_Price, p_StockQuantity)
    RETURNING ProductId INTO v_ProductId;
    
    RETURN v_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Updating Product (replacing stored procedure)
CREATE OR REPLACE FUNCTION sp_UpdateProduct(
    p_ProductId INTEGER,
    p_Name VARCHAR(100),
    p_Description VARCHAR(500),
    p_Price DECIMAL(18, 2),
    p_StockQuantity INTEGER
)
RETURNS VOID AS $$
BEGIN
    UPDATE Products
    SET Name = p_Name,
        Description = p_Description,
        Price = p_Price,
        StockQuantity = p_StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = p_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Deleting Product (replacing stored procedure)
CREATE OR REPLACE FUNCTION sp_DeleteProduct(p_ProductId INTEGER)
RETURNS VOID AS $$
BEGIN
    DELETE FROM Products
    WHERE ProductId = p_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Insert Sample Data (only if table is empty)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Products LIMIT 1) THEN
        -- Insert sample products
        INSERT INTO Products (Name, Description, Price, StockQuantity)
        VALUES 
            ('Laptop', 'High-performance laptop', 999.99, 10),
            ('Mouse', 'Wireless gaming mouse', 49.99, 20),
            ('Keyboard', 'Mechanical keyboard', 129.99, 15);
        
        -- Update ProductStats
        UPDATE ProductStats
        SET 
            TotalProducts = (SELECT COUNT(*) FROM Products),
            AveragePrice = (SELECT AVG(Price) FROM Products),
            LastUpdated = CURRENT_TIMESTAMP
        WHERE StatId = 1;
    END IF;
END $$;

-- Grant permissions (adjust username as needed)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO postgres;
