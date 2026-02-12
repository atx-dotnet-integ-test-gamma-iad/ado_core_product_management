# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture.

**Note:** This application has been migrated from Microsoft SQL Server to PostgreSQL. All SQL statements, database access code, and dependencies have been converted to PostgreSQL equivalents using AWS Database Migration Service (DMS) tools.

## Migration Summary

This application was successfully migrated from SQL Server to PostgreSQL:
- **Database Client**: Microsoft.Data.SqlClient → Npgsql 8.0.5
- **ADO.NET Classes**: SqlConnection/SqlCommand → NpgsqlConnection/NpgsqlCommand
- **SQL Statements**: All 7 SQL statements converted to PostgreSQL syntax
- **Connection Strings**: Updated to PostgreSQL format
- **Transaction Handling**: Updated to PostgreSQL-compatible patterns

For detailed migration documentation, see:
- `extracted_statements.sql` - Original SQL Server statements
- `converted_statements.sql` - Converted PostgreSQL statements
- `sql_equivalency_validation_report.json` - Statement equivalency validation results
- `dms_conversion_log.txt` - Detailed conversion log

## Prerequisites

- Visual Studio 2022 or later
- .NET 9.0 SDK or later
- PostgreSQL 12 or later (recommended: PostgreSQL 15+)
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

## Database Setup

### Create the Products Table

Connect to your PostgreSQL instance and run:

```sql
CREATE TABLE Products (
    ProductId SERIAL PRIMARY KEY,
    Name VARCHAR(200) NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    StockQuantity INT NOT NULL,
    Description TEXT,
    CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ModifiedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Update Connection String

Edit `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true;",
    "ProdConnection": "your-production-connection-string"
  },
  "Environment": "Development"
}
```

## Building and Running

```bash
# Restore packages
dotnet restore

# Build
dotnet build

# Run
dotnet run
```

## CLI Commands

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
```

## Key Features

- Modern async/await patterns for all database operations
- Proper resource management with IAsyncDisposable
- Dependency injection for configuration
- Transaction support with async operations
- Parameterized queries for security
- Connection pooling via Npgsql
- PostgreSQL-specific features (RETURNING clause, SERIAL primary keys)

## Security Considerations

- All database queries use parameterization to prevent SQL injection
- **IMPORTANT**: Change default PostgreSQL credentials before production deployment
- Consider enabling SSL/TLS for database connections in production
- Store connection strings securely using User Secrets or environment variables

## Required NuGet Packages

- **Npgsql** (8.0.5) - PostgreSQL database client (vulnerability-free version)
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

## Migration Notes

This application was migrated from SQL Server to PostgreSQL following AWS best practices:
1. All SQL statements were extracted and cataloged
2. Each statement was processed through AWS DMS conversion tools
3. Statement equivalency was validated using SQL equivalency tools
4. ADO.NET classes were updated from SqlClient to Npgsql
5. Connection strings were converted to PostgreSQL format
6. Transaction handling was updated for PostgreSQL compatibility

## Known Limitations

- This application requires a PostgreSQL database to be available for runtime testing
- No unit tests are included in the current codebase
- Default connection strings use development credentials (update for production)

## Deployment to AWS RDS PostgreSQL

1. Create an RDS PostgreSQL instance in AWS Console
2. Configure security groups to allow access from your application
3. Update the production connection string:
   ```json
   "ProdConnection": "Host=your-rds-instance.region.rds.amazonaws.com;Port=5432;Database=ProductManagement;Username=your_user;Password=your_password;SSL Mode=Require;"
   ```
4. Deploy the application to AWS (EC2, ECS, Lambda, etc.)

## Support and Documentation

- **PostgreSQL**: https://www.postgresql.org/docs/
- **Npgsql**: https://www.npgsql.org/doc/
- **AWS RDS PostgreSQL**: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html
