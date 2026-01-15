# PostgreSQL Database Setup Guide

## Overview
This guide provides instructions for setting up the PostgreSQL database required for the migrated AdoCore application.

## Prerequisites
- PostgreSQL 12 or later installed
- PostgreSQL client tools (psql) or GUI tool (pgAdmin, DBeaver)
- Connection credentials with CREATE SCHEMA and CREATE TABLE permissions

## Database Setup

### 1. Create the Schema

```sql
-- Connect to your PostgreSQL database
-- Replace 'productmanagement' with your database name if different

CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;
```

### 2. Create Tables

```sql
-- Products table
CREATE TABLE productmanagement_dbo.products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price NUMERIC(18,2) NOT NULL,
    stockquantity INTEGER NOT NULL DEFAULT 0,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP
);

-- ProductHistory table
CREATE TABLE productmanagement_dbo.producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(50) NOT NULL,
    oldprice NUMERIC(18,2),
    newprice NUMERIC(18,2),
    oldstock INTEGER,
    newstock INTEGER,
    actiondate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_product FOREIGN KEY (productid) 
        REFERENCES productmanagement_dbo.products(productid)
        ON DELETE CASCADE
);

-- ProductStats table
CREATE TABLE productmanagement_dbo.productstats (
    statid INTEGER PRIMARY KEY,
    totalproducts INTEGER NOT NULL DEFAULT 0,
    averageprice NUMERIC(18,2) NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Initialize ProductStats with a single row
INSERT INTO productmanagement_dbo.productstats (statid, totalproducts, averageprice, lastupdated)
VALUES (1, 0, 0, CURRENT_TIMESTAMP);
```

### 3. Create Indexes (Optional, but Recommended)

```sql
-- Index for product lookups
CREATE INDEX idx_products_name ON productmanagement_dbo.products(name);
CREATE INDEX idx_products_price ON productmanagement_dbo.products(price);
CREATE INDEX idx_products_stockquantity ON productmanagement_dbo.products(stockquantity);

-- Index for product history lookups
CREATE INDEX idx_producthistory_productid ON productmanagement_dbo.producthistory(productid);
CREATE INDEX idx_producthistory_actiondate ON productmanagement_dbo.producthistory(actiondate);
```

### 4. Insert Sample Data (Optional)

```sql
-- Sample products
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity, createddate)
VALUES 
    ('Laptop', 'High-performance laptop', 1299.99, 50, CURRENT_TIMESTAMP),
    ('Mouse', 'Wireless optical mouse', 29.99, 200, CURRENT_TIMESTAMP),
    ('Keyboard', 'Mechanical gaming keyboard', 149.99, 75, CURRENT_TIMESTAMP),
    ('Monitor', '27-inch 4K display', 599.99, 30, CURRENT_TIMESTAMP),
    ('Headphones', 'Noise-cancelling wireless headphones', 249.99, 100, CURRENT_TIMESTAMP);

-- Update ProductStats
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = (SELECT COUNT(*) FROM productmanagement_dbo.products),
    averageprice = (SELECT AVG(price) FROM productmanagement_dbo.products),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;
```

## Connection Configuration

### Update appsettings.json

Ensure your `appsettings.json` contains the correct PostgreSQL connection strings:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=your_password;Pooling=true",
    "ProdConnection": "Host=your_prod_host;Database=ProductManagement;Username=your_prod_user;Password=your_prod_password;Pooling=true"
  },
  "Environment": "Development"
}
```

**Security Note**: Never commit actual passwords to source control. Use environment variables or secure configuration management for production.

### Environment Variables (Recommended for Production)

Instead of storing passwords in `appsettings.json`, use environment variables:

```bash
# Linux/Mac
export POSTGRES_CONNECTION_STRING="Host=localhost;Database=ProductManagement;Username=postgres;Password=your_password;Pooling=true"

# Windows PowerShell
$env:POSTGRES_CONNECTION_STRING="Host=localhost;Database=ProductManagement;Username=postgres;Password=your_password;Pooling=true"

# Windows CMD
set POSTGRES_CONNECTION_STRING=Host=localhost;Database=ProductManagement;Username=postgres;Password=your_password;Pooling=true
```

## Verification Steps

### 1. Test Database Connection

```sql
-- Verify schema exists
SELECT schema_name 
FROM information_schema.schemata 
WHERE schema_name = 'productmanagement_dbo';

-- Verify tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'productmanagement_dbo';

-- Check sample data
SELECT COUNT(*) FROM productmanagement_dbo.products;
```

### 2. Test Application Connection

Run the application and verify:
- Connection establishes successfully
- Product list displays (if sample data was inserted)
- CRUD operations work correctly

## Troubleshooting

### Connection Issues

**Problem**: Application cannot connect to PostgreSQL
- Verify PostgreSQL is running: `sudo systemctl status postgresql` (Linux) or check Services (Windows)
- Check `pg_hba.conf` for authentication settings
- Verify firewall rules allow connections on port 5432
- Test connection using psql: `psql -h localhost -U postgres -d ProductManagement`

**Problem**: Authentication failed
- Verify username and password are correct
- Check PostgreSQL authentication method in `pg_hba.conf`
- Ensure user has necessary permissions

**Problem**: Database does not exist
- Create database: `CREATE DATABASE "ProductManagement";`
- Verify database name matches connection string exactly (case-sensitive)

### Schema Issues

**Problem**: Tables not found
- Verify schema exists: `SELECT schema_name FROM information_schema.schemata;`
- Check search_path: `SHOW search_path;`
- Use fully qualified table names: `productmanagement_dbo.products`

**Problem**: Permission denied on schema
```sql
-- Grant necessary permissions
GRANT USAGE ON SCHEMA productmanagement_dbo TO your_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA productmanagement_dbo TO your_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA productmanagement_dbo TO your_user;
```

### Performance Issues

**Problem**: Queries are slow
- Ensure indexes are created (see step 3)
- Analyze tables: `ANALYZE productmanagement_dbo.products;`
- Check query execution plans: `EXPLAIN ANALYZE SELECT ...`

## Migration from SQL Server (If Applicable)

If you're migrating data from an existing SQL Server database:

### 1. Export Data from SQL Server

```sql
-- SQL Server export scripts
SELECT * FROM dbo.Products;
SELECT * FROM dbo.ProductHistory;
SELECT * FROM dbo.ProductStats;
```

### 2. Transform and Import to PostgreSQL

Use tools like:
- AWS Database Migration Service (DMS)
- pgLoader
- Manual CSV export/import
- Custom migration scripts

### 3. Verify Data Integrity

After migration, verify:
- Row counts match
- Data types are correctly converted
- Foreign key relationships are maintained
- Indexes are created

## Backup and Restore

### Backup Database

```bash
# Full database backup
pg_dump -h localhost -U postgres ProductManagement > productmanagement_backup.sql

# Schema-only backup
pg_dump -h localhost -U postgres --schema=productmanagement_dbo --schema-only ProductManagement > schema_backup.sql

# Data-only backup
pg_dump -h localhost -U postgres --schema=productmanagement_dbo --data-only ProductManagement > data_backup.sql
```

### Restore Database

```bash
# Restore from backup
psql -h localhost -U postgres ProductManagement < productmanagement_backup.sql
```

## Production Deployment Checklist

- [ ] PostgreSQL server installed and configured
- [ ] Database and schema created
- [ ] Tables and indexes created
- [ ] Connection pooling configured
- [ ] Secure credentials management implemented
- [ ] Backup strategy established
- [ ] Monitoring and logging configured
- [ ] Performance baseline established
- [ ] Disaster recovery plan documented
- [ ] Security hardening completed (SSL, firewall, etc.)

## Additional Resources

- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)
- [Npgsql Documentation](https://www.npgsql.org/doc/)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)
- [PostgreSQL Security Best Practices](https://www.postgresql.org/docs/current/auth-pg-hba-conf.html)

## Support

For issues related to:
- **PostgreSQL**: Consult PostgreSQL documentation or community forums
- **Npgsql**: Visit [Npgsql GitHub](https://github.com/npgsql/npgsql)
- **Application**: Check application logs and error messages
