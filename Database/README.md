# PostgreSQL Database Setup Instructions

## Prerequisites
- PostgreSQL 12 or higher installed
- Access to PostgreSQL server with appropriate privileges

## Database Setup Steps

### 1. Create Database
Connect to PostgreSQL as a superuser (e.g., `postgres`) and create the database:

```bash
psql -U postgres
```

```sql
CREATE DATABASE "ProductManagement";
\q
```

### 2. Run Setup Script
Execute the PostgreSQL setup script:

```bash
psql -U postgres -d ProductManagement -f Database/Scripts/01_PostgreSQL_InitialSetup.sql
```

Or connect and run manually:

```bash
psql -U postgres -d ProductManagement
\i Database/Scripts/01_PostgreSQL_InitialSetup.sql
```

### 3. Verify Database Setup
Check that all tables were created:

```sql
\dt
```

You should see the following tables:
- categories
- suppliers
- products
- producthistory
- productstats

Check sample data:

```sql
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM categories;
SELECT COUNT(*) FROM suppliers;
```

### 4. Update Connection String
Update the connection string in `appsettings.json` with your actual PostgreSQL credentials:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=YOUR_USERNAME;Password=YOUR_PASSWORD;Pooling=true"
  }
}
```

**Security Note**: Never commit actual credentials to version control. Use environment variables or secure configuration management.

## Testing Database Connectivity

### Using psql
```bash
psql -h localhost -p 5432 -U YOUR_USERNAME -d ProductManagement
```

### Using the Application
After updating the connection string, run the application:

```bash
dotnet run
```

The application will attempt to connect to PostgreSQL and display an interactive menu for managing products.

## Schema Overview

### Core Tables
- **Products**: Main product catalog with pricing and inventory
- **Categories**: Hierarchical product categories
- **Suppliers**: Supplier information
- **ProductHistory**: Audit trail for product changes
- **ProductStats**: Aggregate statistics

### Key Features
- Automatic history tracking via trigger
- Foreign key constraints for data integrity
- Indexes for query performance
- Sample data included for testing

## Troubleshooting

### Connection Issues
1. Verify PostgreSQL service is running:
   ```bash
   sudo systemctl status postgresql
   ```

2. Check PostgreSQL accepts connections:
   ```bash
   sudo nano /etc/postgresql/XX/main/postgresql.conf
   # Ensure: listen_addresses = '*' or 'localhost'
   ```

3. Verify pg_hba.conf allows your connection method:
   ```bash
   sudo nano /etc/postgresql/XX/main/pg_hba.conf
   # Add: host all all 127.0.0.1/32 md5
   ```

4. Restart PostgreSQL after configuration changes:
   ```bash
   sudo systemctl restart postgresql
   ```

### Permission Issues
Grant necessary privileges to your database user:

```sql
GRANT ALL PRIVILEGES ON DATABASE "ProductManagement" TO your_username;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_username;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO your_username;
```

## Migration Notes

This database schema was migrated from Microsoft SQL Server to PostgreSQL. Key differences:

1. **IDENTITY → SERIAL**: Auto-increment columns use SERIAL type
2. **NVARCHAR → VARCHAR**: Text columns use VARCHAR
3. **BIT → BOOLEAN**: Boolean columns use BOOLEAN type
4. **DECIMAL → NUMERIC**: Decimal columns use NUMERIC type
5. **GETDATE() → CURRENT_TIMESTAMP**: Timestamp functions
6. **Triggers**: Converted to PostgreSQL trigger functions
7. **Stored Procedures**: Replaced with inline SQL in application code

## Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Npgsql Documentation](https://www.npgsql.org/doc/)
- [Migration Report](../final_migration_report.md)
