# PostgreSQL Deployment Guide for AdoCore Application

## Overview
This guide provides step-by-step instructions for deploying the migrated AdoCore application with PostgreSQL database.

## Prerequisites
- PostgreSQL 12 or higher installed
- .NET 8.0 SDK installed
- Network access to PostgreSQL server
- Database administrator credentials

## Step 1: Install PostgreSQL

### On Ubuntu/Debian:
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### On macOS (using Homebrew):
```bash
brew install postgresql
brew services start postgresql
```

### On Windows:
Download and install PostgreSQL from: https://www.postgresql.org/download/windows/

## Step 2: Create Database and User

Connect to PostgreSQL as superuser:
```bash
sudo -u postgres psql
```

Create database and user:
```sql
-- Create database
CREATE DATABASE product_management;

-- Create user (replace 'your_password' with a secure password)
CREATE USER adocore_user WITH PASSWORD 'your_password';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE product_management TO adocore_user;

-- Connect to the database
\c product_management

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO adocore_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO adocore_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO adocore_user;

-- Exit psql
\q
```

## Step 3: Run Schema Migration Script

Navigate to the Database/Scripts directory and run the PostgreSQL setup script:

```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode

# Run the PostgreSQL schema script
psql -U adocore_user -d product_management -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

Verify the tables were created:
```bash
psql -U adocore_user -d product_management -c "\dt"
```

Expected output:
```
                List of relations
 Schema |       Name        | Type  |    Owner     
--------+-------------------+-------+--------------
 public | categories        | table | adocore_user
 public | product_history   | table | adocore_user
 public | product_stats     | table | adocore_user
 public | products          | table | adocore_user
 public | suppliers         | table | adocore_user
```

## Step 4: Update Connection Strings

Edit `appsettings.json` to include your PostgreSQL server details:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=product_management;Username=adocore_user;Password=your_password",
    "ProdConnection": "Host=your-production-host;Port=5432;Database=product_management;Username=adocore_user;Password=your_secure_password;SSL Mode=Require"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

### Connection String Parameters:
- **Host**: PostgreSQL server hostname or IP address
- **Port**: PostgreSQL port (default: 5432)
- **Database**: Database name (product_management)
- **Username**: Database user (adocore_user)
- **Password**: Database user password
- **SSL Mode**: Use "Require" for production (optional for development)

### Additional Connection Parameters (Optional):
```
Host=localhost;Port=5432;Database=product_management;Username=adocore_user;Password=your_password;
Pooling=true;Minimum Pool Size=0;Maximum Pool Size=100;Connection Lifetime=0;
Timeout=15;Command Timeout=30
```

## Step 5: Build the Application

```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode
dotnet build AdoCore.csproj
```

Expected output:
```
Build succeeded.
    0 Error(s)
    X Warning(s) (nullable reference warnings are expected)
```

## Step 6: Test Database Connection

Create a simple test program to verify database connectivity:

```bash
dotnet run --project AdoCore.csproj
```

Or test connection using psql:
```bash
psql -U adocore_user -d product_management -c "SELECT COUNT(*) FROM products;"
```

Expected output:
```
 count 
-------
    18
(1 row)
```

## Step 7: Verify Data Operations

Test the main operations:

### Test SELECT operations:
```sql
-- Get all products
SELECT product_id, name, price, stock_quantity FROM products LIMIT 5;

-- Test CTE with window functions (GetAllProductsAsync query)
WITH ProductStats AS (
    SELECT 
        p.ProductId,
        p.Name,
        p.Price,
        p.StockQuantity,
        AVG(p.Price) OVER (PARTITION BY p.CategoryId) as AvgCategoryPrice,
        COUNT(*) OVER (PARTITION BY p.CategoryId) as CategoryProductCount,
        CASE 
            WHEN p.StockQuantity <= p.ReorderLevel THEN 'Low'
            WHEN p.StockQuantity <= (p.ReorderLevel * 2) THEN 'Medium'
            ELSE 'High'
        END as StockStatus
    FROM Products p
)
SELECT * FROM ProductStats LIMIT 5;
```

### Test INSERT operation:
```sql
-- Insert a test product
INSERT INTO products (name, description, price, stock_quantity, reorder_level, created_date)
VALUES ('Test Product', 'Test Description', 99.99, 10, 5, NOW())
RETURNING product_id;
```

### Test UPDATE operation:
```sql
-- Update a product
UPDATE products 
SET price = 109.99, stock_quantity = 15, modified_date = NOW()
WHERE name = 'Test Product'
RETURNING product_id;
```

### Test DELETE operation:
```sql
-- Delete the test product
DELETE FROM products 
WHERE name = 'Test Product'
RETURNING product_id;
```

### Verify ProductHistory trigger:
```sql
-- Check that history was recorded
SELECT * FROM product_history ORDER BY action_date DESC LIMIT 5;
```

## Step 8: Run Application Tests

If you have unit tests or integration tests:

```bash
# Run all tests
dotnet test

# Run specific test category
dotnet test --filter Category=Integration
```

## Troubleshooting

### Connection Issues

**Error: password authentication failed for user "adocore_user"**
- Verify username and password in connection string
- Check PostgreSQL pg_hba.conf authentication settings
- Ensure user has correct permissions

**Error: connection refused**
- Verify PostgreSQL is running: `sudo systemctl status postgresql`
- Check PostgreSQL is listening on correct port: `sudo netstat -plnt | grep 5432`
- Verify firewall allows connections to port 5432

**Error: database "product_management" does not exist**
- Create database: `createdb -U postgres product_management`
- Run schema setup script

### Schema Issues

**Error: relation "products" does not exist**
- Run the schema setup script: `Database/Scripts/01_InitialSetup_PostgreSQL.sql`
- Verify you're connected to the correct database

**Error: permission denied for table**
- Grant permissions: `GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO adocore_user;`
- Grant sequence permissions: `GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO adocore_user;`

### Query Issues

**Error: column "productid" does not exist**
- PostgreSQL is case-sensitive with quoted identifiers
- The schema uses lowercase column names (product_id, not ProductId)
- Verify the C# code properly handles PostgreSQL naming conventions

**Window function errors**
- Verify PostgreSQL version is 12+ for full window function support
- Check query syntax matches PostgreSQL standards

### Performance Issues

**Slow query execution**
- Run ANALYZE to update statistics: `ANALYZE products;`
- Check query execution plan: `EXPLAIN ANALYZE SELECT ...`
- Verify indexes are created: `\d+ products`
- Consider adding additional indexes for frequently queried columns

## Validation Checklist

Use this checklist to verify the migration is complete:

- [ ] PostgreSQL installed and running
- [ ] Database created with correct name
- [ ] User created with appropriate permissions
- [ ] Schema script executed successfully
- [ ] All tables created (categories, suppliers, products, product_history, product_stats)
- [ ] All indexes created
- [ ] Trigger created and functioning
- [ ] Sample data inserted (18 products, 20 categories, 8 suppliers)
- [ ] Connection string updated in appsettings.json
- [ ] Application builds without errors
- [ ] Application connects to PostgreSQL successfully
- [ ] SELECT queries return expected results
- [ ] INSERT operations work correctly (including RETURNING clause)
- [ ] UPDATE operations work correctly
- [ ] DELETE operations work correctly
- [ ] Transactions maintain atomicity (rollback on error)
- [ ] ProductHistory trigger records all changes
- [ ] Window functions (AVG OVER, RANK, LAG) work correctly
- [ ] CTE queries execute successfully
- [ ] All 7 migrated SQL statements function correctly
- [ ] Unit tests pass (if available)
- [ ] Integration tests pass (if available)
- [ ] Performance is acceptable

## Key Differences from SQL Server

### Syntax Differences:
1. **IDENTITY vs SERIAL**: SQL Server IDENTITY(1,1) → PostgreSQL SERIAL
2. **GETDATE() vs NOW()**: SQL Server GETDATE() → PostgreSQL NOW()
3. **SCOPE_IDENTITY() vs RETURNING**: SQL Server SCOPE_IDENTITY() → PostgreSQL RETURNING clause
4. **BIT vs BOOLEAN**: SQL Server BIT → PostgreSQL BOOLEAN
5. **NVARCHAR vs VARCHAR**: SQL Server NVARCHAR → PostgreSQL VARCHAR (PostgreSQL stores all text as UTF-8)
6. **Square brackets vs lowercase**: SQL Server [TableName] → PostgreSQL tablename (lowercase)

### Transaction Handling:
- SQL Server: BEGIN TRANSACTION, COMMIT, ROLLBACK in SQL
- PostgreSQL: Application-level transactions using NpgsqlConnection.BeginTransactionAsync()

### System Functions:
- SQL Server: SYSTEM_USER → PostgreSQL: current_user
- SQL Server: @@IDENTITY → PostgreSQL: RETURNING clause or currval()

### Triggers:
- SQL Server: Uses inserted/deleted virtual tables
- PostgreSQL: Uses NEW/OLD records and trigger functions

## Production Deployment Considerations

### Security:
1. Use SSL/TLS connections in production (`SSL Mode=Require`)
2. Store passwords in secure configuration (Azure Key Vault, AWS Secrets Manager, environment variables)
3. Use separate database users for different environments
4. Implement least-privilege access control
5. Enable PostgreSQL SSL: Edit postgresql.conf and set `ssl = on`

### Performance:
1. Configure connection pooling in connection string
2. Set appropriate connection pool size based on workload
3. Configure PostgreSQL shared_buffers and work_mem
4. Monitor query performance with pg_stat_statements
5. Set up regular VACUUM and ANALYZE jobs

### Monitoring:
1. Enable PostgreSQL logging: Edit postgresql.conf
2. Monitor connection count: `SELECT count(*) FROM pg_stat_activity;`
3. Monitor slow queries: `SELECT * FROM pg_stat_statements ORDER BY mean_time DESC;`
4. Set up alerts for connection limits, disk space, and performance

### Backup:
1. Schedule regular backups using pg_dump
2. Test backup restoration procedure
3. Consider point-in-time recovery (PITR) setup
4. Store backups in secure, off-site location

### High Availability:
1. Consider PostgreSQL replication for failover
2. Set up read replicas for load distribution
3. Implement connection retry logic in application
4. Use connection pooling (PgBouncer) for better resource management

## Next Steps

After completing deployment:

1. **Performance Baseline**: Establish performance baselines for all queries
2. **Manual SQL Equivalency Validation**: Review the 7 migrated SQL statements for functional equivalence
3. **Edge Case Testing**: Test NULL handling, division by zero, empty result sets
4. **Stress Testing**: Test with production-level data volumes
5. **Monitoring Setup**: Implement application and database monitoring
6. **Documentation**: Update application documentation with PostgreSQL specifics
7. **Training**: Train team members on PostgreSQL differences and troubleshooting

## Additional Resources

- PostgreSQL Official Documentation: https://www.postgresql.org/docs/
- Npgsql Documentation: https://www.npgsql.org/doc/
- PostgreSQL Performance Tuning: https://wiki.postgresql.org/wiki/Performance_Optimization
- SQL Server to PostgreSQL Migration Guide: https://wiki.postgresql.org/wiki/Converting_from_other_Databases_to_PostgreSQL

## Support

For issues specific to this migration:
- Review migration report: `final_migration_report.json`
- Check SQL equivalency report: `sql_equivalency_validation_report.json`
- Review DMS conversion log: `dms_conversion_failures.log`
- Check code changes log: `code_changes.log`
