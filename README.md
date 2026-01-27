# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture.

**MIGRATION NOTE:** This application has been migrated from Microsoft SQL Server to PostgreSQL. See `final_migration_report.md` for complete migration details and `sql_equivalency_validation_report.json` for SQL statement equivalency validation results.

## Prerequisites

- Visual Studio 2022 or later
- .NET 9.0 SDK or later
- PostgreSQL 12 or later (recommended for development)
- pgAdmin 4 or Azure Data Studio with PostgreSQL extension

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
   - Open pgAdmin 4 or Azure Data Studio with PostgreSQL extension
   - Connect to your local PostgreSQL instance
   - Create database: `CREATE DATABASE "ProductManagement";`
   - Open and run the script: `Database/Scripts/01_InitialSetup.sql` (PostgreSQL version)

4. **Update Connection String**:
   - In Solution Explorer, open `appsettings.json`
   - Update the connection string if needed:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=your_password;Pooling=true;Minimum Pool Size=0;Maximum Pool Size=100",
       "ProdConnection": "your-production-connection-string"
     },
     "Environment": "Development"
   }
   ```
   
   **SECURITY WARNING:** The current connection string contains placeholder credentials (postgres/postgres). 
   For production deployments, use secure credential management:
   - Environment variables
   - AWS Secrets Manager
   - Azure Key Vault
   - HashiCorp Vault
   - Never commit production credentials to source control

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
   # Should show PostgreSQL 12.x or later
   ```

2. **Database Setup**:
   ```bash
   # Connect to PostgreSQL
   psql -U postgres -h localhost
   
   # Create database
   CREATE DATABASE "ProductManagement";
   
   # Connect to the new database
   \c ProductManagement
   
   # Run the setup script
   \i Database/Scripts/01_InitialSetup.sql
   ```

3. **Project Setup**:
   ```bash
   # Navigate to project directory
   cd path/to/AdoCore

   # Restore NuGet packages
   dotnet restore

   # Update connection string in appsettings.json
   # Current format:
   # "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=your_password;Pooling=true;Minimum Pool Size=0;Maximum Pool Size=100"
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
- Transaction support with async operations
- Parameterized queries for security (PostgreSQL format)
- Connection pooling and management
- Error handling and logging

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
1. Verify PostgreSQL is running:
   ```bash
   # On Linux/macOS
   sudo systemctl status postgresql
   
   # On Windows
   # Check Services for "postgresql-x64-XX"
   ```
2. Confirm your connection string matches your PostgreSQL instance settings
3. Ensure the `ProductManagement` database was created successfully
4. Check you have appropriate permissions to access the database
5. Make sure all required NuGet packages are restored:
   ```bash
   dotnet restore
   ```
6. Verify PostgreSQL is accepting connections on the specified port (default: 5432)

## Required NuGet Packages

- **Npgsql** (v8.0.5) - PostgreSQL data provider for .NET
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

## Security Considerations

- All database queries use parameterization to prevent SQL injection
- Connection strings should use secure credential management in production:
  - **DO NOT** hardcode passwords in appsettings.json for production
  - Use environment variables: `Username=${DB_USER};Password=${DB_PASSWORD}`
  - Use AWS Secrets Manager for AWS deployments
  - Use Azure Key Vault for Azure deployments
  - Use HashiCorp Vault for on-premises deployments
- Proper error handling and logging is implemented
- All database resources are properly disposed using async patterns
- SSL/TLS connection recommended for production: Add `SSL Mode=Require` to connection string

## Best Practices Implemented

- Modern async/await patterns
- Proper resource disposal with IAsyncDisposable
- Transaction management with async support
- Error handling and logging
- Configuration management using .NET Core's IConfiguration
- Security best practices (parameterized queries, connection pooling)
- Dependency injection
- Separation of concerns (layered architecture)
- PostgreSQL-specific optimizations (RETURNING clause, NOW() function)

## Migration from SQL Server to PostgreSQL

This application was migrated from SQL Server to PostgreSQL. Key changes include:

### Package Changes
- Replaced `Microsoft.Data.SqlClient` with `Npgsql`

### Code Changes
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`
- `SqlParameter` → `NpgsqlParameter`

### SQL Syntax Changes
- `GETDATE()` → `NOW()`
- `SCOPE_IDENTITY()` → `RETURNING id` clause
- Transaction syntax adapted to PostgreSQL

### Connection String Changes
- `Server=` → `Host=`
- `Trusted_Connection=True` → `Username=;Password=`
- Added PostgreSQL-specific parameters: `Port=`, `Pooling=`, `Minimum Pool Size=`, `Maximum Pool Size=`

For detailed migration information, see:
- `final_migration_report.md` - Complete migration documentation
- `sql_equivalency_validation_report.json` - SQL statement equivalency validation
- `conversion_log.txt` - SQL conversion process log
- `extracted_statements.sql` - Original SQL statements
- `converted_statements.sql` - Converted PostgreSQL statements

## Deployment to AWS

### Prerequisites
- PostgreSQL RDS instance or EC2 instance with PostgreSQL installed
- Proper security group configuration
- Database credentials stored in AWS Secrets Manager

### Deployment Steps

1. **Set up PostgreSQL RDS** (recommended) or install PostgreSQL on EC2
2. **Configure Secrets Manager**:
   ```bash
   aws secretsmanager create-secret \
     --name prod/adocore/db \
     --secret-string '{"username":"dbuser","password":"securepassword"}'
   ```
3. **Update application to read from Secrets Manager** (recommended for production)
4. **Deploy the application** using:
   - AWS Elastic Beanstalk
   - ECS/Fargate containers
   - EC2 with systemd service
5. **Update connection string** to point to RDS endpoint

### Production Connection String Example
```json
{
  "ConnectionStrings": {
    "ProdConnection": "Host=your-rds-instance.region.rds.amazonaws.com;Port=5432;Database=ProductManagement;Username=dbuser;Password=from_secrets_manager;SSL Mode=Require;Trust Server Certificate=true"
  }
}
```

## Additional Resources

- [Npgsql Documentation](https://www.npgsql.org/doc/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Migration Report](final_migration_report.md)
- [SQL Equivalency Report](sql_equivalency_validation_report.json)
