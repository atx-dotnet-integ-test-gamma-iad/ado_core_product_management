-- PostgreSQL Database Setup Script
-- Database: ProductManagement
-- Purpose: Setup database schema for AdoCore application after SQL Server to PostgreSQL migration

-- ============================================
-- Step 1: Create Database (run as superuser)
-- ============================================
-- Note: This must be run separately if database doesn't exist
-- CREATE DATABASE "ProductManagement"
--     WITH OWNER = postgres
--     ENCODING = 'UTF8'
--     LC_COLLATE = 'en_US.UTF-8'
--     LC_CTYPE = 'en_US.UTF-8'
--     TEMPLATE = template0;

-- Connect to the database
-- \c ProductManagement

-- ============================================
-- Step 2: Create Schema
-- ============================================
CREATE SCHEMA IF NOT EXISTS public;

-- ============================================
-- Step 3: Create Tables
-- ============================================

-- Products Table
-- Stores product information with auto-incrementing ID
DROP TABLE IF EXISTS public."ProductHistory" CASCADE;
DROP TABLE IF EXISTS public."ProductStats" CASCADE;
DROP TABLE IF EXISTS public."Products" CASCADE;

CREATE TABLE public."Products" (
    "ProductId" SERIAL PRIMARY KEY,
    "Name" VARCHAR(255) NOT NULL,
    "Price" NUMERIC(10, 2) NOT NULL CHECK ("Price" >= 0),
    "StockQuantity" INT NOT NULL CHECK ("StockQuantity" >= 0),
    "CreatedDate" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "LastModifiedDate" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE public."Products" IS 'Main products table containing product catalog';
COMMENT ON COLUMN public."Products"."ProductId" IS 'Auto-incrementing primary key';
COMMENT ON COLUMN public."Products"."Name" IS 'Product name';
COMMENT ON COLUMN public."Products"."Price" IS 'Product price (must be non-negative)';
COMMENT ON COLUMN public."Products"."StockQuantity" IS 'Available stock quantity';

-- ProductHistory Table
-- Tracks changes to products for audit purposes
CREATE TABLE public."ProductHistory" (
    "HistoryId" SERIAL PRIMARY KEY,
    "ProductId" INT NOT NULL,
    "Action" VARCHAR(50) NOT NULL,
    "OldValue" TEXT,
    "NewValue" TEXT,
    "ChangedDate" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "ChangedBy" VARCHAR(100),
    CONSTRAINT fk_producthistory_product 
        FOREIGN KEY ("ProductId") 
        REFERENCES public."Products"("ProductId") 
        ON DELETE CASCADE
);

COMMENT ON TABLE public."ProductHistory" IS 'Audit trail for product changes';
COMMENT ON COLUMN public."ProductHistory"."Action" IS 'Type of change: INSERT, UPDATE, DELETE';

-- ProductStats Table
-- Stores aggregated statistics for products
CREATE TABLE public."ProductStats" (
    "StatId" SERIAL PRIMARY KEY,
    "ProductId" INT NOT NULL,
    "AvgPrice" NUMERIC(10, 2),
    "TotalProducts" INT,
    "LastUpdated" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_productstats_product 
        FOREIGN KEY ("ProductId") 
        REFERENCES public."Products"("ProductId") 
        ON DELETE CASCADE
);

COMMENT ON TABLE public."ProductStats" IS 'Aggregated product statistics';

-- ============================================
-- Step 4: Create Indexes for Performance
-- ============================================

-- Index on Price for range queries
CREATE INDEX idx_products_price ON public."Products"("Price");

-- Index on StockQuantity for low stock queries
CREATE INDEX idx_products_stock ON public."Products"("StockQuantity");

-- Index on Name for search queries
CREATE INDEX idx_products_name ON public."Products"("Name");

-- Index on ProductId in ProductHistory for joins
CREATE INDEX idx_producthistory_productid ON public."ProductHistory"("ProductId");

-- Index on ChangedDate in ProductHistory for temporal queries
CREATE INDEX idx_producthistory_changeddate ON public."ProductHistory"("ChangedDate");

-- Index on ProductId in ProductStats for joins
CREATE INDEX idx_productstats_productid ON public."ProductStats"("ProductId");

-- ============================================
-- Step 5: Create Triggers for Audit Trail
-- ============================================

-- Function to update LastModifiedDate
CREATE OR REPLACE FUNCTION update_modified_date()
RETURNS TRIGGER AS $$
BEGIN
    NEW."LastModifiedDate" = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger on Products table
CREATE TRIGGER trg_products_modified
    BEFORE UPDATE ON public."Products"
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_date();

-- Function to log product changes
CREATE OR REPLACE FUNCTION log_product_change()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO public."ProductHistory" ("ProductId", "Action", "NewValue", "ChangedDate")
        VALUES (NEW."ProductId", 'INSERT', 
                json_build_object('Name', NEW."Name", 'Price', NEW."Price", 'StockQuantity', NEW."StockQuantity")::TEXT,
                CURRENT_TIMESTAMP);
        RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO public."ProductHistory" ("ProductId", "Action", "OldValue", "NewValue", "ChangedDate")
        VALUES (NEW."ProductId", 'UPDATE',
                json_build_object('Name', OLD."Name", 'Price', OLD."Price", 'StockQuantity', OLD."StockQuantity")::TEXT,
                json_build_object('Name', NEW."Name", 'Price', NEW."Price", 'StockQuantity', NEW."StockQuantity")::TEXT,
                CURRENT_TIMESTAMP);
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO public."ProductHistory" ("ProductId", "Action", "OldValue", "ChangedDate")
        VALUES (OLD."ProductId", 'DELETE',
                json_build_object('Name', OLD."Name", 'Price', OLD."Price", 'StockQuantity', OLD."StockQuantity")::TEXT,
                CURRENT_TIMESTAMP);
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger to log all changes
CREATE TRIGGER trg_products_audit
    AFTER INSERT OR UPDATE OR DELETE ON public."Products"
    FOR EACH ROW
    EXECUTE FUNCTION log_product_change();

-- ============================================
-- Step 6: Insert Sample Data
-- ============================================

INSERT INTO public."Products" ("Name", "Price", "StockQuantity") VALUES
('Laptop Computer', 999.99, 50),
('Wireless Mouse', 25.50, 200),
('Mechanical Keyboard', 75.00, 150),
('27" Monitor', 299.99, 30),
('USB-C Cable', 9.99, 500),
('External Hard Drive 1TB', 89.99, 75),
('16GB RAM Module', 149.99, 100),
('Graphics Card', 599.99, 15),
('SSD 500GB', 79.99, 120),
('Webcam HD', 49.99, 80),
('Headset with Microphone', 39.99, 150),
('Docking Station', 199.99, 40),
('Power Supply 650W', 89.99, 60),
('CPU Cooler', 44.99, 90),
('Motherboard', 249.99, 25);

-- ============================================
-- Step 7: Verify Setup
-- ============================================

-- Check table counts
SELECT 'Products' as TableName, COUNT(*) as RecordCount FROM public."Products"
UNION ALL
SELECT 'ProductHistory', COUNT(*) FROM public."ProductHistory"
UNION ALL
SELECT 'ProductStats', COUNT(*) FROM public."ProductStats";

-- Display sample data
SELECT 
    "ProductId",
    "Name",
    "Price",
    "StockQuantity",
    "CreatedDate"
FROM public."Products"
ORDER BY "ProductId"
LIMIT 5;

-- ============================================
-- Step 8: Create Database User (Optional)
-- ============================================
-- Uncomment to create a dedicated application user

-- CREATE USER adocore_app WITH PASSWORD 'your_secure_password';
-- GRANT CONNECT ON DATABASE "ProductManagement" TO adocore_app;
-- GRANT USAGE ON SCHEMA public TO adocore_app;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO adocore_app;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO adocore_app;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO adocore_app;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO adocore_app;

-- ============================================
-- Step 9: Test Connection
-- ============================================

-- Verify you can query the data
SELECT COUNT(*) as TotalProducts FROM public."Products";
SELECT COUNT(*) as TotalHistoryRecords FROM public."ProductHistory";

-- Test a complex query similar to those in the application
WITH ProductStats AS (
    SELECT 
        "ProductId",
        AVG("Price") OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM public."Products"
)
SELECT 
    p."ProductId",
    p."Name",
    p."Price",
    p."StockQuantity",
    ps.AvgPrice,
    ps.TotalProducts
FROM public."Products" p
INNER JOIN ProductStats ps ON p."ProductId" = ps."ProductId"
WHERE p."StockQuantity" > 0
ORDER BY p."Price" DESC
LIMIT 5;

-- ============================================
-- Setup Complete
-- ============================================

-- Connection string for application:
-- Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=your_password;

COMMENT ON DATABASE "ProductManagement" IS 'PostgreSQL database for AdoCore application migrated from SQL Server';

SELECT 'Database setup completed successfully!' as Status;
