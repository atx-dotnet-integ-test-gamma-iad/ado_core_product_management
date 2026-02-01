# PostgreSQL Migration - Runtime Testing Guide

## Overview
This guide provides step-by-step instructions for setting up PostgreSQL and performing runtime validation of the migrated application.

## Prerequisites
- .NET 9.0 SDK installed
- PostgreSQL 13+ installed (or Docker for containerized setup)
- Application successfully builds (0 errors)

## Setup Options

### Option 1: Local PostgreSQL Installation

#### Step 1: Install PostgreSQL
```bash
# For Ubuntu/Debian
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib

# For macOS (using Homebrew)
brew install postgresql@15
brew services start postgresql@15

# For Windows
# Download installer from https://www.postgresql.org/download/windows/
```

#### Step 2: Create Database
```bash
# Connect to PostgreSQL as superuser
sudo -u postgres psql

# Or on Windows/macOS
psql -U postgres

# Create database
CREATE DATABASE "ProductManagement";

# Exit psql
\q
```

#### Step 3: Run Initialization Script
```bash
# Run the PostgreSQL initialization script
psql -U postgres -d ProductManagement -f Scripts/01_InitialSetup_PostgreSQL.sql
```

### Option 2: Docker Setup (Recommended for Testing)

#### Step 1: Create Docker Compose File
```yaml
# Save as docker-compose.yml in the project root
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: ProductManagement
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./Scripts/01_InitialSetup_PostgreSQL.sql:/docker-entrypoint-initdb.d/01_InitialSetup.sql

volumes:
  postgres_data:
```

#### Step 2: Start PostgreSQL Container
```bash
docker-compose up -d
```

#### Step 3: Verify Database Setup
```bash
docker exec -it <container_name> psql -U postgres -d ProductManagement -c "SELECT * FROM Products;"
```

## Runtime Validation

### Exit Criterion 12: Application Connects to PostgreSQL

#### Test Connection
```bash
# From the project directory
cd sourceCode
dotnet run -- --test-connection
```

**Expected Result:**
- Connection successful message
- No connection errors

**Success Criteria:**
- Application establishes connection to PostgreSQL database
- Connection pool is initialized
- No authentication or network errors

### Exit Criterion 13: Database Operations Execute Successfully

#### Test Database Operations
```bash
# Test INSERT operation
dotnet run -- add "Test Product" "Test Description" 99.99 50

# Test SELECT operations
dotnet run -- list

# Test UPDATE operation
dotnet run -- update <ProductId> "Updated Name" "Updated Description" 149.99 75

# Test DELETE operation
dotnet run -- delete <ProductId>
```

**Expected Results:**
- INSERT: New product created, ProductId returned
- SELECT: All products retrieved with correct data
- UPDATE: Product successfully updated
- DELETE: Product successfully removed

**Success Criteria:**
- All 7 repository methods execute without SQL errors
- Data is correctly inserted, retrieved, updated, and deleted
- No PostgreSQL syntax errors
- Results match expected behavior

#### Test Each Repository Method
```bash
# Method 1: GetAllProductsAsync
dotnet run -- list

# Method 2: GetProductByIdAsync
dotnet run -- get <ProductId>

# Method 3: InsertProductAsync
dotnet run -- add "New Product" "Description" 199.99 100

# Method 4: UpdateProductAsync
dotnet run -- update <ProductId> "Updated" "Updated Desc" 299.99 150

# Method 5: DeleteProductAsync
dotnet run -- delete <ProductId>

# Method 6: GetProductsByPriceRangeAsync
dotnet run -- price-range 50.00 500.00

# Method 7: GetLowStockProductsAsync
dotnet run -- low-stock 20
```

### Exit Criterion 14: Transaction Atomicity Maintained

#### Test Transaction Commit
```bash
# Test successful transaction (should commit)
dotnet run -- add "Transactional Product" "Test" 99.99 10

# Verify the product was inserted
dotnet run -- list
```

#### Test Transaction Rollback
Manual testing required - modify code temporarily to force a transaction failure:
1. Add a product that should trigger an error in the transaction
2. Verify that no partial data is committed
3. Verify database state is consistent

**Expected Results:**
- Successful operations commit all changes
- Failed operations rollback completely
- No partial data left in database
- ProductHistory table updated correctly

**Success Criteria:**
- All transaction operations complete atomically
- COMMIT successfully persists all changes
- ROLLBACK successfully reverts all changes
- No data inconsistencies

### Exit Criterion 15: Application Passes Tests

#### Current Status
**No test suite exists in the repository**

#### Recommended Actions
1. **Create Unit Tests**
   - Test repository methods with mock database
   - Test business logic in isolation
   - Use xUnit or NUnit framework

2. **Create Integration Tests**
   - Test against actual PostgreSQL test database
   - Verify end-to-end functionality
   - Test transaction scenarios

3. **Example Test Structure**
```bash
# Create test project
dotnet new xunit -n AdoCore.Tests
cd AdoCore.Tests
dotnet add reference ../AdoCore.csproj
dotnet add package Npgsql
dotnet add package Testcontainers.PostgreSql

# Run tests
dotnet test
```

## Validation Checklist

### Pre-Runtime Validation (Completed)
- [x] Application compiles without errors
- [x] All SQL statements converted to PostgreSQL syntax
- [x] All ADO.NET classes replaced with Npgsql
- [x] Connection strings updated to PostgreSQL format
- [x] Npgsql package upgraded to secure version (8.0.5+)

### Runtime Validation (To Be Completed)
- [ ] PostgreSQL database installed and running
- [ ] Database schema created (Products, ProductHistory, ProductStats tables)
- [ ] Application successfully connects to PostgreSQL
- [ ] INSERT operations execute successfully
- [ ] SELECT operations execute successfully
- [ ] UPDATE operations execute successfully
- [ ] DELETE operations execute successfully
- [ ] Complex queries with CTEs execute successfully
- [ ] Window functions execute correctly
- [ ] Transaction COMMIT works correctly
- [ ] Transaction ROLLBACK works correctly
- [ ] ProductHistory table is updated correctly
- [ ] ProductStats table is updated correctly

### Security Validation (To Be Completed)
- [ ] Move hardcoded credentials to secure configuration
  - Use environment variables
  - Use Azure Key Vault or similar secret management
  - Use user secrets for development
- [ ] Review connection string security
- [ ] Implement proper error handling for security exceptions

## Known Issues and Recommendations

### SQL Equivalency Status
- **2 EQUIVALENT**: UPDATE and DELETE operations validated
- **5 ERROR/UNKNOWN**: Complex queries with CTEs and window functions
  - Tool could not formally verify equivalency
  - Requires runtime testing to confirm correctness
  - Statements follow PostgreSQL best practices

### Security Recommendations
1. **Immediate**: Remove hardcoded passwords from appsettings.json
   ```bash
   dotnet user-secrets init
   dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD"
   ```

2. **Production**: Use managed identity or secure credential storage

### Performance Considerations
- Connection pooling is enabled in connection string
- Consider adding indexes for frequently queried columns
- Monitor query performance with EXPLAIN ANALYZE

## Troubleshooting

### Connection Issues
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql  # Linux
brew services list                # macOS
# Check Windows Services           # Windows

# Check PostgreSQL logs
tail -f /var/log/postgresql/postgresql-15-main.log  # Linux
```

### Permission Issues
```sql
-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE "ProductManagement" TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
```

### SQL Syntax Errors
- Review converted_statements.sql for the converted SQL
- Compare with extracted_statements.sql for original SQL
- Check sql_equivalency_validation_report.json for conversion details

## Next Steps

1. **Complete Runtime Testing**
   - Follow the steps in this guide
   - Document all test results
   - Update validation summary with results

2. **Address Security Issues**
   - Move credentials to secure storage
   - Implement proper error handling
   - Review access controls

3. **Create Test Suite**
   - Add unit tests for business logic
   - Add integration tests for database operations
   - Implement CI/CD pipeline

4. **Production Readiness**
   - Performance testing and optimization
   - Load testing
   - Disaster recovery planning
   - Monitoring and alerting setup
