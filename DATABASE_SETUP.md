# PostgreSQL Database Setup Guide

## Overview
This guide provides step-by-step instructions for setting up the PostgreSQL database required to complete the migration validation and run the AdoCore application.

## Prerequisites
- PostgreSQL 12 or later installed
- Administrative access to PostgreSQL server
- Network connectivity to PostgreSQL server

## Installation

### Linux (Ubuntu/Debian)
```bash
# Update package list
sudo apt update

# Install PostgreSQL
sudo apt install postgresql postgresql-contrib

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### macOS
```bash
# Using Homebrew
brew install postgresql@14

# Start PostgreSQL service
brew services start postgresql@14
```

### Windows
1. Download PostgreSQL installer from https://www.postgresql.org/download/windows/
2. Run the installer and follow the setup wizard
3. Remember the password you set for the postgres user
4. Ensure PostgreSQL service is started

## Database Setup

### Step 1: Connect to PostgreSQL
```bash
# Connect as postgres user
sudo -u postgres psql

# Or on Windows/macOS with default user
psql -U postgres
```

### Step 2: Create Database
```sql
-- Create the ProductManagement database
CREATE DATABASE "ProductManagement"
    WITH 
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Connect to the new database
\c ProductManagement
```

### Step 3: Create Application User
```sql
-- Create a dedicated application user
CREATE USER app_user WITH PASSWORD 'secure_password_here';

-- Grant database connection
GRANT CONNECT ON DATABASE "ProductManagement" TO app_user;

-- Grant schema usage
GRANT USAGE ON SCHEMA public TO app_user;

-- Grant table permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;

-- Grant sequence permissions (for auto-increment/identity columns)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public 
    GRANT USAGE, SELECT ON SEQUENCES TO app_user;
```

### Step 4: Create Schema (Required for Application)

The application expects the following table structure. You need to migrate the schema from SQL Server to PostgreSQL.

**Example Product Table (adjust based on your actual SQL Server schema):**

```sql
-- Create Products table
CREATE TABLE IF NOT EXISTS Products (
    ProductId SERIAL PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Price DECIMAL(18,2),
    Category VARCHAR(100),
    StockQuantity INTEGER,
    CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ModifiedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on commonly queried columns
CREATE INDEX idx_products_category ON Products(Category);
CREATE INDEX idx_products_name ON Products(Name);

-- Grant permissions to app user
GRANT SELECT, INSERT, UPDATE, DELETE ON Products TO app_user;
GRANT USAGE, SELECT ON SEQUENCE products_productid_seq TO app_user;
```

**IMPORTANT**: The exact schema structure should be migrated from your SQL Server database. Use tools like:
- `pg_dump` and `pg_restore` for schema migration
- AWS Database Migration Service (DMS) for automated schema conversion
- Manual DDL conversion from SQL Server to PostgreSQL syntax

### Step 5: Verify Setup
```sql
-- List databases
\l

-- List tables in current database
\dt

-- Verify user permissions
\dp Products

-- Test basic operations
INSERT INTO Products (Name, Price, Category, StockQuantity) 
VALUES ('Test Product', 19.99, 'Test', 100);

SELECT * FROM Products;

-- Clean up test data
DELETE FROM Products WHERE Name = 'Test Product';
```

## Configure Application Connection

### Option 1: Environment Variables
```bash
# Set environment variables
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=ProductManagement
export DB_USERNAME=app_user
export DB_PASSWORD=secure_password_here

# Run application
dotnet run
```

### Option 2: Update appsettings.json (Development Only)
**WARNING**: Never commit actual credentials to version control!

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=app_user;Password=secure_password_here;Pooling=true"
  }
}
```

## Testing Database Connection

### Using psql
```bash
psql -h localhost -p 5432 -U app_user -d ProductManagement -c "SELECT version();"
```

### Using .NET Application
```bash
# Build and run the application
cd /path/to/AdoCore
dotnet build
dotnet run
```

## Validation Steps

After setting up the database, verify the following exit criteria:

### 1. Database Connection (Criterion 12)
```bash
# Test connection from application
dotnet run

# Expected: Application starts without connection errors
```

### 2. Database Operations (Criterion 13)
Test all CRUD operations:
- Create: Insert new products
- Read: Query products with various filters
- Update: Modify existing products
- Delete: Remove products

### 3. Transaction Atomicity (Criterion 14)
Test that transactions rollback correctly on errors:
```sql
BEGIN;
INSERT INTO Products (Name, Price) VALUES ('Test1', 10.00);
INSERT INTO Products (Name, Price) VALUES (NULL, 20.00); -- Should fail
ROLLBACK;
-- Verify Test1 was not inserted
SELECT * FROM Products WHERE Name = 'Test1';
```

### 4. Run Tests (Criterion 15)
```bash
# Run unit and integration tests
dotnet test

# Expected: All tests pass
```

## Troubleshooting

### Connection Refused
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Check PostgreSQL is listening on correct port
sudo netstat -plnt | grep 5432

# Check pg_hba.conf for connection permissions
sudo nano /etc/postgresql/14/main/pg_hba.conf
```

### Authentication Failed
- Verify username and password are correct
- Check pg_hba.conf authentication method (should be `md5` or `scram-sha-256`)
- Reload PostgreSQL configuration: `sudo systemctl reload postgresql`

### Database Does Not Exist
```bash
# List all databases
psql -U postgres -l

# Create database if missing
psql -U postgres -c "CREATE DATABASE ProductManagement;"
```

### Permission Denied
```sql
-- Reconnect as postgres user and grant permissions
psql -U postgres -d ProductManagement

GRANT ALL PRIVILEGES ON DATABASE "ProductManagement" TO app_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_user;
```

## Security Best Practices

1. **Use Strong Passwords**: Generate random, complex passwords for database users
2. **Limit Permissions**: Grant only necessary permissions (SELECT, INSERT, UPDATE, DELETE)
3. **Use SSL/TLS**: Enable SSL for production connections
4. **Network Security**: Restrict access to PostgreSQL port (5432) via firewall
5. **Regular Backups**: Implement automated backup strategy
6. **Monitor Access**: Review PostgreSQL logs regularly

## Next Steps

After completing database setup:

1. ✅ Verify application connects successfully (Criterion 12)
2. ✅ Execute all database operations (Criterion 13)
3. ✅ Test transaction behavior (Criterion 14)
4. ✅ Run comprehensive test suite (Criterion 15)
5. Document any SQL statement equivalency issues discovered during testing
6. Performance tune PostgreSQL configuration as needed
7. Implement monitoring and alerting for production environment

## Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)
- [Npgsql Connection Strings](https://www.npgsql.org/doc/connection-string-parameters.html)
- [PostgreSQL Security Best Practices](https://www.postgresql.org/docs/current/security.html)
