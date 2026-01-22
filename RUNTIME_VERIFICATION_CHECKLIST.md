# Runtime Verification Checklist

This document provides a checklist for verifying the migrated application meets all runtime exit criteria.

## Exit Criteria Status

### ✅ Completed (Criteria 1-11)
- All SQL Server packages replaced with PostgreSQL equivalents
- All ADO.NET classes replaced with Npgsql equivalents
- All SQL statements processed through DMS MCP tool
- Comprehensive catalogs created for all statements
- All statement pairs validated through SQL Equivalency tool
- Equivalency validation report generated
- No agent judgment used for equivalency determination
- Failed DMS conversions documented
- Connection strings updated to PostgreSQL format
- Transaction handling updated to PostgreSQL syntax
- Application compiles without errors

### ⏳ Pending Runtime Verification (Criteria 12-15)

The following criteria require a live PostgreSQL database and runtime testing:

## Criterion 12: Database Connectivity ⏳

**Required Setup:**
```bash
# 1. Install PostgreSQL
# See POSTGRESQL_MIGRATION_GUIDE.md for installation instructions

# 2. Create database and run schema setup
psql -U postgres
CREATE DATABASE "ProductManagement";
\c ProductManagement
\i Database/Scripts/01_InitialSetup_PostgreSQL.sql
\q

# 3. Verify connection string in appsettings.json
# Default: Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres
```

**Verification Steps:**
```bash
# Build and run the application
cd sourceCode
dotnet build
dotnet run

# Expected: Application starts without connection errors
# Expected: Can retrieve menu options
```

**Success Criteria:**
- [ ] Application starts successfully
- [ ] No connection exceptions thrown
- [ ] Connection pool initializes correctly

## Criterion 13: Database Operations ⏳

**Verification Steps:**

### Test 1: GetAllProductsAsync
```bash
# Run application and select "Get all products"
# Expected: Returns 18 products from sample data
```
**Verify in PostgreSQL:**
```sql
SELECT COUNT(*) FROM products; -- Should be 18
```

### Test 2: GetProductByIdAsync
```bash
# Run application and select "Get product by ID"
# Test with ID = 1
# Expected: Returns "ProBook X1" product details
```

### Test 3: InsertProductAsync
```bash
# Run application and select "Insert new product"
# Enter test data:
#   Name: Test Product
#   Description: Test Description
#   Price: 99.99
#   Stock: 10
# Expected: Returns new ProductId
```
**Verify in PostgreSQL:**
```sql
SELECT * FROM products WHERE name = 'Test Product';
SELECT * FROM product_history WHERE action = 'INSERT' ORDER BY action_date DESC LIMIT 1;
SELECT * FROM product_stats; -- Verify counters updated
```

### Test 4: UpdateProductAsync
```bash
# Run application and select "Update existing product"
# Update the test product created above
# Change price to 149.99 and stock to 15
# Expected: Success message
```
**Verify in PostgreSQL:**
```sql
SELECT * FROM products WHERE name = 'Test Product';
-- Should show price=149.99, stock_quantity=15
SELECT * FROM product_history WHERE action = 'UPDATE' ORDER BY action_date DESC LIMIT 1;
-- Should show old and new values
```

### Test 5: DeleteProductAsync
```bash
# Run application and select "Delete product"
# Delete the test product
# Expected: Success message
```
**Verify in PostgreSQL:**
```sql
SELECT * FROM products WHERE name = 'Test Product';
-- Should return 0 rows
SELECT * FROM product_history WHERE action = 'DELETE' ORDER BY action_date DESC LIMIT 1;
-- Should show delete history
```

### Test 6: GetProductsByPriceRangeAsync
```bash
# Run application and select "Get products by price range"
# Enter: Min=100, Max=500
# Expected: Returns products in that price range with category info
```

### Test 7: GetLowStockProductsAsync
```bash
# Run application and select "Get low stock products"
# Expected: Returns products where stock <= reorder_level
```
**Verify in PostgreSQL:**
```sql
SELECT name, stock_quantity, reorder_level 
FROM products 
WHERE stock_quantity <= reorder_level;
```

**Success Criteria:**
- [ ] All SELECT queries return correct data
- [ ] INSERT operations create records in all required tables
- [ ] UPDATE operations modify data correctly
- [ ] DELETE operations remove data correctly
- [ ] No SQL exceptions during operations
- [ ] Data types convert correctly (decimals, dates, booleans)

## Criterion 14: Transaction Atomicity ⏳

**Test Scenario 1: Successful Transaction (Insert)**
```bash
# Insert a new product
# Verify all 3 operations in transaction succeed:
```
**Verify:**
```sql
BEGIN;
SELECT * FROM products WHERE product_id = (SELECT MAX(product_id) FROM products);
-- Should exist
SELECT * FROM product_history WHERE product_id = (SELECT MAX(product_id) FROM products);
-- Should have INSERT record
SELECT * FROM product_stats WHERE stat_id = 1;
-- Should have updated counters
COMMIT;
```

**Test Scenario 2: Successful Transaction (Update)**
```bash
# Update an existing product
# Verify all 4 operations in transaction succeed:
```
**Verify:**
```sql
-- Product record updated
-- ProductHistory record created
-- ProductStats updated (if price/stock changed)
-- All within same transaction
```

**Test Scenario 3: Successful Transaction (Delete)**
```bash
# Delete a product
# Verify all 4 operations in transaction succeed:
```
**Verify:**
```sql
-- Product record deleted
-- ProductHistory records remain (foreign key should be ON DELETE CASCADE or NO ACTION)
-- ProductStats updated
-- All within same transaction
```

**Test Scenario 4: Rollback on Error (Manual Test)**

To test rollback behavior, temporarily modify the code:

1. Open `DataAccess/ProductRepository.cs`
2. In `InsertProductAsync`, add after the first SQL statement:
   ```csharp
   throw new Exception("Test rollback");
   ```
3. Build and run
4. Try to insert a product
5. Verify in database:
   ```sql
   -- No partial data should exist
   SELECT * FROM products ORDER BY product_id DESC LIMIT 1;
   SELECT * FROM product_history ORDER BY action_date DESC LIMIT 1;
   -- Both should show no new records
   ```
6. Remove the test exception and rebuild

**Success Criteria:**
- [ ] Successful transactions commit all operations
- [ ] Failed transactions rollback all operations
- [ ] No partial data exists after rollback
- [ ] ProductHistory accurately reflects all changes
- [ ] ProductStats remains consistent

## Criterion 15: Unit and Integration Tests ⏳

**Current Status:** No test suite exists

**Required Actions:**

### 1. Create Test Project
```bash
cd sourceCode
dotnet new xunit -n AdoCore.Tests
cd AdoCore.Tests
dotnet add reference ../AdoCore.csproj
dotnet add package Npgsql
dotnet add package Moq
dotnet add package FluentAssertions
```

### 2. Create Unit Tests

Create `ProductRepositoryTests.cs`:
```csharp
public class ProductRepositoryTests
{
    [Fact]
    public async Task GetAllProductsAsync_ReturnsProducts()
    {
        // Arrange
        var connectionString = "your-test-connection-string";
        var repository = new ProductRepository(connectionString);
        
        // Act
        var products = await repository.GetAllProductsAsync();
        
        // Assert
        Assert.NotNull(products);
        Assert.NotEmpty(products);
    }
    
    // Add tests for all 7 repository methods
}
```

### 3. Create Integration Tests

Create `ProductRepositoryIntegrationTests.cs` with:
- Database setup and teardown
- Test data insertion
- Full CRUD cycle tests
- Transaction tests
- Concurrency tests

### 4. Run Tests
```bash
cd AdoCore.Tests
dotnet test --logger "console;verbosity=detailed"
```

**Success Criteria:**
- [ ] Test project created
- [ ] Unit tests implemented for all 7 methods
- [ ] Integration tests implemented
- [ ] All tests pass against PostgreSQL database
- [ ] Test coverage > 80%

## Quick Verification Script

Save this as `verify_migration.sh`:

```bash
#!/bin/bash

echo "=== PostgreSQL Migration Verification ==="
echo ""

# Check PostgreSQL is running
echo "1. Checking PostgreSQL..."
if pg_isready -h localhost -p 5432; then
    echo "✓ PostgreSQL is running"
else
    echo "✗ PostgreSQL is not running"
    exit 1
fi

# Check database exists
echo "2. Checking database..."
if psql -U postgres -lqt | cut -d \| -f 1 | grep -qw ProductManagement; then
    echo "✓ ProductManagement database exists"
else
    echo "✗ ProductManagement database not found"
    exit 1
fi

# Check tables exist
echo "3. Checking tables..."
TABLE_COUNT=$(psql -U postgres -d ProductManagement -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'")
if [ "$TABLE_COUNT" -ge 5 ]; then
    echo "✓ Database tables exist ($TABLE_COUNT tables)"
else
    echo "✗ Missing database tables"
    exit 1
fi

# Check sample data
echo "4. Checking sample data..."
PRODUCT_COUNT=$(psql -U postgres -d ProductManagement -tAc "SELECT COUNT(*) FROM products")
if [ "$PRODUCT_COUNT" -ge 18 ]; then
    echo "✓ Sample data loaded ($PRODUCT_COUNT products)"
else
    echo "✗ Missing sample data"
    exit 1
fi

# Try to build application
echo "5. Building application..."
cd sourceCode
if dotnet build > /dev/null 2>&1; then
    echo "✓ Application builds successfully"
else
    echo "✗ Build failed"
    exit 1
fi

echo ""
echo "=== All verification checks passed ==="
echo "You can now run the application with: dotnet run"
```

Make executable:
```bash
chmod +x verify_migration.sh
./verify_migration.sh
```

## Summary

### To Complete Runtime Verification:

1. **Set up PostgreSQL database** (30 minutes)
   - Install PostgreSQL
   - Run setup script
   - Verify sample data

2. **Test database operations** (1 hour)
   - Test all 7 repository methods
   - Verify data in PostgreSQL after each operation
   - Check ProductHistory and ProductStats updates

3. **Test transaction integrity** (30 minutes)
   - Verify successful transactions
   - Test rollback scenarios
   - Validate data consistency

4. **Create and run tests** (2-4 hours)
   - Create test project
   - Implement unit tests
   - Implement integration tests
   - Achieve passing test suite

**Total Estimated Time:** 4-6 hours

## Notes

- Criteria 12-14 are runtime environment dependent
- Criterion 15 requires test infrastructure creation
- All code changes are complete and compile successfully
- The application is ready for runtime testing once PostgreSQL is set up
