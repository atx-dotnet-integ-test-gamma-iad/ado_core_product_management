# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture.

**MIGRATION STATUS**: This application has been successfully migrated from Microsoft SQL Server to PostgreSQL using AWS Database Migration Service (DMS) tools.

## Prerequisites

- Visual Studio 2022 or later (optional)
- .NET 9.0 SDK or later
- PostgreSQL 12 or later (recommended: PostgreSQL 14+)
- pgAdmin or any PostgreSQL client tool

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
├── Program.cs
├── AdoCore.csproj
├── appsettings.json
└── DATABASE_SETUP_GUIDE.md  ← **START HERE for database setup**
```

## Quick Start

### Step 1: Database Setup

**IMPORTANT**: Before running the application, you must set up the PostgreSQL database.

Follow the comprehensive guide: [DATABASE_SETUP_GUIDE.md](./DATABASE_SETUP_GUIDE.md)

The guide covers:
- Creating the PostgreSQL database and schema
- Creating all required tables (products, producthistory, productstats)
- Inserting sample data for testing
- Configuring user permissions
- Updating connection strings

### Step 2: Application Setup

#### Option A: Using Visual Studio

1. **Open the Project**:
   - Open Visual Studio 2022
   - Select "Open a project or solution"
   - Navigate to the project folder and select `AdoCore.csproj`

2. **Restore NuGet Packages**:
   - Right-click on the solution in Solution Explorer
   - Select "Restore NuGet Packages"

3. **Update Connection String**:
   - In Solution Explorer, open `appsettings.json`
   - Update the connection string with your PostgreSQL credentials:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=yourpassword;Pooling=true",
       "ProdConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=yourpassword;Pooling=true"
     },
     "Environment": "Development"
   }
   ```

4. **Run the Application**:
   - Press F5 to run in debug mode
   - Or press Ctrl+F5 to run without debugging
   - The application will start in interactive mode

#### Option B: Using Command Line

1. **Prerequisites Check**:
   ```bash
   # Verify .NET 9.0 SDK is installed
   dotnet --version
   # Should show 9.0.x
   ```

2. **Database Setup**:
   - Follow instructions in [DATABASE_SETUP_GUIDE.md](./DATABASE_SETUP_GUIDE.md)

3. **Project Setup**:
   ```bash
   # Navigate to project directory
   cd /path/to/AdoCore

   # Restore NuGet packages
   dotnet restore

   # Update connection string in appsettings.json with your PostgreSQL credentials
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
   6. Get products by price range
   7. Get low stock products
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

# Get products by price range
dotnet run -- pricerange 10.00 100.00

# Get low stock products (threshold)
dotnet run -- lowstock 20
```

## Key Features

- Modern async/await patterns for all database operations
- Proper resource management with IAsyncDisposable
- Dependency injection for configuration
- Transaction support with async operations (application-level)
- Parameterized queries for security
- Connection pooling and management
- PostgreSQL-specific features:
  - Window functions (LAG, RANK, PERCENT_RANK)
  - RETURNING clause for INSERT operations
  - Common Table Expressions (CTEs)
  - CURRENT_TIMESTAMP for automatic timestamps

## Migration from SQL Server

This application was migrated from Microsoft SQL Server to PostgreSQL. Key changes include:

### Package Updates
- **Removed**: Microsoft.Data.SqlClient
- **Added**: Npgsql 8.0.5 (PostgreSQL .NET driver)

### Code Changes
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`
- `SqlTransaction` → `NpgsqlTransaction`
- `SqlParameter` → `NpgsqlParameter`

### SQL Syntax Changes
- Transaction handling moved from T-SQL to application-level (BeginTransactionAsync)
- `GETDATE()` → `CURRENT_TIMESTAMP`
- Schema names updated (e.g., `dbo.products` → `productmanagement_dbo.products`)
- Column and table names converted to lowercase
- `IDENTITY` columns → `SERIAL`
- `TOP N` → `LIMIT N`

### Migration Artifacts
For detailed migration information, see:
- `extracted_statements.sql` - Original SQL Server statements
- `converted_statements.sql` - Converted PostgreSQL statements
- `dms_conversion_log.json` - DMS conversion process log
- `sql_equivalency_validation_report.json` - SQL equivalency validation results
- `migration_final_report.md` - Complete migration report

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

4. Test window functions:
   ```bash
   # Get products in price range with ranking
   dotnet run -- pricerange 10.00 500.00
   
   # Get low stock products with analysis
   dotnet run -- lowstock 30
   ```

## Troubleshooting

### Connection Issues

**Error**: `FATAL: password authentication failed`
- Verify credentials in appsettings.json
- Check PostgreSQL pg_hba.conf for authentication method
- Ensure user has been created with correct password

**Error**: `FATAL: database "ProductManagement" does not exist`
- Follow the [DATABASE_SETUP_GUIDE.md](./DATABASE_SETUP_GUIDE.md) to create the database
- Verify database name spelling (case-sensitive)

**Error**: `relation "productmanagement_dbo.products" does not exist`
- Verify schema was created: `productmanagement_dbo`
- Ensure all tables were created with the correct schema prefix
- Check table names are lowercase

### Build Issues

If you encounter build errors:
1. Make sure all required NuGet packages are restored:
   ```bash
   dotnet restore
   ```
2. Verify .NET 9.0 SDK is installed:
   ```bash
   dotnet --version
   ```
3. Clean and rebuild:
   ```bash
   dotnet clean
   dotnet build
   ```

## Required NuGet Packages

- **Npgsql** (8.0.5) - PostgreSQL .NET Data Provider
- **Microsoft.Extensions.Configuration** (8.0.0)
- **Microsoft.Extensions.Configuration.Json** (8.0.0)
- **Microsoft.Extensions.DependencyInjection** (8.0.0)

## Security Considerations

- All database queries use parameterization to prevent SQL injection
- Connection strings should use secure credentials (see [DATABASE_SETUP_GUIDE.md](./DATABASE_SETUP_GUIDE.md))
- For production: Use environment variables or secure configuration providers
- Production connections should use SSL (add `SSL Mode=Require` to connection string)
- Proper error handling and logging is implemented
- All database resources are properly disposed using async patterns

## Best Practices Implemented

- Modern async/await patterns
- Proper resource disposal with IAsyncDisposable
- Application-level transaction management with async support
- Error handling with proper rollback
- Configuration management using .NET Core's IConfiguration
- Security best practices (parameterized queries, no SQL injection vulnerabilities)
- Dependency injection
- Separation of concerns (layered architecture)
- Connection pooling for performance

## PostgreSQL-Specific Features Used

- **Window Functions**: LAG, RANK, PERCENT_RANK for advanced analytics
- **Common Table Expressions (CTEs)**: For complex queries
- **RETURNING Clause**: Get inserted IDs without additional queries
- **CURRENT_TIMESTAMP**: Automatic timestamp handling
- **Application-Level Transactions**: Proper async transaction management

## Validation Status

### Completed Exit Criteria ✓
- All SQL Server packages replaced with PostgreSQL equivalents
- All ADO.NET classes migrated to Npgsql
- All SQL statements processed through AWS DMS tool
- Comprehensive SQL statement catalog created
- All SQL pairs validated through SQL Equivalency tool
- Complete equivalency validation report generated
- No agent judgment used for equivalency determination
- Failed DMS conversions documented
- Connection strings updated to PostgreSQL format
- Transaction handling updated to PostgreSQL patterns
- Application compiles without errors

### Pending Validation (Requires Database Environment)
- Database connectivity testing
- CRUD operations validation
- Transaction atomicity testing
- Integration test execution

See [DATABASE_SETUP_GUIDE.md](./DATABASE_SETUP_GUIDE.md) for instructions on completing these validations.

## Additional Resources

- [DATABASE_SETUP_GUIDE.md](./DATABASE_SETUP_GUIDE.md) - Complete database setup instructions
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Npgsql Documentation](https://www.npgsql.org/doc/)
- [PostgreSQL Window Functions](https://www.postgresql.org/docs/current/tutorial-window.html)
- Migration artifacts in project root directory

## Support

For issues specific to the migration:
- Review `migration_final_report.md` for transformation details
- Check `sql_equivalency_validation_report.json` for statement validation status
- Review `dms_conversion_log.json` for conversion details
- See [DATABASE_SETUP_GUIDE.md](./DATABASE_SETUP_GUIDE.md) for database setup help
