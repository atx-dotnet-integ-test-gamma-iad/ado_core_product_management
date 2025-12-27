# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture.

## Migration Status

This application has been migrated from Microsoft SQL Server to PostgreSQL:
- ✅ All SQL Server packages replaced with Npgsql
- ✅ All ADO.NET classes updated to Npgsql equivalents
- ✅ All SQL statements converted and validated
- ✅ Connection strings updated to PostgreSQL format
- ✅ Application compiles successfully

## Prerequisites

- Visual Studio 2022 or later (optional)
- .NET 9.0 SDK or later
- PostgreSQL 12 or later (recommended: PostgreSQL 15+)
- pgAdmin 4 or any PostgreSQL client tool

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs
├── Models/
│   └── Product.cs
├── Business/
│   └── ProductService.cs
├── CLI/
│   ├── CommandLineInterface.cs
│   └── InteractiveMenu.cs
├── Database/
│   └── Scripts/
│       ├── 01_InitialSetup.sql (SQL Server - legacy)
│       └── 01_InitialSetup_PostgreSQL.sql (PostgreSQL - use this)
├── Program.cs
├── AdoCore.csproj
└── appsettings.json
```

## Setup Instructions

### Step 1: Install PostgreSQL

1. **Download and Install PostgreSQL**:
   - Visit https://www.postgresql.org/download/
   - Download PostgreSQL 15+ for your operating system
   - During installation, set a password for the `postgres` user (remember this!)
   - Default port is 5432 (keep this unless you have conflicts)

2. **Verify Installation**:
   ```bash
   # Check PostgreSQL is running
   psql --version
   # Should show: psql (PostgreSQL) 15.x or later
   ```

### Step 2: Create Database Schema

**Option A: Using psql command line**

```bash
# Connect to PostgreSQL as postgres user
psql -U postgres -h localhost

# Create database
CREATE DATABASE ProductManagement;

# Connect to the new database
\c ProductManagement

# Run the setup script
\i Database/Scripts/01_InitialSetup_PostgreSQL.sql

# Verify tables were created
\dt

# Exit psql
\q
```

**Option B: Using pgAdmin 4**

1. Open pgAdmin 4
2. Connect to your PostgreSQL server (localhost)
3. Right-click on "Databases" → Create → Database
4. Name it "ProductManagement"
5. Open Query Tool (Tools → Query Tool)
6. Open file: `Database/Scripts/01_InitialSetup_PostgreSQL.sql`
7. Execute the script (F5 or click Execute button)
8. Verify tables in the left panel under ProductManagement → Schemas → public → Tables

### Step 3: Update Connection String

1. Open `appsettings.json`
2. Update the connection string with your PostgreSQL credentials:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD_HERE;Pooling=true",
    "ProdConnection": "your-production-connection-string"
  },
  "Environment": "Development"
}
```

**Important**: Replace `YOUR_PASSWORD_HERE` with the password you set during PostgreSQL installation.

### Step 4: Build the Application

**Using Visual Studio:**
1. Open Visual Studio 2022
2. Select "Open a project or solution"
3. Navigate to the project folder and select `AdoCore.csproj`
4. Press F6 to build
5. Ensure build succeeds with 0 errors

**Using Command Line:**
```bash
# Navigate to project directory
cd /path/to/AdoCore/sourceCode

# Restore NuGet packages
dotnet restore

# Build the project
dotnet build

# Should show: Build succeeded. 0 Error(s)
```

### Step 5: Run the Application

**Interactive Mode:**
```bash
dotnet run
```

You'll see the main menu:
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
```

**CLI Mode:**
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

# Update stock quantity
dotnet run -- stock 1 20
```

## Migration Details

### SQL Statements Converted

All 7 SQL statements in the application were processed through AWS DMS and validated:
- `GetAllProductsAsync`: WITH clause with window functions (ROW_NUMBER, SUM, COUNT)
- `GetProductByIdAsync`: WITH clause with LAG window function
- `InsertProductAsync`: INSERT with RETURNING clause (replaces SCOPE_IDENTITY())
- `UpdateProductAsync`: UPDATE with transaction handling
- `DeleteProductAsync`: DELETE with transaction handling
- `GetProductsByPriceRangeAsync`: WITH clause with RANK and PERCENT_RANK functions
- `GetLowStockProductsAsync`: WITH clause with AVG, MIN, MAX window functions

### Key Changes from SQL Server

1. **Package Changes**:
   - ❌ Removed: `Microsoft.Data.SqlClient`
   - ✅ Added: `Npgsql 8.0.1`

2. **ADO.NET Classes**:
   - `SqlConnection` → `NpgsqlConnection`
   - `SqlCommand` → `NpgsqlCommand`
   - `SqlDataReader` → `NpgsqlDataReader`

3. **SQL Syntax Changes**:
   - `SCOPE_IDENTITY()` → `RETURNING productid`
   - `GETDATE()` → `CURRENT_TIMESTAMP` or `clock_timestamp()`
   - `LEFT JOIN` → `LEFT OUTER JOIN`
   - All table/column names converted to lowercase
   - `NULLS FIRST` added to ORDER BY clauses

4. **Connection String**:
   - Old: `Server=localhost;Database=ProductManagement;Trusted_Connection=True`
   - New: `Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=***`

## Testing the Application

After setting up the database, test each feature:

1. **List all products** (should show 19 sample products):
   ```bash
   dotnet run -- list
   ```

2. **Get specific product**:
   ```bash
   dotnet run -- get 1
   ```

3. **Add a new product**:
   ```bash
   dotnet run -- add "Test Product" 29.99 5 "Test Description"
   ```

4. **Update the product**:
   ```bash
   dotnet run -- update 20 "Updated Product" 39.99 10 "Updated Description"
   ```

5. **Check product history** (via SQL):
   ```sql
   SELECT * FROM producthistory ORDER BY actiondate DESC LIMIT 10;
   ```

6. **Delete the test product**:
   ```bash
   dotnet run -- delete 20
   ```

## Troubleshooting

### Connection Issues

**Error: "could not connect to server"**
- Verify PostgreSQL is running: `sudo systemctl status postgresql` (Linux) or check Services (Windows)
- Check port 5432 is not blocked by firewall
- Verify connection string has correct host, port, and credentials

**Error: "password authentication failed"**
- Double-check password in `appsettings.json`
- Verify postgres user password is correct
- Try connecting with psql: `psql -U postgres -h localhost`

**Error: "database does not exist"**
- Create the database: `CREATE DATABASE ProductManagement;`
- Run the setup script: `\i Database/Scripts/01_InitialSetup_PostgreSQL.sql`

### Build Issues

**Error: Package 'Npgsql' not found**
- Run: `dotnet restore`
- Check internet connection
- Clear NuGet cache: `dotnet nuget locals all --clear`

**Warning: Nullable reference types**
- These are warnings only, not errors
- Application will compile and run successfully
- Can be addressed as code quality improvements

### Runtime Issues

**Error: "relation does not exist"**
- Tables not created - run `01_InitialSetup_PostgreSQL.sql`
- Check you're connected to correct database
- Verify schema is 'public' (default)

**Error: "column does not exist"**
- Column names in PostgreSQL are case-sensitive when quoted
- Ensure all column names are lowercase (handled by migration)

## Required NuGet Packages

- Npgsql (PostgreSQL driver)
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

## Key Features

- ✅ Modern async/await patterns for all database operations
- ✅ Proper resource management with IAsyncDisposable
- ✅ Dependency injection for configuration
- ✅ Transaction support with async operations
- ✅ Parameterized queries for security
- ✅ Connection pooling and management
- ✅ Error handling and logging
- ✅ PostgreSQL-specific optimizations

## Migration Artifacts

The following files document the complete migration process:

- `extracted_statements.sql` - All original SQL Server statements
- `converted_statements.sql` - All converted PostgreSQL statements
- `dms_conversion_log.json` - Detailed DMS conversion log
- `sql_equivalency_validation_report.json` - Equivalency validation results
- `final_migration_report.json` - Complete migration summary

## Production Deployment

For production deployment to PostgreSQL:

1. Create production PostgreSQL database
2. Run `01_InitialSetup_PostgreSQL.sql` on production database
3. Update `appsettings.json` with production connection string
4. Consider using environment variables for sensitive data:
   ```bash
   export ConnectionStrings__DevConnection="Host=prod-server;Port=5432;Database=ProductManagement;Username=app_user;Password=secure_password"
   ```
5. Enable SSL/TLS for production: Add `SslMode=Require` to connection string
6. Use connection pooling (already configured)
7. Set appropriate user permissions (principle of least privilege)

## Security Considerations

- ✅ All database queries use parameterization to prevent SQL injection
- ✅ Connection strings stored in configuration (use secrets management in production)
- ✅ Proper error handling and logging implemented
- ✅ All database resources properly disposed using async patterns
- ⚠️ Default credentials in appsettings.json - change for production
- ⚠️ Consider using Azure Key Vault or AWS Secrets Manager for production secrets

## Support and Documentation

- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Npgsql Documentation: https://www.npgsql.org/doc/
- .NET Documentation: https://docs.microsoft.com/dotnet/

## License

See LICENSE file for details.
