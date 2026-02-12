# PostgreSQL Database Setup Guide

This guide provides step-by-step instructions for setting up the PostgreSQL database for the AdoCore application.

## Prerequisites

Before proceeding, ensure you have:
- PostgreSQL 12 or later installed
- A PostgreSQL client tool (psql, pgAdmin, DBeaver, or Azure Data Studio)
- Appropriate permissions to create databases and tables

## Installation Options

### Option 1: PostgreSQL on Linux

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql postgresql-contrib

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Switch to postgres user
sudo -i -u postgres
psql
```

### Option 2: PostgreSQL on macOS

```bash
# Using Homebrew
brew install postgresql@15

# Start PostgreSQL service
brew services start postgresql@15

# Connect to PostgreSQL
psql postgres
```

### Option 3: PostgreSQL on Windows

1. Download PostgreSQL installer from https://www.postgresql.org/download/windows/
2. Run the installer and follow the installation wizard
3. Remember the password you set for the postgres user
4. Open SQL Shell (psql) or pgAdmin from the Start menu

### Option 4: Using Docker

```bash
# Run PostgreSQL in Docker
docker run --name postgres-adocore \
  -e POSTGRES_PASSWORD=your_password \
  -e POSTGRES_DB=ProductManagement \
  -p 5432:5432 \
  -d postgres:15

# Connect to the container
docker exec -it postgres-adocore psql -U postgres -d ProductManagement
```

## Database Setup Steps

### Step 1: Create Database

If the database doesn't exist, create it:

```bash
# Using psql command line
psql -U postgres -h localhost

# In psql, run:
CREATE DATABASE "ProductManagement";

# Connect to the database
\c ProductManagement

# Exit psql
\q
```

### Step 2: Run Database Setup Script

Navigate to the project directory and run the PostgreSQL setup script:

```bash
# Navigate to the sourceCode directory
cd /path/to/sourceCode

# Run the setup script
psql -U postgres -h localhost -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

**Expected Output:**
- Tables created: categories, suppliers, products, product_history, product_stats
- 20 sample categories inserted
- 8 sample suppliers inserted
- 18 sample products inserted
- Statistics initialized
- Trigger function and trigger created

### Step 3: Verify Database Setup

Connect to the database and verify the setup:

```bash
# Connect to PostgreSQL
psql -U postgres -h localhost -d ProductManagement

# List all tables
\dt

# Expected output:
#             List of relations
#  Schema |       Name        | Type  |  Owner
# --------+-------------------+-------+----------
#  public | categories        | table | postgres
#  public | product_history   | table | postgres
#  public | product_stats     | table | postgres
#  public | products          | table | postgres
#  public | suppliers         | table | postgres

# Check row counts
SELECT 'Categories' AS table_name, COUNT(*) AS row_count FROM categories
UNION ALL
SELECT 'Suppliers', COUNT(*) FROM suppliers
UNION ALL
SELECT 'Products', COUNT(*) FROM products;

# Expected output:
#  table_name  | row_count
# -------------+-----------
#  Categories  |        20
#  Suppliers   |         8
#  Products    |        18

# View sample products
SELECT product_id, name, price, stock_quantity FROM products LIMIT 5;

# Exit psql
\q
```

### Step 4: Configure Application Connection String

Update the connection string in `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=your_password;Pooling=true"
  },
  "Environment": "Development"
}
```

**Replace `your_password` with your actual PostgreSQL password.**

### Step 5: Test Connection from Application

Run the application to test the database connection:

```bash
# Navigate to sourceCode directory
cd /path/to/sourceCode

# Build the application
dotnet build

# Run the application (list products)
dotnet run -- list
```

If successful, you should see a list of products from the database.

## Database Schema Overview

### Tables

1. **categories**
   - category_id (SERIAL, PRIMARY KEY)
   - name (VARCHAR(50), NOT NULL)
   - description (VARCHAR(200))
   - parent_category_id (INTEGER, self-referencing FK)
   - created_date (TIMESTAMP)

2. **suppliers**
   - supplier_id (SERIAL, PRIMARY KEY)
   - name, contact_name, email, phone, address, country
   - is_active (BOOLEAN)
   - created_date (TIMESTAMP)

3. **products**
   - product_id (SERIAL, PRIMARY KEY)
   - name, description, price, stock_quantity
   - category_id (FK to categories)
   - supplier_id (FK to suppliers)
   - sku, weight, dimensions
   - is_discontinued (BOOLEAN)
   - reorder_level (INTEGER)
   - created_date, modified_date (TIMESTAMP)

4. **product_history**
   - history_id (SERIAL, PRIMARY KEY)
   - product_id (FK to products)
   - action (VARCHAR(10): INSERT, UPDATE, DELETE)
   - old_price, new_price, old_stock, new_stock
   - action_date (TIMESTAMP)
   - modified_by (VARCHAR(100))

5. **product_stats**
   - stat_id (INTEGER, PRIMARY KEY, always 1)
   - total_products, average_price, total_stock_value
   - low_stock_count, discontinued_count
   - last_updated (TIMESTAMP)

### Indexes

- ix_products_category_id
- ix_products_supplier_id
- ix_products_sku (UNIQUE, partial index)
- ix_product_history_product_id
- ix_product_history_action_date

### Triggers

- **trg_products_history**: Automatically logs changes to products table
  - INSERT: Records new product with new values
  - UPDATE: Records old and new values (only if price or stock changes)
  - DELETE: Records deleted product with old values

## Troubleshooting

### Issue: "psql: error: connection to server at 'localhost' failed"

**Solution:**
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql   # Linux
brew services list                  # macOS
# Windows: Check Services app for "PostgreSQL" service

# Start PostgreSQL if not running
sudo systemctl start postgresql     # Linux
brew services start postgresql@15   # macOS
# Windows: Start service from Services app
```

### Issue: "database 'ProductManagement' does not exist"

**Solution:**
```bash
# Connect to postgres database
psql -U postgres -h localhost

# Create the database
CREATE DATABASE "ProductManagement";

# Exit and reconnect
\q
psql -U postgres -h localhost -d ProductManagement
```

### Issue: "permission denied for table"

**Solution:**
```bash
# Grant all privileges to your user
psql -U postgres -h localhost -d ProductManagement

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_username;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO your_username;
```

### Issue: "role 'postgres' does not exist"

**Solution:**
```bash
# Create the postgres role
createuser -s postgres

# Or specify a different user in your connection string
```

### Issue: Application cannot connect to database

**Checklist:**
1. Verify PostgreSQL is running: `pg_isready`
2. Check connection string in appsettings.json
3. Verify username and password are correct
4. Check PostgreSQL is listening on port 5432: `netstat -an | grep 5432`
5. Check firewall allows connections to port 5432
6. Review PostgreSQL logs: 
   - Linux: `/var/log/postgresql/`
   - macOS: `/usr/local/var/log/`
   - Windows: `C:\Program Files\PostgreSQL\<version>\data\log\`

## Security Recommendations

### For Development

1. **Use strong passwords** even in development
2. **Limit network access**: Configure `pg_hba.conf` to only allow localhost connections
3. **Create application-specific user** (don't use postgres superuser):

```sql
-- Connect as postgres
psql -U postgres -h localhost

-- Create application user
CREATE USER adocore_app WITH PASSWORD 'secure_password_here';

-- Grant necessary privileges
GRANT CONNECT ON DATABASE "ProductManagement" TO adocore_app;
\c ProductManagement
GRANT USAGE ON SCHEMA public TO adocore_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO adocore_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO adocore_app;

-- Update connection string to use this user
-- Host=localhost;Port=5432;Database=ProductManagement;Username=adocore_app;Password=secure_password_here;Pooling=true
```

### For Production

1. **Never use default passwords**
2. **Use environment variables** for connection strings
3. **Enable SSL/TLS** for database connections
4. **Implement connection string encryption**
5. **Use managed database services** (AWS RDS, Azure Database, etc.)
6. **Enable audit logging**
7. **Regular backups** and backup testing
8. **Principle of least privilege** - grant only necessary permissions
9. **Network isolation** - use VPC/virtual networks
10. **Monitor database access** and set up alerts

## Production Connection String Example

```json
{
  "ConnectionStrings": {
    "ProdConnection": "Host=your-db-server.com;Port=5432;Database=ProductManagement;Username=adocore_app;Password=from_env_var;SSL Mode=Require;Trust Server Certificate=false;Pooling=true;Maximum Pool Size=100"
  }
}
```

**Better approach - Use environment variables:**

```bash
# Set environment variable
export ConnectionStrings__ProdConnection="Host=...;Port=5432;..."

# Or use AWS Secrets Manager, Azure Key Vault, etc.
```

## Backup and Restore

### Backup Database

```bash
# Full database backup
pg_dump -U postgres -h localhost ProductManagement > productmanagement_backup.sql

# With custom format (compressed)
pg_dump -U postgres -h localhost -Fc ProductManagement > productmanagement_backup.dump

# Backup specific table
pg_dump -U postgres -h localhost -t products ProductManagement > products_backup.sql
```

### Restore Database

```bash
# From SQL file
psql -U postgres -h localhost -d ProductManagement < productmanagement_backup.sql

# From custom format
pg_restore -U postgres -h localhost -d ProductManagement productmanagement_backup.dump
```

## Testing the Setup

Run these SQL queries to verify everything is working:

```sql
-- Test 1: Verify all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Test 2: Check data was inserted
SELECT 
    (SELECT COUNT(*) FROM categories) AS categories,
    (SELECT COUNT(*) FROM suppliers) AS suppliers,
    (SELECT COUNT(*) FROM products) AS products;

-- Test 3: Test the trigger (insert a product and check history)
INSERT INTO products (name, description, price, stock_quantity)
VALUES ('Test Product', 'Test Description', 99.99, 10);

SELECT * FROM product_history ORDER BY action_date DESC LIMIT 1;

-- Test 4: Test window functions (used in application)
SELECT 
    product_id,
    name,
    price,
    ROW_NUMBER() OVER (ORDER BY price DESC) AS price_rank
FROM products
LIMIT 5;

-- Test 5: Update product stats
UPDATE product_stats
SET 
    total_products = (SELECT COUNT(*) FROM products),
    average_price = (SELECT AVG(price) FROM products),
    total_stock_value = (SELECT SUM(price * stock_quantity) FROM products),
    last_updated = CURRENT_TIMESTAMP
WHERE stat_id = 1;

SELECT * FROM product_stats;
```

## Next Steps

After successful database setup:

1. Build and run the application: `dotnet run`
2. Test all CRUD operations
3. Verify transaction handling
4. Check application logs for any errors
5. Review and optimize queries if needed

## Additional Resources

- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Npgsql Documentation: https://www.npgsql.org/doc/
- psql Guide: https://www.postgresql.org/docs/current/app-psql.html
- pgAdmin Documentation: https://www.pgadmin.org/docs/

## Support

If you encounter issues not covered in this guide:
1. Check PostgreSQL logs
2. Verify application logs
3. Review error messages carefully
4. Consult PostgreSQL and Npgsql documentation
