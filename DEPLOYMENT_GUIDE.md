# PostgreSQL Migration Deployment Guide

## Overview
This guide provides step-by-step instructions for deploying and testing the migrated ADO.NET application with PostgreSQL.

## Prerequisites
- PostgreSQL 12 or higher installed
- .NET 6.0 or higher SDK installed
- Access to PostgreSQL server with appropriate privileges

## Deployment Steps

### 1. PostgreSQL Database Setup

#### Option A: Using PostgreSQL Command Line (psql)
```bash
# Connect to PostgreSQL as superuser
psql -U postgres

# Create the database
CREATE DATABASE ProductManagement;

# Connect to the new database
\c ProductManagement

# Run the setup script
\i /path/to/Database/Scripts/01_InitialSetup_PostgreSQL.sql

# Verify tables were created
\dt

# Exit psql
\q
```

#### Option B: Using pgAdmin
1. Open pgAdmin and connect to your PostgreSQL server
2. Right-click on "Databases" and select "Create" > "Database"
3. Name it "ProductManagement" and click "Save"
4. Right-click on the new database and select "Query Tool"
5. Open the file `Database/Scripts/01_InitialSetup_PostgreSQL.sql`
6. Execute the script (F5 or click Execute button)
7. Verify all tables, indexes, and functions were created successfully

### 2. Update Connection String

Edit `appsettings.json` to match your PostgreSQL configuration:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=ProductManagement;Username=your_username;Password=your_password;Port=5432",
    "ProdConnection": "Host=your_production_host;Database=ProductManagement;Username=your_username;Password=your_password;Port=5432"
  },
  "Environment": "Development"
}
```

**Important**: Replace the placeholder credentials:
- `your_username`: Your PostgreSQL username (e.g., `postgres`)
- `your_password`: Your PostgreSQL password
- `localhost`: Your PostgreSQL server hostname (use actual hostname for production)

### 3. Build the Application

```bash
# Navigate to the project directory
cd /path/to/sourceCode

# Restore dependencies
dotnet restore

# Build the project
dotnet build

# Expected output: "Build succeeded" with 0 errors
```

### 4. Run the Application

```bash
# Run the application
dotnet run

# The application will start and attempt to connect to PostgreSQL
```

## Verification Steps

### 1. Database Connection Test
The application should successfully connect to PostgreSQL. Check the console output for any connection errors.

### 2. CRUD Operations Test

Test each operation:

#### GetAllProductsAsync
- Should return all 18 products from the database
- Verifies SELECT with CTE and window functions
- Check that PriceCategory and PricePercentageOfAverage are calculated correctly

#### GetProductByIdAsync
- Test with ProductId = 1
- Should return product details with price change percentage
- Verifies LAG window function and LEFT JOIN

#### InsertProductAsync
- Insert a new product with test data
- Verify the product is inserted and ProductId is returned
- Check ProductHistory table for INSERT record
- Check ProductStats table is updated
- Verifies transaction handling and RETURNING clause

#### UpdateProductAsync
- Update an existing product (e.g., ProductId = 1)
- Verify the product is updated
- Check ProductHistory table for UPDATE record
- Check ProductStats table is updated
- Verifies transaction handling with multiple operations

#### DeleteProductAsync
- Delete a product (e.g., the one just inserted)
- Verify the product is deleted
- Check ProductHistory table for DELETE record
- Check ProductStats table is updated
- Verifies transaction rollback on error

#### GetProductsByPriceRangeAsync
- Test with MinPrice = 100, MaxPrice = 500
- Should return products in that price range
- Verify PriceRank and PriceSegment are calculated correctly
- Verifies RANK and PERCENT_RANK window functions

#### GetLowStockProductsAsync
- Test with Threshold = 10
- Should return products with stock quantity <= 10
- Verify StockStatus and StockPercentageOfAverage are calculated correctly
- Verifies multiple window aggregations (AVG, MIN, MAX)

### 3. Transaction Integrity Test

Test transaction rollback:
1. Temporarily modify UpdateProductAsync to throw an exception after the first operation
2. Run the update operation
3. Verify that NO changes were committed to the database
4. Verify transaction was rolled back properly

### 4. Database Trigger Test

The PostgreSQL trigger should automatically log changes to ProductHistory:
1. Manually insert/update/delete a product
2. Query ProductHistory table to verify the trigger fired
3. Verify ActionDate and ModifiedBy are populated correctly

```sql
-- Check ProductHistory entries
SELECT * FROM ProductHistory ORDER BY ActionDate DESC LIMIT 10;
```

## Common Issues and Troubleshooting

### Issue 1: Connection Refused
**Error**: `Npgsql.NpgsqlException: Connection refused`
**Solution**: 
- Verify PostgreSQL is running: `sudo systemctl status postgresql`
- Check the port in connection string matches PostgreSQL port
- Verify firewall allows connections on port 5432

### Issue 2: Authentication Failed
**Error**: `Npgsql.NpgsqlException: password authentication failed`
**Solution**:
- Verify username and password in appsettings.json
- Check pg_hba.conf for authentication method
- Ensure the user has permissions on ProductManagement database

### Issue 3: Database Does Not Exist
**Error**: `Npgsql.NpgsqlException: database "ProductManagement" does not exist`
**Solution**:
- Run the database setup script (01_InitialSetup_PostgreSQL.sql)
- Verify database was created: `psql -U postgres -l`

### Issue 4: Permission Denied
**Error**: `Npgsql.NpgsqlException: permission denied for table Products`
**Solution**:
```sql
-- Grant permissions to your user
GRANT ALL PRIVILEGES ON DATABASE ProductManagement TO your_username;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_username;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO your_username;
```

### Issue 5: Window Function Errors
**Error**: `column "ps.avgprice" must appear in the GROUP BY clause`
**Solution**: This should not occur with the migrated code. If it does, verify the SQL statements match those in converted_statements.sql

## Validation Checklist

Use this checklist to verify successful migration:

- [ ] PostgreSQL database created successfully
- [ ] All tables created (Products, ProductHistory, ProductStats, Categories, Suppliers)
- [ ] All indexes created
- [ ] All functions/stored procedures created
- [ ] Trigger created and functional
- [ ] Sample data loaded (18 products, 20 categories, 8 suppliers)
- [ ] Application builds without errors
- [ ] Application connects to PostgreSQL successfully
- [ ] GetAllProductsAsync returns correct results
- [ ] GetProductByIdAsync returns correct results
- [ ] InsertProductAsync works and returns new ProductId
- [ ] UpdateProductAsync works and ProductHistory is updated
- [ ] DeleteProductAsync works and ProductHistory is updated
- [ ] GetProductsByPriceRangeAsync returns correct results with ranking
- [ ] GetLowStockProductsAsync returns correct results with aggregations
- [ ] Transactions commit on success
- [ ] Transactions rollback on error
- [ ] Trigger automatically logs changes to ProductHistory

## Performance Verification

Compare performance between SQL Server and PostgreSQL:

1. **Query Execution Time**: Measure time for each operation
2. **Connection Pool**: Verify connection pooling works correctly
3. **Concurrent Operations**: Test multiple simultaneous operations
4. **Window Functions**: Verify window functions perform efficiently

## Migration Artifacts Reference

The following files document the complete migration:

1. **extracted_statements.sql**: All original SQL Server statements
2. **converted_statements.sql**: All PostgreSQL converted statements
3. **dms_conversion_failure_log.md**: DMS tool conversion attempts and manual conversions
4. **sql_equivalency_validation_report.json**: Equivalency validation results for all statement pairs
5. **migration_summary.md**: Overall migration summary
6. **01_InitialSetup_PostgreSQL.sql**: PostgreSQL database schema setup

## Next Steps After Successful Deployment

1. **Security Hardening**:
   - Remove or update default credentials
   - Implement proper user roles and permissions
   - Enable SSL/TLS for database connections

2. **Performance Tuning**:
   - Analyze query execution plans
   - Add additional indexes if needed
   - Configure PostgreSQL parameters for optimal performance

3. **Monitoring**:
   - Set up database monitoring
   - Configure logging for database operations
   - Implement health checks

4. **Backup Strategy**:
   - Configure automated backups
   - Test backup restoration procedures
   - Document backup retention policies

5. **Integration Testing**:
   - Run full integration test suite
   - Perform load testing
   - Validate all edge cases

## Support and Documentation

For additional information, refer to:
- [Npgsql Documentation](https://www.npgsql.org/doc/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [ADO.NET to PostgreSQL Migration Best Practices](https://www.npgsql.org/doc/migration.html)
