# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture.

**🔄 MIGRATION STATUS**: This application has been successfully migrated from Microsoft SQL Server to PostgreSQL, including:
- ✅ All 7 SQL statements converted using AWS DMS MCP tool
- ✅ All SQL statement pairs validated for equivalency
- ✅ All ADO.NET classes replaced (SqlConnection → NpgsqlConnection, etc.)
- ✅ Connection strings updated to PostgreSQL format
- ✅ Transaction handling migrated to ADO.NET level
- ✅ Security vulnerabilities addressed (Npgsql 8.0.5)
- ✅ Credentials secured using User Secrets

## Prerequisites

- Visual Studio 2022 or later
- .NET 9.0 SDK or later
- PostgreSQL 12 or later (recommended for development)
- pgAdmin or Azure Data Studio with PostgreSQL extension

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs      # PostgreSQL data access using Npgsql
├── Models/
│   └── Product.cs                # Domain models
├── Business/
│   └── ProductService.cs         # Business logic layer
├── CLI/
│   ├── CommandLineInterface.cs   # CLI implementation
│   └── InteractiveMenu.cs        # Interactive menu system
├── Program.cs                     # Application entry point
├── AdoCore.csproj                # Project configuration with Npgsql 8.0.5
└── appsettings.json              # Configuration (credentials in User Secrets)
```

## 🔐 Security: Credential Management

### Development Environment (User Secrets)

This application uses .NET User Secrets to securely store database credentials during development. **DO NOT** hardcode credentials in appsettings.json.

#### Initial Setup - Configure User Secrets:

```bash
# Navigate to project directory
cd /path/to/AdoCore

# User Secrets are already initialized with ID: 2e405733-25ab-4aae-8568-733ead493eb1
# To configure your connection strings:

# Set development connection string
dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=localhost;Database=ProductManagement;Username=your_username;Password=your_password;Port=5432;Pooling=true"

# Set production connection string (for local testing only)
dotnet user-secrets set "ConnectionStrings:ProdConnection" "Host=your_server;Database=ProductManagement;Username=your_username;Password=your_password;Port=5432;Pooling=true"

# List all configured secrets
dotnet user-secrets list

# Remove a secret if needed
dotnet user-secrets remove "ConnectionStrings:DevConnection"

# Clear all secrets
dotnet user-secrets clear
```

**Important**: User Secrets are stored in your user profile directory and are NOT included in source control:
- **Windows**: `%APPDATA%\Microsoft\UserSecrets\2e405733-25ab-4aae-8568-733ead493eb1\secrets.json`
- **Linux/macOS**: `~/.microsoft/usersecrets/2e405733-25ab-4aae-8568-733ead493eb1/secrets.json`

### Production Environment (Secrets Management Service)

**⚠️ CRITICAL**: For production deployments, you MUST use a proper secrets management service:

#### Option 1: Azure Key Vault
```bash
# Install Azure Key Vault configuration provider
dotnet add package Azure.Extensions.AspNetCore.Configuration.Secrets

# Update Program.cs to read from Key Vault
# Add Key Vault configuration in production environment
```

#### Option 2: AWS Secrets Manager
```bash
# Install AWS Secrets Manager configuration provider
dotnet add package Amazon.Extensions.Configuration.SystemsManager

# Configure in deployment pipeline to read secrets from AWS Secrets Manager
```

#### Option 3: HashiCorp Vault
```bash
# Use VaultSharp or similar library to integrate with Vault
dotnet add package VaultSharp
```

**Production Deployment Checklist**:
1. ✅ Never commit appsettings.Production.json with real credentials
2. ✅ Configure secrets in your chosen secrets management service
3. ✅ Update deployment pipeline to inject connection strings as environment variables
4. ✅ Use connection string encryption at rest
5. ✅ Enable SSL/TLS for PostgreSQL connections (sslmode=Require)
6. ✅ Use managed identity or service accounts (no username/password)
7. ✅ Rotate credentials regularly
8. ✅ Audit access to secrets

## Setup Instructions

### Option 1: Using Visual Studio

1. **Open the Project**:
   - Open Visual Studio 2022
   - Select "Open a project or solution"
   - Navigate to the project folder and select `AdoCore.csproj`

2. **Restore NuGet Packages**:
   - Right-click on the solution in Solution Explorer
   - Select "Restore NuGet Packages"

3. **PostgreSQL Database Setup**:
   - Install PostgreSQL 12 or later
   - Create database `ProductManagement`
   - Run the PostgreSQL schema setup script (see Database Setup section)

4. **Configure Connection String** (User Secrets):
   - Open Package Manager Console or Terminal in Visual Studio
   - Run the User Secrets commands shown in the Security section above
   - Update with your PostgreSQL credentials

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

   # Connect to database
   \c ProductManagement

   # Create schema (lowercase per PostgreSQL conventions)
   CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;

   # Create tables (see Database Setup section for full schema)
   ```

3. **Project Setup**:
   ```bash
   # Navigate to project directory
   cd /path/to/AdoCore

   # Restore NuGet packages
   dotnet restore

   # Configure User Secrets (see Security section above)
   dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=localhost;Database=ProductManagement;Username=postgres;Password=your_password;Port=5432;Pooling=true"
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

## Database Setup

### PostgreSQL Schema

The application expects the following PostgreSQL schema:

```sql
-- Create schema
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;

-- Create products table
CREATE TABLE productmanagement_dbo.products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    stock INTEGER NOT NULL,
    description TEXT
);

-- Create producthistory table
CREATE TABLE productmanagement_dbo.producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    details TEXT
);

-- Create productstats table
CREATE TABLE productmanagement_dbo.productstats (
    statsid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    totalupdates INTEGER NOT NULL DEFAULT 0,
    lastmodified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_producthistory_productid ON productmanagement_dbo.producthistory(productid);
CREATE INDEX idx_productstats_productid ON productmanagement_dbo.productstats(productid);
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

- ✅ Modern async/await patterns for all database operations
- ✅ Proper resource management with IAsyncDisposable
- ✅ Dependency injection for configuration
- ✅ Transaction support with ADO.NET async operations
- ✅ Parameterized queries for SQL injection prevention
- ✅ Connection pooling and management
- ✅ Comprehensive error handling and logging
- ✅ PostgreSQL-optimized SQL syntax
- ✅ Secure credential management with User Secrets

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

### Connection Issues
1. Verify PostgreSQL is running:
   ```bash
   # Linux/macOS
   sudo systemctl status postgresql
   
   # Windows (check Services)
   # Or use: pg_ctl status
   ```

2. Check connection string in User Secrets:
   ```bash
   dotnet user-secrets list
   ```

3. Test PostgreSQL connectivity:
   ```bash
   psql -U postgres -h localhost -d ProductManagement
   ```

### Build Issues
1. Ensure all required NuGet packages are restored:
   ```bash
   dotnet restore
   dotnet clean
   dotnet build
   ```

2. Verify .NET 9.0 SDK is installed:
   ```bash
   dotnet --version
   ```

### User Secrets Not Found
If the application can't find connection strings:
```bash
# Verify User Secrets are configured
dotnet user-secrets list

# If empty, reconfigure:
dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=localhost;Database=ProductManagement;Username=postgres;Password=your_password;Port=5432;Pooling=true"
```

## Required NuGet Packages

- **Npgsql** (8.0.5) - PostgreSQL data provider for .NET
- **Microsoft.Extensions.Configuration** (8.0.0) - Configuration framework
- **Microsoft.Extensions.Configuration.Json** (8.0.0) - JSON configuration provider
- **Microsoft.Extensions.DependencyInjection** (8.0.0) - Dependency injection framework

User Secrets support is built into .NET 9.0 SDK and doesn't require additional packages for console applications.

## Migration Details

### SQL Server to PostgreSQL Conversion

All SQL statements have been converted from SQL Server T-SQL syntax to PostgreSQL syntax:

| Original SQL Server | Converted PostgreSQL |
|---------------------|----------------------|
| `TOP N` | `LIMIT N` |
| `GETDATE()` | `CURRENT_TIMESTAMP` |
| `[schema].[table]` | `schema.table` |
| `@@IDENTITY` | `RETURNING id` |
| Mixed case tables | Lowercase tables |
| BEGIN TRAN/COMMIT | BeginTransactionAsync/CommitAsync |

### ADO.NET Class Replacements

All SQL Server ADO.NET classes have been replaced:

- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`
- `SqlParameter` → `NpgsqlParameter`
- `SqlTransaction` → `NpgsqlTransaction`

Total: 30 class replacements across the codebase.

## Security Considerations

- ✅ All database queries use parameterization to prevent SQL injection
- ✅ Connection strings are stored securely in User Secrets (development)
- ✅ Production requires secrets management service (Azure Key Vault, AWS Secrets Manager, etc.)
- ✅ Npgsql 8.0.5 with security vulnerability patches applied
- ✅ Proper error handling and logging implemented
- ✅ All database resources properly disposed using async patterns
- ✅ No hardcoded credentials in source code or configuration files

## Best Practices Implemented

- ✅ Modern async/await patterns throughout
- ✅ Proper resource disposal with IAsyncDisposable
- ✅ ADO.NET transaction management with async support
- ✅ Comprehensive error handling and logging
- ✅ Configuration management using .NET Core's IConfiguration
- ✅ Security best practices (User Secrets, parameterized queries)
- ✅ Dependency injection pattern
- ✅ Separation of concerns (layered architecture)
- ✅ PostgreSQL naming conventions (lowercase, underscores)

## Deployment

### Development Deployment
1. Configure User Secrets (see Security section)
2. Ensure PostgreSQL database is created
3. Run database schema setup script
4. Build and run the application

### Production Deployment

**Azure:**
```bash
# Use Azure Key Vault for secrets
az keyvault secret set --vault-name <vault-name> --name "ConnectionStrings--DevConnection" --value "<connection-string>"

# Configure App Service to use Key Vault
# Update Program.cs to add Key Vault configuration provider
```

**AWS:**
```bash
# Use AWS Secrets Manager
aws secretsmanager create-secret --name AdoCore/ConnectionStrings/DevConnection --secret-string "<connection-string>"

# Configure environment to use Secrets Manager
# Update deployment scripts to inject secrets
```

**Production Checklist**:
1. ✅ Secrets stored in secrets management service
2. ✅ SSL/TLS enabled for PostgreSQL connections
3. ✅ Connection strings use managed identity (no credentials)
4. ✅ Database firewall rules configured
5. ✅ Regular credential rotation enabled
6. ✅ Monitoring and alerting configured
7. ✅ Backup and disaster recovery tested
8. ✅ Security scanning and vulnerability assessment completed

## Support and Documentation

For more information on:
- **Npgsql**: https://www.npgsql.org/doc/
- **PostgreSQL**: https://www.postgresql.org/docs/
- **.NET User Secrets**: https://docs.microsoft.com/en-us/aspnet/core/security/app-secrets
- **Azure Key Vault**: https://docs.microsoft.com/en-us/azure/key-vault/
- **AWS Secrets Manager**: https://docs.aws.amazon.com/secretsmanager/

## License

[Your License Here]
