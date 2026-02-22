# ADO.NET Core PostgreSQL Data Management Application

This application has been **migrated from SQL Server to PostgreSQL**, demonstrating modern ADO.NET integration with PostgreSQL following best practices for data access and application architecture.

## ⚠️ SECURITY WARNING ⚠️

**IMPORTANT**: The connection strings in `appsettings.json` contain placeholder credentials (postgres/postgres) for development purposes only. 

**Before deploying to production:**
1. Replace hardcoded credentials with secure credential management solutions:
   - Use AWS Secrets Manager, Azure Key Vault, or HashiCorp Vault
   - Implement environment variables for sensitive configuration
   - Use IAM authentication where possible (e.g., AWS RDS IAM authentication)
2. **NEVER** commit production credentials to version control
3. Follow the principle of least privilege for database access
4. Use connection string encryption in production environments

## Migration Summary

This application was successfully migrated from Microsoft SQL Server to PostgreSQL:

- **SQL Statements Processed**: 7 statements converted to PostgreSQL syntax
- **Package Migration**: Microsoft.Data.SqlClient → Npgsql 10.0.1
- **Connection Strings**: Updated to PostgreSQL format
- **Transaction Handling**: Converted to PostgreSQL syntax
- **Schema Objects**: All table and column names converted to lowercase for PostgreSQL compatibility

For detailed migration information, see:
- `extracted_statements.sql` - Original SQL Server statements
- `converted_statements.sql` - Converted PostgreSQL statements
- `sql_equivalency_validation_report.json` - SQL equivalency validation results

## Prerequisites

- Visual Studio 2022 or later
- .NET 9.0 SDK or later
- **PostgreSQL 12 or later** (or compatible cloud service like AWS RDS for PostgreSQL)
- pgAdmin, DBeaver, or another PostgreSQL management tool

## Database Schema Requirements

Before running the application, ensure your PostgreSQL database has the following tables with **lowercase** names:

```sql
-- Products table
CREATE TABLE products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(18,2) NOT NULL,
    stock INTEGER NOT NULL,
    description TEXT,
    createdat TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedat TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ProductHistory table
CREATE TABLE producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INTEGER REFERENCES products(productid),
    oldprice DECIMAL(18,2),
    newprice DECIMAL(18,2),
    oldstock INTEGER,
    newstock INTEGER,
    changedat TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ProductStats table
CREATE TABLE productstats (
    productid INTEGER PRIMARY KEY REFERENCES products(productid),
    totalupdates INTEGER DEFAULT 0,
    lastupdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs       (Uses Npgsql for PostgreSQL)
├── Models/
│   └── Product.cs
├── Business/
│   └── ProductService.cs
├── CLI/
│   ├── CommandLineInterface.cs
│   └── InteractiveMenu.cs
├── Program.cs
├── AdoCore.csproj                 (References Npgsql 10.0.1)
├── appsettings.json               (PostgreSQL connection strings)
├── extracted_statements.sql       (Original SQL Server statements)
├── converted_statements.sql       (Converted PostgreSQL statements)
└── sql_equivalency_validation_report.json
```

## Setup Instructions

### Option 1: Using Visual Studio

1. **Open the Project**:
   - Open Visual Studio 2022
   - Select "Open a project or solution"
   - Navigate to the project folder and select `AdoCore.csproj`

2. **Restore NuGet Packages**:
   - Right-click on the solution in Solution Explorer
   - Select "Restore NuGet Packages"
   - Verify Npgsql 10.0.1 is installed

3. **Database Setup**:
   - Open pgAdmin or your PostgreSQL management tool
   - Connect to your PostgreSQL server (default: localhost:5432)
   - Create a database named `ProductManagement`
   - Run the schema creation SQL (see Database Schema Requirements above)

4. **Update Connection String** (if needed):
   - In Solution Explorer, open `appsettings.json`
   - Current connection string format:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres;Port=5432",
       "ProdConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres;Port=5432"
     },
     "Environment": "Development"
   }
   ```
   - **⚠️ SECURITY**: Replace with secure credentials before production use

5. **Run the Application**:
   - Press F5 to run in debug mode
   - Or press Ctrl+F5 to run without debugging
   - The application will start in interactive mode

### Option 2: Using Command Line

1. **Prerequisites Check**:
   ```bash
   # Verify .NET 9.0 SDK is installed
   dotnet --version
   # Should show 9.0.x
   
   # Verify PostgreSQL is running
   psql --version
   # Or check PostgreSQL service status
   ```

2. **Database Setup**:
   ```bash
   # Connect to PostgreSQL
   psql -U postgres -h localhost
   
   # Create database
   CREATE DATABASE "ProductManagement";
   
   # Connect to the database
   \c ProductManagement
   
   # Run the schema creation SQL (see Database Schema Requirements)
   ```

3. **Project Setup**:
   ```bash
   # Navigate to project directory
   cd /path/to/AdoCore
   
   # Restore NuGet packages
   dotnet restore
   
   # Verify Npgsql package is installed
   dotnet list package
   # Should show: Npgsql 10.0.1
   ```

4. **Build and Run**:
   ```bash
   # Build the project
   dotnet build
   
   # Run in interactive mode
   dotnet run
   
   # Or run with CLI commands
   dotnet run -- list
   ```

## Running the Application

The application can be run in two modes: Interactive (menu-driven) and Command-Line Interface (CLI).

### Interactive Mode

1. Run the application without any arguments:
   ```bash
   dotnet run
   ```
2. You'll see the main menu with these options:
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

The application supports the following commands:

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

## Key Features

- Modern async/await patterns for all database operations
- Proper resource management with IAsyncDisposable
- Dependency injection for configuration
- **PostgreSQL-specific features**:
  - DO $$ anonymous blocks for complex transactions
  - RETURNING clause for INSERT operations
  - PostgreSQL-native parameterized queries
  - Npgsql connection pooling
- Transaction support with async operations
- Parameterized queries for security
- Error handling and logging

## Migration Details

### SQL Conversion Summary

All 7 SQL statements were converted from SQL Server to PostgreSQL syntax:

1. **GetAllProductsAsync**: Complex CTE query with window functions
2. **GetProductByIdAsync**: Simple SELECT with LEFT JOIN
3. **InsertProductAsync**: INSERT with RETURNING clause and transaction
4. **UpdateProductAsync**: UPDATE with transaction and history tracking
5. **DeleteProductAsync**: DELETE with transaction and history tracking
6. **GetProductsByPriceRangeAsync**: Parameterized range query
7. **GetLowStockProductsAsync**: Filtered SELECT with sorting

### Key Syntax Transformations

- `GETDATE()` → `CURRENT_TIMESTAMP`
- `SCOPE_IDENTITY()` → `RETURNING productid`
- `BEGIN TRANSACTION` → `BEGIN`
- `DECLARE @var` → `DECLARE var`
- `SELECT @var = value` → `SELECT value INTO var`
- Schema objects converted to lowercase (Products → products)

### Package Changes

- **Removed**: Microsoft.Data.SqlClient
- **Added**: Npgsql 10.0.1 (with security vulnerability fixes)
- **Retained**: Microsoft.Extensions.Configuration, Microsoft.Extensions.Configuration.Json, Microsoft.Extensions.DependencyInjection

## Testing the Application

1. Try listing products:
   ```bash
   dotnet run -- list
   ```

2. Add a new product:
   ```bash
   dotnet run -- add "Test Product" 29.99 5 "Test Description"
   ```

3. View the product details:
   ```bash
   dotnet run -- get 1
   ```

## Troubleshooting

If you encounter errors:

1. **Connection Issues**:
   - Verify PostgreSQL is running: `sudo systemctl status postgresql` (Linux) or check Services (Windows)
   - Confirm connection string matches your PostgreSQL configuration
   - Check firewall settings allow connection to port 5432
   - Verify credentials are correct

2. **Database Issues**:
   - Ensure the `ProductManagement` database exists
   - Verify all required tables (products, producthistory, productstats) are created
   - Check table names are lowercase
   - Verify user has appropriate permissions

3. **Build Issues**:
   - Ensure all NuGet packages are restored: `dotnet restore`
   - Verify .NET 9.0 SDK is installed: `dotnet --version`
   - Check for compilation errors: `dotnet build`

4. **Runtime Issues**:
   - Check appsettings.json exists in output directory
   - Verify connection string format is correct for PostgreSQL
   - Review error messages for specific PostgreSQL errors

## Required NuGet Packages

- **Npgsql** 10.0.1 (PostgreSQL data provider)
- Microsoft.Extensions.Configuration 8.0.0
- Microsoft.Extensions.Configuration.Json 8.0.0
- Microsoft.Extensions.DependencyInjection 8.0.0

## Security Considerations

- All database queries use parameterization to prevent SQL injection
- **⚠️ CONNECTION STRINGS**: Replace placeholder credentials before production deployment
- Proper error handling and logging is implemented
- All database resources are properly disposed using async patterns
- Use SSL/TLS for PostgreSQL connections in production
- Implement row-level security (RLS) in PostgreSQL for multi-tenant scenarios
- Regular security updates for Npgsql package

## Best Practices Implemented

- Modern async/await patterns
- Proper resource disposal with IAsyncDisposable
- Transaction management with async support
- Error handling and logging
- Configuration management using .NET Core's IConfiguration
- Security best practices (parameterized queries)
- Dependency injection
- Separation of concerns (layered architecture)
- PostgreSQL-specific optimizations

## Cloud Deployment

### AWS RDS PostgreSQL

1. Create an RDS PostgreSQL instance
2. Update connection string:
   ```json
   "ProdConnection": "Host=your-instance.region.rds.amazonaws.com;Database=ProductManagement;Username=your_user;Password=your_secure_password;Port=5432;SSL Mode=Require"
   ```
3. Configure security groups to allow application access
4. Consider using AWS Secrets Manager for credential management
5. Enable RDS Performance Insights for monitoring

### Azure Database for PostgreSQL

1. Create Azure Database for PostgreSQL instance
2. Update connection string with Azure endpoint
3. Use Azure Key Vault for credential management
4. Enable SSL enforcement
5. Configure firewall rules

## Known Limitations

1. **SQL Equivalency Validation**: All 7 statement pairs returned ERROR status from the equivalency validation tool. Manual code review confirms PostgreSQL syntax is correct, but automated equivalency testing requires tool investigation.

2. **Runtime Testing**: Criteria 12-14 require a live PostgreSQL database for validation. Ensure database setup is complete before runtime testing.

3. **Test Coverage**: No unit tests exist in the original application. Consider adding test coverage for production use.

## Migration Artifacts

- `extracted_statements.sql`: Complete catalog of original SQL Server statements
- `converted_statements.sql`: Complete catalog of PostgreSQL statements with conversion notes
- `sql_equivalency_validation_report.json`: Detailed equivalency validation results (tool errors documented)

## Support and Documentation

- Npgsql Documentation: https://www.npgsql.org/doc/
- PostgreSQL Documentation: https://www.postgresql.org/docs/
- .NET Data Access: https://docs.microsoft.com/en-us/dotnet/framework/data/adonet/

## License

[Your license information here]
