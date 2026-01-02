# Post-Migration Deployment and Verification Checklist

This checklist addresses the remaining items that could not be automatically verified during the migration process due to environmental dependencies.

## Overview

The code migration from SQL Server to PostgreSQL is **COMPLETE**. All 11 code-related exit criteria have been met. The following 4 criteria require runtime verification with an actual PostgreSQL database instance:

- **Criterion 12**: Database connection verification
- **Criterion 13**: Database operations execution verification
- **Criterion 14**: Transaction atomicity verification
- **Criterion 15**: Unit/Integration test execution (N/A - no tests exist in codebase)

## Prerequisites Verification

### ✓ Code Migration (Complete)
- [x] SQL Server packages replaced with Npgsql
- [x] ADO.NET classes converted to Npgsql equivalents
- [x] All 7 SQL statements processed through DMS MCP tool
- [x] Comprehensive catalogs created (extracted_statements.sql, converted_statements.sql)
- [x] All 7 statement pairs validated through SQL Equivalency tool
- [x] Equivalency validation report generated
- [x] DMS failures documented (1 statement)
- [x] Connection strings converted to PostgreSQL format
- [x] Transaction handling updated for PostgreSQL
- [x] Application compiles without errors (0 errors, 12 warnings)

### ⚠ Runtime Verification Required

## Step 1: PostgreSQL Environment Setup

### 1.1 Install PostgreSQL (if not already installed)

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

**Windows:**
- Download installer from https://www.postgresql.org/download/windows/
- Run installer and follow wizard
- Default port: 5432

**Docker (Quick Testing):**
```bash
docker run --name postgres-adocore \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=ProductManagement \
  -p 5432:5432 \
  -d postgres:15
```

**Verification:**
```bash
psql --version
# Expected: psql (PostgreSQL) 12.x or later
```

Status: [ ] Complete

### 1.2 Create Database and Schema

Execute the setup script:

```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode

# Connect as postgres user
psql -U postgres

# In psql:
CREATE DATABASE "ProductManagement" WITH ENCODING 'UTF8';
\c ProductManagement
\i Database/Scripts/01_PostgreSQL_InitialSetup.sql
\q
```

**Verification:**
```bash
psql -U postgres -d ProductManagement -c "SELECT COUNT(*) FROM products;"
# Expected: count = 19
```

Status: [ ] Complete

### 1.3 Update Connection String

**For Development Testing:**

Edit `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres"
  }
}
```

**For Production:**

Use secure configuration:
```bash
# Option 1: Environment variable
export ConnectionStrings__DevConnection="Host=prod-host;Port=5432;Database=ProductManagement;Username=app_user;Password=secure_password;SSL Mode=Require"

# Option 2: User secrets (development)
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres"

# Option 3: Azure Key Vault (production)
# Configure Key Vault reference in Azure App Service configuration
```

Status: [ ] Complete

## Step 2: Criterion 12 - Database Connection Verification

### 2.1 Test Connection from Application

Run the application:
```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode
dotnet run
```

**Expected Behavior:**
- Application starts without connection errors
- Menu displays successfully
- No "unable to connect" errors in output

**If Connection Fails:**

Check PostgreSQL is accepting connections:
```bash
# Test direct connection
psql -U postgres -d ProductManagement -c "SELECT 1;"

# Check PostgreSQL is listening
sudo netstat -plnt | grep 5432

# Review PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-15-main.log  # Linux
tail -f ~/Library/Application\ Support/Postgres/var-15/postgresql.log  # macOS
```

Check `pg_hba.conf` authentication:
```bash
# Locate config
psql -U postgres -c "SHOW hba_file;"

# Add local connection if needed
# local   all   all   trust
# host    all   all   127.0.0.1/32   md5
```

**Test Command:**
```bash
dotnet run
# Select option 1 (Get All Products)
# Should display product list without errors
```

**Success Criteria:**
- [ ] Application connects to PostgreSQL without errors
- [ ] Connection can be opened and closed successfully
- [ ] No authentication or network errors

Status: [ ] PASS / [ ] FAIL

Issues Encountered:
```
[Document any connection issues here]
```

## Step 3: Criterion 13 - Database Operations Verification

Test each CRUD operation:

### 3.1 SELECT Operations

**Test 1: Get All Products**
```bash
dotnet run
# Choose option: 1
```

**Expected:** List of 19 products displayed

**Success Criteria:**
- [ ] Query executes without errors
- [ ] All 19 products returned
- [ ] Data displays correctly with lowercase column names

Status: [ ] PASS / [ ] FAIL

---

**Test 2: Get Product by ID**
```bash
dotnet run
# Choose option: 2
# Enter ID: 1
```

**Expected:** Single product details displayed

**Success Criteria:**
- [ ] Parameterized query executes correctly
- [ ] Correct product returned
- [ ] All fields populated

Status: [ ] PASS / [ ] FAIL

---

**Test 3: Get Products by Price Range**
```bash
dotnet run
# Choose option: 6
# Enter min price: 100
# Enter max price: 500
```

**Expected:** Products in price range displayed

**Success Criteria:**
- [ ] Window function query executes
- [ ] Correct products returned
- [ ] Price filtering works correctly

Status: [ ] PASS / [ ] FAIL

---

**Test 4: Get Low Stock Products**
```bash
dotnet run
# Choose option: 7
```

**Expected:** Products with stock <= reorder level displayed

**Success Criteria:**
- [ ] CTE query executes
- [ ] Correct low-stock products returned
- [ ] Stock levels accurately identified

Status: [ ] PASS / [ ] FAIL

### 3.2 INSERT Operations

**Test 5: Insert Product**
```bash
dotnet run
# Choose option: 3
# Enter name: Test Product
# Enter description: Test Description
# Enter price: 99.99
# Enter stock: 50
```

**Expected:** Product inserted, new ID returned via RETURNING clause

**Success Criteria:**
- [ ] Insert executes without errors
- [ ] RETURNING clause returns new ID correctly
- [ ] Product appears in subsequent queries
- [ ] ProductHistory record created (INSERT action)
- [ ] ProductStats updated correctly

**Verification Queries:**
```sql
-- Verify product inserted
SELECT * FROM products WHERE name = 'Test Product';

-- Verify history record
SELECT * FROM producthistory WHERE action = 'INSERT' ORDER BY actiondate DESC LIMIT 1;

-- Verify stats updated
SELECT * FROM productstats WHERE statid = 1;
```

Status: [ ] PASS / [ ] FAIL

### 3.3 UPDATE Operations

**Test 6: Update Product**
```bash
dotnet run
# Choose option: 4
# Enter ID: [ID from insert test]
# Enter new name: Updated Product
# Enter new description: Updated Description
# Enter new price: 89.99
# Enter new stock: 45
```

**Expected:** Product updated, history recorded

**Success Criteria:**
- [ ] Update executes without errors
- [ ] Product values changed correctly
- [ ] ModifiedDate set to CURRENT_TIMESTAMP
- [ ] ProductHistory record created (UPDATE action)
- [ ] Old and new values captured in history
- [ ] ProductStats updated correctly

**Verification Queries:**
```sql
-- Verify product updated
SELECT * FROM products WHERE productid = [ID];

-- Verify history record
SELECT * FROM producthistory WHERE action = 'UPDATE' AND productid = [ID] ORDER BY actiondate DESC LIMIT 1;
```

Status: [ ] PASS / [ ] FAIL

### 3.4 DELETE Operations

**Test 7: Delete Product**
```bash
dotnet run
# Choose option: 5
# Enter ID: [ID from insert test]
```

**Expected:** Product deleted, history preserved

**Success Criteria:**
- [ ] Delete executes without errors
- [ ] Product removed from products table
- [ ] ProductHistory record created (DELETE action)
- [ ] Foreign key constraints respected
- [ ] ProductStats updated correctly

**Verification Queries:**
```sql
-- Verify product deleted
SELECT COUNT(*) FROM products WHERE productid = [ID];
-- Expected: 0

-- Verify history record preserved
SELECT * FROM producthistory WHERE action = 'DELETE' AND productid = [ID];
-- Expected: 1 record with old values
```

Status: [ ] PASS / [ ] FAIL

### Summary: All Database Operations

**Overall Status:** [ ] All PASS / [ ] Some FAIL

**Operations Summary:**
- SELECT operations (4): [ ] PASS
- INSERT operations (1): [ ] PASS
- UPDATE operations (1): [ ] PASS
- DELETE operations (1): [ ] PASS

**Criterion 13 Status:** [ ] PASS / [ ] PARTIAL / [ ] FAIL

## Step 4: Criterion 14 - Transaction Atomicity Verification

Test that multi-statement transactions maintain atomicity:

### 4.1 Test Insert Transaction Rollback

**Simulate an error during insert transaction:**

Temporarily break the transaction to test rollback:

```bash
# Modify ProductRepository.cs temporarily to force an error
# After INSERT product, before COMMIT, add:
# throw new Exception("Simulated error");

dotnet build
dotnet run
# Choose option: 3, enter test data
```

**Expected:** Transaction rolls back completely

**Success Criteria:**
- [ ] Product NOT inserted in products table
- [ ] ProductHistory record NOT created
- [ ] ProductStats NOT updated
- [ ] Error message displayed to user
- [ ] Database remains in consistent state

**Verification:**
```sql
-- Check no partial data inserted
SELECT COUNT(*) FROM products WHERE name = 'Test Product';
SELECT COUNT(*) FROM producthistory WHERE action = 'INSERT' AND actiondate > NOW() - INTERVAL '1 minute';
```

Status: [ ] PASS / [ ] FAIL

### 4.2 Test Update Transaction Rollback

**Simulate error during update:**

```bash
# Add forced exception after UPDATE but before COMMIT
# Same modification approach as above

dotnet build
dotnet run
# Choose option: 4, update an existing product
```

**Success Criteria:**
- [ ] Product values NOT changed
- [ ] ProductHistory record NOT created
- [ ] ProductStats NOT updated
- [ ] Original values preserved

Status: [ ] PASS / [ ] FAIL

### 4.3 Test Delete Transaction Rollback

**Simulate error during delete:**

```bash
# Add forced exception after DELETE but before COMMIT

dotnet build
dotnet run
# Choose option: 5, attempt to delete a product
```

**Success Criteria:**
- [ ] Product NOT deleted
- [ ] ProductHistory record NOT created
- [ ] ProductStats NOT updated

Status: [ ] PASS / [ ] FAIL

### 4.4 Test Concurrent Transaction Isolation

**Test transaction isolation:**

Open two terminal windows:

**Terminal 1:**
```bash
psql -U postgres -d ProductManagement
BEGIN;
UPDATE products SET price = 999.99 WHERE productid = 1;
-- Do NOT commit yet
```

**Terminal 2:**
```bash
dotnet run
# Choose option: 4 (Update Product)
# Try to update productid = 1
```

**Expected:** Terminal 2 waits for Terminal 1's transaction to complete

**Terminal 1:**
```sql
ROLLBACK;
```

**Success Criteria:**
- [ ] Terminal 2 operation waits during Terminal 1 transaction
- [ ] After ROLLBACK, Terminal 2 proceeds
- [ ] No dirty reads occur
- [ ] Transaction isolation maintained

Status: [ ] PASS / [ ] FAIL

### Summary: Transaction Atomicity

**Overall Status:** [ ] All PASS / [ ] Some FAIL

**Transaction Tests:**
- Insert rollback: [ ] PASS
- Update rollback: [ ] PASS
- Delete rollback: [ ] PASS
- Isolation: [ ] PASS

**Criterion 14 Status:** [ ] PASS / [ ] PARTIAL / [ ] FAIL

## Step 5: Criterion 15 - Unit/Integration Tests

**Status: N/A - No test suite exists in codebase**

The source application does not include unit tests or integration tests. This is a limitation of the source codebase, not a migration failure.

**Recommendation:** Create test suite for production application

**Optional: Create Basic Tests**

If you want to create tests post-migration:

```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode
dotnet new xunit -n AdoCore.Tests
cd AdoCore.Tests
dotnet add reference ../AdoCore.csproj
dotnet add package Npgsql
dotnet add package FluentAssertions
```

**Example test structure:**
```csharp
public class ProductRepositoryTests : IDisposable
{
    private readonly NpgsqlConnection _connection;
    
    public ProductRepositoryTests()
    {
        // Setup test database connection
    }
    
    [Fact]
    public async Task GetAllProducts_ReturnsProducts()
    {
        // Test implementation
    }
    
    public void Dispose()
    {
        _connection?.Dispose();
    }
}
```

Status: [ ] Tests Created / [ ] Skipped (N/A)

## Step 6: Additional Recommendations

### 6.1 Update Npgsql Version (Security)

Current version 8.0.0 has vulnerability warning NU1903.

```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode
dotnet add package Npgsql --version 8.0.5  # Or latest stable
dotnet build
# Re-run all tests from Steps 2-4
```

Status: [ ] Complete / [ ] Skipped

### 6.2 Production Security Hardening

- [ ] Use strong passwords (not 'postgres')
- [ ] Create dedicated application user with minimal privileges
- [ ] Enable SSL/TLS for database connections
- [ ] Store secrets in Key Vault/Secrets Manager
- [ ] Configure connection pooling
- [ ] Enable audit logging
- [ ] Set up database backups
- [ ] Configure firewall rules

Status: [ ] Complete / [ ] Planned

### 6.3 Performance Testing

- [ ] Load testing with expected traffic
- [ ] Query performance analysis (EXPLAIN ANALYZE)
- [ ] Index optimization review
- [ ] Connection pool sizing
- [ ] Resource monitoring setup

Status: [ ] Complete / [ ] Planned

## Final Verification Summary

### Exit Criteria Status After Runtime Testing

| Criterion | Description | Status |
|-----------|-------------|--------|
| 1 | SQL Server packages replaced | ✅ PASS |
| 2 | ADO.NET classes replaced | ✅ PASS |
| 3 | All SQL processed through DMS | ✅ PASS |
| 4 | Comprehensive catalog exists | ✅ PASS |
| 5 | All statements validated for equivalency | ✅ PASS |
| 6 | Equivalency report generated | ✅ PASS |
| 7 | No agent judgment for equivalency | ✅ PASS |
| 8 | DMS failures documented | ✅ PASS |
| 9 | Connection strings updated | ✅ PASS |
| 10 | Transaction handling updated | ✅ PASS |
| 11 | Application compiles | ✅ PASS |
| 12 | Database connection works | ⚠ PENDING |
| 13 | Database operations execute | ⚠ PENDING |
| 14 | Transaction atomicity maintained | ⚠ PENDING |
| 15 | Tests pass | N/A (no tests) |
| 16 | Final report with equivalency status | ✅ PASS |

### Completion Checklist

- [ ] PostgreSQL environment set up (Step 1)
- [ ] Database connection verified (Step 2)
- [ ] All CRUD operations verified (Step 3)
- [ ] Transaction atomicity verified (Step 4)
- [ ] Security hardening applied (Step 6.2)
- [ ] Documentation reviewed and updated

## Sign-off

**Code Migration Status:** ✅ COMPLETE (11/11 code criteria passed)

**Runtime Verification Status:** ⚠ PENDING (Requires PostgreSQL database instance)

**Completed By:** _________________ **Date:** _________________

**Runtime Tests Completed By:** _________________ **Date:** _________________

**Approved for Production:** _________________ **Date:** _________________

## Appendix: Troubleshooting Reference

### Common Issues

**Issue 1: Connection Timeout**
```
Solution: Check PostgreSQL is running, verify port 5432, check firewall rules
```

**Issue 2: Authentication Failed**
```
Solution: Verify username/password, check pg_hba.conf, ensure user has database access
```

**Issue 3: Permission Denied on Tables**
```sql
-- Run as superuser:
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO your_user;
```

**Issue 4: SSL Required**
```
Solution: Add SSL Mode=Require to connection string or disable in pg_hba.conf for testing
```

### Contact and Support

- Migration artifacts: sourceCode directory
- PostgreSQL docs: https://www.postgresql.org/docs/
- Npgsql docs: https://www.npgsql.org/doc/
- Issues: [Document your support contact information]
