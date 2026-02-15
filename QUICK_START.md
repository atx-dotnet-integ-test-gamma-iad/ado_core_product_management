# Quick Start Guide - PostgreSQL Migration Testing

## Immediate Next Steps

This migration has completed all **code-level transformations** successfully. To complete the validation of exit criteria 12-15, follow these steps:

## Option 1: Quick Docker Setup (Recommended)

If you have Docker installed, this is the fastest way to test:

```bash
# 1. Start PostgreSQL in Docker
docker run --name postgres-test \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=ProductManagement \
  -p 5432:5432 \
  -d postgres:16

# 2. Wait a few seconds for PostgreSQL to start
sleep 5

# 3. Load the schema
docker cp Database/Scripts/01_InitialSetup_PostgreSQL.sql postgres-test:/tmp/
docker exec -i postgres-test psql -U postgres -d ProductManagement -f /tmp/01_InitialSetup_PostgreSQL.sql

# 4. Run the validation tests
dotnet run -- test

# 5. Cleanup (optional)
docker stop postgres-test
docker rm postgres-test
```

## Option 2: Local PostgreSQL Installation

### Windows
1. Download PostgreSQL from https://www.postgresql.org/download/windows/
2. Run the installer (use password: postgres)
3. Open pgAdmin or Command Prompt
4. Execute:
   ```cmd
   cd sourceCode
   psql -U postgres
   CREATE DATABASE "ProductManagement";
   \c ProductManagement
   \i Database/Scripts/01_InitialSetup_PostgreSQL.sql
   \q
   dotnet run -- test
   ```

### macOS
```bash
brew install postgresql@16
brew services start postgresql@16
createdb ProductManagement
cd sourceCode
psql -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
dotnet run -- test
```

### Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo -u postgres psql
CREATE DATABASE "ProductManagement";
\q
cd sourceCode
sudo -u postgres psql -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
dotnet run -- test
```

## Running the Tests

Once PostgreSQL is set up, run:

```bash
cd sourceCode
dotnet run -- test
```

This will execute all 8 validation tests and provide a comprehensive report.

## Expected Test Results

If all tests pass, you will see:
```
============================================================
PostgreSQL Database Migration Validation Tests
============================================================

Test 1: Database Connectivity
✅ PASS - Successfully connected to PostgreSQL database

Test 2: GetAllProductsAsync()
✅ PASS - Retrieved all products successfully

Test 3: GetProductByIdAsync(int productId)
✅ PASS - Retrieved product by ID successfully

Test 4: InsertProductAsync(Product product)
✅ PASS - Inserted product successfully (ID: 19)

Test 5: UpdateProductAsync(Product product)
✅ PASS - Updated product successfully

Test 6: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
✅ PASS - Retrieved products by price range successfully

Test 7: GetLowStockProductsAsync(int threshold)
✅ PASS - Retrieved low stock products successfully

Test 8: DeleteProductAsync(int productId)
✅ PASS - Deleted product successfully

============================================================
Test Summary
============================================================
Total Tests: 8
Passed: 8
Failed: 0
Success Rate: 100.00%

🎉 All tests passed! Migration validation successful.

Exit Criteria Status:
✅ Criterion 12: Database connectivity - PASS
✅ Criterion 13: Database operations - PASS
✅ Criterion 14: Transaction handling - PASS
============================================================
```

## Troubleshooting

### Connection Refused
- Verify PostgreSQL is running: `systemctl status postgresql` (Linux) or check Services (Windows)
- Check if port 5432 is available: `netstat -an | grep 5432`
- Verify connection string in `appsettings.json`

### Authentication Failed
- Ensure username/password match in appsettings.json
- Check PostgreSQL pg_hba.conf for authentication method
- Try connecting with psql: `psql -U postgres -d ProductManagement`

### Schema Not Found
- Verify the PostgreSQL schema script was executed successfully
- Check for errors in the script output
- Verify tables exist: `psql -U postgres -d ProductManagement -c "\dt"`

## Current Status Summary

### ✅ Completed (12/16 Exit Criteria)
1. ✅ Package migration (SQL Server → PostgreSQL)
2. ✅ ADO.NET classes migration
3. ✅ All SQL statements processed through DMS tool
4. ✅ Comprehensive SQL statement catalog created
5. ✅ All SQL pairs validated through equivalency tool
6. ✅ Equivalency validation report generated
7. ✅ No agent judgment used for equivalency
8. ✅ DMS failures documented
9. ✅ Connection strings updated
10. ✅ Transaction handling updated
11. ✅ Application compiles successfully
16. ✅ Final report with equivalency status

### ⏳ Pending Runtime Validation (4/16 Exit Criteria)
12. ⏳ Database connectivity test (requires PostgreSQL instance)
13. ⏳ Database operations test (requires PostgreSQL instance)
14. ⏳ Transaction atomicity test (requires PostgreSQL instance)
15. ⏳ Unit/Integration tests (requires PostgreSQL instance)

**These pending criteria will be satisfied once you run `dotnet run -- test` with a PostgreSQL database.**

## Additional Resources

- Full testing guide: `POSTGRESQL_TESTING_GUIDE.md`
- PostgreSQL schema script: `Database/Scripts/01_InitialSetup_PostgreSQL.sql`
- Migration artifacts: `../dms_conversion_log.json`, `../final_migration_report.json`
- SQL equivalency report: `../sql_equivalency_validation_report.json`
