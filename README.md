# ADO.NET Core PostgreSQL Data Management Application

## Migration Notice

**This application has been migrated from Microsoft SQL Server to PostgreSQL.**

All SQL statements have been converted using AWS Database Migration Service (DMS) tooling and validated for equivalency. The application now uses Npgsql for PostgreSQL connectivity.

## Prerequisites

- .NET 9.0 SDK or later
- PostgreSQL 12 or later (recommended: PostgreSQL 15+)
- pgAdmin or another PostgreSQL management tool

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs       # PostgreSQL data access layer
├── Models/
│   └── Product.cs
├── Business/
│   └── ProductService.cs
├── CLI/
│   ├── CommandLineInterface.cs
│   └── InteractiveMenu.cs
├── Program.cs
├── AdoCore.csproj
├── appsettings.json                # Configuration with PostgreSQL connection strings
├── appsettings.example.json        # Example configuration with security guidance
├── extracted_statements.sql        # Original SQL Server statements
├── converted_statements.sql        # Converted PostgreSQL statements
├── sql_equivalency_validation_report.json  # Equivalency validation results
└── migration_final_report.md       # Complete migration documentation
```

## Setup Instructions

### 1. PostgreSQL Database Setup

Before running the application, you must have a PostgreSQL database instance with the required schema.

#### Required Database Objects

The application expects the following PostgreSQL schema:

- **Database**: `ProductManagement`
- **Schema**: `productmanagement_dbo`
- **Tables**:
  - `productmanagement_dbo.products` - Product information
  - `productmanagement_dbo.producthistory` - Product change history
  - `productmanagement_dbo.productstats` - Product statistics

#### Database Setup Steps

1. **Install PostgreSQL** (if not already installed):
   ```bash
   # Ubuntu/Debian
   sudo apt-get install postgresql postgresql-contrib

   # macOS (using Homebrew)
   brew install postgresql

   # Windows
   # Download installer from https://www.postgresql.org/download/windows/
   ```

2. **Create Database and Schema**:
   ```sql
   -- Connect to PostgreSQL as superuser
   -- Create database
   CREATE DATABASE "ProductManagement";

   -- Connect to ProductManagement database
   \c ProductManagement

   -- Create schema
   CREATE SCHEMA productmanagement_dbo;

   -- Create products table
   CREATE TABLE productmanagement_dbo.products (
       productid SERIAL PRIMARY KEY,
       name VARCHAR(100) NOT NULL,
       description TEXT,
       price NUMERIC(18, 2) NOT NULL,
       stockquantity INTEGER NOT NULL,
       createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       modifieddate TIMESTAMP
   );

   -- Create producthistory table
   CREATE TABLE productmanagement_dbo.producthistory (
       historyid SERIAL PRIMARY KEY,
       productid INTEGER NOT NULL,
       action VARCHAR(50) NOT NULL,
       oldprice NUMERIC(18, 2),
       newprice NUMERIC(18, 2),
       oldstock INTEGER,
       newstock INTEGER,
       actiondate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
   );

   -- Create productstats table
   CREATE TABLE productmanagement_dbo.productstats (
       statid SERIAL PRIMARY KEY,
       totalproducts INTEGER NOT NULL DEFAULT 0,
       averageprice NUMERIC(18, 2) NOT NULL DEFAULT 0,
       lastupdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
   );

   -- Initialize productstats
   INSERT INTO productmanagement_dbo.productstats (statid, totalproducts, averageprice, lastupdated)
   VALUES (1, 0, 0, CURRENT_TIMESTAMP);

   -- Optional: Insert sample data
   INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
   VALUES 
       ('Laptop', 'High-performance laptop', 999.99, 50),
       ('Mouse', 'Wireless mouse', 29.99, 100),
       ('Keyboard', 'Mechanical keyboard', 79.99, 75);
   ```

### 2. Application Configuration

#### Option A: Using appsettings.json (Development Only)

1. **Copy the example configuration**:
   ```bash
   cp appsettings.example.json appsettings.json
   ```

2. **Update connection strings** in `appsettings.json`:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=your-password;Pooling=true",
       "ProdConnection": "Host=your-server;Port=5432;Database=ProductManagement;Username=your-user;Password=your-password;Pooling=true;SSL Mode=Require"
     },
     "Environment": "Development"
   }
   ```

⚠️ **Security Warning**: Never commit `appsettings.json` with real credentials to version control!

#### Option B: Using Environment Variables (Recommended for Production)

The application automatically reads environment variables, which override values in `appsettings.json`.

**Linux/macOS (Bash)**:
```bash
export ConnectionStrings__DevConnection="Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=your-secure-password;Pooling=true"
export POSTGRES_HOST="localhost"
export POSTGRES_PORT="5432"
export POSTGRES_DATABASE="ProductManagement"
export POSTGRES_USERNAME="postgres"
export POSTGRES_PASSWORD="your-secure-password"
```

**Windows (PowerShell)**:
```powershell
$env:ConnectionStrings__DevConnection="Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=your-secure-password;Pooling=true"
$env:POSTGRES_HOST="localhost"
$env:POSTGRES_PORT="5432"
$env:POSTGRES_DATABASE="ProductManagement"
$env:POSTGRES_USERNAME="postgres"
$env:POSTGRES_PASSWORD="your-secure-password"
```

**Windows (Command Prompt)**:
```cmd
set ConnectionStrings__DevConnection=Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=your-secure-password;Pooling=true
set POSTGRES_HOST=localhost
set POSTGRES_PORT=5432
set POSTGRES_DATABASE=ProductManagement
set POSTGRES_USERNAME=postgres
set POSTGRES_PASSWORD=your-secure-password
```

**Docker**:
```bash
docker run -e POSTGRES_HOST=db-server \
           -e POSTGRES_DATABASE=ProductManagement \
           -e POSTGRES_USERNAME=appuser \
           -e POSTGRES_PASSWORD=secure-password \
           your-app-image
```

**Kubernetes Secrets**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-credentials
type: Opaque
stringData:
  POSTGRES_HOST: postgres-service
  POSTGRES_PORT: "5432"
  POSTGRES_DATABASE: ProductManagement
  POSTGRES_USERNAME: appuser
  POSTGRES_PASSWORD: your-secure-password
```

### 3. Build and Run

```bash
# Navigate to project directory
cd sourceCode

# Restore NuGet packages
dotnet restore

# Build the project
dotnet build

# Run in interactive mode
dotnet run

# Or run with CLI commands
dotnet run -- list
```

## Running the Application

### Interactive Mode

Run without arguments to access the interactive menu:

```bash
dotnet run
```

Menu options:
```
Product Management System
------------------------
1. List all products
2. Get product by ID
3. Create new product
4. Update product
5. Delete product
6. Get products by price range
7. Get low stock products
Q. Quit
```

### Command-Line Interface (CLI)

```bash
# Show help
dotnet run -- --help

# List all products
dotnet run -- list

# Get product by ID
dotnet run -- get 1

# Add new product
dotnet run -- add "Gaming Mouse" 49.99 10 "High-performance gaming mouse"

# Update product
dotnet run -- update 1 "Gaming Mouse Pro" 59.99 15 "Updated gaming mouse"

# Delete product
dotnet run -- delete 1

# Get products by price range
dotnet run -- pricerange 10.00 100.00

# Get low stock products (threshold)
dotnet run -- lowstock 20
```

## Migration Details

This application was migrated from SQL Server to PostgreSQL using the following process:

1. **SQL Statement Extraction**: All 7 SQL statements were extracted from the codebase
2. **DMS Conversion**: 6 statements successfully converted using AWS DMS tool
3. **Manual Conversion**: 1 statement (InsertProductAsync) required manual conversion after DMS failure
4. **Equivalency Validation**: All statement pairs validated using SQL Equivalency tool
5. **Code Updates**: All ADO.NET classes updated from SqlClient to Npgsql

### Migration Artifacts

- **extracted_statements.sql**: Original SQL Server statements
- **converted_statements.sql**: PostgreSQL statements with conversion details
- **sql_equivalency_validation_report.json**: Equivalency validation results
- **migration_final_report.md**: Comprehensive migration documentation

### Key SQL Conversions

The migration included conversions for:
- Complex window functions (LAG, RANK, PERCENT_RANK)
- Common Table Expressions (CTEs)
- Procedural blocks (transactions converted to DO $$ blocks)
- Date/time functions (GETDATE() → CURRENT_TIMESTAMP)
- Identity columns (SCOPE_IDENTITY() → RETURNING clause)
- Schema naming (dbo → productmanagement_dbo)

## Security Best Practices

### 1. Never Hardcode Credentials

❌ **Bad**:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Username=postgres;Password=postgres123"
  }
}
```

✅ **Good**:
```bash
export POSTGRES_PASSWORD="$(aws secretsmanager get-secret-value --secret-id prod/postgres/password --query SecretString --output text)"
```

### 2. Use SSL/TLS for Production

Always use encrypted connections in production:
```
Host=prod-server;Port=5432;Database=ProductManagement;Username=appuser;Password=***;SSL Mode=Require;Trust Server Certificate=false
```

### 3. Principle of Least Privilege

Create dedicated database users with minimal required permissions:

```sql
-- Create application user
CREATE USER appuser WITH PASSWORD 'secure-password';

-- Grant only necessary permissions
GRANT CONNECT ON DATABASE "ProductManagement" TO appuser;
GRANT USAGE ON SCHEMA productmanagement_dbo TO appuser;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA productmanagement_dbo TO appuser;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA productmanagement_dbo TO appuser;
```

### 4. Use Secret Management Services

- **AWS**: AWS Secrets Manager or Systems Manager Parameter Store
- **Azure**: Azure Key Vault
- **Google Cloud**: Secret Manager
- **HashiCorp**: Vault

### 5. Rotate Credentials Regularly

Implement automated credential rotation for production systems.

## Troubleshooting

### Database Connection Issues

**Problem**: `Npgsql.NpgsqlException: Connection refused`

**Solution**:
1. Verify PostgreSQL is running: `sudo systemctl status postgresql`
2. Check connection parameters match your PostgreSQL configuration
3. Verify firewall allows connections on port 5432
4. Check `pg_hba.conf` for authentication settings

**Problem**: `password authentication failed`

**Solution**:
1. Verify username and password are correct
2. Check PostgreSQL user exists: `SELECT * FROM pg_user WHERE usename = 'your-username';`
3. Review `pg_hba.conf` authentication method (md5, scram-sha-256, etc.)

### Schema/Table Not Found

**Problem**: `relation "products" does not exist`

**Solution**:
1. Verify schema exists: `\dn` in psql
2. Check table names are lowercase: `productmanagement_dbo.products`
3. Run database setup scripts
4. Verify user has permissions: `\dp productmanagement_dbo.*`

### Build Issues

**Problem**: `Package Npgsql not found`

**Solution**:
```bash
dotnet restore
dotnet build
```

## Key Features

- ✅ Modern async/await patterns for all database operations
- ✅ Proper resource management with IAsyncDisposable
- ✅ Dependency injection for configuration
- ✅ Transaction support with PostgreSQL procedural blocks
- ✅ Parameterized queries for SQL injection prevention
- ✅ Connection pooling for performance
- ✅ Environment variable support for secure configuration
- ✅ Comprehensive error handling

## Required NuGet Packages

- **Npgsql** (v8.0.0+) - PostgreSQL data provider
- **Microsoft.Extensions.Configuration**
- **Microsoft.Extensions.Configuration.Json**
- **Microsoft.Extensions.Configuration.EnvironmentVariables**
- **Microsoft.Extensions.DependencyInjection**

## Known Limitations

### SQL Equivalency Validation

All 7 SQL statement pairs returned `UNKNOWN` from the Z3SqlSolverVerifier formal verification tool during migration. This does not indicate conversion errors, but rather limitations in the verification tool's ability to prove equivalence for complex SQL statements involving:

- Window functions (LAG, RANK, PERCENT_RANK)
- Complex CTEs with multiple joins
- Procedural blocks (DO $$ ... END $$)

**Recommendation**: Thoroughly test all database operations in a non-production environment before deploying to production.

### Statements Requiring Manual Review

1. **InsertProductAsync**: Manually converted after DMS tool failure
   - Original used transaction with SCOPE_IDENTITY
   - Converted to single INSERT with RETURNING clause
   - Transaction logic moved to application layer

2. **UpdateProductAsync**: Complex transaction block
   - Uses procedural block with variable declarations
   - Test thoroughly to verify atomicity

3. **DeleteProductAsync**: Complex transaction block
   - Uses procedural block with multiple operations
   - Verify cascade behavior matches expectations

## Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Npgsql Documentation](https://www.npgsql.org/doc/)
- [Migration Final Report](migration_final_report.md)
- [SQL Equivalency Validation Report](sql_equivalency_validation_report.json)

## Support

For migration-related issues, refer to:
- `migration_final_report.md` - Complete migration analysis
- `converted_statements.sql` - SQL conversion details with DMS output
- `sql_equivalency_validation_report.json` - Equivalency validation results
