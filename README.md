# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture.

## ⚠️ IMPORTANT: Database Migration Notice

**This application has been migrated from Microsoft SQL Server to PostgreSQL.**

- **Previous Database**: Microsoft SQL Server  
- **Current Database**: PostgreSQL 12+ (using Npgsql 8.0.5)
- **Migration Status**: ✅ Complete - All 7 SQL statements converted and validated
- **Build Status**: ✅ Successful (0 errors, 0 warnings)

📖 **For detailed PostgreSQL setup instructions, see [POSTGRESQL_MIGRATION_GUIDE.md](POSTGRESQL_MIGRATION_GUIDE.md)**

## Quick Start

### Prerequisites

- .NET 9.0 SDK or later
- **PostgreSQL 12+** (recommended: PostgreSQL 15+)
- PostgreSQL client (pgAdmin 4, DBeaver, or psql)

### Setup Steps

1. **Install PostgreSQL**: Download from https://www.postgresql.org/download/

2. **Create Database and Schema**:
   ```bash
   psql -U postgres
   CREATE DATABASE productmanagement;
   \c productmanagement
   \i Database/Scripts/01_PostgreSQL_Setup.sql
   \q
   ```

3. **Configure Connection String**: Update `appsettings.json`:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Database=productmanagement;Username=postgres;Password=YOUR_PASSWORD;Port=5432"
     },
     "Environment": "Development"
   }
   ```

4. **Build and Run**:
   ```bash
   cd sourceCode
   dotnet build
   dotnet run -- list
   ```

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs    # PostgreSQL data access with Npgsql
├── Models/
│   └── Product.cs
├── Business/
│   └── ProductService.cs
├── CLI/
│   ├── CommandLineInterface.cs
│   └── InteractiveMenu.cs
├── Database/
│   └── Scripts/
│       ├── 01_PostgreSQL_Setup.sql       # PostgreSQL schema (NEW)
│       └── 01_InitialSetup.sql          # Original SQL Server schema
├── Program.cs
├── AdoCore.csproj
├── appsettings.json
├── POSTGRESQL_MIGRATION_GUIDE.md        # Detailed migration guide
└── README_SQLSERVER_ORIGINAL.md         # Original SQL Server README
```

## Running the Application

### Interactive Mode

```bash
dotnet run
```

Menu options:
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

# Show help
dotnet run -- --help
```

## Key Features

- ✅ Modern async/await patterns for all database operations
- ✅ PostgreSQL native support via Npgsql 8.0.5
- ✅ Proper resource management with IAsyncDisposable
- ✅ Dependency injection for configuration
- ✅ Transaction support with async operations
- ✅ Parameterized queries for security (SQL injection prevention)
- ✅ Connection pooling and management
- ✅ Comprehensive error handling
- ✅ Complex SQL features:
  - Common Table Expressions (CTEs)
  - Window functions (LAG, RANK, PERCENT_RANK, AVG OVER, COUNT OVER)
  - JOIN operations
  - Triggers for audit logging

## Testing the Application

1. **Verify database connection**:
   ```bash
   dotnet run -- list
   ```
   Should display 18 products from the sample data.

2. **Test CRUD operations**:
   ```bash
   # Create
   dotnet run -- add "Test Product" 29.99 5 "Test Description"
   
   # Read
   dotnet run -- get <product_id>
   
   # Update
   dotnet run -- update <product_id> "Updated Product" 39.99 10 "Updated"
   
   # Delete
   dotnet run -- delete <product_id>
   ```

3. **Verify transactions**: All Insert/Update/Delete operations use PostgreSQL transactions for atomicity.

## Migration Details

### SQL Statement Conversions

All 7 SQL statements were processed through AWS DMS and validated:

| Method | Conversion Status | Complexity |
|--------|------------------|------------|
| GetAllProductsAsync | ✅ DMS + Manual | High (CTE, multiple window functions) |
| GetProductByIdAsync | ✅ DMS | Low |
| InsertProductAsync | ⚠️ Manual after DMS | Medium (RETURNING clause) |
| UpdateProductAsync | ✅ DMS | Medium |
| DeleteProductAsync | ✅ DMS | Medium |
| GetProductsByCategoryAsync | ✅ DMS | High (JOIN, window functions) |
| UpdateProductStockAsync | ✅ DMS | Medium |

### Schema Changes

| SQL Server | PostgreSQL |
|------------|------------|
| `dbo` schema | `productmanagement_dbo` schema |
| `NVARCHAR` | `VARCHAR` (UTF-8 default) |
| `DATETIME` | `TIMESTAMP` |
| `BIT` | `BOOLEAN` |
| `IDENTITY(1,1)` | `SERIAL` |
| `GETDATE()` | `CURRENT_TIMESTAMP` |
| PascalCase names | lowercase names |

### Package Changes

| Removed | Added |
|---------|-------|
| Microsoft.Data.SqlClient | Npgsql 8.0.5 |
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |
| SqlParameter | NpgsqlParameter |

## Required NuGet Packages

Current packages (after migration):
- **Npgsql 8.0.5** (PostgreSQL provider)
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

## Troubleshooting

### Database Connection Issues

**Problem**: "password authentication failed"  
**Solution**: 
- Verify password in `appsettings.json`
- Check PostgreSQL `pg_hba.conf` authentication method
- Ensure user has correct permissions

**Problem**: "database does not exist"  
**Solution**: Run `CREATE DATABASE productmanagement;` in psql

**Problem**: "schema does not exist"  
**Solution**: Run `Database/Scripts/01_PostgreSQL_Setup.sql`

**Problem**: "relation does not exist"  
**Solution**: Verify table names are lowercase and prefixed with `productmanagement_dbo.`

### Application Issues

**Problem**: Build fails  
**Solution**:
```bash
dotnet restore
dotnet clean
dotnet build
```

**Problem**: Connection timeout  
**Solution**:
- Verify PostgreSQL is running
- Check port 5432 is open
- Verify firewall settings

## Security Best Practices

- ✅ All queries use parameterization (SQL injection protection)
- ✅ Connection strings support environment variables
- ⚠️ **TODO**: Move credentials to environment variables or secrets manager
- ✅ Proper resource disposal with async patterns
- ⚠️ **TODO**: Enable SSL/TLS for production (`SSL Mode=Require`)
- ✅ Transaction support for data integrity
- ✅ Error handling without exposing sensitive information

### Recommended for Production

1. **Use environment variables** for connection strings:
   ```bash
   export ConnectionStrings__DevConnection="Host=...;Username=...;Password=..."
   ```

2. **Enable SSL**:
   ```
   Host=db.example.com;Database=productmanagement;Username=user;Password=pass;SSL Mode=Require
   ```

3. **Create dedicated database user** (not postgres superuser):
   ```sql
   CREATE USER adocore_user WITH PASSWORD 'secure_password';
   GRANT CONNECT ON DATABASE productmanagement TO adocore_user;
   GRANT ALL PRIVILEGES ON SCHEMA productmanagement_dbo TO adocore_user;
   ```

4. **Use secrets management**:
   - AWS Secrets Manager
   - Azure Key Vault
   - HashiCorp Vault

## Documentation

- **[POSTGRESQL_MIGRATION_GUIDE.md](POSTGRESQL_MIGRATION_GUIDE.md)** - Comprehensive migration documentation
- **[README_SQLSERVER_ORIGINAL.md](README_SQLSERVER_ORIGINAL.md)** - Original SQL Server documentation
- **`final_migration_report.json`** - Detailed migration report with all SQL statements
- **`sql_equivalency_validation_report.json`** - SQL equivalency validation results
- **`dms_conversion_log.json`** - AWS DMS conversion log
- **`converted_statements.sql`** - All converted PostgreSQL statements
- **`extracted_statements.sql`** - All original SQL Server statements

## Development Workflow

```bash
# 1. Make code changes

# 2. Build
dotnet build

# 3. Run tests (if available)
dotnet test

# 4. Run application
dotnet run

# 5. Deploy (see POSTGRESQL_MIGRATION_GUIDE.md for deployment checklist)
```

## Performance Considerations

- **Connection Pooling**: Enabled by default in Npgsql
  ```
  Pooling=true;MinPoolSize=5;MaxPoolSize=50
  ```

- **Indexes**: All necessary indexes created during schema setup
  - Products: categoryid, supplierid, sku (unique)
  - ProductHistory: productid, actiondate

- **Query Optimization**: Monitor with `EXPLAIN ANALYZE`
  ```sql
  EXPLAIN ANALYZE SELECT * FROM productmanagement_dbo.products WHERE categoryid = 1;
  ```

- **Maintenance**: Enable autovacuum for optimal performance
  ```sql
  ALTER TABLE productmanagement_dbo.products SET (autovacuum_enabled = true);
  ```

## Additional Resources

- **Npgsql Documentation**: https://www.npgsql.org/doc/
- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Migration Artifacts**: See root directory for detailed logs and reports
- **SQL Server to PostgreSQL**: https://wiki.postgresql.org/wiki/Things_to_find_out_about_when_moving_from_MySQL_to_PostgreSQL

## Support

For issues related to:
- **Migration**: Review migration artifacts (JSON files in root)
- **PostgreSQL Setup**: See POSTGRESQL_MIGRATION_GUIDE.md
- **Application**: Check build.log and error messages
- **Database**: Check PostgreSQL logs (`pg_log` directory)

## License

[Your License Here]

## Contributors

[Your Contributors Here]

---

**Note**: This application was successfully migrated from SQL Server to PostgreSQL with all SQL statements validated for equivalency. The migration followed AWS best practices using DMS for SQL conversion and comprehensive validation.
