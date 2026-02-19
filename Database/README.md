# PostgreSQL Database Setup Guide

This guide provides instructions for setting up the PostgreSQL database required for the AdoCore application after migration from SQL Server.

## Prerequisites

1. PostgreSQL 12 or higher installed
2. PostgreSQL server running on localhost (or update connection string accordingly)
3. Access to create databases and execute SQL scripts

## Setup Instructions

### Step 1: Install PostgreSQL

If PostgreSQL is not already installed, download and install it from:
https://www.postgresql.org/download/

### Step 2: Create Database

Connect to PostgreSQL using psql or your preferred PostgreSQL client:

```bash
psql -U postgres
```

Create the ProductManagement database:

```sql
CREATE DATABASE "ProductManagement";
```

Exit psql:
```
\q
```

### Step 3: Execute Setup Script

Run the PostgreSQL setup script to create all tables, indexes, triggers, and sample data:

```bash
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

Or using psql interactive mode:
```bash
psql -U postgres -d ProductManagement
\i Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

### Step 4: Verify Setup

Connect to the database and verify tables were created:

```bash
psql -U postgres -d ProductManagement
```

List all tables:
```sql
\dt
```

You should see:
- categories
- suppliers
- products
- producthistory
- productstats

Check sample data was loaded:
```sql
SELECT COUNT(*) FROM Products;
-- Should return 19 products

SELECT COUNT(*) FROM Categories;
-- Should return 20 categories

SELECT COUNT(*) FROM Suppliers;
-- Should return 8 suppliers
```

### Step 5: Update Connection String (if needed)

If your PostgreSQL server is not running on localhost with default credentials, update the connection string in `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=your-host;Database=ProductManagement;Username=your-username;Password=your-password;Port=5432;Pooling=true"
  }
}
```

## Database Schema Overview

### Tables Created

1. **Categories** - Product categories with hierarchical support
2. **Suppliers** - Supplier information
3. **Products** - Main product catalog
4. **ProductHistory** - Audit trail for product changes
5. **ProductStats** - Aggregated product statistics

### Functions Created (PostgreSQL equivalents of SQL Server stored procedures)

1. **sp_GetAllProducts()** - Returns all products ordered by name
2. **sp_GetProductById(ProductId)** - Returns a specific product by ID
3. **sp_InsertProduct(Name, Description, Price, StockQuantity)** - Inserts a new product
4. **sp_UpdateProduct(ProductId, Name, Description, Price, StockQuantity)** - Updates an existing product
5. **sp_DeleteProduct(ProductId)** - Deletes a product

### Triggers Created

1. **trg_Products_History** - Automatically logs all INSERT, UPDATE, and DELETE operations on Products table to ProductHistory

## Testing Database Connection

Build and run the application to test the database connection:

```bash
dotnet build
dotnet run
```

The application should successfully connect to PostgreSQL and execute database operations.

## Troubleshooting

### Connection Issues

If you encounter connection errors:

1. Verify PostgreSQL is running:
   ```bash
   sudo systemctl status postgresql  # Linux
   brew services list | grep postgres  # macOS
   ```

2. Check pg_hba.conf for authentication settings
   - Location: Usually in PostgreSQL data directory
   - Ensure local connections are allowed

3. Verify credentials in appsettings.json match your PostgreSQL setup

### Permission Issues

If you encounter permission errors:

```sql
GRANT ALL PRIVILEGES ON DATABASE "ProductManagement" TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO postgres;
```

### Reset Database

To completely reset the database:

```bash
psql -U postgres
DROP DATABASE "ProductManagement";
CREATE DATABASE "ProductManagement";
\q
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

## Key Differences from SQL Server

1. **IDENTITY → SERIAL**: Auto-increment columns use SERIAL type
2. **GETDATE() → CURRENT_TIMESTAMP**: Date/time functions
3. **BIT → BOOLEAN**: Boolean type is native in PostgreSQL
4. **NVARCHAR → VARCHAR**: PostgreSQL VARCHAR is Unicode by default
5. **Stored Procedures → Functions**: PostgreSQL uses functions with RETURNS TABLE
6. **Triggers**: Different syntax but similar functionality
7. **SCOPE_IDENTITY() → RETURNING**: Use RETURNING clause for inserted IDs

## Sample Data Loaded

The setup script loads:
- 20 product categories
- 8 suppliers
- 19 sample products across various categories
- Initial product statistics record

## Next Steps

1. Build the application: `dotnet build`
2. Run the application: `dotnet run`
3. Test CRUD operations through the CLI
4. Verify data integrity and transaction handling

## Support

For PostgreSQL documentation, visit: https://www.postgresql.org/docs/

For Npgsql (.NET PostgreSQL driver) documentation, visit: https://www.npgsql.org/doc/
