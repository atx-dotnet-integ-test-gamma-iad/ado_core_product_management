# Runtime Validation Support - Quick Reference

This document provides quick links to all artifacts created to support runtime validation of the PostgreSQL migration.

## Support Artifacts Created

### 1. PostgreSQL Database Schema Script
**Location**: `Database/Scripts/01_PostgreSQL_InitialSetup.sql`

**Purpose**: Complete PostgreSQL schema initialization script converted from SQL Server

**How to use**:
```bash
# Create database
createdb -U postgres ProductManagement

# Initialize schema
psql -U postgres -d ProductManagement -f Database/Scripts/01_PostgreSQL_InitialSetup.sql
```

**What it creates**:
- All required tables (Products, Categories, Suppliers, ProductHistory, ProductStats)
- All indexes
- Foreign key constraints
- Triggers (converted to PostgreSQL functions)
- Stored procedures (converted to PostgreSQL functions)
- Sample data (20 categories, 8 suppliers, 18 products)

---

### 2. Connection Test Utility
**Location**: `Testing/ConnectionTestUtility.cs`

**Purpose**: Automated connection testing utility to validate database connectivity

**Features**:
- Tests connection string parsing
- Tests connection opening
- Tests query execution
- Verifies database schema
- Checks sample data
- Tests connection pooling
- Exports results to JSON

**How to use**:
```csharp
// Add to Program.cs or create a test program
var configuration = new ConfigurationBuilder()
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("appsettings.json", optional: false)
    .Build();

var tester = new ConnectionTestUtility(configuration);
var result = await tester.TestConnectionAsync();

// Results are printed to console and returned as ConnectionTestResult object
if (result.OverallSuccess)
{
    Console.WriteLine("Exit Criterion 12 (Database Connection) is SATISFIED");
}
```

**Test Coverage**:
- ✅ Connection string validation
- ✅ PostgreSQL connectivity
- ✅ Query execution capability
- ✅ Schema validation (all required tables)
- ✅ Sample data presence
- ✅ Connection pooling functionality

---

### 3. Runtime Validation Guide
**Location**: `RUNTIME_VALIDATION_GUIDE.md`

**Purpose**: Comprehensive step-by-step guide for completing runtime validation

**Contents**:
- Environment setup instructions (PostgreSQL installation)
- Database initialization procedures
- Connection string configuration
- Detailed test procedures for all 4 unmet exit criteria:
  - Criterion 12: Database Connection Testing
  - Criterion 13: Database Operations Testing (all 7 operations)
  - Criterion 14: Transaction Atomicity Testing
  - Criterion 15: Test Suite Execution
- Validation checklists
- Troubleshooting guide
- Documentation templates

**How to use**: Open the guide and follow step-by-step procedures for each criterion

---

### 4. Complete Validation Summary
**Location**: `~/.aws/atx/custom/20260121_062320_2fc063fd/artifacts/validation_summary.md`

**Purpose**: Comprehensive validation summary with detailed analysis

**Contents**:
- Executive summary of transformation
- Results for all 16 exit criteria (12 passed, 4 pending)
- Detailed SQL statement conversion analysis
- DMS and equivalency tool performance analysis
- Critical compliance verification
- Recommendations (immediate and future)
- Complete artifact inventory
- Change log

---

## Quick Start for Runtime Validation

### Prerequisites
1. PostgreSQL 12+ installed and running
2. .NET SDK installed
3. Application built successfully (`dotnet build`)

### Step-by-Step Quick Start

**Step 1: Set up database** (5 minutes)
```bash
createdb -U postgres ProductManagement
psql -U postgres -d ProductManagement -f Database/Scripts/01_PostgreSQL_InitialSetup.sql
```

**Step 2: Update connection string** (1 minute)
Edit `appsettings.json` and update the password if needed:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Pooling=true"
  }
}
```

**Step 3: Test connection** (2 minutes)
Run the application:
```bash
dotnet run
```

If no errors appear and the application starts, Criterion 12 is satisfied.

**Step 4: Test database operations** (10 minutes)
Use the interactive menu to test all operations:
1. List all products (GetAllProductsAsync)
2. View product details (GetProductByIdAsync)
3. Add new product (InsertProductAsync)
4. Update product (UpdateProductAsync)
5. Delete product (DeleteProductAsync)
6. Search by price range (GetProductsByPriceRangeAsync)
7. View low stock (GetLowStockProductsAsync)

If all operations complete without errors, Criterion 13 is satisfied.

**Step 5: Verify transactions** (5 minutes)
In a separate terminal, monitor database:
```bash
psql -U postgres -d ProductManagement
```

Run operations and verify:
- INSERT creates records in Products, ProductHistory, and ProductStats
- UPDATE creates history records
- DELETE creates history records and removes product

If all tables are updated atomically, Criterion 14 is satisfied.

**Step 6: Run tests** (if applicable)
```bash
dotnet test
```

If no test projects exist, document this in validation summary.

---

## Validation Checklist

Use this checklist to track your progress:

- [ ] PostgreSQL installed and running
- [ ] Database created (`ProductManagement`)
- [ ] Schema initialized (tables, indexes, functions, sample data)
- [ ] Connection string updated with correct credentials
- [ ] Application builds successfully
- [ ] **Criterion 12**: Application connects to PostgreSQL
- [ ] **Criterion 13**: All 7 database operations tested and working
  - [ ] GetAllProductsAsync
  - [ ] GetProductByIdAsync
  - [ ] InsertProductAsync (verify RETURNING clause)
  - [ ] UpdateProductAsync
  - [ ] DeleteProductAsync
  - [ ] GetProductsByPriceRangeAsync
  - [ ] GetLowStockProductsAsync
- [ ] **Criterion 14**: Transaction atomicity verified
  - [ ] Commit scenarios tested
  - [ ] Rollback scenarios tested
- [ ] **Criterion 15**: Test suite executed (or documented as N/A)
- [ ] All results documented
- [ ] Validation summary updated with results

---

## Critical Notes for Testing

### Statements Requiring Extra Attention

**5 statements have ERROR equivalency status** (tool could not formally prove equivalency):
1. GetAllProductsAsync (Statement 1)
2. GetProductByIdAsync (Statement 2)
3. InsertProductAsync (Statement 3) - **CRITICAL: Test RETURNING clause**
4. GetProductsByPriceRangeAsync (Statement 6)
5. GetLowStockProductsAsync (Statement 7)

These statements use window functions and CTEs that are syntactically identical in SQL Server and PostgreSQL, but the formal verification tool could not prove equivalency. Functional testing is essential.

**2 statements have EQUIVALENT status** (formally verified):
1. UpdateProductAsync (Statement 4)
2. DeleteProductAsync (Statement 5)

These were formally verified as equivalent by the StructuralEquivalenceVerifier.

### Most Critical Test

**InsertProductAsync (Statement 3)** is the most critical test because:
- Uses RETURNING clause (PostgreSQL-specific pattern)
- Replaces SQL Server's SCOPE_IDENTITY()
- Code uses ExecuteScalarAsync() to capture returned value
- Must verify ProductId is correctly captured
- Three-statement transaction must commit atomically

**Test procedure**:
```bash
# Run application
dotnet run

# Select "Add product" from menu
# Enter test data
# Verify new ProductId is displayed
# Check database to confirm all three operations completed:
psql -U postgres -d ProductManagement
SELECT * FROM Products WHERE Name = 'Your Test Product';
SELECT * FROM ProductHistory WHERE Action = 'INSERT' ORDER BY ActionDate DESC LIMIT 1;
SELECT * FROM ProductStats WHERE StatId = 1;
```

---

## Troubleshooting

### Connection Issues
```
Error: "Connection refused"
Solution: sudo systemctl start postgresql
```

```
Error: "Authentication failed"
Solution: Check credentials in appsettings.json, verify pg_hba.conf
```

```
Error: "database does not exist"
Solution: createdb -U postgres ProductManagement
```

### Query Issues
```
Error: "relation does not exist"
Solution: Run 01_PostgreSQL_InitialSetup.sql script
```

```
Error: "column does not exist"
Solution: Verify schema was created correctly, check table structure
```

### RETURNING Clause Issues
```
Error: ExecuteScalarAsync returns null
Solution: Verify command.ExecuteScalarAsync() is used (not ExecuteNonQueryAsync)
```

---

## Success Criteria

### All 4 Remaining Exit Criteria Must Pass

**Criterion 12**: Application connects to PostgreSQL
- ✅ No connection errors
- ✅ Connection string parsed correctly
- ✅ Database accessible

**Criterion 13**: All database operations execute successfully
- ✅ All 7 SELECT/INSERT/UPDATE/DELETE operations work
- ✅ Window functions return expected results
- ✅ RETURNING clause captures ProductId
- ✅ Parameters properly bound

**Criterion 14**: Transaction atomicity maintained
- ✅ Successful transactions commit all changes
- ✅ Failed transactions rollback completely
- ✅ No orphaned records

**Criterion 15**: Application passes all tests
- ✅ All tests pass (or documented as N/A if no tests exist)

---

## After Validation Complete

1. Update validation summary with test results
2. Change OVERALL STATUS from PARTIAL to PASS
3. Document any issues encountered
4. Consider addressing recommendations:
   - Upgrade Npgsql to address security vulnerability
   - Implement test suite if none exists
   - Secure connection strings for production

---

## Additional Resources

- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Npgsql Documentation**: https://www.npgsql.org/doc/
- **Window Functions**: https://www.postgresql.org/docs/current/tutorial-window.html
- **Transactions**: https://www.postgresql.org/docs/current/tutorial-transactions.html

---

**For complete details, see**:
- `RUNTIME_VALIDATION_GUIDE.md` - Comprehensive testing procedures
- `~/.aws/atx/custom/20260121_062320_2fc063fd/artifacts/validation_summary.md` - Complete validation summary
