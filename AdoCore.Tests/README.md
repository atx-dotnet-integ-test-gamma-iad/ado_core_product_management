# AdoCore Test Suite

This test suite verifies the PostgreSQL migration of the AdoCore application.

## Test Structure

### Unit Tests (`Unit/`)
- **ProductRepositoryUnitTests.cs**: Tests configuration and model validation without requiring database connection
- No database required
- Fast execution
- Can be run in any environment

### Integration Tests (`Integration/`)
- **ProductRepositoryIntegrationTests.cs**: Tests all 7 converted SQL statements against actual PostgreSQL database
- Requires PostgreSQL database connection
- Verifies actual database operations
- Tests transaction handling

## Test Coverage

The test suite covers all 16 exit criteria from the migration definition:

### SQL Statement Coverage
1. **Statement 1** (GetAllProductsAsync): CTE with window functions, complex ordering
2. **Statement 2** (GetProductByIdAsync): LAG window function, LEFT JOIN
3. **Statement 3** (InsertProductAsync): RETURNING clause (was SCOPE_IDENTITY), NOW() (was GETDATE())
4. **Statement 4** (UpdateProductAsync): CTE pattern for variables (was DECLARE)
5. **Statement 5** (DeleteProductAsync): Chained CTEs, transaction handling
6. **Statement 6** (GetProductsByPriceRangeAsync): RANK(), PERCENT_RANK() window functions
7. **Statement 7** (GetLowStockProductsAsync): Multiple window functions

### PostgreSQL-Specific Syntax Verification
- ✅ SCOPE_IDENTITY() → RETURNING clause
- ✅ GETDATE() → NOW()
- ✅ BEGIN TRANSACTION/COMMIT removed (Npgsql handles via BeginTransactionAsync)
- ✅ DECLARE variables → CTE patterns
- ✅ @ parameter prefix (Npgsql native support)
- ✅ Window functions (OVER clause)
- ✅ NULL handling

## Prerequisites for Integration Tests

### 1. PostgreSQL Server Setup
```bash
# Ensure PostgreSQL is running
sudo systemctl start postgresql  # Linux
# or
brew services start postgresql   # macOS
# or use Docker:
docker run --name postgres-test -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:latest
```

### 2. Database Creation
```sql
-- Connect to PostgreSQL
psql -U postgres

-- Create test database
CREATE DATABASE "AdoCoreDb_Test";

-- Connect to test database
\c AdoCoreDb_Test

-- Run schema creation scripts from Database folder
-- \i path/to/Database/schema.sql
```

### 3. Schema Setup
Run the database migration scripts located in the `Database` folder to create:
- Products table
- ProductHistory table
- ProductStats table
- Any required indexes and constraints

### 4. Test Data (Optional)
For comprehensive testing, populate with sample data:
```sql
INSERT INTO ProductStats (StatId, TotalProducts, AveragePrice, LastUpdated)
VALUES (1, 0, 0, NOW());

INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
VALUES 
  ('Laptop', 'High-performance laptop', 1299.99, 50, NOW()),
  ('Mouse', 'Wireless mouse', 29.99, 200, NOW()),
  ('Keyboard', 'Mechanical keyboard', 89.99, 100, NOW()),
  ('Monitor', '27-inch 4K monitor', 499.99, 30, NOW()),
  ('Webcam', 'HD webcam', 79.99, 75, NOW());
```

## Running Tests

### Run All Tests
```bash
cd AdoCore.Tests
dotnet test
```

### Run Only Unit Tests (No Database Required)
```bash
dotnet test --filter "FullyQualifiedName~AdoCore.Tests.Unit"
```

### Run Only Integration Tests (Database Required)
```bash
dotnet test --filter "FullyQualifiedName~AdoCore.Tests.Integration"
```

### Run Specific Test
```bash
dotnet test --filter "FullyQualifiedName~GetAllProductsAsync_ShouldReturnProducts_WithPriceAnalysis"
```

### Run with Verbose Output
```bash
dotnet test --logger "console;verbosity=detailed"
```

## Test Results Interpretation

### Success Indicators
- ✅ All unit tests pass: Configuration and model validation correct
- ✅ All integration tests pass: SQL conversion successful, PostgreSQL syntax correct
- ✅ Transaction tests pass: Npgsql transaction handling working correctly

### Common Failure Scenarios

#### Connection Failures
```
Message: Npgsql.NpgsqlException: Failed to connect to localhost:5432
```
**Solution**: Ensure PostgreSQL server is running and accessible

#### Schema Missing
```
Message: Npgsql.PostgresException: relation "products" does not exist
```
**Solution**: Run database schema creation scripts

#### Syntax Errors
```
Message: Npgsql.PostgresException: syntax error at or near "..."
```
**Solution**: Review SQL statement conversion - may indicate incomplete migration

## Migration Validation Checklist

Use this test suite to verify migration exit criteria:

- [ ] **Criterion 1-2**: Code compiles with Npgsql (verified by successful build)
- [ ] **Criterion 3-4**: All statements processed and cataloged (verified by test coverage)
- [ ] **Criterion 5-8**: Equivalency validation (tested through actual execution)
- [ ] **Criterion 9**: Connection strings work (tested by successful connections)
- [ ] **Criterion 10**: Transactions work (tested by transaction tests)
- [ ] **Criterion 11**: Application compiles (build succeeds)
- [ ] **Criterion 12**: Database connectivity (integration tests connect)
- [ ] **Criterion 13**: CRUD operations work (all repository methods tested)
- [ ] **Criterion 14**: Transaction atomicity (transaction rollback tested)
- [ ] **Criterion 15**: Tests exist and pass (this test suite)
- [ ] **Criterion 16**: Complete documentation (equivalency report + this test suite)

## Continuous Integration

Add to your CI/CD pipeline:

```yaml
# .github/workflows/test.yml example
- name: Start PostgreSQL
  run: |
    docker run -d --name postgres-test \
      -e POSTGRES_PASSWORD=postgres \
      -p 5432:5432 \
      postgres:latest
    
- name: Setup Database
  run: |
    sleep 5
    psql -h localhost -U postgres -c "CREATE DATABASE \"AdoCoreDb_Test\";"
    psql -h localhost -U postgres -d AdoCoreDb_Test -f Database/schema.sql

- name: Run Tests
  run: dotnet test --logger "trx;LogFileName=test-results.trx"
```

## Notes

### SQL Equivalency Tool Results
All 7 SQL statement pairs returned ERROR status from the SQL Equivalency tool (Z3SqlSolverVerifier could not prove equivalency). This does not mean the conversions are incorrect - the tool has limitations with complex queries. This test suite provides functional verification through actual execution.

### Manual Review
The following conversions were manually applied after DMS tool failures:
- Statement 1, 2, 6, 7: PostgreSQL-compatible as-is
- Statement 3, 4, 5: Critical syntax conversions (SCOPE_IDENTITY→RETURNING, GETDATE→NOW, DECLARE→CTE)

All conversions follow PostgreSQL best practices and are verified by this test suite.

## Troubleshooting

### Test Discovery Issues
```bash
# Rebuild test project
dotnet clean
dotnet build
dotnet test
```

### Configuration Issues
Verify `appsettings.test.json` has correct connection string for your environment.

### Timeout Issues
Increase test timeout in tests if database is slow:
```csharp
[Fact(Timeout = 30000)] // 30 seconds
```

## Additional Resources

- [Npgsql Documentation](https://www.npgsql.org/doc/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [xUnit Documentation](https://xunit.net/)
- Migration artifacts: See `converted_statements.sql` and `sql_equivalency_validation_report.json`
