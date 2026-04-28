-- PostgreSQL Setup Script for ProductManagement Database
-- Converted from MS SQL Server to PostgreSQL

-- Create Products Table
CREATE TABLE IF NOT EXISTS products(
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price DECIMAL(18, 2) NOT NULL,
    stockquantity INT NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT NOW(),
    modifieddate TIMESTAMP NULL
);

-- Create ProductHistory Table
CREATE TABLE IF NOT EXISTS producthistory(
    historyid SERIAL PRIMARY KEY,
    productid INT NOT NULL,
    action VARCHAR(10) NOT NULL,
    oldprice DECIMAL(18, 2) NULL,
    newprice DECIMAL(18, 2) NULL,
    oldstock INT NULL,
    newstock INT NULL,
    actiondate TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_producthistory_products FOREIGN KEY (productid) REFERENCES products(productid)
);

-- Create ProductStats Table
CREATE TABLE IF NOT EXISTS productstats(
    statid INT PRIMARY KEY DEFAULT 1,
    totalproducts INT NOT NULL DEFAULT 0,
    averageprice DECIMAL(18, 2) NOT NULL DEFAULT 0,
    totalstockvalue DECIMAL(18, 2) NOT NULL DEFAULT 0,
    lowstockcount INT NOT NULL DEFAULT 0,
    discontinuedcount INT NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create Indexes
CREATE INDEX IF NOT EXISTS ix_producthistory_productid ON producthistory(productid);
CREATE INDEX IF NOT EXISTS ix_producthistory_actiondate ON producthistory(actiondate);

-- Insert Sample Data
INSERT INTO products (name, description, price, stockquantity) VALUES ('Laptop', 'High-performance laptop', 999.99, 10)
ON CONFLICT DO NOTHING;
INSERT INTO products (name, description, price, stockquantity) VALUES ('Mouse', 'Wireless gaming mouse', 49.99, 20)
ON CONFLICT DO NOTHING;
INSERT INTO products (name, description, price, stockquantity) VALUES ('Keyboard', 'Mechanical keyboard', 129.99, 15)
ON CONFLICT DO NOTHING;

-- Insert initial stats record
INSERT INTO productstats (statid, totalproducts, averageprice, totalstockvalue, lowstockcount, discontinuedcount, lastupdated)
VALUES (1, 0, 0, 0, 0, 0, NOW())
ON CONFLICT (statid) DO NOTHING;

-- Update initial statistics
UPDATE productstats
SET 
    totalproducts = (SELECT COUNT(*) FROM products),
    averageprice = (SELECT COALESCE(AVG(price), 0) FROM products),
    totalstockvalue = (SELECT COALESCE(SUM(price * stockquantity), 0) FROM products),
    lastupdated = NOW()
WHERE statid = 1;
