-- PostgreSQL Table Creation DDL for Products Table
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
    CreatedDate TIMESTAMP NOT NULL DEFAULT NOW(),
    ModifiedDate TIMESTAMP
);

CREATE TABLE ProductHistory(
    HistoryId SERIAL PRIMARY KEY,
    ProductId INTEGER NOT NULL,
    Action VARCHAR(10) NOT NULL,
    OldPrice DECIMAL(18, 2),
    NewPrice DECIMAL(18, 2),
    OldStock INTEGER,
    NewStock INTEGER,
    ActionDate TIMESTAMP NOT NULL DEFAULT NOW(),
    ModifiedBy VARCHAR(100)
);

CREATE TABLE ProductStats(
    StatId INTEGER PRIMARY KEY DEFAULT 1,
    TotalProducts INTEGER NOT NULL DEFAULT 0,
    AveragePrice DECIMAL(18, 2) NOT NULL DEFAULT 0,
    TotalStockValue DECIMAL(18, 2) NOT NULL DEFAULT 0,
    LowStockCount INTEGER NOT NULL DEFAULT 0,
    DiscontinuedCount INTEGER NOT NULL DEFAULT 0,
    LastUpdated TIMESTAMP NOT NULL DEFAULT NOW()
);
