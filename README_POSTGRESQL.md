# ADO.NET Core PostgreSQL Data Management Application

**Migration Status:** This application has been successfully migrated from SQL Server to PostgreSQL using AWS Database Migration Service (DMS) conversion tools.

## Overview

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture. All SQL statements have been converted from SQL Server to PostgreSQL syntax, and the application has been updated to use Npgsql (PostgreSQL .NET driver).

## Prerequisites

- Visual Studio 2022 or later (optional)
- .NET 9.0 SDK or later
- PostgreSQL 13 or later (version 15 recommended)
- pgAdmin 4 or psql CLI (for database management)

## Migration Completed

✅ All SQL Server packages replaced with Npgsql 8.0.5  
✅ All ADO.NET classes migrated (SqlConnection → NpgsqlConnection, etc.)  
✅ All 7 SQL statements converted to PostgreSQL syntax  
✅ Connection strings updated to PostgreSQL format  
✅ Transaction handling updated for PostgreSQL  
✅ Application compiles successfully

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs (Updated for PostgreSQL/Npgsql)
├── Models/
│   └── Product.cs
├── Business/
│   └── ProductService.cs
├── CLI/
│   ├── CommandLineInterface.cs
│   └── InteractiveMenu.cs
├── Database/
│   └── Scripts/
│       ├── 01_InitialSetup.sql (Original SQL Server script)
│       └── 02_PostgreSQL_Setup.sql (NEW - PostgreSQL setup script)
├── Program.cs
├── AdoCore.csproj (Updated with Npgsql)
├── appsettings.json (Updated for PostgreSQL)
├── POSTGRESQL_TESTING_GUIDE.md (NEW - Complete testing instructions)
└── README_POSTGRESQL.md (This file)
```

## Quick Start - PostgreSQL Setup

### Option 1: Using Docker (Recommended for Testing)

```bash
# Pull and run PostgreSQL in Docker
docker run --name adocore-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=ProductManagement \
  -p 5432:5432 \
  -d postgres:15

# Verify running
docker ps | grep adocore-postgres

# Execute setup script
docker exec -i adocore-postgres psql -U postgres -d ProductManagement < Database/Scripts/02_PostgreSQL_Setup.sql
```

### Option 2: Using Local PostgreSQL

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE "ProductManagement";

# Exit psql
\q

# Execute setup script
psql -U postgres -d ProductManagement -f Database/Scripts/02_PostgreSQL_Setup.sql
```

### Option 3: Using pgAdmin

1. Open pgAdmin and connect to your PostgreSQL server
2. Right-click on "Databases" → Create → Database
3. Name: `ProductManagement`
4. Open Query Tool for the ProductManagement database
5. Load and execute: `Database/Scripts/02_PostgreSQL_Setup.sql`

## Configuration

Update `appsettings.json` with your PostgreSQL credentials:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Pooling=true",
    "ProdConnection": "Host=your-prod-host;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Pooling=true;SSL Mode=Require"
  },
  "Environment": "Development"
}
```

**For Docker setup, use:**
```json
"DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true"
```

## Building and Running

```bash
# Navigate to source directory
cd sourceCode

# Restore packages (Npgsql will be installed)
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

### Command-Line Interface (CLI)

```bash
# Show help
dotnet run -- --help

# List all products (tests complex CTE with window functions)
dotnet run -- list

# Get product by ID (tests CTE with LAG window function)
dotnet run -- get 1

# Add new product (tests INSERT with RETURNING)
dotnet run -- add "Gaming Mouse" 49.99 10 "High-performance gaming mouse"

# Update product (tests multi-statement transaction)
dotnet run -- update 1 "Gaming Mouse Pro" 59.99 15 "Updated gaming mouse"

# Delete product (tests DELETE with transaction)
dotnet run -- delete 1

# Update stock quantity
dotnet run -- stock 1 20
```

## Migration Details

### SQL Statements Converted

All 7 SQL statements have been converted from SQL Server to PostgreSQL:

1. **GetAllProductsAsync** - CTE with window functions (AVG OVER, COUNT OVER)
2. **GetProductByIdAsync** - CTE with LAG window function
3. **InsertProductAsync** - Multi-statement transaction with RETURNING clause
4. **UpdateProductAsync** - Multi-statement transaction with history tracking
5. **DeleteProductAsync** - Multi-statement transaction with history tracking
6. **GetProductsByPriceRangeAsync** - CTE with RANK and PERCENT_RANK window functions
7. **GetLowStockProductsAsync** - Window functions with aggregations

### Key PostgreSQL Syntax Changes

- `GETDATE()` → `CURRENT_TIMESTAMP` or `NOW()`
- `SCOPE_IDENTITY()` → `RETURNING` clause
- Schema: All tables prefixed with `productmanagement_dbo.`
- Table/column names: Converted to lowercase (PostgreSQL standard)
- `BEGIN TRANSACTION` → Application-level transaction management
- `IDENTITY(1,1)` → `SERIAL` or `GENERATED ALWAYS AS IDENTITY`

### Package Changes

**Removed:**
- Microsoft.Data.SqlClient

**Added:**
- Npgsql 8.0.5

### Class Replacements

- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`
- `SqlParameter` → `NpgsqlParameter`
- `SqlTransaction` → `NpgsqlTransaction`

## Testing

For comprehensive testing instructions, see **POSTGRESQL_TESTING_GUIDE.md**.

### Quick Validation

```bash
# Test database connectivity
dotnet run -- list

# Expected: Lists 18 sample products from PostgreSQL database

# Test INSERT operation
dotnet run -- add "Test Product" 99.99 50 "Test Description"

# Expected: Returns new ProductId, creates history record, updates stats

# Verify in PostgreSQL
psql -U postgres -d ProductManagement -c "SELECT * FROM productmanagement_dbo.products ORDER BY productid DESC LIMIT 1;"
```

## PostgreSQL Features Used

- **Window Functions**: LAG, RANK, PERCENT_RANK, AVG OVER, COUNT OVER
- **Common Table Expressions (CTEs)**: WITH clauses
- **CASE Expressions**: Conditional logic
- **JOINS**: INNER JOIN, LEFT OUTER JOIN
- **Aggregate Functions**: AVG, COUNT, SUM, MIN, MAX
- **Transaction Management**: BEGIN, COMMIT, ROLLBACK
- **RETURNING Clause**: Get inserted/updated values

## Troubleshooting

### Issue: "Npgsql.PostgresException: relation does not exist"
**Solution:** Ensure you've run the `02_PostgreSQL_Setup.sql` script.

### Issue: "column does not exist"
**Solution:** PostgreSQL uses lowercase column names. Check your queries use lowercase.

### Issue: "Connection refused"
**Solution:** Verify PostgreSQL is running:
```bash
# Check PostgreSQL status
sudo systemctl status postgresql
# or for Docker
docker ps | grep postgres
```

### Issue: "password authentication failed"
**Solution:** Update `appsettings.json` with correct PostgreSQL credentials.

### Issue: SSL connection error
**Solution:** For local development, add `SSL Mode=Disable` to connection string.

## Required NuGet Packages

- Npgsql (8.0.5)
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

## Security Considerations

- All database queries use parameterization to prevent SQL injection
- Connection strings stored securely in configuration
- Proper error handling and logging implemented
- All database resources properly disposed using async patterns
- SSL/TLS support for production environments

## Best Practices Implemented

- Modern async/await patterns throughout
- Proper resource disposal with IAsyncDisposable
- Transaction management with async support
- Comprehensive error handling
- Configuration management using .NET Core's IConfiguration
- Parameterized queries for security
- Dependency injection
- Separation of concerns (layered architecture)

## Migration Artifacts

The following artifacts document the complete migration process:

- `extracted_statements.sql` - Original SQL Server statements
- `converted_statements.sql` - Converted PostgreSQL statements
- `sql_equivalency_validation_report.json` - Equivalency validation results
- `dms_conversion_log.json` - DMS conversion process log
- `ado_class_migration_log.json` - ADO.NET class replacements
- `connection_string_migration_log.json` - Connection string transformations
- `final_migration_report.json` - Complete migration summary

## What's Next

### Remaining Validation Steps (Require PostgreSQL Database)

The code-level migration is complete. The following validation steps require access to a running PostgreSQL database:

1. **Database Connectivity Testing** - Test connection to PostgreSQL
2. **Database Operations Testing** - Execute all CRUD operations
3. **Transaction Atomicity Testing** - Verify rollback behavior
4. **Integration Testing** - Create and run integration tests

See **POSTGRESQL_TESTING_GUIDE.md** for detailed instructions.

### Production Deployment

1. Provision PostgreSQL database (AWS RDS recommended)
2. Execute `02_PostgreSQL_Setup.sql` to create schema
3. Update production connection string in `appsettings.json`
4. Configure SSL/TLS for secure connections
5. Set `"Environment": "Production"` in configuration
6. Deploy application using your preferred method

## AWS Deployment Options

### Option 1: AWS RDS PostgreSQL
1. Create RDS PostgreSQL instance (version 13+)
2. Configure security group for application access
3. Execute schema setup script on RDS instance
4. Update connection string with RDS endpoint

### Option 2: AWS EC2 with PostgreSQL
1. Launch EC2 instance with Ubuntu/Amazon Linux
2. Install PostgreSQL 13 or higher
3. Configure PostgreSQL for remote access
4. Execute schema setup script
5. Deploy .NET application on EC2 or container

### Option 3: AWS ECS/Fargate with Aurora PostgreSQL
1. Create Aurora PostgreSQL cluster
2. Deploy application as Docker container to ECS/Fargate
3. Use AWS Secrets Manager for database credentials
4. Configure VPC networking for database access

## Support and Documentation

- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Npgsql Documentation**: https://www.npgsql.org/doc/
- **Testing Guide**: See POSTGRESQL_TESTING_GUIDE.md
- **Migration Report**: See final_migration_report.json

## License

Original license terms preserved. This is a migrated version of the original SQL Server application.
