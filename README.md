# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL (migrated from SQL Server), following best practices for data access and application architecture.

## Migration Status

**✅ Successfully migrated from SQL Server to PostgreSQL**
- All SQL Server ADO.NET components replaced with Npgsql equivalents  
- All SQL statements converted to PostgreSQL syntax
- Database schema converted to PostgreSQL
- Application compiles successfully and is ready for PostgreSQL database
- Comprehensive migration documentation and SQL statement conversion catalog available

## Prerequisites

- Visual Studio 2022 or later (or VS Code)
- .NET 9.0 SDK or later
- **PostgreSQL 12 or later** (PostgreSQL is free and open source)
- pgAdmin 4 or psql command-line tool

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs          # PostgreSQL data access using Npgsql
├── Models/
│   └── Product.cs
├── Business/
│   └── ProductService.cs
├── CLI/
│   ├── CommandLineInterface.cs
│   └── InteractiveMenu.cs
├── Database/
│   ├── Scripts/
│   │   ├── 01_InitialSetup.sql              # Original SQL Server script (reference)
│   │   └── 01_InitialSetup_PostgreSQL.sql   # PostgreSQL schema script
│   └── POSTGRESQL_SETUP_GUIDE.md            # Comprehensive setup guide
├── Program.cs
├── AdoCore.csproj
├── appsettings.json                  # PostgreSQL connection strings
├── extracted_statements.sql          # Catalog of original SQL statements
├── converted_statements.sql          # Catalog of converted PostgreSQL statements
└── sql_equivalency_validation_report.json  # SQL equivalency validation results
```

## Quick Start

### 1. PostgreSQL Database Setup

**IMPORTANT**: Before running the application, you must set up the PostgreSQL database.

#### Option A: Follow the Detailed Guide
See the comprehensive setup guide: `Database/POSTGRESQL_SETUP_GUIDE.md`

#### Option B: Quick Setup (if PostgreSQL is already installed)

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE "ProductManagement";

# Connect to database
\c ProductManagement

# Run schema script
\i Database/Scripts/01_InitialSetup_PostgreSQL.sql

# Exit
\q
```

### 2. Update Connection String

Edit `appsettings.json` and update the password:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD",
    "ProdConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD"
  },
  "Environment": "Development"
}
```

**Security Note**: Replace `YOUR_PASSWORD` with your PostgreSQL password. Never commit passwords to source control.

### 3. Build and Run

```bash
# Restore packages
dotnet restore

# Build
dotnet build

# Run in interactive mode
dotnet run

# Or run with CLI command
dotnet run -- list
```

## Running the Application

The application supports two modes: Interactive (menu-driven) and Command-Line Interface (CLI).

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
6. Update product stock
7. Get product statistics
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
dotnet run -- add "Gaming Mouse Pro" 59.99 25 "High-precision gaming mouse with RGB"

# Update product
dotnet run -- update 1 "Updated Name" 69.99 30 "Updated description"

# Delete product
dotnet run -- delete 1

# Update stock quantity
dotnet run -- stock 1 50
```

## Key Features

- **PostgreSQL Integration**: Full PostgreSQL support using Npgsql
- **Async/Await Patterns**: Modern asynchronous database operations
- **Transaction Support**: Atomic operations with proper rollback
- **Parameterized Queries**: Protection against SQL injection
- **Connection Pooling**: Efficient database connection management
- **Error Handling**: Comprehensive exception handling and logging
- **Dependency Injection**: Clean architecture with DI pattern
- **Resource Management**: Proper disposal with IAsyncDisposable

## Database Schema

### Tables
- **products** - Main product catalog (lowercase per PostgreSQL convention)
- **categories** - Product categories with hierarchical structure
- **suppliers** - Supplier information
- **producthistory** - Audit trail for all product changes
- **productstats** - Aggregated product statistics

### Key Differences from SQL Server
- All table and column names use lowercase (PostgreSQL best practice)
- SERIAL instead of IDENTITY for auto-increment
- BOOLEAN instead of BIT
- TIMESTAMP instead of DATETIME
- VARCHAR instead of NVARCHAR
- Functions instead of stored procedures

## Testing the Application

### Basic Tests

1. **List all products** (should show 18 sample products):
   ```bash
   dotnet run -- list
   ```

2. **Get product details**:
   ```bash
   dotnet run -- get 1
   ```

3. **Add a new product**:
   ```bash
   dotnet run -- add "Test Product" 29.99 10 "Test Description"
   ```

4. **Update stock quantity**:
   ```bash
   dotnet run -- stock 1 100
   ```

### Integration Testing Checklist

After database setup, verify:
- [ ] List all products returns 18 products
- [ ] Get product by ID retrieves correct details
- [ ] Insert product creates new record with returning ID
- [ ] Update product modifies existing record
- [ ] Delete product removes record
- [ ] Product history trigger logs all changes
- [ ] Transaction rollback works on errors
- [ ] Statistics update correctly

## Migration Documentation

### SQL Statement Conversion
All SQL statements have been systematically converted from SQL Server to PostgreSQL:

1. **extracted_statements.sql** - Original SQL Server statements (7 total)
2. **converted_statements.sql** - PostgreSQL converted statements with detailed notes
3. **sql_equivalency_validation_report.json** - Validation results for each statement pair

### Key SQL Syntax Changes
- `SCOPE_IDENTITY()` → `RETURNING productid`
- `GETDATE()` → `CURRENT_TIMESTAMP`
- `BEGIN TRANSACTION` → Npgsql API `BeginTransactionAsync()`
- Schema names lowercase: `Products` → `products`

## Troubleshooting

### Connection Errors

**Error**: `Connection refused` or `could not connect to server`
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql  # Linux
brew services list                # macOS

# Start PostgreSQL if needed
sudo systemctl start postgresql   # Linux
brew services start postgresql@14 # macOS
```

**Error**: `password authentication failed`
- Verify username and password in `appsettings.json`
- Ensure PostgreSQL user has proper permissions
- Check `pg_hba.conf` authentication method

**Error**: `database "ProductManagement" does not exist`
- Run the database setup script: `Database/Scripts/01_InitialSetup_PostgreSQL.sql`
- See `Database/POSTGRESQL_SETUP_GUIDE.md` for detailed instructions

### Application Errors

**Error**: `relation "products" does not exist`
- Database schema not created - run `01_InitialSetup_PostgreSQL.sql`
- Connected to wrong database - verify connection string

**Error**: `Npgsql package not found`
```bash
dotnet restore
dotnet build
```

## Required NuGet Packages

- **Npgsql** (Version 8.0.5) - PostgreSQL data provider
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

## Security Considerations

1. **Parameterized Queries**: All queries use parameters to prevent SQL injection
2. **No Hardcoded Credentials**: Use environment variables for production passwords
3. **Connection Pooling**: Efficient resource management
4. **Proper Disposal**: All database resources properly disposed
5. **SSL Support**: Enable SSL for production connections
6. **Least Privilege**: Create dedicated user with minimum required permissions

### Production User Setup

```sql
-- Create dedicated application user
CREATE USER appuser WITH PASSWORD 'secure_password_here';

-- Grant necessary privileges
GRANT CONNECT ON DATABASE "ProductManagement" TO appuser;
GRANT USAGE ON SCHEMA public TO appuser;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO appuser;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO appuser;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO appuser;

-- Update connection string to use appuser
-- Host=localhost;Port=5432;Database=ProductManagement;Username=appuser;Password=secure_password_here
```

## Best Practices Implemented

- ✅ Modern async/await patterns throughout
- ✅ Proper resource disposal with IAsyncDisposable
- ✅ Transaction management with async support
- ✅ Comprehensive error handling
- ✅ Dependency injection for loose coupling
- ✅ Separation of concerns (layered architecture)
- ✅ PostgreSQL naming conventions (lowercase)
- ✅ Parameterized queries for security
- ✅ Connection pooling for performance
- ✅ Configuration management via IConfiguration

## Deployment Considerations

### AWS RDS PostgreSQL
1. Create RDS PostgreSQL instance
2. Update connection string with RDS endpoint
3. Configure security groups for database access
4. Run schema script on RDS instance
5. Deploy application to AWS (EC2, ECS, or Lambda)

### Docker Deployment
```dockerfile
# Example PostgreSQL + Application deployment
# See Database/POSTGRESQL_SETUP_GUIDE.md for details
```

## Additional Resources

- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Npgsql Documentation**: https://www.npgsql.org/doc/
- **Migration Guide**: See `Database/POSTGRESQL_SETUP_GUIDE.md`
- **SQL Conversion Catalog**: See `converted_statements.sql`
- **Equivalency Report**: See `sql_equivalency_validation_report.json`

## Support and Troubleshooting

For detailed PostgreSQL setup instructions, troubleshooting, and migration documentation:
- See `Database/POSTGRESQL_SETUP_GUIDE.md`
- Review `sql_equivalency_validation_report.json` for SQL conversion details
- Check `converted_statements.sql` for SQL statement mappings

## Original Application

The original SQL Server version has been preserved as `README_SQLSERVER_ORIGINAL.md` for reference.
