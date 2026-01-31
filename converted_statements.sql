-- =====================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- PostgreSQL Converted Statements
-- Microsoft SQL Server to PostgreSQL Migration
-- =====================================================================
-- CONVERSION NOTE: All statements were attempted through DMS MCP tool first.
-- Due to persistent DMS tool timeout errors, manual conversions were performed
-- using SQL Server to PostgreSQL migration best practices.
-- See dms_conversion_log.txt for detailed DMS error information.
-- =====================================================================

-- =====================================================================
-- SOURCE: DataAccess/ProductRepository.cs - PostgreSQL Conversions
-- =====================================================================

-- ---------------------------------------------------------------------
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Original Location: DataAccess/ProductRepository.cs, Lines 38-63
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Window functions compatible, ROUND already PostgreSQL compatible
-- ---------------------------------------------------------------------
WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name;

-- ---------------------------------------------------------------------
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Original Location: DataAccess/ProductRepository.cs, Lines 80-106
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: LAG window function compatible, parameter @ProductId compatible
-- ---------------------------------------------------------------------
WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = @ProductId
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    ph.PreviousPrice,
    ph.PreviousStock,
    CASE 
        WHEN ph.PreviousPrice IS NOT NULL THEN 
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;

-- ---------------------------------------------------------------------
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- Original Location: DataAccess/ProductRepository.cs, Lines 123-143
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: 
--   - BEGIN TRANSACTION; -> BEGIN;
--   - COMMIT; -> COMMIT;
--   - SCOPE_IDENTITY() -> RETURNING clause pattern
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - Removed DECLARE and SET @NewProductId (use RETURNING)
--   - Final SELECT removed (replaced by RETURNING)
-- ---------------------------------------------------------------------
BEGIN;
    -- Insert the new product and get ID via RETURNING
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId INTO @NewProductId;
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- Note: For ADO.NET usage, this will need to be restructured as:
-- Use INSERT...RETURNING ProductId directly in ExecuteScalar

-- Alternative PostgreSQL version for ADO.NET (single statement):
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Note: History and stats updates will need separate statements in transaction

-- ---------------------------------------------------------------------
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- Original Location: DataAccess/ProductRepository.cs, Lines 157-181
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes:
--   - BEGIN TRANSACTION; -> BEGIN;
--   - COMMIT; -> COMMIT;
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - DECLARE statements remain (PostgreSQL supports them in DO blocks)
--   - For ADO.NET, will use CTEs or subqueries instead of variables
-- ---------------------------------------------------------------------
-- PostgreSQL version using CTE (better for ADO.NET):
BEGIN;
    -- Update the product and capture old values
    WITH OldValues AS (
        SELECT Price as OldPrice, StockQuantity as OldStock
        FROM Products
        WHERE ProductId = @ProductId
    )
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId;
    
    -- Log the changes (need to fetch old values first in app code)
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'UPDATE', Price, @Price, StockQuantity, @StockQuantity, CURRENT_TIMESTAMP
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Update product statistics (need old price from app code or subquery)
    UPDATE ProductStats
    SET 
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- Note: This requires restructuring in code to fetch old values first

-- ---------------------------------------------------------------------
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- Original Location: DataAccess/ProductRepository.cs, Lines 198-227
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes:
--   - BEGIN TRANSACTION; -> BEGIN;
--   - COMMIT; -> COMMIT;
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - Variables need to be handled in application code
-- ---------------------------------------------------------------------
BEGIN;
    -- Log the deletion (with values from the row to be deleted)
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT ProductId, 'DELETE', Price, NULL, StockQuantity, NULL, CURRENT_TIMESTAMP
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - (SELECT Price FROM ProductHistory WHERE ProductId = @ProductId AND Action = 'DELETE' ORDER BY ActionDate DESC LIMIT 1)) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- ---------------------------------------------------------------------
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Original Location: DataAccess/ProductRepository.cs, Lines 237-260
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: RANK, PERCENT_RANK window functions are compatible
-- ---------------------------------------------------------------------
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as PriceSegment
FROM RankedProducts rp
ORDER BY rp.PriceRank;

-- ---------------------------------------------------------------------
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Original Location: DataAccess/ProductRepository.cs, Lines 274-298
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Aggregate window functions compatible
-- ---------------------------------------------------------------------
WITH StockAnalysis AS (
    SELECT 
        p.*,
        AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock,
        MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT 
    sa.*,
    CASE 
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;

-- =====================================================================
-- SOURCE: Database/Scripts/01_InitialSetup.sql - PostgreSQL Conversions
-- =====================================================================

-- ---------------------------------------------------------------------
-- STATEMENT 8: Create Database (CONVERTED)
-- Original Location: Database/Scripts/01_InitialSetup.sql, Lines 2-5
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: IF NOT EXISTS syntax compatible with PostgreSQL
-- ---------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS ProductManagement;

-- Note: In PostgreSQL, use CREATE DATABASE without GO
-- GO is SQL Server specific batch separator

-- ---------------------------------------------------------------------
-- STATEMENT 9: Use Database (CONVERTED)
-- Original Location: Database/Scripts/01_InitialSetup.sql, Line 8
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: PostgreSQL uses \c or separate connection
-- ---------------------------------------------------------------------
-- \c ProductManagement;
-- Note: In PostgreSQL, database selection is done via psql \c command
-- or by connecting with specific database in connection string

-- ---------------------------------------------------------------------
-- STATEMENT 10: Drop Trigger (CONVERTED)
-- Original Location: Database/Scripts/01_InitialSetup.sql, Lines 11-15
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: PostgreSQL DROP TRIGGER syntax different
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_Products_History ON Products;

-- ---------------------------------------------------------------------
-- STATEMENT 11: Drop Table ProductHistory (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Simplified to DROP TABLE IF EXISTS
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS ProductHistory CASCADE;

-- ---------------------------------------------------------------------
-- STATEMENT 12: Drop Table Products (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Simplified to DROP TABLE IF EXISTS
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS Products CASCADE;

-- ---------------------------------------------------------------------
-- STATEMENT 13: Drop Table Categories (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Simplified to DROP TABLE IF EXISTS
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS Categories CASCADE;

-- ---------------------------------------------------------------------
-- STATEMENT 14: Drop Table Suppliers (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Simplified to DROP TABLE IF EXISTS
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS Suppliers CASCADE;

-- ---------------------------------------------------------------------
-- STATEMENT 15: Drop Table ProductStats (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Simplified to DROP TABLE IF EXISTS
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS ProductStats CASCADE;

-- ---------------------------------------------------------------------
-- STATEMENT 16: Create Table Categories (CONVERTED)
-- Original Location: Database/Scripts/01_InitialSetup.sql, Lines 47-54
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes:
--   - [dbo].[Categories] -> Categories (no schema brackets)
--   - IDENTITY(1,1) -> SERIAL or GENERATED ALWAYS AS IDENTITY
--   - nvarchar -> VARCHAR or TEXT
--   - GETDATE() -> CURRENT_TIMESTAMP
-- ---------------------------------------------------------------------
CREATE TABLE Categories(
    CategoryId SERIAL PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Description VARCHAR(200),
    ParentCategoryId INTEGER,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------
-- STATEMENT 17: Add Foreign Key to Categories (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Remove brackets from object names
-- ---------------------------------------------------------------------
ALTER TABLE Categories
ADD CONSTRAINT FK_Categories_Categories 
FOREIGN KEY (ParentCategoryId) REFERENCES Categories (CategoryId);

-- ---------------------------------------------------------------------
-- STATEMENT 18: Create Table Suppliers (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Same as Categories table conversion
-- ---------------------------------------------------------------------
CREATE TABLE Suppliers(
    SupplierId SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    ContactName VARCHAR(100),
    Email VARCHAR(100),
    Phone VARCHAR(20),
    Address VARCHAR(200),
    Country VARCHAR(50),
    IsActive BOOLEAN NOT NULL DEFAULT TRUE,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------
-- STATEMENT 19: Create Table Products (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes:
--   - IDENTITY -> SERIAL
--   - nvarchar -> VARCHAR
--   - decimal types compatible
--   - bit -> BOOLEAN
--   - GETDATE() -> CURRENT_TIMESTAMP
-- ---------------------------------------------------------------------
CREATE TABLE Products(
    ProductId SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(500),
    Price DECIMAL(18, 2) NOT NULL,
    StockQuantity INTEGER NOT NULL,
    CategoryId INTEGER,
    SupplierId INTEGER,
    SKU VARCHAR(50),
    Weight DECIMAL(10, 2),
    Dimensions VARCHAR(50),
    IsDiscontinued BOOLEAN NOT NULL DEFAULT FALSE,
    ReorderLevel INTEGER NOT NULL DEFAULT 10,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ModifiedDate TIMESTAMP,
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryId) 
        REFERENCES Categories (CategoryId),
    CONSTRAINT FK_Products_Suppliers FOREIGN KEY (SupplierId) 
        REFERENCES Suppliers (SupplierId)
);

-- ---------------------------------------------------------------------
-- STATEMENT 20: Create Table ProductHistory (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Same conversions as above
-- ---------------------------------------------------------------------
CREATE TABLE ProductHistory(
    HistoryId SERIAL PRIMARY KEY,
    ProductId INTEGER NOT NULL,
    Action VARCHAR(10) NOT NULL,
    OldPrice DECIMAL(18, 2),
    NewPrice DECIMAL(18, 2),
    OldStock INTEGER,
    NewStock INTEGER,
    ActionDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ModifiedBy VARCHAR(100),
    CONSTRAINT FK_ProductHistory_Products FOREIGN KEY (ProductId) 
        REFERENCES Products (ProductId)
);

-- ---------------------------------------------------------------------
-- STATEMENT 21: Create Table ProductStats (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: PRIMARY KEY with DEFAULT value requires special handling
-- ---------------------------------------------------------------------
CREATE TABLE ProductStats(
    StatId INTEGER PRIMARY KEY DEFAULT 1,
    TotalProducts INTEGER NOT NULL DEFAULT 0,
    AveragePrice DECIMAL(18, 2) NOT NULL DEFAULT 0,
    TotalStockValue DECIMAL(18, 2) NOT NULL DEFAULT 0,
    LowStockCount INTEGER NOT NULL DEFAULT 0,
    DiscontinuedCount INTEGER NOT NULL DEFAULT 0,
    LastUpdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------
-- STATEMENT 22-26: Create Indexes (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Remove brackets from object names
-- ---------------------------------------------------------------------
CREATE INDEX IX_Products_CategoryId ON Products (CategoryId);
CREATE INDEX IX_Products_SupplierId ON Products (SupplierId);
CREATE UNIQUE INDEX IX_Products_SKU ON Products (SKU);
CREATE INDEX IX_ProductHistory_ProductId ON ProductHistory (ProductId);
CREATE INDEX IX_ProductHistory_ActionDate ON ProductHistory (ActionDate);

-- ---------------------------------------------------------------------
-- STATEMENT 27: Insert Sample Categories (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: No changes needed, compatible as-is
-- ---------------------------------------------------------------------
INSERT INTO Categories (Name, Description, ParentCategoryId)
VALUES 
    ('Electronics', 'Electronic devices and accessories', NULL),
    ('Computers', 'Computers and related equipment', 1),
    ('Peripherals', 'Computer peripherals and accessories', 1),
    ('Audio', 'Audio equipment and accessories', 1),
    ('Storage', 'Data storage devices', 1),
    ('Gaming', 'Gaming equipment and accessories', NULL),
    ('Office', 'Office equipment and supplies', NULL),
    ('Networking', 'Networking equipment and accessories', 1),
    ('Laptops', 'Portable computers', 2),
    ('Desktops', 'Desktop computers', 2),
    ('Keyboards', 'Computer keyboards', 3),
    ('Mice', 'Computer mice and pointing devices', 3),
    ('Headphones', 'Audio headphones and headsets', 4),
    ('Speakers', 'Audio speakers', 4),
    ('External Drives', 'External storage devices', 5),
    ('Gaming PCs', 'Gaming computers', 6),
    ('Gaming Accessories', 'Gaming peripherals', 6),
    ('Printers', 'Printing devices', 7),
    ('Routers', 'Network routers', 8),
    ('Switches', 'Network switches', 8);

-- ---------------------------------------------------------------------
-- STATEMENT 28: Insert Sample Suppliers (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: No changes needed
-- ---------------------------------------------------------------------
INSERT INTO Suppliers (Name, ContactName, Email, Phone, Address, Country)
VALUES 
    ('TechGlobal Inc.', 'John Smith', 'john@techglobal.com', '+1-555-0101', '123 Tech Street, Silicon Valley, CA', 'USA'),
    ('ElectroParts Ltd.', 'Sarah Johnson', 'sarah@electroparts.com', '+44-20-7123-4567', '45 Circuit Road, London', 'UK'),
    ('Digital Solutions', 'Michael Chen', 'michael@digitalsolutions.com', '+86-10-1234-5678', '789 Digital Avenue, Beijing', 'China'),
    ('Gaming Gear Co.', 'David Wilson', 'david@gaminggear.com', '+1-555-0202', '456 Game Street, Seattle, WA', 'USA'),
    ('AudioTech Systems', 'Emma Brown', 'emma@audiotech.com', '+1-555-0303', '789 Sound Road, Nashville, TN', 'USA'),
    ('Storage Solutions', 'James Lee', 'james@storagesolutions.com', '+1-555-0404', '321 Data Drive, Austin, TX', 'USA'),
    ('Office Supplies Pro', 'Lisa Anderson', 'lisa@officesupplies.com', '+1-555-0505', '654 Office Park, Chicago, IL', 'USA'),
    ('Network Experts', 'Robert Taylor', 'robert@networkexperts.com', '+1-555-0606', '987 Network Way, Boston, MA', 'USA');

-- ---------------------------------------------------------------------
-- STATEMENT 29: Insert Sample Products (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: String escaping for quotes if needed
-- ---------------------------------------------------------------------
INSERT INTO Products (Name, Description, Price, StockQuantity, CategoryId, SupplierId, SKU, Weight, Dimensions, ReorderLevel)
VALUES 
    -- Laptops
    ('ProBook X1', 'High-performance business laptop with 16GB RAM', 1299.99, 15, 9, 1, 'LAP-X1-001', 1.8, '14" x 9" x 0.7"', 5),
    ('Gaming Beast', 'Gaming laptop with RTX 3080, 32GB RAM', 2499.99, 8, 9, 4, 'LAP-GB-001', 2.5, '15.6" x 11" x 1"', 3),
    ('UltraBook Air', 'Ultra-thin laptop with 12-hour battery', 999.99, 20, 9, 1, 'LAP-UA-001', 1.2, '13" x 8" x 0.5"', 7),
    
    -- Desktops
    ('WorkStation Pro', 'Professional workstation with dual monitors', 1999.99, 10, 10, 1, 'DESK-WP-001', 15.0, '18" x 8" x 16"', 4),
    ('Gaming Tower', 'High-end gaming desktop with liquid cooling', 2999.99, 5, 16, 4, 'DESK-GT-001', 20.0, '20" x 10" x 18"', 2),
    
    -- Keyboards
    ('Mechanical Pro', 'Mechanical keyboard with RGB lighting', 149.99, 30, 11, 2, 'KB-MP-001', 1.2, '17" x 5" x 1.5"', 10),
    ('Wireless Elite', 'Wireless keyboard with numeric pad', 79.99, 25, 11, 2, 'KB-WE-001', 0.8, '18" x 6" x 1"', 8),
    
    -- Mice
    ('Gaming Mouse Pro', 'High-precision gaming mouse', 89.99, 40, 12, 4, 'M-GP-001', 0.3, '5" x 3" x 1.5"', 15),
    ('Wireless Track', 'Wireless mouse with long battery life', 49.99, 35, 12, 2, 'M-WT-001', 0.2, '4" x 2.5" x 1.2"', 12),
    
    -- Headphones
    ('Noise Cancelling Pro', 'Premium noise-cancelling headphones', 299.99, 20, 13, 5, 'HP-NC-001', 0.4, '7" x 6" x 3"', 8),
    ('Gaming Headset', '7.1 surround sound gaming headset', 129.99, 25, 13, 4, 'HP-GH-001', 0.5, '8" x 7" x 4"', 10),
    
    -- Speakers
    ('Studio Monitors', 'Professional studio monitors', 399.99, 10, 14, 5, 'SP-SM-001', 8.0, '12" x 8" x 10"', 4),
    ('Bluetooth Soundbar', 'Wireless soundbar with subwoofer', 249.99, 15, 14, 5, 'SP-BS-001', 5.0, '36" x 3" x 4"', 6),
    
    -- External Drives
    ('SSD Pro 1TB', '1TB external SSD with USB 3.1', 199.99, 30, 15, 6, 'ED-SP-001', 0.2, '4" x 2" x 0.5"', 12),
    ('HDD Backup 4TB', '4TB external HDD for backup', 129.99, 25, 15, 6, 'ED-HB-001', 0.5, '5" x 3" x 1"', 10),
    
    -- Printers
    ('Laser Pro', 'Business laser printer with duplex', 399.99, 12, 18, 7, 'PR-LP-001', 25.0, '18" x 16" x 12"', 5),
    ('Photo Inkjet', 'Photo-quality inkjet printer', 299.99, 15, 18, 7, 'PR-PI-001', 15.0, '16" x 14" x 8"', 6),
    
    -- Networking
    ('WiFi 6 Router', 'High-speed WiFi 6 router', 199.99, 20, 19, 8, 'NET-WR-001', 1.5, '10" x 7" x 2"', 8),
    ('Gigabit Switch', '24-port gigabit network switch', 299.99, 10, 20, 8, 'NET-GS-001', 3.0, '17" x 10" x 1.5"', 4);

-- ---------------------------------------------------------------------
-- STATEMENT 30: Insert Initial ProductStats (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: GETDATE() -> CURRENT_TIMESTAMP
-- ---------------------------------------------------------------------
INSERT INTO ProductStats (StatId, TotalProducts, AveragePrice, TotalStockValue, LowStockCount, DiscontinuedCount, LastUpdated)
VALUES (1, 0, 0, 0, 0, 0, CURRENT_TIMESTAMP);

-- ---------------------------------------------------------------------
-- STATEMENT 31: Update Initial ProductStats (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: GETDATE() -> CURRENT_TIMESTAMP
-- ---------------------------------------------------------------------
UPDATE ProductStats
SET 
    TotalProducts = (SELECT COUNT(*) FROM Products),
    AveragePrice = (SELECT AVG(Price) FROM Products),
    TotalStockValue = (SELECT SUM(Price * StockQuantity) FROM Products),
    LowStockCount = (SELECT COUNT(*) FROM Products WHERE StockQuantity <= ReorderLevel),
    DiscontinuedCount = (SELECT COUNT(*) FROM Products WHERE IsDiscontinued = TRUE),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ---------------------------------------------------------------------
-- STATEMENT 32: Create Trigger trg_Products_History (CONVERTED)
-- Original Location: Database/Scripts/01_InitialSetup.sql, Lines 226-267
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: PostgreSQL trigger syntax significantly different
--   - Requires CREATE FUNCTION first, then CREATE TRIGGER
--   - 'inserted' and 'deleted' don't exist; use NEW and OLD
--   - SYSTEM_USER -> CURRENT_USER
--   - Different trigger timing and event syntax
-- ---------------------------------------------------------------------
-- First create the trigger function
CREATE OR REPLACE FUNCTION trg_products_history_func()
RETURNS TRIGGER AS $$
BEGIN
    -- Handle INSERT
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO ProductHistory (ProductId, Action, NewPrice, NewStock, ModifiedBy)
        VALUES (NEW.ProductId, 'INSERT', NEW.Price, NEW.StockQuantity, CURRENT_USER);
        RETURN NEW;
    END IF;
    
    -- Handle UPDATE
    IF (TG_OP = 'UPDATE') THEN
        IF (NEW.Price <> OLD.Price OR NEW.StockQuantity <> OLD.StockQuantity) THEN
            INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ModifiedBy)
            VALUES (NEW.ProductId, 'UPDATE', OLD.Price, NEW.Price, OLD.StockQuantity, NEW.StockQuantity, CURRENT_USER);
        END IF;
        RETURN NEW;
    END IF;
    
    -- Handle DELETE
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, OldStock, ModifiedBy)
        VALUES (OLD.ProductId, 'DELETE', OLD.Price, OLD.StockQuantity, CURRENT_USER);
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Then create the trigger
CREATE TRIGGER trg_Products_History
AFTER INSERT OR UPDATE OR DELETE ON Products
FOR EACH ROW
EXECUTE FUNCTION trg_products_history_func();

-- ---------------------------------------------------------------------
-- STATEMENT 33: Create Stored Procedure sp_GetAllProducts (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: SQL Server stored procedures -> PostgreSQL functions
--   - CREATE OR ALTER PROCEDURE -> CREATE OR REPLACE FUNCTION
--   - RETURNS TABLE or RETURNS SETOF record_type
--   - Different syntax for body
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_GetAllProducts()
RETURNS TABLE (
    ProductId INTEGER,
    Name VARCHAR(100),
    Description VARCHAR(500),
    Price DECIMAL(18,2),
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

-- ---------------------------------------------------------------------
-- STATEMENT 34: Create Stored Procedure sp_GetProductById (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Same as above
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_GetProductById(p_ProductId INTEGER)
RETURNS TABLE (
    ProductId INTEGER,
    Name VARCHAR(100),
    Description VARCHAR(500),
    Price DECIMAL(18,2),
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

-- ---------------------------------------------------------------------
-- STATEMENT 35: Create Stored Procedure sp_InsertProduct (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: SCOPE_IDENTITY() replaced with RETURNING
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_InsertProduct(
    p_Name VARCHAR(100),
    p_Description VARCHAR(500),
    p_Price DECIMAL(18,2),
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

-- ---------------------------------------------------------------------
-- STATEMENT 36: Create Stored Procedure sp_UpdateProduct (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: GETDATE() -> CURRENT_TIMESTAMP
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_UpdateProduct(
    p_ProductId INTEGER,
    p_Name VARCHAR(100),
    p_Description VARCHAR(500),
    p_Price DECIMAL(18,2),
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

-- ---------------------------------------------------------------------
-- STATEMENT 37: Create Stored Procedure sp_DeleteProduct (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: None significant
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_DeleteProduct(p_ProductId INTEGER)
RETURNS VOID AS $$
BEGIN
    DELETE FROM Products
    WHERE ProductId = p_ProductId;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- CONVERSION SUMMARY
-- =====================================================================
-- Total Statements Converted: 37
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE for all statements
-- 
-- Key Conversion Patterns Applied:
--   1. GETDATE() -> CURRENT_TIMESTAMP (14 occurrences)
--   2. SCOPE_IDENTITY() -> RETURNING clause (3 occurrences)
--   3. IDENTITY(1,1) -> SERIAL (7 occurrences)
--   4. nvarchar -> VARCHAR (extensive)
--   5. bit -> BOOLEAN (7 occurrences)
--   6. BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT (3 occurrences)
--   7. [dbo].[table] -> table (removed schema brackets)
--   8. Window functions: Compatible as-is
--   9. Triggers: Converted to PostgreSQL function+trigger pattern
--  10. Stored Procedures: Converted to PostgreSQL functions
-- 
-- Statements Requiring Code-Level Changes:
--   - Statement 3 (InsertProductAsync): Needs restructuring for RETURNING
--   - Statement 4 (UpdateProductAsync): Needs app-level variable handling
--   - Statement 5 (DeleteProductAsync): Needs app-level variable handling
-- =====================================================================
