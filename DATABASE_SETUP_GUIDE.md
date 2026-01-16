# PostgreSQL Database Setup Guide for AdoCore Application

This guide provides step-by-step instructions for setting up the PostgreSQL database required to complete the validation of criteria 12-15.

## Prerequisites

- PostgreSQL 12 or higher installed
- PostgreSQL client tools (psql)
- Administrative access to PostgreSQL server

## Database Setup Steps

### 1. Create Database

```sql
CREATE DATABASE "ProductManagement"
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;
```

### 2. Connect to Database

```bash
psql -U postgres -d ProductManagement
```

### 3. Create Schema

```sql
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;
```

### 4. Create Tables

#### Products Table

```sql
CREATE TABLE productmanagement_dbo.products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL DEFAULT 0,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP
);

CREATE INDEX idx_products_price ON productmanagement_dbo.products(price);
CREATE INDEX idx_products_stockquantity ON productmanagement_dbo.products(stockquantity);
```

#### ProductHistory Table

```sql
CREATE TABLE productmanagement_dbo.producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(50) NOT NULL,
    oldprice NUMERIC(18, 2),
    newprice NUMERIC(18, 2),
    oldstock INTEGER,
    newstock INTEGER,
    actiondate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_producthistory_product FOREIGN KEY (productid) 
        REFERENCES productmanagement_dbo.products(productid) ON DELETE CASCADE
);

CREATE INDEX idx_producthistory_productid ON productmanagement_dbo.producthistory(productid);
CREATE INDEX idx_producthistory_actiondate ON productmanagement_dbo.producthistory(actiondate);
```

#### ProductStats Table

```sql
CREATE TABLE productmanagement_dbo.productstats (
    statid SERIAL PRIMARY KEY,
    totalproducts INTEGER NOT NULL DEFAULT 0,
    averageprice NUMERIC(18, 2) NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial stats record
INSERT INTO productmanagement_dbo.productstats (statid, totalproducts, averageprice, lastupdated)
VALUES (1, 0, 0, CURRENT_TIMESTAMP);
```

### 5. Insert Sample Data (Optional but Recommended for Testing)

```sql
-- Insert sample products
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity, createddate)
VALUES 
    ('Laptop', 'High-performance laptop', 1299.99, 15, CURRENT_TIMESTAMP),
    ('Mouse', 'Wireless optical mouse', 29.99, 50, CURRENT_TIMESTAMP),
    ('Keyboard', 'Mechanical gaming keyboard', 89.99, 30, CURRENT_TIMESTAMP),
    ('Monitor', '27-inch 4K display', 449.99, 10, CURRENT_TIMESTAMP),
    ('USB Cable', 'USB-C to USB-A cable', 12.99, 100, CURRENT_TIMESTAMP),
    ('Webcam', '1080p HD webcam', 79.99, 25, CURRENT_TIMESTAMP),
    ('Headphones', 'Noise-canceling headphones', 199.99, 20, CURRENT_TIMESTAMP),
    ('SSD', '1TB NVMe SSD', 129.99, 40, CURRENT_TIMESTAMP),
    ('RAM', '16GB DDR4 RAM', 79.99, 35, CURRENT_TIMESTAMP),
    ('Graphics Card', 'Mid-range graphics card', 399.99, 5, CURRENT_TIMESTAMP);

-- Update product stats
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = (SELECT COUNT(*) FROM productmanagement_dbo.products),
    averageprice = (SELECT AVG(price) FROM productmanagement_dbo.products),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- Insert initial history records
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
SELECT 
    productid, 
    'INSERT', 
    NULL, 
    price, 
    NULL, 
    stockquantity, 
    createddate
FROM productmanagement_dbo.products;
```

### 6. Grant Permissions (if using a non-postgres user)

```sql
-- Create application user (replace 'yourpassword' with a strong password)
CREATE USER adocore_user WITH PASSWORD 'your_secure_password_here';

-- Grant schema usage
GRANT USAGE ON SCHEMA productmanagement_dbo TO adocore_user;

-- Grant table permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA productmanagement_dbo TO adocore_user;

-- Grant sequence permissions for SERIAL columns
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA productmanagement_dbo TO adocore_user;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA productmanagement_dbo 
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO adocore_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA productmanagement_dbo 
    GRANT USAGE, SELECT ON SEQUENCES TO adocore_user;
```

### 7. Update Connection String

Update the `appsettings.json` file with your PostgreSQL connection details:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=adocore_user;Password=your_secure_password_here;Pooling=true",
    "ProdConnection": "Host=your_prod_host;Port=5432;Database=ProductManagement;Username=adocore_user;Password=your_secure_password_here;Pooling=true;SSL Mode=Require"
  },
  "Environment": "Development"
}
```

**Security Best Practice:** Use environment variables instead of hardcoded passwords:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=${DB_HOST:localhost};Port=${DB_PORT:5432};Database=${DB_NAME:ProductManagement};Username=${DB_USER:postgres};Password=${DB_PASSWORD};Pooling=true"
  },
  "Environment": "Development"
}
```

Then set environment variables:
```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=ProductManagement
export DB_USER=adocore_user
export DB_PASSWORD=your_secure_password_here
```

## Validation Testing

Once the database is set up, run the following validation tests:

### Test 1: Database Connectivity (Criterion 12)

Run the application and verify it connects successfully:

```bash
dotnet run
```

Expected: Application starts without connection errors.

### Test 2: CRUD Operations (Criterion 13)

Test each operation through the application menu:
- **SELECT**: View all products, view product by ID
- **INSERT**: Add a new product
- **UPDATE**: Modify an existing product
- **DELETE**: Remove a product

Verify that:
- All operations complete successfully
- Data is correctly inserted/updated/deleted
- Window functions (RANK, PERCENT_RANK, LAG) return expected results

### Test 3: Transaction Atomicity (Criterion 14)

Test transaction rollback scenarios:

1. **Test Insert Transaction Rollback**:
   - Temporarily modify InsertProductAsync to throw an exception after the first INSERT
   - Verify that no records are inserted (rollback successful)

2. **Test Update Transaction Rollback**:
   - Temporarily modify UpdateProductAsync to throw an exception after the UPDATE
   - Verify that changes are not persisted (rollback successful)

3. **Test Delete Transaction Rollback**:
   - Temporarily modify DeleteProductAsync to throw an exception after DELETE
   - Verify that the product is not deleted (rollback successful)

### Test 4: Integration Tests (Criterion 15)

If unit/integration tests exist in the project:

```bash
dotnet test
```

Verify all tests pass with the PostgreSQL database.

## SQL Statement Equivalency Validation

The following SQL statements have been marked as ERROR in the equivalency report and require runtime validation:

### Statement 2: GetProductByIdAsync (LAG Window Function)
**Test**: Insert multiple price updates for a product and verify the `previousprice` calculation matches historical data.

### Statement 3: InsertProductAsync (RETURNING Clause)
**Test**: Insert a new product and verify the returned `productid` matches the actual inserted record.

### Statement 6: GetProductsByPriceRangeAsync (RANK and PERCENT_RANK)
**Test**: Query products within a price range and verify ranking calculations are correct.

## Troubleshooting

### Connection Issues

**Error**: `FATAL: password authentication failed`
- Verify credentials in appsettings.json
- Check PostgreSQL pg_hba.conf for authentication method
- Ensure user has been created with correct password

**Error**: `FATAL: database "ProductManagement" does not exist`
- Verify database was created successfully
- Check database name spelling (case-sensitive)

**Error**: `column "productid" does not exist`
- Verify all tables were created with lowercase column names
- Check schema name is correct: `productmanagement_dbo`

### Performance Considerations

For production environments:
- Create additional indexes on frequently queried columns
- Configure connection pooling appropriately
- Monitor query performance using PostgreSQL EXPLAIN
- Consider partitioning for large tables

## Additional Resources

- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Npgsql Documentation: https://www.npgsql.org/doc/
- PostgreSQL Window Functions: https://www.postgresql.org/docs/current/tutorial-window.html

## Support

For issues specific to the migration:
- Review `migration_final_report.md` for transformation details
- Check `sql_equivalency_validation_report.json` for statement validation status
- Review `dms_conversion_log.json` for conversion details
