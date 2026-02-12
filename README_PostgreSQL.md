# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL using Npgsql, following best practices for data access and application architecture.

**This application has been migrated from Microsoft SQL Server to PostgreSQL.**

## Prerequisites

- Visual Studio 2022 or later (optional)
- .NET 9.0 SDK or later
- PostgreSQL 12 or later (recommended: PostgreSQL 15+)
- pgAdmin, DBeaver, Azure Data Studio, or any PostgreSQL client tool

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
└── appsettings.json
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

3. **Database Setup**:
   - Install PostgreSQL if not already installed
   - Open pgAdmin or your preferred PostgreSQL client
   - Create a new database named `ProductManagement` (or connect to psql and run: `CREATE DATABASE "ProductManagement";`)
   - Connect to the `ProductManagement` database
   - Open and run the script: `Database/Scripts/01_InitialSetup_PostgreSQL.sql`

4. **Update Connection String**:
   - In Solution Explorer, open `appsettings.json`
   - Update the connection string if needed:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=your_password;Pooling=true",
       "ProdConnection": "your-production-connection-string"
     },
     "Environment": "Development"
   }
   ```
   - Replace `your_password` with your PostgreSQL password
   - For production, use environment variables or secure configuration management

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

   # Verify PostgreSQL is installed and running
   psql --version
   # Should show PostgreSQL version
   ```

2. **Database Setup**:
   ```bash
   # Connect to PostgreSQL (adjust connection parameters as needed)
   psql -U postgres -h localhost

   # In psql, create the database:
   CREATE DATABASE "ProductManagement";

   # Connect to the new database:
   \c ProductManagement

   # Exit psql:
   \q

   # Run the setup script from command line:
   psql -U postgres -h localhost -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
   ```

3. **Project Setup**:
   ```bash
   # Navigate to project directory
   cd /path/to/sourceCode

   # Restore NuGet packages
   dotnet restore

   # Update connection string in appsettings.json if needed
   # Current connection string format:
   # "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=your_password;Pooling=true"
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
dotnet run -- price-range 50.00 200.00

# Get low stock products
dotnet run -- low-stock
```

## Key Features

- Modern async/await patterns for all database operations
- Proper resource management with IAsyncDisposable
- Dependency injection for configuration
- Transaction support with async operations
- Parameterized queries for security (SQL injection prevention)
- Connection pooling and management with Npgsql
- Error handling and logging
- Advanced PostgreSQL features:
  - Common Table Expressions (CTEs)
  - Window functions (ROW_NUMBER, RANK, LAG, etc.)
  - RETURNING clause for INSERT operations

## Migration from SQL Server

This application was migrated from Microsoft SQL Server to PostgreSQL. Key changes include:

- **Package**: Replaced `Microsoft.Data.SqlClient` with `Npgsql`
- **Classes**: 
  - `SqlConnection` → `NpgsqlConnection`
  - `SqlCommand` → `NpgsqlCommand`
  - `SqlDataReader` → `NpgsqlDataReader`
  - `SqlTransaction` → `NpgsqlTransaction`
- **Connection String Format**: Changed from SQL Server to PostgreSQL format
- **SQL Syntax**: Updated to PostgreSQL-compatible syntax
- **Database Schema**: Converted naming from PascalCase to snake_case (PostgreSQL convention)

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

4. Get products in price range:
   ```bash
   dotnet run -- price-range 100.00 300.00
   ```

5. Get low stock products:
   ```bash
   dotnet run -- low-stock
   ```

## Troubleshooting

If you encounter errors:

1. **Connection Issues**:
   - Verify PostgreSQL is running: `pg_isready` or check system services
   - Confirm your connection string matches your PostgreSQL configuration
   - Check PostgreSQL is listening on port 5432: `netstat -an | grep 5432`

2. **Authentication Issues**:
   - Ensure the username and password in `appsettings.json` are correct
   - Check PostgreSQL `pg_hba.conf` file for authentication settings
   - Try connecting with psql: `psql -U postgres -h localhost -d ProductManagement`

3. **Database Issues**:
   - Ensure the `ProductManagement` database exists: `psql -l | grep ProductManagement`
   - Verify tables were created: Connect with psql and run `\dt`
   - Check you have appropriate permissions on the database

4. **Package Issues**:
   - Make sure all required NuGet packages are restored:
     ```bash
     dotnet restore
     ```
   - If you see Npgsql vulnerability warnings, consider updating to the latest version

## Required NuGet Packages

- **Npgsql** (version 8.0.0 or later) - PostgreSQL ADO.NET provider
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

## Security Considerations

- **Parameterized Queries**: All database queries use parameterization to prevent SQL injection attacks
- **Configuration Management**: Connection strings are stored in configuration files (not hardcoded)
- **Password Management**: 
  - Never commit passwords to source control
  - Use environment variables for production credentials
  - Consider using Azure Key Vault, AWS Secrets Manager, or similar for production
- **Connection Pooling**: Npgsql handles connection pooling efficiently
- **Resource Disposal**: All database resources are properly disposed using async patterns
- **Error Handling**: Comprehensive error handling prevents information leakage

## Best Practices Implemented

- Modern async/await patterns throughout
- Proper resource disposal with IAsyncDisposable
- Transaction management with async support
- Error handling and logging
- Configuration management using .NET Core's IConfiguration
- Security best practices (parameterized queries, no hardcoded credentials)
- Dependency injection
- Separation of concerns (layered architecture)
- Use of PostgreSQL-specific features (RETURNING, window functions, CTEs)

## PostgreSQL-Specific Features Used

This application leverages several PostgreSQL features:

1. **RETURNING Clause**: Get inserted/updated values without additional queries
2. **Common Table Expressions (CTEs)**: For complex queries with better readability
3. **Window Functions**: 
   - `ROW_NUMBER()` for row numbering
   - `RANK()` and `PERCENT_RANK()` for ranking
   - `LAG()` for accessing previous row values
   - Aggregate window functions (SUM, AVG, etc.)
4. **SERIAL/BIGSERIAL**: Auto-incrementing primary keys
5. **Boolean Type**: Native boolean support (instead of bit)
6. **Triggers**: Using PostgreSQL function syntax

## Deployment Considerations

### Local Development
- Use the provided `appsettings.json` with local PostgreSQL credentials
- Ensure PostgreSQL is running locally

### Production Deployment
1. Set up PostgreSQL database (cloud or on-premises)
2. Run database setup script (`01_InitialSetup_PostgreSQL.sql`)
3. Update connection string using environment variables or secure configuration
4. Consider using connection string encryption
5. Set appropriate PostgreSQL user permissions (principle of least privilege)
6. Enable SSL/TLS for database connections in production

### AWS Deployment
- Use Amazon RDS for PostgreSQL for managed database service
- Store connection strings in AWS Secrets Manager
- Use IAM authentication for RDS when possible
- Configure VPC security groups appropriately

### Azure Deployment
- Use Azure Database for PostgreSQL
- Store connection strings in Azure Key Vault
- Use managed identity when possible
- Configure firewall rules appropriately

## Additional Notes

- The original SQL Server schema used PascalCase for table and column names
- The PostgreSQL schema uses snake_case (e.g., `product_id` instead of `ProductId`)
- Table names are lowercase (e.g., `products` instead of `Products`)
- All SQL statements have been converted to PostgreSQL syntax
- Original SQL Server setup script is preserved as `01_InitialSetup.sql` for reference

## Support and Documentation

- **Npgsql Documentation**: https://www.npgsql.org/doc/
- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **.NET Documentation**: https://docs.microsoft.com/en-us/dotnet/

## License

This application is provided as-is for educational and demonstration purposes.
