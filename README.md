# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture.

## Prerequisites

- Visual Studio 2022 or later
- .NET 9.0 SDK or later
- PostgreSQL 14 or later (PostgreSQL is free and open-source)
- PostgreSQL client tools (pgAdmin, psql, or Azure Data Studio with PostgreSQL extension)

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
   - Open pgAdmin, psql, or Azure Data Studio with PostgreSQL extension
   - Connect to your local PostgreSQL instance
   - Create the database and run setup scripts if available

4. **Update Connection String**:
   - In Solution Explorer, open `appsettings.json`
   - The connection string is already configured for PostgreSQL:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Database=postgres;Username=postgres;Password=postgres",
       "ProdConnection": "Host=localhost;Database=postgres;Username=postgres;Password=postgres"
     },
     "Environment": "Development"
   }
   ```
   - Update host, database, username, and password as needed for your PostgreSQL instance

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
   # Connect to PostgreSQL using psql
   psql -h localhost -U postgres
   
   # Create database (if needed)
   CREATE DATABASE productmanagement;
   
   # Connect to the database
   \c productmanagement
   
   # Run setup scripts if available
   ```

3. **Project Setup**:
   ```bash
   # Navigate to project directory
   cd <your-project-path>

   # Restore NuGet packages
   dotnet restore

   # Update connection string in appsettings.json if needed
   # Current connection string format:
   # "Host=localhost;Database=postgres;Username=postgres;Password=postgres"
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

## PostgreSQL Connection String Format

The application uses Npgsql for PostgreSQL connectivity. Connection string format:

```
Host=<hostname>;Port=<port>;Database=<database>;Username=<username>;Password=<password>
```

**Connection String Parameters:**
- `Host` or `Server`: PostgreSQL server hostname (e.g., localhost)
- `Port`: PostgreSQL server port (default: 5432, can be omitted if using default)
- `Database`: Database name
- `Username` or `User Id`: PostgreSQL username
- `Password`: PostgreSQL password

**Optional Parameters:**
- `Timeout=<seconds>`: Connection timeout (default: 15)
- `Pooling=true|false`: Enable/disable connection pooling (default: true)
- `SSL Mode=<mode>`: SSL/TLS mode (Disable, Allow, Prefer, Require)
- `SearchPath=<schema>`: Default schema search path

**Example Connection Strings:**
```
# Development (local)
Host=localhost;Database=productmanagement;Username=postgres;Password=postgres

# Production (with SSL)
Host=prod-server.example.com;Port=5432;Database=productmanagement;Username=app_user;Password=secure_password;SSL Mode=Require

# With connection pooling settings
Host=localhost;Database=productmanagement;Username=postgres;Password=postgres;Pooling=true;Minimum Pool Size=5;Maximum Pool Size=100
```

## Key Features

- Modern async/await patterns for all database operations
- Proper resource management with IAsyncDisposable
- Dependency injection for configuration
- Transaction support with async operations
- Parameterized queries for security
- Connection pooling and management
- Error handling and logging
- PostgreSQL-specific features (RETURNING clause, NOW() function)

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
   # On Linux/Mac
   systemctl status postgresql
   # Or
   brew services list | grep postgresql
   
   # On Windows (check Services or use)
   pg_isready
   ```
2. Confirm your connection string matches your PostgreSQL instance configuration
3. Ensure the database was created successfully
4. Check you have appropriate permissions to access the database:
   ```sql
   -- In psql, check permissions
   \du
   ```
5. Make sure all required NuGet packages are restored:
   ```bash
   dotnet restore
   ```
6. Test PostgreSQL connection independently:
   ```bash
   psql -h localhost -U postgres -d productmanagement
   ```

## Required NuGet Packages

- Npgsql (PostgreSQL .NET data provider)
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

## Security Considerations

- All database queries use parameterization to prevent SQL injection
- Connection strings are stored securely in configuration
- Proper error handling and logging is implemented
- All database resources are properly disposed using async patterns
- Consider using SSL/TLS for production connections (`SSL Mode=Require`)
- Never commit connection strings with production credentials to version control
- Use environment variables or secure vaults for production credentials

## Best Practices Implemented

- Modern async/await patterns
- Proper resource disposal with IAsyncDisposable
- Transaction management with async support
- Error handling and logging
- Configuration management using .NET Core's IConfiguration
- Security best practices (parameterized queries)
- Dependency injection
- Separation of concerns (layered architecture)
- PostgreSQL-specific optimizations (RETURNING clause for INSERT operations)

## Migration from SQL Server

This application has been migrated from SQL Server to PostgreSQL. Key changes include:

1. **Package Changes:**
   - Replaced `Microsoft.Data.SqlClient` with `Npgsql`

2. **Class Replacements:**
   - `SqlConnection` → `NpgsqlConnection`
   - `SqlCommand` → `NpgsqlCommand`
   - `SqlDataReader` → `NpgsqlDataReader`

3. **SQL Syntax Updates:**
   - `SCOPE_IDENTITY()` → `RETURNING` clause
   - `GETDATE()` → `NOW()`
   - SQL Server transactions → PostgreSQL transaction handling

4. **Connection String Format:**
   - Changed from SQL Server format to PostgreSQL format
   - Updated parameters (Server→Host, Trusted_Connection→Username/Password)

## Deployment to AWS EC2

1. Install PostgreSQL on the EC2 instance or use Amazon RDS for PostgreSQL
2. Update the production connection string in appsettings.json
3. Configure security groups to allow PostgreSQL connections (port 5432)
4. Deploy the application using Visual Studio's Publish feature or CI/CD pipeline
5. Consider using AWS Secrets Manager for connection string storage
6. Enable SSL/TLS for production database connections

## Useful PostgreSQL Commands

```bash
# Connect to PostgreSQL
psql -h localhost -U postgres

# List databases
\l

# Connect to a database
\c productmanagement

# List tables
\dt

# Describe table structure
\d products

# Run SQL file
\i /path/to/script.sql

# Exit psql
\q
```

## PostgreSQL Client Tools

- **pgAdmin**: Full-featured GUI for PostgreSQL administration
- **psql**: Command-line interface (included with PostgreSQL installation)
- **Azure Data Studio**: Microsoft's cross-platform database tool with PostgreSQL extension
- **DBeaver**: Universal database tool with PostgreSQL support
- **DataGrip**: JetBrains' database IDE with excellent PostgreSQL support
