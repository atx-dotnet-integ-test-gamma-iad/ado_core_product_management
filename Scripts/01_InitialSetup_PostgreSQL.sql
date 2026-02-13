-- PostgreSQL Database Setup Script
-- Note: Database creation is typically done separately in PostgreSQL
-- Run this script after connecting to the ProductManagement database

-- Create Products Table
CREATE TABLE IF NOT EXISTS Products (
    ProductId SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description TEXT,
    Price NUMERIC(18, 2) NOT NULL,
    StockQuantity INTEGER NOT NULL,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ModifiedDate TIMESTAMP NULL
);

-- Note: The application uses inline SQL in ProductRepository.cs
-- The following stored procedures are converted to PostgreSQL functions
-- but are not used by the C# code. They are included for reference only.

-- Function for Getting All Products (not used by C# code)
CREATE OR REPLACE FUNCTION sp_GetAllProducts()
RETURNS TABLE (
    ProductId INTEGER,
    Name VARCHAR(100),
    Description TEXT,
    Price NUMERIC(18, 2),
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

-- Function for Getting Product by ID (not used by C# code)
CREATE OR REPLACE FUNCTION sp_GetProductById(p_ProductId INTEGER)
RETURNS TABLE (
    ProductId INTEGER,
    Name VARCHAR(100),
    Description TEXT,
    Price NUMERIC(18, 2),
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

-- Function for Inserting Product (not used by C# code)
CREATE OR REPLACE FUNCTION sp_InsertProduct(
    p_Name VARCHAR(100),
    p_Description TEXT,
    p_Price NUMERIC(18, 2),
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

-- Function for Updating Product (not used by C# code)
CREATE OR REPLACE FUNCTION sp_UpdateProduct(
    p_ProductId INTEGER,
    p_Name VARCHAR(100),
    p_Description TEXT,
    p_Price NUMERIC(18, 2),
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

-- Function for Deleting Product (not used by C# code)
CREATE OR REPLACE FUNCTION sp_DeleteProduct(p_ProductId INTEGER)
RETURNS VOID AS $$
BEGIN
    DELETE FROM Products
    WHERE ProductId = p_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Insert Sample Data
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Products LIMIT 1) THEN
        INSERT INTO Products (Name, Description, Price, StockQuantity) VALUES
            ('Laptop', 'High-performance laptop', 999.99, 10),
            ('Mouse', 'Wireless gaming mouse', 49.99, 20),
            ('Keyboard', 'Mechanical keyboard', 129.99, 15);
    END IF;
END $$;

-- Additional tables mentioned in ProductRepository.cs
-- Note: These tables are referenced in the C# code but not in the original setup script

-- Create ProductHistory Table
CREATE TABLE IF NOT EXISTS ProductHistory (
    HistoryId SERIAL PRIMARY KEY,
    ProductId INTEGER NOT NULL,
    Action VARCHAR(50) NOT NULL,
    OldPrice NUMERIC(18, 2),
    NewPrice NUMERIC(18, 2),
    OldStock INTEGER,
    NewStock INTEGER,
    ActionDate TIMESTAMP NOT NULL,
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId) ON DELETE CASCADE
);

-- Create ProductStats Table
CREATE TABLE IF NOT EXISTS ProductStats (
    StatId INTEGER PRIMARY KEY,
    TotalProducts INTEGER NOT NULL DEFAULT 0,
    AveragePrice NUMERIC(18, 2) NOT NULL DEFAULT 0,
    LastUpdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Initialize ProductStats with a single row
INSERT INTO ProductStats (StatId, TotalProducts, AveragePrice, LastUpdated)
VALUES (1, 0, 0, CURRENT_TIMESTAMP)
ON CONFLICT (StatId) DO NOTHING;

-- Update ProductStats with current data
UPDATE ProductStats
SET TotalProducts = (SELECT COUNT(*) FROM Products),
    AveragePrice = COALESCE((SELECT AVG(Price) FROM Products), 0),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;
