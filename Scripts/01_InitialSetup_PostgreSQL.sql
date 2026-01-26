-- PostgreSQL Database Initialization Script
-- Converted from SQL Server to PostgreSQL
-- Migration Date: 2026-01-25

-- Create database (run separately if needed)
-- CREATE DATABASE IF NOT EXISTS productmanagement;

-- Connect to database
\c productmanagement

-- Create Products Table
CREATE TABLE IF NOT EXISTS public.products (
    ProductId SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(500),
    Price NUMERIC(18,2) NOT NULL,
    StockQuantity INTEGER NOT NULL,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ModifiedDate TIMESTAMP
);

-- Create ProductHistory Table (referenced in application)
CREATE TABLE IF NOT EXISTS public.producthistory (
    HistoryId SERIAL PRIMARY KEY,
    ProductId INTEGER NOT NULL,
    Action VARCHAR(50) NOT NULL,
    OldPrice NUMERIC(18,2),
    NewPrice NUMERIC(18,2),
    OldStock INTEGER,
    NewStock INTEGER,
    ActionDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create ProductStats Table (referenced in application)
CREATE TABLE IF NOT EXISTS public.productstats (
    StatId SERIAL PRIMARY KEY,
    TotalProducts INTEGER NOT NULL DEFAULT 0,
    AveragePrice NUMERIC(18,2) NOT NULL DEFAULT 0,
    LastUpdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Initialize ProductStats with a default row
INSERT INTO public.productstats (StatId, TotalProducts, AveragePrice, LastUpdated)
VALUES (1, 0, 0, CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;

-- Insert Sample Data
INSERT INTO public.products (Name, Description, Price, StockQuantity)
VALUES 
    ('Laptop', 'High-performance laptop', 999.99, 10),
    ('Mouse', 'Wireless gaming mouse', 49.99, 20),
    ('Keyboard', 'Mechanical keyboard', 129.99, 15)
ON CONFLICT DO NOTHING;

-- Note: Stored procedures from SQL Server version have been replaced
-- with inline parameterized SQL in the application code (ProductRepository.cs).
-- This is a standard approach when migrating from SQL Server to PostgreSQL.
