# PostgreSQL Migration Guide

This document provides detailed instructions for setting up and running the migrated ADO.NET application with PostgreSQL.

## Prerequisites

- .NET 9.0 SDK or later
- PostgreSQL 12 or later (recommended: PostgreSQL 15+)
- pgAdmin 4 or another PostgreSQL management tool
- Basic knowledge of PostgreSQL administration

## Migration Summary

This application has been successfully migrated from Microsoft SQL Server to PostgreSQL. The migration included:

✅ All SQL Server packages replaced with Npgsql (PostgreSQL .NET driver)
✅ All ADO.NET classes updated (SqlConnection → NpgsqlConnection, etc.)
✅ All SQL statements converted to PostgreSQL syntax
✅ Connection strings updated to PostgreSQL format
✅ Transaction handling updated for PostgreSQL
✅ Application compiles successfully with zero errors

## Database Setup

### Step 1: Install PostgreSQL

1. **Download PostgreSQL:**
   - Visit https://www.postgresql.org/download/
   - Download and install PostgreSQL for your operating system
   - During installation, set a password for the `postgres` superuser
   - Note the port number (default: 5432)

2. **Verify Installation:**
   ```bash
   psql --version
   # Should display PostgreSQL version 12.x or higher
   ```

### Step 2: Create the Database

1. **Connect to PostgreSQL:**
   
   **Option A: Using psql (command line):**
   ```bash
   psql -U postgres -h localhost
   # Enter the postgres user password when prompted
   ```

   **Option B: Using pgAdmin:**
   - Open pgAdmin
   - Connect to your PostgreSQL server
   - Right-click on "Databases" → "Create" → "Database"

2. **Create the ProductManagement Database:**
   ```sql
   CREATE DATABASE ProductManagement;
   ```

3. **Connect to the new database:**
   ```bash
   \c ProductManagement
   ```

### Step 3: Run the Schema Setup Script

1. **Locate the PostgreSQL setup script:**
   - File: `Database/Scripts/01_InitialSetup_PostgreSQL.sql`

2. **Execute the script:**

   **Option A: Using psql:**
   ```bash
   psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
   ```

   **Option B: Using pgAdmin:**
   - Connect to the ProductManagement database
   - Open Query Tool (Tools → Query Tool)
   - Open the file `01_InitialSetup_PostgreSQL.sql`
   - Execute the script (F5 or click Execute)

3. **Verify the setup:**
   ```sql
   -- List all tables
   \dt
   
   -- Check that sample data was inserted
   SELECT COUNT(*) FROM Products;
   -- Should return 18
   
   SELECT COUNT(*) FROM Categories;
   -- Should return 20
   
   SELECT COUNT(*) FROM Suppliers;
   -- Should return 8
   ```

## Application Configuration

### Step 1: Update Connection String

1. Open `appsettings.json` in the project root
2. Update the connection string with your PostgreSQL credentials:

   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Port=5432",
       "ProdConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Port=5432"
     },
     "Environment": "Development"
   }
   ```

3. Replace `YOUR_PASSWORD` with your actual PostgreSQL password

### Connection String Parameters Explained:

- **Host**: PostgreSQL server hostname (localhost for local development)
- **Database**: Database name (ProductManagement)
- **Username**: PostgreSQL user (postgres is the default superuser)
- **Password**: PostgreSQL user password
- **Port**: PostgreSQL server port (default: 5432)

### Optional Parameters:

```
Host=localhost;Database=ProductManagement;Username=postgres;Password=your_password;Port=5432;Timeout=30;CommandTimeout=30;Pooling=true;MinPoolSize=1;MaxPoolSize=20
```

- **Timeout**: Connection timeout in seconds (default: 15)
- **CommandTimeout**: Command execution timeout in seconds (default: 30)
- **Pooling**: Enable connection pooling (default: true)
- **MinPoolSize**: Minimum number of connections in pool (default: 1)
- **MaxPoolSize**: Maximum number of connections in pool (default: 100)

## Running the Application

### Option 1: Using Command Line

1. **Navigate to the project directory:**
   ```bash
   cd /path/to/sourceCode
   ```

2. **Restore packages (first time only):**
   ```bash
   dotnet restore
   ```

3. **Build the application:**
   ```bash
   dotnet build
   ```

4. **Run the application:**
   
   **Interactive Mode:**
   ```bash
   dotnet run
   ```

   **CLI Commands:**
   ```bash
   # List all products
   dotnet run -- list

   # Get product by ID
   dotnet run -- get 1

   # Add new product
   dotnet run -- add "New Product" 99.99 10 "Product description"

   # Update product
   dotnet run -- update 1 "Updated Product" 109.99 15 "Updated description"

   # Delete product
   dotnet run -- delete 1

   # Update stock quantity
   dotnet run -- stock 1 25

   # Show help
   dotnet run -- --help
   ```

### Option 2: Using Visual Studio

1. Open `AdoCore.sln` in Visual Studio 2022
2. Ensure the connection string in `appsettings.json` is correct
3. Press F5 to run with debugging or Ctrl+F5 to run without debugging

## Testing Database Operations

### Test 1: Verify Connection

```bash
dotnet run -- list
```

Expected output: List of all products from the database

### Test 2: Test INSERT Operation

```bash
dotnet run -- add "Test Product" 29.99 5 "This is a test product"
```

Expected output: Success message with new ProductId

### Test 3: Test SELECT Operation

```bash
dotnet run -- get 1
```

Expected output: Details of product with ID 1

### Test 4: Test UPDATE Operation

```bash
dotnet run -- update 1 "Updated Product Name" 39.99 10 "Updated description"
```

Expected output: Success message

### Test 5: Test DELETE Operation

```bash
dotnet run -- delete 19
```

Expected output: Success message (deleting the test product)

### Test 6: Verify Transaction Handling

The application uses transactions for complex operations. You can verify this by:

1. Using the interactive mode to perform operations
2. Checking the ProductHistory table for audit records:

   ```sql
   SELECT * FROM ProductHistory ORDER BY ActionDate DESC LIMIT 10;
   ```

## Database Schema

### Tables Created:

1. **Categories** - Product categories with hierarchical structure
2. **Suppliers** - Supplier information
3. **Products** - Main product information
4. **ProductHistory** - Audit trail for product changes
5. **ProductStats** - Aggregated statistics

### Key Features:

- **Foreign Keys**: Enforced referential integrity
- **Triggers**: Automatic audit logging in ProductHistory
- **Indexes**: Optimized for common queries
- **Sample Data**: 18 products, 20 categories, 8 suppliers

## Troubleshooting

### Issue: "Failed to connect to the database"

**Solution:**
1. Verify PostgreSQL is running:
   ```bash
   # Linux/Mac
   sudo systemctl status postgresql
   
   # Windows (Services)
   services.msc → look for "postgresql-x64-XX"
   ```

2. Check connection string parameters:
   - Host is correct (localhost or server IP)
   - Port is correct (default: 5432)
   - Database name exists
   - Username and password are correct

3. Test connection using psql:
   ```bash
   psql -U postgres -h localhost -d ProductManagement
   ```

### Issue: "Password authentication failed"

**Solution:**
1. Verify the password in appsettings.json matches your PostgreSQL password
2. If you forgot the password, reset it:
   ```sql
   -- As superuser
   ALTER USER postgres WITH PASSWORD 'new_password';
   ```

### Issue: "Database 'ProductManagement' does not exist"

**Solution:**
```bash
psql -U postgres -h localhost
CREATE DATABASE ProductManagement;
\q
```

### Issue: "Table does not exist"

**Solution:**
Run the schema setup script:
```bash
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

### Issue: Build errors or missing packages

**Solution:**
```bash
dotnet clean
dotnet restore
dotnet build
```

## Migration Artifacts

The following files document the migration process:

1. **extracted_statements.sql** - Original SQL Server statements
2. **converted_statements.sql** - Converted PostgreSQL statements
3. **dms_conversion_log.json** - DMS conversion log
4. **sql_equivalency_validation_report.json** - Equivalency validation report
5. **final_migration_report.json** - Comprehensive migration report

## Key Differences from SQL Server

### Syntax Changes:
- `IDENTITY` → `SERIAL` (auto-increment)
- `GETDATE()` → `CURRENT_TIMESTAMP`
- `BIT` → `BOOLEAN`
- `NVARCHAR` → `VARCHAR`
- `SCOPE_IDENTITY()` → Not needed (use RETURNING clause)

### Transaction Changes:
- Transactions are handled at the ADO.NET layer using `NpgsqlTransaction`
- No need for `BEGIN TRANSACTION`, `COMMIT`, or `ROLLBACK` in SQL statements

### Trigger Changes:
- Triggers require a separate function in PostgreSQL
- Use `CREATE OR REPLACE FUNCTION` + `CREATE TRIGGER`

## Performance Considerations

1. **Connection Pooling**: Enabled by default in Npgsql
2. **Prepared Statements**: Automatically used by parameterized queries
3. **Async Operations**: All database operations use async/await patterns
4. **Indexing**: Appropriate indexes created on foreign keys and common query columns

## Security Best Practices

1. **Never commit credentials** to source control
2. **Use environment variables** for production credentials
3. **Restrict database user permissions** (don't use postgres superuser in production)
4. **Enable SSL/TLS** for production connections
5. **Use parameterized queries** (already implemented)

## Production Deployment

For production deployments:

1. Create a dedicated PostgreSQL user with limited permissions:
   ```sql
   CREATE USER app_user WITH PASSWORD 'secure_password';
   GRANT CONNECT ON DATABASE ProductManagement TO app_user;
   GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
   GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;
   ```

2. Update connection string to use the new user:
   ```json
   {
     "ConnectionStrings": {
       "ProdConnection": "Host=prod-server;Database=ProductManagement;Username=app_user;Password=secure_password;Port=5432;SSL Mode=Require"
     }
   }
   ```

3. Enable SSL/TLS in production
4. Consider using connection string encryption or Azure Key Vault
5. Implement proper logging and monitoring

## Additional Resources

- **Npgsql Documentation**: https://www.npgsql.org/doc/
- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **PostgreSQL Tutorial**: https://www.postgresqltutorial.com/

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the migration artifacts for detailed conversion information
3. Consult Npgsql and PostgreSQL documentation
