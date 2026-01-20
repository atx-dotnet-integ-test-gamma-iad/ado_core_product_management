# Next Steps Guide
## Post-Migration Runtime Testing and Deployment

**Date:** 2026-01-20  
**Application:** ProductManagement ADO .NET Core Application  
**Current Status:** Code migration complete, ready for runtime testing

---

## Overview

This guide provides step-by-step instructions for setting up PostgreSQL, migrating data, testing the application, and preparing for production deployment after the code-level migration is complete.

---

## Phase 1: PostgreSQL Database Setup

### Step 1: Install PostgreSQL

#### Option A: Local Installation (Development/Testing)

**Windows:**
```powershell
# Download and install PostgreSQL from https://www.postgresql.org/download/windows/
# Or use Chocolatey
choco install postgresql

# Start PostgreSQL service
net start postgresql-x64-15
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**macOS:**
```bash
brew install postgresql
brew services start postgresql
```

#### Option B: Docker Container (Recommended for Testing)
```bash
docker run --name postgres-productmanagement \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=ProductManagement \
  -p 5432:5432 \
  -d postgres:15

# Verify container is running
docker ps | grep postgres-productmanagement
```

#### Option C: Cloud PostgreSQL (AWS RDS, Azure Database, Google Cloud SQL)
- Create managed PostgreSQL instance through cloud provider console
- Note the connection details (host, port, database name, username, password)
- Configure security groups/firewall rules to allow application access

### Step 2: Verify PostgreSQL Installation
```bash
# Test PostgreSQL is running and accessible
psql -h localhost -U postgres -d postgres -c "SELECT version();"

# Expected output: PostgreSQL version information
```

---

## Phase 2: Database Schema Creation

### Step 1: Create Database
```bash
psql -h localhost -U postgres
```

```sql
-- Create database if not exists
CREATE DATABASE ProductManagement;

-- Connect to the database
\c ProductManagement

-- Verify connection
SELECT current_database();
```

### Step 2: Run Schema Creation Script
```bash
cd /path/to/sourceCode
psql -h localhost -U postgres -d ProductManagement -f Database/Scripts/PostgreSQL_Schema.sql
```

**Script Creates:**
- `Products` table with SERIAL primary key
- `ProductHistory` table with foreign key
- `ProductStats` table for statistics
- Indexes for performance
- Initial ProductStats row

### Step 3: Verify Schema
```sql
-- List all tables
\dt

-- Describe Products table
\d Products

-- Describe ProductHistory table
\d ProductHistory

-- Describe ProductStats table
\d ProductStats

-- Verify ProductStats initialization
SELECT * FROM ProductStats;
```

---

## Phase 3: Test Data Creation

### Option A: Manual Test Data Insertion
```sql
-- Insert sample products
INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate) VALUES
('Laptop', 'High-performance laptop', 1200.00, 50, CURRENT_TIMESTAMP),
('Mouse', 'Wireless mouse', 25.99, 200, CURRENT_TIMESTAMP),
('Keyboard', 'Mechanical keyboard', 89.99, 150, CURRENT_TIMESTAMP),
('Monitor', '27-inch 4K monitor', 399.99, 75, CURRENT_TIMESTAMP),
('Headphones', 'Noise-cancelling headphones', 199.99, 100, CURRENT_TIMESTAMP);

-- Update ProductStats
UPDATE ProductStats SET 
    TotalProducts = 5,
    AveragePrice = (1200.00 + 25.99 + 89.99 + 399.99 + 199.99) / 5,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- Verify data
SELECT * FROM Products;
SELECT * FROM ProductStats;
```

### Option B: Data Migration from SQL Server

**Using pg_dump and psql:**
1. Export data from SQL Server to SQL format
2. Transform data types and syntax for PostgreSQL compatibility
3. Import using psql

**Using ETL Tools:**
- AWS Database Migration Service (DMS)
- Azure Data Factory
- Custom C# migration utility

**Sample C# Data Migration Utility:**
```csharp
// Connect to both databases
var sqlServerConn = new SqlConnection(sqlServerConnectionString);
var postgresConn = new NpgsqlConnection(postgresConnectionString);

// Read from SQL Server
var products = await sqlServerConn.QueryAsync<Product>("SELECT * FROM Products");

// Insert into PostgreSQL
foreach (var product in products)
{
    await postgresConn.ExecuteAsync(
        "INSERT INTO Products (ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate) VALUES (@ProductId, @Name, @Description, @Price, @StockQuantity, @CreatedDate, @ModifiedDate)",
        product);
}
```

---

## Phase 4: Application Runtime Testing

### Test 1: Connection Test
```bash
cd /path/to/sourceCode
dotnet run
```

**Expected:** Application starts without connection errors

### Test 2: GetAllProductsAsync (Statement 1)
**Test SQL:**
```sql
-- Verify CTE with window functions
WITH ProductStats AS (
    SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT p.*, 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice)::numeric * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId;
```

**Application Test:**
```csharp
var products = await productService.GetAllProductsAsync();
Assert.NotEmpty(products);
Console.WriteLine($"Retrieved {products.Count} products");
```

### Test 3: GetProductByIdAsync (Statement 2)
**Test SQL:**
```sql
-- Test with existing product ID
SELECT * FROM Products WHERE ProductId = 1;
```

**Application Test:**
```csharp
var product = await productService.GetProductAsync(1);
Assert.NotNull(product);
Console.WriteLine($"Product: {product.Name}, Price: {product.Price}");
```

### Test 4: InsertProductAsync (Statement 3) - CRITICAL TRANSACTION TEST
**Application Test:**
```csharp
var newProduct = new Product
{
    Name = "Test Product",
    Description = "Test Description",
    Price = 99.99m,
    StockQuantity = 10
};

int newId = await productService.CreateProductAsync(newProduct);
Assert.True(newId > 0);

// Verify product was inserted
var inserted = await productService.GetProductAsync(newId);
Assert.NotNull(inserted);
Assert.Equal("Test Product", inserted.Name);

// Verify ProductHistory was created
// SELECT * FROM ProductHistory WHERE ProductId = newId AND Action = 'INSERT'

// Verify ProductStats was updated
// SELECT * FROM ProductStats WHERE StatId = 1
```

### Test 5: UpdateProductAsync (Statement 4) - CRITICAL TRANSACTION TEST
**Application Test:**
```csharp
var product = await productService.GetProductAsync(1);
var originalPrice = product.Price;
var originalStock = product.StockQuantity;

product.Price = 999.99m;
product.StockQuantity = 75;
await productService.UpdateProductAsync(product);

// Verify product was updated
var updated = await productService.GetProductAsync(1);
Assert.Equal(999.99m, updated.Price);
Assert.Equal(75, updated.StockQuantity);

// Verify ProductHistory was created
// SELECT * FROM ProductHistory WHERE ProductId = 1 AND Action = 'UPDATE'
// Verify OldPrice and OldStock match original values

// Verify ProductStats was updated correctly
```

### Test 6: DeleteProductAsync (Statement 5) - CRITICAL TRANSACTION TEST
**Application Test:**
```csharp
// Insert a test product first
var testProduct = new Product
{
    Name = "Delete Test",
    Description = "Will be deleted",
    Price = 50.00m,
    StockQuantity = 5
};
int testId = await productService.CreateProductAsync(testProduct);

// Delete the product
await productService.DeleteProductAsync(testId);

// Verify product was deleted
var deleted = await productService.GetProductAsync(testId);
Assert.Null(deleted);

// Verify ProductHistory was created
// SELECT * FROM ProductHistory WHERE ProductId = testId AND Action = 'DELETE'

// Verify ProductStats was updated
```

### Test 7: GetProductsByPriceRangeAsync (Statement 6)
**Test SQL:**
```sql
SELECT * FROM Products WHERE Price BETWEEN 50.00 AND 500.00;
```

**Application Test:**
```csharp
var products = await repository.GetProductsByPriceRangeAsync(50.00m, 500.00m);
Assert.NotEmpty(products);
foreach (var p in products)
{
    Assert.True(p.Price >= 50.00m && p.Price <= 500.00m);
}
```

### Test 8: GetLowStockProductsAsync (Statement 7)
**Test SQL:**
```sql
WITH StockAnalysis AS (
    SELECT p.*, 
        AVG(StockQuantity) OVER() as AvgStock
    FROM Products p
)
SELECT * FROM StockAnalysis WHERE StockQuantity <= 25;
```

**Application Test:**
```csharp
var lowStockProducts = await repository.GetLowStockProductsAsync(25);
Assert.NotEmpty(lowStockProducts);
foreach (var p in lowStockProducts)
{
    Assert.True(p.StockQuantity <= 25);
}
```

### Test 9: Transaction Rollback Test
**Application Test:**
```csharp
try
{
    await productService.CreateProductAsync(new Product
    {
        Name = null, // This should cause validation error
        Price = 100m,
        StockQuantity = 10
    });
    Assert.Fail("Should have thrown validation exception");
}
catch (ArgumentException)
{
    // Expected - verify no partial data was inserted
    // Verify ProductHistory and ProductStats were not affected
}
```

---

## Phase 5: Performance Testing

### Test 1: Query Performance Comparison
```sql
-- Enable query timing
\timing on

-- Test Statement 1 performance
EXPLAIN ANALYZE
WITH ProductStats AS (
    SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT * FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId;

-- Compare execution time with SQL Server baseline
```

### Test 2: Connection Pool Testing
```csharp
// Configure connection pooling
var connectionString = "Host=localhost;...;Minimum Pool Size=5;Maximum Pool Size=50;";

// Simulate concurrent requests
var tasks = Enumerable.Range(0, 100).Select(async i => 
{
    return await productService.GetAllProductsAsync();
});

await Task.WhenAll(tasks);
```

### Test 3: Transaction Performance
- Measure INSERT/UPDATE/DELETE operation times
- Compare with SQL Server baseline
- Identify bottlenecks

---

## Phase 6: Production Deployment Checklist

### Security
- [ ] Replace placeholder password in appsettings.json with actual credentials
- [ ] Implement secrets management (AWS Secrets Manager, Azure Key Vault, Environment Variables)
- [ ] Configure SSL/TLS for database connections (`SSL Mode=Require`)
- [ ] Set up database user with least-privilege access
- [ ] Disable `Include Error Detail` in production connection string
- [ ] Review and harden `pg_hba.conf` authentication rules
- [ ] Enable PostgreSQL audit logging

### Database Configuration
- [ ] Configure appropriate `max_connections`
- [ ] Set `shared_buffers` and `effective_cache_size`
- [ ] Configure WAL archiving and point-in-time recovery
- [ ] Set up automated backups (pg_dump, pg_basebackup, or cloud provider backups)
- [ ] Configure replication for high availability
- [ ] Set up monitoring (pg_stat_statements, pgBadger, cloud monitoring)

### Application Configuration
- [ ] Update `appsettings.Production.json` with production connection string
- [ ] Configure appropriate connection pool settings
- [ ] Set up application logging and monitoring
- [ ] Configure health checks
- [ ] Set up error tracking (Sentry, Application Insights, etc.)

### Testing
- [ ] Complete all Phase 4 runtime tests successfully
- [ ] Perform load testing with production-like data volumes
- [ ] Test failover scenarios
- [ ] Verify backup and restore procedures
- [ ] Test rollback procedures

### Documentation
- [ ] Update operations runbooks
- [ ] Document PostgreSQL administration procedures
- [ ] Create incident response procedures
- [ ] Train support team on PostgreSQL troubleshooting

### Deployment
- [ ] Deploy to staging environment first
- [ ] Perform smoke tests in staging
- [ ] Schedule production deployment window
- [ ] Prepare rollback plan
- [ ] Execute production deployment
- [ ] Monitor application and database metrics closely
- [ ] Verify all functionality post-deployment

---

## Phase 7: Monitoring and Optimization

### Database Monitoring
```sql
-- Monitor active queries
SELECT pid, usename, application_name, client_addr, state, query
FROM pg_stat_activity
WHERE datname = 'ProductManagement';

-- Monitor table statistics
SELECT schemaname, tablename, seq_scan, idx_scan, n_tup_ins, n_tup_upd, n_tup_del
FROM pg_stat_user_tables;

-- Check for missing indexes
SELECT schemaname, tablename, attname, n_distinct, correlation
FROM pg_stats
WHERE schemaname = 'public'
ORDER BY abs(correlation) DESC;
```

### Application Monitoring
- Monitor connection pool utilization
- Track query execution times
- Monitor error rates
- Set up alerts for anomalies

### Optimization Opportunities
1. Add indexes based on query patterns
2. Tune PostgreSQL configuration parameters
3. Optimize slow queries using EXPLAIN ANALYZE
4. Consider partitioning for large tables
5. Implement caching layer (Redis, Memcached)

---

## Rollback Procedures

### If Issues Are Discovered Post-Deployment

#### Quick Rollback (Application Level)
1. Stop the application
2. Restore backup files from `/Backups/`
   - Copy `ProductRepository_SQL_Server.cs` back to `ProductRepository.cs`
   - Copy `appsettings_sqlserver.json` back to `appsettings.json`
3. Update `AdoCore.csproj`:
   ```xml
   <PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />
   ```
4. Run `dotnet restore`
5. Run `dotnet build`
6. Start the application (now connected to SQL Server)

#### Data Rollback (If Data Was Migrated)
1. Stop all application instances
2. Restore SQL Server database from backup
3. Verify data integrity
4. Restart application with SQL Server configuration

---

## Troubleshooting Common Issues

### Issue: Connection Timeout
**Solution:**
- Increase `Timeout` in connection string
- Check firewall rules
- Verify PostgreSQL is listening on correct interface

### Issue: Parameter Type Mismatch
**Solution:**
- Review parameter types in C# code
- Ensure proper type casting in SQL statements
- Check for implicit conversions

### Issue: Transaction Deadlock
**Solution:**
- Review transaction isolation levels
- Optimize query execution order
- Implement retry logic with exponential backoff

### Issue: Slow Query Performance
**Solution:**
- Run `EXPLAIN ANALYZE` on slow queries
- Add appropriate indexes
- Consider query rewriting
- Review PostgreSQL configuration

---

## Support Resources

- **PostgreSQL Documentation:** https://www.postgresql.org/docs/
- **Npgsql Documentation:** https://www.npgsql.org/doc/
- **PostgreSQL Wiki:** https://wiki.postgresql.org/
- **Community Support:** PostgreSQL mailing lists, Stack Overflow
- **Professional Support:** Consider PostgreSQL support subscription

---

## Conclusion

Following this guide will ensure a smooth transition from code migration to production deployment. Take time to thoroughly test each phase before proceeding to the next.

**Remember:** The code migration is complete, but thorough runtime testing is CRITICAL before production deployment.

---

**Guide Version:** 1.0  
**Last Updated:** 2026-01-20  
**Status:** Ready for Phase 1 - PostgreSQL Setup
