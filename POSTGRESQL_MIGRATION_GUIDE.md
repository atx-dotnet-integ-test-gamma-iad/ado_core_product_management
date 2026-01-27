# PostgreSQL Migration - Next Steps Guide

## Current Status

✅ **CODE TRANSFORMATION: COMPLETE**
- All SQL Server references removed
- All Npgsql types implemented
- All 7 SQL statements converted to PostgreSQL syntax
- Connection strings updated to PostgreSQL format
- Application compiles with 0 errors, 0 warnings

⚠️ **RUNTIME VERIFICATION: PENDING**
- Requires PostgreSQL database instance
- Requires database schema creation
- Requires runtime testing

## Prerequisites for Runtime Testing

### 1. Install PostgreSQL
```bash
# For Ubuntu/Debian
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib

# For macOS (using Homebrew)
brew install postgresql
brew services start postgresql

# For Windows
# Download installer from https://www.postgresql.org/download/windows/
```

### 2. Verify PostgreSQL Installation
```bash
# Check PostgreSQL version
psql --version

# Check if PostgreSQL service is running
# Linux/macOS:
sudo systemctl status postgresql
# or
brew services list

# Windows:
# Check Services for PostgreSQL service
```

### 3. Create Database User (if needed)
```bash
# Connect as postgres superuser
sudo -u postgres psql

# Create user (if not using default postgres user)
CREATE USER your_username WITH PASSWORD 'your_password';
ALTER USER your_username WITH SUPERUSER;

# Exit psql
\q
```

## Database Setup Instructions

### Option 1: Using psql Command Line

```bash
# Step 1: Connect to PostgreSQL as postgres user
sudo -u postgres psql

# Step 2: Create the ProductManagement database
CREATE DATABASE "ProductManagement" WITH ENCODING 'UTF8';

# Step 3: Exit psql
\q

# Step 4: Connect to ProductManagement database
sudo -u postgres psql -d ProductManagement

# Step 5: Run the setup script
\i /path/to/Database/Scripts/02_PostgreSQL_Setup.sql

# Step 6: Verify the setup
SELECT 'Categories:' as object_type, COUNT(*) as count FROM categories
UNION ALL
SELECT 'Suppliers:', COUNT(*) FROM suppliers
UNION ALL
SELECT 'Products:', COUNT(*) FROM products;

# Step 7: Exit psql
\q
```

### Option 2: Using pgAdmin

1. Open pgAdmin
2. Connect to your PostgreSQL server
3. Right-click on "Databases" → "Create" → "Database..."
4. Name: `ProductManagement`, Encoding: `UTF8`
5. Open Query Tool for ProductManagement database
6. Load and execute `/path/to/Database/Scripts/02_PostgreSQL_Setup.sql`
7. Verify tables were created successfully

### Option 3: Using DBeaver

1. Open DBeaver
2. Create new PostgreSQL connection
3. Right-click on connection → "Create New Database"
4. Name: `ProductManagement`
5. Open SQL Editor for ProductManagement database
6. Load and execute `/path/to/Database/Scripts/02_PostgreSQL_Setup.sql`
7. Refresh database to see tables

## Connection String Configuration

### Update appsettings.json

Current connection strings are configured for local development:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true",
    "ProdConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true"
  },
  "Environment": "Development"
}
```

**If your PostgreSQL setup is different, update these values:**

- `Host`: PostgreSQL server hostname (e.g., `localhost`, `192.168.1.100`, `db.example.com`)
- `Port`: PostgreSQL port (default is `5432`)
- `Database`: Database name (should be `ProductManagement`)
- `Username`: PostgreSQL username (default is `postgres`)
- `Password`: PostgreSQL password
- `Pooling`: Connection pooling (recommended: `true`)

### Security Best Practice

For production, use environment variables instead of hardcoded credentials:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=${DB_HOST};Port=${DB_PORT};Database=${DB_NAME};Username=${DB_USER};Password=${DB_PASSWORD};Pooling=true"
  }
}
```

## Running the Application

### Step 1: Build the Application
```bash
cd /path/to/sourceCode
dotnet build
```

Expected output:
```
Build succeeded.
    0 Warning(s)
    0 Error(s)
```

### Step 2: Run in Interactive Mode
```bash
dotnet run
```

You should see:
```
Product Management System
------------------------
1. List all products
2. Get product by ID
3. Create new product
4. Update product
5. Delete product
6. Update product stock
Q. Quit

Enter your choice:
```

### Step 3: Test Database Operations

Try each menu option to verify:

1. **List all products** - Should display 18 sample products
2. **Get product by ID** - Try ID 1 (ProBook X1)
3. **Create new product** - Add a test product
4. **Update product** - Update the test product
5. **Delete product** - Delete the test product
6. **Update product stock** - Change stock quantity

### Step 4: Run CLI Commands
```bash
# List all products
dotnet run -- list

# Get product by ID
dotnet run -- get 1

# Add new product
dotnet run -- add "Test Product" 29.99 5 "Test Description"

# Update product
dotnet run -- update 1 "Updated Name" 39.99 10 "Updated Description"

# Update stock
dotnet run -- stock 1 20

# Delete product
dotnet run -- delete 1
```

## Verification Testing

### Test 1: Connection Verification
```bash
# This will test database connectivity
dotnet run -- list
```

**Expected:** List of products displayed  
**If fails:** Check connection string, PostgreSQL service status, database exists

### Test 2: Select Operations
```bash
# Test GetAllProductsAsync
dotnet run -- list

# Test GetProductByIdAsync
dotnet run -- get 1

# Test GetProductsByPriceRangeAsync (modify code to test)
# Test GetLowStockProductsAsync (modify code to test)
```

**Expected:** Data retrieved successfully with correct formatting  
**Verify:** CTEs and window functions work correctly

### Test 3: Insert Operation
```bash
dotnet run -- add "PostgreSQL Test" 99.99 50 "Testing INSERT with RETURNING"
```

**Expected:** Product created, ID returned  
**Verify:** RETURNING clause works correctly (replaced SCOPE_IDENTITY())

### Test 4: Update Operation
```bash
dotnet run -- update 1 "Updated Name" 199.99 25 "Updated Description"
```

**Expected:** Product updated successfully  
**Verify:** NOW() function works correctly (replaced GETDATE())

### Test 5: Delete Operation
```bash
dotnet run -- delete 999
```

**Expected:** Product deleted or "not found" message  
**Verify:** Cascading history insert works correctly

### Test 6: Transaction Testing

**Manual test for transaction atomicity:**
1. Modify UpdateProductAsync to throw an exception after first statement
2. Run update operation
3. Verify rollback occurred (product not updated, history not recorded)
4. Remove exception and verify normal operation

## Troubleshooting

### Issue: Cannot connect to PostgreSQL
**Symptoms:** Connection timeout or authentication failed

**Solutions:**
1. Verify PostgreSQL is running: `sudo systemctl status postgresql`
2. Check pg_hba.conf authentication settings
3. Verify username/password in connection string
4. Check firewall rules (port 5432)

### Issue: Database does not exist
**Symptoms:** "database ProductManagement does not exist"

**Solutions:**
1. Create database: `CREATE DATABASE "ProductManagement";`
2. Verify database name is case-sensitive in PostgreSQL
3. Check you're connected to correct PostgreSQL server

### Issue: Tables do not exist
**Symptoms:** "relation products does not exist"

**Solutions:**
1. Run 02_PostgreSQL_Setup.sql script
2. Verify script executed without errors
3. Check table names are lowercase (PostgreSQL convention)
4. Verify you're connected to ProductManagement database

### Issue: Permission denied
**Symptoms:** "permission denied for table products"

**Solutions:**
1. Grant permissions: `GRANT ALL ON ALL TABLES IN SCHEMA public TO your_user;`
2. Grant sequence permissions: `GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO your_user;`
3. Use postgres superuser for initial testing

### Issue: Application crashes on startup
**Symptoms:** Exception when starting application

**Solutions:**
1. Check connection string format
2. Verify Npgsql package is installed (check .csproj)
3. Review error message for specific issue
4. Check PostgreSQL logs: `/var/log/postgresql/postgresql-*.log`

## Exit Criteria Still Pending

The following exit criteria from the transformation definition require runtime verification:

| Criterion | Status | Required Action |
|-----------|--------|-----------------|
| 12. Application successfully connects to PostgreSQL database | ⚠️ PENDING | Run application after database setup |
| 13. All database operations execute successfully | ⚠️ PENDING | Test all 7 repository methods |
| 14. Transaction blocks maintain atomicity | ⚠️ PENDING | Test rollback scenarios |
| 15. Application passes all tests | N/A | No tests in codebase |

**Once you complete the database setup and runtime testing above, these criteria can be marked as PASS.**

## Migration Artifacts Reference

All migration documentation is available:

- `extracted_statements.sql` - Original SQL Server statements
- `converted_statements.sql` - Converted PostgreSQL statements
- `dms_conversion_log.json` - DMS tool conversion attempts and failures
- `sql_equivalency_validation_report.json` - SQL equivalency validation results
- `migration_summary.md` - Complete migration documentation
- `manual_review_required.md` - Manual review guidance
- `VALIDATION_SUMMARY.md` - Validation results and recommendations

## SQL Conversion Summary

All 7 SQL statements were converted with the following key changes:

| Original SQL Server Syntax | PostgreSQL Equivalent | Count |
|---------------------------|----------------------|-------|
| `GETDATE()` | `NOW()` | 10 occurrences |
| `SCOPE_IDENTITY()` | `RETURNING product_id` | 1 occurrence |
| Multi-statement transactions | Separate C# method calls | All transaction blocks |

**Compatible features (no changes needed):**
- Common Table Expressions (CTEs)
- Window functions (ROW_NUMBER, RANK, PERCENT_RANK, LAG)
- CASE expressions
- Aggregate functions (AVG, MIN, MAX, COUNT, SUM)
- ROUND function

## Support and Additional Resources

### PostgreSQL Documentation
- Official documentation: https://www.postgresql.org/docs/
- Npgsql documentation: https://www.npgsql.org/doc/

### SQL Server to PostgreSQL Migration Guides
- AWS Database Migration Service: https://docs.aws.amazon.com/dms/
- PostgreSQL Wiki - SQL Server compatibility: https://wiki.postgresql.org/wiki/SQL_Server_Compatibility

### Questions or Issues?
If you encounter any issues during runtime testing, document:
1. The specific operation that failed
2. The complete error message
3. PostgreSQL server version
4. Connection string used (without password)
5. Relevant PostgreSQL log entries

This information will help with troubleshooting and further refinement.

---

**Next Step:** Set up PostgreSQL database and run the verification tests above to complete the migration validation.
