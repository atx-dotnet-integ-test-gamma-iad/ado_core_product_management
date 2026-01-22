# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture.

**🔄 Migration Note**: This application has been migrated from SQL Server to PostgreSQL. All SQL Server dependencies have been replaced with Npgsql (PostgreSQL .NET provider). See [MIGRATION_NOTES.md](MIGRATION_NOTES.md) for details.

## Prerequisites

- Visual Studio 2022 or later
- .NET 9.0 SDK or later
- **PostgreSQL 12 or later** (free and open source)
- **pgAdmin 4** or **psql** command-line tool

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs (✅ Migrated to Npgsql)
├── Models/
│   └── Product.cs
├── Business/
│   └── ProductService.cs
├── CLI/
│   ├── CommandLineInterface.cs
│   └── InteractiveMenu.cs
├── Database/
│   └── Scripts/
│       ├── 01_InitialSetup.sql (SQL Server - deprecated)
│       └── 02_PostgreSQL_Schema.sql (✅ PostgreSQL)
├── Program.cs
├── AdoCore.csproj (✅ Updated to Npgsql)
├── appsettings.json (✅ PostgreSQL connection strings)
└── RUNTIME_TESTING_GUIDE.md (✅ Testing instructions)
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
   - Verify Npgsql package is installed (version 8.0.3)

3. **Database Setup**:
   - Install PostgreSQL from https://www.postgresql.org/download/
   - Open pgAdmin 4 or use psql command-line
   - Connect to your PostgreSQL instance
   - Create database: `CREATE DATABASE productmanagement;`
   - Run the schema script: `Database/Scripts/02_PostgreSQL_Schema.sql`

4. **Update Connection String**:
   - In Solution Explorer, open `appsettings.json`
   - Update with your PostgreSQL credentials:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Port=5432;Database=productmanagement;Username=postgres;Password=your_password",
       "ProdConnection": "Host=your_prod_host;Database=productmanagement;Username=your_user;Password=your_password"
     },
     "Environment": "Development"
   }
   ```

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
   
   # Verify PostgreSQL is installed
   psql --version
   # Should show PostgreSQL 12+
   ```

2. **Database Setup**:
   ```bash
   # Connect to PostgreSQL
   psql -U postgres
   
   # Create database
   CREATE DATABASE productmanagement;
   
   # Connect to the database
   \c productmanagement;
   
   # Run schema script
   \i Database/Scripts/02_PostgreSQL_Schema.sql
   
   # Verify tables created
   \dt
   
   # Exit psql
   \q
   ```

3. **Project Setup**:
   ```bash
   # Navigate to project directory
   cd sourceCode
   
   # Restore NuGet packages
   dotnet restore
   
   # Update connection string in appsettings.json
   # Replace 'your_password' with actual PostgreSQL password
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

# List all products (uses CTE with window functions)
dotnet run -- list

# Get product by ID (uses LAG window function)
dotnet run -- get 1

# Add new product (uses RETURNING clause)
dotnet run -- add "Gaming Mouse" 49.99 10 "High-performance gaming mouse"

# Update product (PostgreSQL transaction)
dotnet run -- update 1 "Gaming Mouse Pro" 59.99 15 "Updated gaming mouse"

# Delete product (PostgreSQL transaction)
dotnet run -- delete 1

# Update stock quantity
dotnet run -- stock 1 20
```

## Key Features

- ✅ **Modern async/await patterns** for all database operations
- ✅ **Npgsql driver** for PostgreSQL connectivity
- ✅ **PostgreSQL-specific features**: RETURNING clause, CURRENT_TIMESTAMP
- ✅ **Complex SQL queries**: CTEs, window functions (AVG OVER, LAG OVER, RANK, etc.)
- ✅ **Transaction management** with async operations
- ✅ **Proper resource management** with IAsyncDisposable
- ✅ **Dependency injection** for configuration
- ✅ **Parameterized queries** for security
- ✅ **Connection pooling** and management
- ✅ **Error handling** and rollback support

## Migration from SQL Server

This application was successfully migrated from SQL Server to PostgreSQL. Key changes include:

### Code Changes
- Replaced `Microsoft.Data.SqlClient` with `Npgsql 8.0.3`
- Replaced `SqlConnection` → `NpgsqlConnection`
- Replaced `SqlCommand` → `NpgsqlCommand`
- Replaced `SqlDataReader` → `NpgsqlDataReader`
- Replaced `SqlParameter` → `NpgsqlParameter`

### SQL Syntax Changes
- `SCOPE_IDENTITY()` → `RETURNING ProductId`
- `GETDATE()` → `CURRENT_TIMESTAMP`
- `[dbo].[TableName]` → `TableName`
- `NVARCHAR` → `VARCHAR`
- `BIT` → `BOOLEAN`
- `IDENTITY(1,1)` → `SERIAL`
- Multi-statement T-SQL transactions → C# transaction management

### Transaction Refactoring
All multi-statement T-SQL transactions have been refactored to use C# transaction management:
- `BEGIN TRANSACTION` in SQL → `await connection.BeginTransactionAsync()`
- `COMMIT` in SQL → `await transaction.CommitAsync()`
- `ROLLBACK` in SQL → `await transaction.RollbackAsync()`

For detailed migration information, see:
- [RUNTIME_TESTING_GUIDE.md](RUNTIME_TESTING_GUIDE.md) - Comprehensive testing guide
- [extracted_statements.sql](extracted_statements.sql) - Original SQL Server statements
- [converted_statements.sql](converted_statements.sql) - Converted PostgreSQL statements
- [sql_equivalency_validation_report.json](sql_equivalency_validation_report.json) - Equivalency validation
- [dms_conversion_log.txt](dms_conversion_log.txt) - Conversion process log

## Testing the Application

### Quick Start Test
1. Verify database connection:
   ```bash
   dotnet run -- list
   ```
   Should return 18 sample products with window function calculations

2. Test RETURNING clause (PostgreSQL-specific):
   ```bash
   dotnet run -- add "Test Product" 29.99 5 "Test Description"
   ```
   Should return the new ProductId

3. Test transaction management:
   ```bash
   dotnet run -- update 1 "Updated Product" 39.99 10 "Updated description"
   ```
   Should update product, log history, and update statistics atomically

### Comprehensive Testing
See [RUNTIME_TESTING_GUIDE.md](RUNTIME_TESTING_GUIDE.md) for comprehensive testing instructions including:
- Connection testing
- CRUD operations validation
- Complex query testing (window functions, CTEs)
- Transaction atomicity verification
- Concurrency testing
- Performance benchmarking

## Troubleshooting

### Common Issues

1. **Connection fails with "password authentication failed"**
   - Verify PostgreSQL credentials in appsettings.json
   - Check PostgreSQL authentication settings in pg_hba.conf
   - Ensure PostgreSQL service is running

2. **"relation 'products' does not exist"**
   - Run the schema script: `Database/Scripts/02_PostgreSQL_Schema.sql`
   - Verify you're connected to the correct database
   - Check table names are case-sensitive in PostgreSQL

3. **"Integrated Security=true" error**
   - Remove `Integrated Security=true` from connection string
   - Use `Username` and `Password` parameters instead
   - PostgreSQL doesn't support Windows Integrated Security

4. **NuGet package errors**
   - Ensure Npgsql package is installed (not Microsoft.Data.SqlClient)
   - Run: `dotnet restore`
   - Check AdoCore.csproj for correct package reference

5. **Build warnings about nullability (CS86xx)**
   - These are pre-existing nullability warnings
   - Not related to migration
   - Application compiles and runs correctly

### Verification Steps
```bash
# 1. Check PostgreSQL is running
sudo systemctl status postgresql  # Linux
# or check Windows Services

# 2. Test database connection
psql -U postgres -d productmanagement -c "SELECT COUNT(*) FROM Products;"

# 3. Verify NuGet packages
dotnet list package

# 4. Build project
dotnet build

# 5. Check for errors
echo $?  # Should be 0
```

## Required NuGet Packages

- ✅ **Npgsql** (8.0.3) - PostgreSQL .NET provider
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

**Removed** (SQL Server packages):
- ❌ Microsoft.Data.SqlClient
- ❌ System.Data.SqlClient

## Security Considerations

- ✅ All database queries use parameterization to prevent SQL injection
- ✅ Connection strings stored securely in configuration (use environment variables in production)
- ✅ Proper error handling and transaction rollback
- ✅ All database resources properly disposed using async patterns
- ✅ No hardcoded credentials in code
- ⚠️ Use SSL/TLS for production PostgreSQL connections: `SSL Mode=Require`

## Best Practices Implemented

- ✅ Modern async/await patterns throughout
- ✅ Proper resource disposal with IAsyncDisposable
- ✅ Transaction management with async support and rollback
- ✅ Error handling with try-catch-rollback pattern
- ✅ Configuration management using .NET Core's IConfiguration
- ✅ Security best practices (parameterized queries, no SQL injection)
- ✅ Dependency injection
- ✅ Separation of concerns (layered architecture)
- ✅ PostgreSQL-specific optimizations (RETURNING, window functions)
- ✅ Connection pooling configuration

## Performance Considerations

PostgreSQL-specific optimizations implemented:
- **RETURNING clause**: Eliminates round-trip for getting inserted ID
- **Window functions**: Efficient analytical queries (AVG OVER, LAG, RANK)
- **CTEs**: Improved query readability and optimization
- **Connection pooling**: Reuse connections for better performance
- **Async operations**: Non-blocking database access

Performance testing results (see RUNTIME_TESTING_GUIDE.md):
- Simple queries: < 100ms
- Window function queries: < 500ms
- Transaction operations: < 200ms

## Deployment

### Local Development
Connection string with local PostgreSQL:
```json
"DevConnection": "Host=localhost;Port=5432;Database=productmanagement;Username=postgres;Password=your_password;Pooling=true"
```

### Production Deployment
Connection string with security:
```json
"ProdConnection": "Host=your_prod_host;Port=5432;Database=productmanagement;Username=app_user;Password=secure_password;SSL Mode=Require;Pooling=true;Minimum Pool Size=5;Maximum Pool Size=100"
```

**Best Practices**:
1. Use environment variables for credentials (not appsettings.json)
2. Enable SSL/TLS: `SSL Mode=Require`
3. Configure connection pooling for performance
4. Use least-privilege database user
5. Set appropriate timeout values
6. Enable connection retry logic

### AWS RDS PostgreSQL
```json
"ProdConnection": "Host=your-rds-endpoint.rds.amazonaws.com;Port=5432;Database=productmanagement;Username=app_user;Password=secure_password;SSL Mode=Require;Trust Server Certificate=false;Pooling=true"
```

## Documentation

- [RUNTIME_TESTING_GUIDE.md](RUNTIME_TESTING_GUIDE.md) - Comprehensive testing instructions
- [extracted_statements.sql](extracted_statements.sql) - Original SQL statements
- [converted_statements.sql](converted_statements.sql) - PostgreSQL statements
- [dms_conversion_log.txt](dms_conversion_log.txt) - Migration process log
- [sql_equivalency_validation_report.json](sql_equivalency_validation_report.json) - Validation results
- [final_migration_report.json](final_migration_report.json) - Complete migration report

## Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review [RUNTIME_TESTING_GUIDE.md](RUNTIME_TESTING_GUIDE.md)
3. Verify PostgreSQL is properly configured
4. Check application logs for detailed error messages

## License

This project follows the original license terms. No license headers were modified during migration.
