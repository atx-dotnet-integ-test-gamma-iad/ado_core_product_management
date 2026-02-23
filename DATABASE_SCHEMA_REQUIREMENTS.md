# PostgreSQL Database Schema Requirements

## Overview
This application has been migrated from Microsoft SQL Server to PostgreSQL. All SQL statements have been converted to use lowercase naming conventions for PostgreSQL compatibility.

## Required Schema Objects

### Tables Required
The following tables must exist in your PostgreSQL database with lowercase names and columns:

#### 1. `products` (Main Product Table)
```sql
CREATE TABLE products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(18,2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP DEFAULT NOW(),
    modifieddate TIMESTAMP DEFAULT NOW()
);
```

#### 2. `producthistory` (Product Change History)
```sql
CREATE TABLE producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(50) NOT NULL,
    oldprice DECIMAL(18,2),
    newprice DECIMAL(18,2),
    oldstock INTEGER,
    newstock INTEGER,
    actiondate TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (productid) REFERENCES products(productid)
);
```

#### 3. `productstats` (Product Statistics)
```sql
CREATE TABLE productstats (
    statid INTEGER PRIMARY KEY,
    totalproducts INTEGER DEFAULT 0,
    averageprice DECIMAL(18,2) DEFAULT 0,
    lastupdated TIMESTAMP DEFAULT NOW()
);

-- Insert initial stats row
INSERT INTO productstats (statid, totalproducts, averageprice, lastupdated)
VALUES (1, 0, 0, NOW());
```

## Schema Naming Convention Changes

### SQL Server → PostgreSQL Mapping
The following naming conventions were applied during migration:

| SQL Server (Mixed Case) | PostgreSQL (Lowercase) |
|------------------------|------------------------|
| Products               | products               |
| ProductId              | productid              |
| ProductHistory         | producthistory         |
| ProductStats           | productstats           |
| Name                   | name                   |
| Description            | description            |
| Price                  | price                  |
| StockQuantity          | stockquantity          |
| CreatedDate            | createddate            |
| ModifiedDate           | modifieddate           |
| TotalProducts          | totalproducts          |
| AveragePrice           | averageprice           |
| LastUpdated            | lastupdated            |

## SQL Function Changes

### Date/Time Functions
- `GETDATE()` → `NOW()`
- `SCOPE_IDENTITY()` → `RETURNING productid` clause

### Identity/Sequence Changes
SQL Server's `IDENTITY` columns are replaced with PostgreSQL's `SERIAL` type or explicit sequences.

## Migration Script
Use the provided SQL script above to create the required schema in your PostgreSQL database before running the application.

## Connection Requirements
- PostgreSQL server must be running and accessible
- Database specified in connection string must exist
- User must have permissions to:
  - CREATE TABLE (for schema setup)
  - SELECT, INSERT, UPDATE, DELETE (for CRUD operations)
  - BEGIN TRANSACTION, COMMIT, ROLLBACK (for transaction management)

## Testing Schema Setup
After creating the schema, you can verify it with:

```sql
-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('products', 'producthistory', 'productstats');

-- Check table structure
\d products
\d producthistory
\d productstats
```

## Sample Data (Optional)
To test the application, you can insert sample data:

```sql
INSERT INTO products (name, description, price, stockquantity)
VALUES 
    ('Laptop', 'High-performance laptop', 1299.99, 50),
    ('Mouse', 'Wireless optical mouse', 29.99, 200),
    ('Keyboard', 'Mechanical gaming keyboard', 129.99, 75);
```
