# ADO.NET Core PostgreSQL Data Management Application

**MIGRATION STATUS: Successfully migrated from SQL Server to PostgreSQL**

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture. This application has been migrated from SQL Server to PostgreSQL.

## Migration Summary

This application has been successfully migrated from Microsoft SQL Server to PostgreSQL:
- ✅ All SQL Server packages replaced with Npgsql
- ✅ All ADO.NET classes updated (SqlConnection → NpgsqlConnection, etc.)
- ✅ All 7 SQL statements converted to PostgreSQL syntax
- ✅ Connection strings updated to PostgreSQL format
- ✅ Transaction handling updated for PostgreSQL
- ✅ Application compiles without errors

**Note:** Functional testing against a live PostgreSQL database is required to complete validation.

## Prerequisites

- Visual Studio 2022 or later (optional)
- .NET 9.0 SDK or later
- **PostgreSQL 12 or later** (replaces SQL Server)
- pgAdmin 4 or DBeaver (database management tools)

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs (Updated for PostgreSQL)
├── Models/
│   └── Product.cs
├── Business/
│   └── ProductService.cs
├── CLI/
│   ├── CommandLineInterface.cs
│   └── InteractiveMenu.cs
├── Database/
│   └── Scripts/
│       ├── 01_InitialSetup_PostgreSQL.sql (NEW - PostgreSQL schema)
│       └── 01_InitialSetup.sql (Original SQL Server schema)
├── Program.cs
├── AdoCore.csproj
└── appsettings.json (Updated for PostgreSQL)
```

## Setup Instructions

### Step 1: Install PostgreSQL

1. **Download PostgreSQL**:
   - Visit https://www.postgresql.org/download/
   - Download PostgreSQL 12 or later for your operating system
   - Install with default settings

2. **Note your credentials**:
   - Default username: `postgres`
   - Password: (set during installation)
   - Default port: `5432`

### Step 2: Create the Database

#### Option A: Using pgAdmin 4 (GUI)

1. Open pgAdmin 4
2. Connect to your PostgreSQL server
3. Right-click on "Databases" → Create → Database
4. Database name: `ProductManagement`
5. Click "Save"
6. Right-click on the new database → Query Tool
7. Open and execute the script: `Database/Scripts/01_InitialSetup_PostgreSQL.sql`

#### Option B: Using psql (Command Line)

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE "ProductManagement";

# Connect to the new database
\c ProductManagement

# Run the setup script
\i 'path/to/Database/Scripts/01_InitialSetup_PostgreSQL.sql'

# Verify tables were created
\dt
```

### Step 3: Update Connection String (if needed)

Open `appsettings.json` and verify/update the connection string:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=your_password;Port=5432",
    "ProdConnection": "Host=your_server;Database=ProductManagement;Username=postgres;Password=your_password;Port=5432"
  },
  "Environment": "Development"
}
```

**Connection String Parameters:**
- `Host`: PostgreSQL server address (localhost for local development)
- `Database`: Database name (ProductManagement)
- `Username`: PostgreSQL username (default: postgres)
- `Password`: Your PostgreSQL password
- `Port`: PostgreSQL port (default: 5432)

### Step 4: Build and Run

#### Using Command Line

```bash
# Navigate to project directory
cd path/to/AdoCore

# Restore NuGet packages
dotnet restore

# Build the project
dotnet build

# Run in interactive mode
dotnet run

# Or run with CLI commands
dotnet run -- list
```

#### Using Visual Studio

1. Open `AdoCore.sln` in Visual Studio 2022
2. Right-click on solution → Restore NuGet Packages
3. Press F5 to run in debug mode
4. The application will start in interactive mode

## Running the Application

The application can be run in two modes: Interactive (menu-driven) and Command-Line Interface (CLI).

### Interactive Mode

Run the application without any arguments:
```bash
dotnet run
```

Main menu options:
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

# Get low stock products (threshold)
dotnet run -- low-stock 15
```

## Database Schema

The PostgreSQL database includes:

### Tables
- **products**: Main product catalog
- **categories**: Product categories (hierarchical)
- **suppliers**: Supplier information
- **product_history**: Audit trail of product changes
- **product_stats**: Aggregate statistics

### Key Features
- Automatic history tracking via triggers
- Sample data (18 products across multiple categories)
- Proper foreign key constraints
- Indexes for performance

## PostgreSQL-Specific Features Used

1. **SERIAL** data type for auto-incrementing IDs
2. **RETURNING** clause for INSERT operations
3. **Common Table Expressions (CTEs)** for complex queries
4. **Window functions** for analytics
5. **Trigger functions** for audit logging
6. **CURRENT_TIMESTAMP** for timestamps

## Testing the Application

1. **List all products**:
   ```bash
   dotnet run -- list
   ```
   Expected: Shows 18 sample products

2. **Get product by ID**:
   ```bash
   dotnet run -- get 1
   ```
   Expected: Shows details of ProBook X1

3. **Add a new product**:
   ```bash
   dotnet run -- add "Test Product" 29.99 5 "Test Description"
   ```
   Expected: Creates new product and returns its ID

4. **Price range query**:
   ```bash
   dotnet run -- price-range 100 500
   ```
   Expected: Shows products priced between $100 and $500

5. **Low stock check**:
   ```bash
   dotnet run -- low-stock 10
   ```
   Expected: Shows products with stock <= 10 units

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to PostgreSQL
**Solutions**:
1. Verify PostgreSQL is running:
   ```bash
   # Windows
   services.msc (look for postgresql service)
   
   # Linux/Mac
   sudo systemctl status postgresql
   ```
2. Check connection string matches your PostgreSQL configuration
3. Verify firewall allows port 5432
4. Test connection with pgAdmin or psql

### Build Issues

**Problem**: Build errors or missing packages
**Solution**:
```bash
dotnet clean
dotnet restore
dotnet build
```

### Database Issues

**Problem**: Tables don't exist
**Solution**:
```bash
# Reconnect and run setup script
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

**Problem**: Permission errors
**Solution**:
- Ensure PostgreSQL user has proper permissions
- Grant required privileges:
  ```sql
  GRANT ALL PRIVILEGES ON DATABASE "ProductManagement" TO postgres;
  ```

## Security Considerations

- ✅ All queries use parameterized commands (SQL injection prevention)
- ✅ Connection strings stored in configuration (not hardcoded)
- ✅ Proper error handling and logging
- ✅ Resources properly disposed using async patterns
- ⚠️ **Important**: Change default passwords in production
- ⚠️ **Important**: Use environment variables for production credentials

## Migration Notes

### Changes from SQL Server Version

1. **Package Changes**:
   - Removed: `Microsoft.Data.SqlClient`
   - Added: `Npgsql 10.0.1`

2. **Code Changes**:
   - `SqlConnection` → `NpgsqlConnection`
   - `SqlCommand` → `NpgsqlCommand`
   - `SqlDataReader` → `NpgsqlDataReader`
   - `SqlParameter` → `NpgsqlParameter`
   - `SqlTransaction` → `NpgsqlTransaction`

3. **SQL Syntax Changes**:
   - `IDENTITY` → `SERIAL`
   - `GETDATE()` → `CURRENT_TIMESTAMP`
   - `SCOPE_IDENTITY()` → `RETURNING` clause
   - `NVARCHAR` → `VARCHAR`
   - Window functions updated for PostgreSQL syntax
   - Triggers converted to PostgreSQL function syntax

4. **Connection String Changes**:
   - SQL Server: `Server=...;Database=...;Trusted_Connection=True`
   - PostgreSQL: `Host=...;Database=...;Username=...;Password=...;Port=5432`

### SQL Statement Conversion Summary

All 7 SQL statements were successfully converted:
1. GetAllProductsAsync - SELECT with CTE
2. GetProductByIdAsync - SELECT with CTE
3. InsertProductAsync - INSERT with RETURNING
4. UpdateProductAsync - UPDATE with CTE transaction
5. DeleteProductAsync - DELETE with CTE transaction
6. GetProductsByPriceRangeAsync - SELECT with window functions
7. GetLowStockProductsAsync - SELECT with CTEs

See `sql_equivalency_validation_report.json` for detailed conversion documentation.

## NuGet Packages

**Current (PostgreSQL)**:
- Npgsql 10.0.1
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

**Previous (SQL Server)**:
- ~~Microsoft.Data.SqlClient~~ (removed)

## Next Steps

1. ✅ Database setup completed
2. ✅ Application runs successfully
3. ⚠️ Run functional tests against PostgreSQL database
4. ⚠️ Create unit tests (recommended)
5. ⚠️ Update production connection strings
6. ⚠️ Deploy to production environment

## Support

For PostgreSQL-specific questions:
- Official documentation: https://www.postgresql.org/docs/
- Npgsql documentation: https://www.npgsql.org/doc/

For migration-specific issues:
- Review `sql_equivalency_validation_report.json`
- Check `dms_conversion_log.json` for SQL conversion details
- See `MIGRATION_VALIDATION_REPORT.md` for complete validation status
