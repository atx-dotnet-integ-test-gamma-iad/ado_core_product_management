# PostgreSQL Database Setup Guide

## Prerequisites
- PostgreSQL 12 or later installed
- Access to PostgreSQL server with superuser or database creation privileges
- Network connectivity to PostgreSQL server
- psql command-line tool or pgAdmin for executing scripts

## Environment Setup Steps

### 1. Install PostgreSQL (if not already installed)

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**macOS (using Homebrew):**
```bash
brew install postgresql@14
brew services start postgresql@14
```

**Windows:**
Download and install from: https://www.postgresql.org/download/windows/

**Docker (Quick Setup):**
```bash
docker run --name postgres-productmanagement \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_USER=postgres \
  -p 5432:5432 \
  -d postgres:14
```

### 2. Create Database and User

Connect to PostgreSQL as superuser:
```bash
psql -U postgres
```

Execute the following commands:
```sql
-- Create database
CREATE DATABASE "ProductManagement";

-- Create application user (recommended for production)
CREATE USER productapp WITH PASSWORD 'your_secure_password_here';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE "ProductManagement" TO productapp;

-- Connect to the database
\c ProductManagement

-- Grant schema privileges
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO productapp;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO productapp;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO productapp;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO productapp;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO productapp;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO productapp;
```

### 3. Execute Schema Setup Script

Execute the PostgreSQL schema script:

**Using psql:**
```bash
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

**Using pgAdmin:**
1. Open pgAdmin
2. Connect to your PostgreSQL server
3. Right-click on ProductManagement database
4. Select "Query Tool"
5. Open and execute `Database/Scripts/01_InitialSetup_PostgreSQL.sql`

### 4. Verify Database Setup

Connect to the database and verify:
```bash
psql -U postgres -d ProductManagement
```

Run verification queries:
```sql
-- Check tables
\dt

-- Verify sample data
SELECT COUNT(*) FROM Products;
SELECT COUNT(*) FROM Categories;
SELECT COUNT(*) FROM Suppliers;

-- Verify functions
\df

-- Test a simple query
SELECT * FROM Products LIMIT 5;
```

Expected results:
- 5 tables: Categories, Suppliers, Products, ProductHistory, ProductStats
- 18 products
- 20 categories
- 8 suppliers
- Multiple functions (sp_GetAllProducts, sp_GetProductById, etc.)

### 5. Update Application Connection String

Edit `appsettings.json` with your PostgreSQL connection details:

**Development (localhost):**
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=productapp;Password=your_secure_password;Include Error Detail=true;Pooling=true;Timeout=30"
  }
}
```

**Production:**
```json
{
  "ConnectionStrings": {
    "ProdConnection": "Host=your-postgres-server;Port=5432;Database=ProductManagement;Username=productapp;Password=your_secure_password;Pooling=true;Timeout=30;SSL Mode=Require"
  }
}
```

**Environment Variables (Recommended for Production):**
```bash
export ConnectionStrings__DevConnection="Host=localhost;Port=5432;Database=ProductManagement;Username=productapp;Password=your_password;Pooling=true;Timeout=30"
```

### 6. Test Application Connectivity

Run the application:
```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode
dotnet run
```

The application should:
1. Successfully connect to PostgreSQL database
2. Display the interactive menu
3. Allow you to perform CRUD operations

### 7. Verify Database Operations

Test each operation from the application menu:
- **Option 1:** Get All Products - Should display 18 products
- **Option 2:** Get Product By ID - Test with ID 1-18
- **Option 3:** Insert Product - Create a new product and verify
- **Option 4:** Update Product - Modify an existing product
- **Option 5:** Delete Product - Remove a product
- **Option 6:** Get Products by Price Range - Test filtering
- **Option 7:** Get Low Stock Products - Test with threshold

### 8. Verify Transaction Atomicity

Test transaction operations:

1. **Insert Transaction Test:**
   - Insert a new product
   - Check ProductHistory for INSERT record
   - Check ProductStats for updated counts

2. **Update Transaction Test:**
   - Update a product's price or stock
   - Check ProductHistory for UPDATE record
   - Verify ProductStats reflects changes

3. **Delete Transaction Test:**
   - Delete a product
   - Check ProductHistory for DELETE record
   - Verify ProductStats updated correctly

**SQL verification queries:**
```sql
-- Check transaction history
SELECT * FROM ProductHistory ORDER BY ActionDate DESC LIMIT 10;

-- Check product statistics
SELECT * FROM ProductStats;

-- Verify data integrity
SELECT 
    (SELECT COUNT(*) FROM Products) as actual_count,
    TotalProducts as stats_count
FROM ProductStats;
```

## Security Best Practices

### For Production Deployment:

1. **Never use default passwords:**
   ```sql
   ALTER USER productapp WITH PASSWORD 'strong_random_password_here';
   ```

2. **Create dedicated application user with minimal privileges:**
   ```sql
   CREATE USER readonly_user WITH PASSWORD 'password';
   GRANT CONNECT ON DATABASE "ProductManagement" TO readonly_user;
   GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;
   ```

3. **Enable SSL connections:**
   - Configure PostgreSQL to require SSL (pg_hba.conf)
   - Update connection string: `SSL Mode=Require`

4. **Use environment variables for credentials:**
   - Never commit connection strings with passwords to source control
   - Use Azure Key Vault, AWS Secrets Manager, or similar

5. **Configure pg_hba.conf for network security:**
   ```
   # Only allow connections from specific IPs
   host    ProductManagement    productapp    192.168.1.0/24    md5
   ```

6. **Enable connection pooling:**
   - Already configured in connection strings
   - Monitor pool usage in production

7. **Regular backups:**
   ```bash
   pg_dump -U postgres ProductManagement > backup_$(date +%Y%m%d).sql
   ```

## Troubleshooting

### Connection Issues:

**Error: "password authentication failed"**
- Check username and password in connection string
- Verify user exists: `\du` in psql
- Check pg_hba.conf authentication method

**Error: "could not connect to server"**
- Verify PostgreSQL service is running: `systemctl status postgresql`
- Check port 5432 is not blocked by firewall
- Verify Host parameter in connection string

**Error: "database does not exist"**
- Create database: `CREATE DATABASE "ProductManagement";`
- Check database name matches connection string exactly

### Runtime Errors:

**Error: "relation does not exist"**
- Execute schema setup script: `01_InitialSetup_PostgreSQL.sql`
- Verify tables exist: `\dt` in psql

**Error: "function does not exist"**
- Verify functions created: `\df` in psql
- Re-run function creation section of schema script

**Permission Errors:**
- Grant necessary privileges to application user
- Check current privileges: `\dp` in psql

## Network Configuration

### Docker PostgreSQL Access:

If using Docker, allow external connections:
```bash
docker run --name postgres-productmanagement \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_USER=postgres \
  -p 5432:5432 \
  -v postgres-data:/var/lib/postgresql/data \
  -d postgres:14
```

### Remote PostgreSQL Access:

Edit `postgresql.conf`:
```
listen_addresses = '*'  # or specific IP
```

Edit `pg_hba.conf`:
```
host    all    all    0.0.0.0/0    md5  # Allow all (not recommended for production)
host    ProductManagement    productapp    your_app_ip/32    md5  # Recommended
```

Restart PostgreSQL:
```bash
sudo systemctl restart postgresql
```

## Performance Tuning (Optional)

For better performance with this application:

```sql
-- Analyze tables for query optimization
ANALYZE Products;
ANALYZE ProductHistory;
ANALYZE Categories;
ANALYZE Suppliers;

-- Verify indexes are being used
EXPLAIN ANALYZE SELECT * FROM Products WHERE ProductId = 1;
```

## Next Steps After Setup

1. Run application and test all CRUD operations
2. Verify transaction atomicity
3. Check ProductHistory audit trail
4. Monitor ProductStats accuracy
5. Test concurrent operations
6. Implement application-level tests (currently not present)
7. Configure monitoring and logging
8. Set up regular database backups

## Summary

Once these steps are complete:
- ✅ PostgreSQL database is running
- ✅ ProductManagement database exists with complete schema
- ✅ Sample data is loaded
- ✅ Application can connect successfully
- ✅ All CRUD operations work correctly
- ✅ Transactions maintain atomicity
- ✅ Audit trail (ProductHistory) is functioning

The migration from SQL Server to PostgreSQL will be complete and functional.
