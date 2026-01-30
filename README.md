# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture.

**MIGRATION NOTE**: This application has been migrated from Microsoft SQL Server to PostgreSQL. All SQL statements have been converted to PostgreSQL syntax, and the data access layer now uses Npgsql instead of Microsoft.Data.SqlClient.

## Prerequisites

- Visual Studio 2022 or later (or any .NET IDE)
- .NET 9.0 SDK or later
- PostgreSQL 12 or later (PostgreSQL 15+ recommended for best performance)
- pgAdmin 4 or any PostgreSQL client tool (DBeaver, DataGrip, psql command-line, etc.)

## Migration Summary

This application was successfully migrated from SQL Server to PostgreSQL with the following changes:

1. **Package Migration**: Replaced `Microsoft.Data.SqlClient` with `Npgsql 8.0.5`
2. **ADO.NET Classes**: All SQL Server classes replaced with PostgreSQL equivalents
   - `SqlConnection` → `NpgsqlConnection`
   - `SqlCommand` → `NpgsqlCommand`
   - `SqlDataReader` → `NpgsqlDataReader`
   - `SqlParameter` → `NpgsqlParameter`
   - `SqlTransaction` → `NpgsqlTransaction`
3. **SQL Syntax**: All 7 SQL statements converted to PostgreSQL syntax
   - Converted `GETDATE()` to `CURRENT_TIMESTAMP`
   - Converted `SCOPE_IDENTITY()` to `RETURNING` clause
   - Converted `ROUND()` function to PostgreSQL CAST syntax
   - Converted transaction blocks to PostgreSQL `DO $$` syntax
4. **Connection Strings**: Updated to PostgreSQL format

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs      # Uses Npgsql for PostgreSQL access
├── Models/
│   └── Product.cs
├── Business/
│   └── ProductService.cs
├── CLI/
│   ├── CommandLineInterface.cs
│   └── InteractiveMenu.cs
├── Database/
│   └── Scripts/
│       ├── 01_InitialSetup.sql          # Original SQL Server script
│       └── 01_PostgreSQL_Setup.sql      # PostgreSQL equivalent script
├── Program.cs
├── AdoCore.csproj
└── appsettings.json                      # PostgreSQL connection strings
```

## PostgreSQL Installation

### Windows

1. Download PostgreSQL from: https://www.postgresql.org/download/windows/
2. Run the installer and follow the setup wizard
3. Remember the password you set for the `postgres` user
4. Default port is 5432
5. Optionally install pgAdmin 4 (usually included with the installer)

### macOS

Using Homebrew:
```bash
brew install postgresql@15
brew services start postgresql@15
```

Using Postgres.app:
1. Download from: https://postgresapp.com/
2. Move to Applications folder and launch

### Linux (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### Docker (All Platforms)

```bash
docker run --name postgres-dev \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=ProductManagement \
  -p 5432:5432 \
  -d postgres:15
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
   - Verify that Npgsql 8.0.5 is installed

3. **Database Setup**:
   - Open pgAdmin 4 or your preferred PostgreSQL client
   - Connect to your local PostgreSQL instance
   - Open and run the script: `Database/Scripts/01_PostgreSQL_Setup.sql`
   - This will create the `ProductManagement` database with all necessary tables and sample data

4. **Update Connection String** (if needed):
   - In Solution Explorer, open `appsettings.json`
   - Current connection string format:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres",
       "ProdConnection": "Host=your-prod-host;Port=5432;Database=ProductManagement;Username=your-user;Password=your-password"
     },
     "Environment": "Development"
   }
   ```
   - Update username and password if you used different credentials during PostgreSQL setup

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
   # Should show PostgreSQL version
   ```

2. **Database Setup**:
   ```bash
   # Connect to PostgreSQL as superuser
   psql -U postgres
   
   # Create the database (if not using the SQL script)
   CREATE DATABASE "ProductManagement";
   \q
   
   # Run the setup script
   psql -U postgres -d ProductManagement -f Database/Scripts/01_PostgreSQL_Setup.sql
   ```

   Or using pgAdmin 4:
   - Open pgAdmin 4
   - Connect to localhost
   - Right-click on "Databases" → Create → Database
   - Name: ProductManagement
   - Open Query Tool and run the contents of `01_PostgreSQL_Setup.sql`

3. **Project Setup**:
   ```bash
   # Navigate to project directory
   cd /path/to/AdoCore

   # Restore NuGet packages (including Npgsql)
   dotnet restore

   # Verify Npgsql is installed
   dotnet list package
   # Should show: Npgsql 8.0.5

   # Update connection string in appsettings.json if needed
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
- Transaction support with PostgreSQL async operations
- Parameterized queries for security
- Connection pooling and management with Npgsql
- Error handling and logging
- Complex SQL with CTEs, window functions, and aggregations

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

### PostgreSQL Connection Issues

1. **Verify PostgreSQL is running**:
   ```bash
   # Windows
   services.msc  # Look for "postgresql-x64-15" service
   
   # macOS
   brew services list | grep postgresql
   
   # Linux
   sudo systemctl status postgresql
   
   # Docker
   docker ps | grep postgres
   ```

2. **Test PostgreSQL connection**:
   ```bash
   psql -U postgres -h localhost -p 5432
   # Enter password when prompted
   ```

3. **Check connection string parameters**:
   - Host: Should match your PostgreSQL server (usually `localhost`)
   - Port: Default is `5432`
   - Database: Must be `ProductManagement`
   - Username: Default superuser is `postgres`
   - Password: What you set during installation

4. **Common errors**:
   - `Npgsql.NpgsqlException: Connection refused`: PostgreSQL is not running
   - `password authentication failed`: Wrong username or password in connection string
   - `database "ProductManagement" does not exist`: Run the setup SQL script
   - `relation "products" does not exist`: Tables not created, run setup script

### Build Issues

1. **Verify NuGet packages are restored**:
   ```bash
   dotnet restore
   dotnet list package
   # Should show Npgsql 8.0.5
   ```

2. **Clean and rebuild**:
   ```bash
   dotnet clean
   dotnet build
   ```

3. **Verify .NET version**:
   ```bash
   dotnet --version
   # Must be 9.0.x or later
   ```

## Required NuGet Packages

- **Npgsql** (8.0.5) - PostgreSQL data provider for .NET
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

## Security Considerations

- All database queries use parameterization to prevent SQL injection
- Connection strings should be stored securely (use User Secrets for development, Key Vault for production)
- **IMPORTANT**: Replace default credentials (`postgres`/`postgres`) with strong passwords in production
- All database resources are properly disposed using async patterns
- Consider using SSL/TLS connections for production (add `SSL Mode=Require` to connection string)
- Implement connection string encryption for production deployments

## PostgreSQL-Specific Features Used

1. **RETURNING clause**: Used instead of SCOPE_IDENTITY() for retrieving generated IDs
2. **CURRENT_TIMESTAMP**: Replaced SQL Server's GETDATE()
3. **DO $$ blocks**: For complex transaction logic with variables
4. **NUMERIC type**: For precise decimal calculations
5. **Window functions**: LAG, RANK, PERCENT_RANK, AVG OVER, etc.
6. **CTEs (Common Table Expressions)**: WITH clauses for complex queries

## Best Practices Implemented

- Modern async/await patterns with Npgsql
- Proper resource disposal with IAsyncDisposable
- Transaction management with NpgsqlTransaction
- Error handling and logging
- Configuration management using .NET Core's IConfiguration
- Security best practices (parameterized queries, no SQL injection vulnerabilities)
- Dependency injection
- Separation of concerns (layered architecture)
- Connection pooling for performance

## Production Deployment Checklist

### Security
- [ ] Replace default PostgreSQL credentials with strong passwords
- [ ] Use environment variables or Azure Key Vault for connection strings
- [ ] Enable SSL/TLS for database connections (`SSL Mode=Require`)
- [ ] Configure PostgreSQL to accept connections only from application servers
- [ ] Set up PostgreSQL firewall rules (pg_hba.conf)
- [ ] Use least-privilege database user (not postgres superuser)

### PostgreSQL Configuration
- [ ] Tune PostgreSQL performance settings (shared_buffers, work_mem, etc.)
- [ ] Set up regular database backups (pg_dump or continuous archiving)
- [ ] Configure connection pooling (max_connections, Npgsql MaxPoolSize)
- [ ] Enable query logging for monitoring
- [ ] Set up monitoring and alerting (pgBadger, pg_stat_statements)

### Application Configuration
- [ ] Update ProdConnection in appsettings.json or environment variables
- [ ] Set Environment to "Production"
- [ ] Configure logging levels appropriately
- [ ] Test all CRUD operations in staging environment
- [ ] Verify transaction atomicity and rollback behavior
- [ ] Load test with expected production traffic

### Deployment Options

#### AWS RDS PostgreSQL
1. Create RDS PostgreSQL instance
2. Run setup script to create schema
3. Update connection string with RDS endpoint
4. Deploy application to EC2, ECS, or Lambda
5. Configure security groups for database access

#### Azure Database for PostgreSQL
1. Create Azure PostgreSQL Flexible Server
2. Run setup script to create schema
3. Update connection string with Azure endpoint
4. Deploy application to App Service or Container Apps
5. Configure firewall rules and VNet integration

#### Docker Compose
```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: ProductManagement
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./Database/Scripts/01_PostgreSQL_Setup.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
  
  app:
    build: .
    environment:
      ConnectionStrings__DevConnection: "Host=postgres;Port=5432;Database=ProductManagement;Username=appuser;Password=${DB_PASSWORD}"
    depends_on:
      - postgres
    ports:
      - "8080:8080"

volumes:
  postgres_data:
```

## Migration Documentation

For detailed information about the SQL Server to PostgreSQL migration:
- See `extracted_statements.sql` for original SQL Server statements
- See `converted_statements.sql` for PostgreSQL equivalents
- See `sql_equivalency_validation_report.json` for equivalency validation results
- See `dms_conversion_log.json` for DMS tool conversion workflow
- See `final_migration_report.json` for comprehensive migration summary

## Support and Resources

- **Npgsql Documentation**: https://www.npgsql.org/doc/
- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **PostgreSQL Best Practices**: https://wiki.postgresql.org/wiki/Don%27t_Do_This
- **.NET Data Access**: https://learn.microsoft.com/en-us/dotnet/framework/data/adonet/

## Known Limitations

1. This migration assumes PostgreSQL 12+ is available. Some features may not work on older versions.
2. The application currently uses basic authentication. Consider implementing connection pooling middleware for high-traffic scenarios.
3. No automated integration tests are included. Consider adding tests using Testcontainers for PostgreSQL.
4. The setup script uses sample/default credentials. These MUST be changed for production use.

## Next Steps

1. **Set up PostgreSQL** using one of the installation methods above
2. **Run the setup script** to create the database schema
3. **Update connection string** with your PostgreSQL credentials
4. **Build and test** the application
5. **Create unit and integration tests** for comprehensive coverage
6. **Deploy to your target environment** following the production checklist
