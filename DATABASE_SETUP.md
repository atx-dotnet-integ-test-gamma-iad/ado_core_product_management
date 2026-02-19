# PostgreSQL Database Setup Guide

## Overview
This guide provides instructions for setting up the PostgreSQL database required to complete the migration validation (Exit Criteria 12-15).

## Prerequisites
- PostgreSQL 12 or higher installed
- PostgreSQL server running
- Administrative access to create databases

## Database Setup Steps

### 1. Create Database
```sql
CREATE DATABASE ProductManagement;
```

### 2. Connect to Database
```bash
psql -U postgres -d ProductManagement
```

### 3. Create Tables

#### Products Table
```sql
CREATE TABLE Products (
    ProductId SERIAL PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Description TEXT,
    Price DECIMAL(18,2) NOT NULL,
    StockQuantity INTEGER NOT NULL DEFAULT 0,
    CreatedDate TIMESTAMP NOT NULL DEFAULT NOW(),
    ModifiedDate TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_products_price ON Products(Price);
CREATE INDEX idx_products_stock ON Products(StockQuantity);
```

#### ProductHistory Table
```sql
CREATE TABLE ProductHistory (
    HistoryId SERIAL PRIMARY KEY,
    ProductId INTEGER NOT NULL,
    Action VARCHAR(50) NOT NULL,
    OldPrice DECIMAL(18,2),
    NewPrice DECIMAL(18,2),
    OldStock INTEGER,
    NewStock INTEGER,
    ActionDate TIMESTAMP NOT NULL DEFAULT NOW(),
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId) ON DELETE CASCADE
);

CREATE INDEX idx_product_history_productid ON ProductHistory(ProductId);
CREATE INDEX idx_product_history_actiondate ON ProductHistory(ActionDate);
```

#### ProductStats Table
```sql
CREATE TABLE ProductStats (
    StatId SERIAL PRIMARY KEY,
    TotalProducts INTEGER NOT NULL DEFAULT 0,
    AveragePrice DECIMAL(18,2) NOT NULL DEFAULT 0,
    LastUpdated TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Insert initial stats record
INSERT INTO ProductStats (StatId, TotalProducts, AveragePrice, LastUpdated)
VALUES (1, 0, 0.00, NOW());
```

### 4. Insert Sample Data (Optional)
```sql
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES 
    ('Product A', 'Description A', 29.99, 100),
    ('Product B', 'Description B', 49.99, 50),
    ('Product C', 'Description C', 19.99, 200),
    ('Product D', 'Description D', 99.99, 25),
    ('Product E', 'Description E', 39.99, 75);

-- Update stats
UPDATE ProductStats
SET 
    TotalProducts = (SELECT COUNT(*) FROM Products),
    AveragePrice = (SELECT AVG(Price) FROM Products),
    LastUpdated = NOW()
WHERE StatId = 1;
```

## Connection String Configuration

### Update appsettings.json
Replace placeholder credentials with your actual PostgreSQL server details:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=YOUR_HOST;Port=5432;Database=ProductManagement;Username=YOUR_USERNAME;Password=YOUR_PASSWORD;Pooling=true",
    "ProdConnection": "Host=YOUR_PROD_HOST;Port=5432;Database=ProductManagement;Username=YOUR_PROD_USERNAME;Password=YOUR_PROD_PASSWORD;Pooling=true"
  },
  "Environment": "Development"
}
```

**Current placeholder values:**
- Host: localhost
- Username: postgres
- Password: postgres

**Security Note:** Never commit real credentials to source control. Use environment variables or secure configuration management in production.

## Validation Testing

### Test Connectivity
```bash
dotnet run
```

### Test Database Operations
Execute each repository method to verify:

1. **GetAllProductsAsync** - Tests CTE with window functions
2. **GetProductByIdAsync** - Tests CTE with LAG window function
3. **InsertProductAsync** - Tests INSERT with RETURNING clause and transaction
4. **UpdateProductAsync** - Tests UPDATE with transaction atomicity
5. **DeleteProductAsync** - Tests DELETE with transaction atomicity
6. **GetProductsByPriceRangeAsync** - Tests CTE with RANK and PERCENT_RANK
7. **GetLowStockProductsAsync** - Tests CTE with multiple window functions

### Transaction Testing
Test rollback scenarios to verify transaction atomicity:

1. Cause InsertProductAsync to fail mid-transaction
2. Verify rollback occurs correctly
3. Repeat for UpdateProductAsync and DeleteProductAsync

## Troubleshooting

### Connection Issues
- Verify PostgreSQL service is running: `systemctl status postgresql` (Linux) or check Services (Windows)
- Check firewall rules allow connections on port 5432
- Verify pg_hba.conf allows connections from your application host

### Permission Issues
- Ensure the database user has appropriate permissions:
```sql
GRANT ALL PRIVILEGES ON DATABASE ProductManagement TO your_username;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_username;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO your_username;
```

### Migration Issues
- If schema objects differ from expectations, review converted_statements.sql
- Check dms_conversion_issues.log for any documented conversion concerns
- Review sql_equivalency_validation_report.json for statement validation details

## Exit Criteria Completion

After completing database setup and testing, the following exit criteria can be validated:

- ✅ **Criterion 12**: Application successfully connects to PostgreSQL database
- ✅ **Criterion 13**: All database operations execute successfully
- ✅ **Criterion 14**: Transaction blocks maintain atomicity
- ✅ **Criterion 15**: Application passes all tests (requires creating test suite)

## Creating Test Suite (Required for Criterion 15)

No test suite currently exists. Consider creating:

1. **Unit Tests** for individual repository methods
2. **Integration Tests** for transaction scenarios
3. **Performance Tests** for window function queries

Example test structure:
```
AdoCore.Tests/
├── DataAccess/
│   └── ProductRepositoryTests.cs
├── Integration/
│   └── TransactionTests.cs
└── AdoCore.Tests.csproj
```

## Additional Resources
- [Npgsql Documentation](https://www.npgsql.org/doc/)
- [PostgreSQL Window Functions](https://www.postgresql.org/docs/current/tutorial-window.html)
- [PostgreSQL Transactions](https://www.postgresql.org/docs/current/tutorial-transactions.html)
