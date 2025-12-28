# PostgreSQL Migration Quick Reference Guide

## How to Use the Transformed Script

### 1. Database Setup

```bash
# Connect to PostgreSQL (ensure database exists)
psql -U username -d productmanagement

# Run the initialization script
\i /path/to/01_InitialSetup_PostgreSQL.sql
```

### 2. Calling Functions (Instead of Stored Procedures)

#### Get All Products
**SQL Server:**
```sql
EXEC dbo.sp_GetAllProducts;
```

**PostgreSQL:**
```sql
SELECT * FROM productmanagement_dbo.sp_getallproducts();
```

#### Get Product By ID
**SQL Server:**
```sql
EXEC dbo.sp_GetProductById @ProductId = 1;
```

**PostgreSQL:**
```sql
SELECT * FROM productmanagement_dbo.sp_getproductbyid(1);
```

#### Insert Product
**SQL Server:**
```sql
DECLARE @NewId INT;
EXEC dbo.sp_InsertProduct 
    @Name = 'New Product',
    @Description = 'Description',
    @Price = 99.99,
    @StockQuantity = 10;
SELECT SCOPE_IDENTITY() AS NewProductId;
```

**PostgreSQL:**
```sql
SELECT productmanagement_dbo.sp_insertproduct(
    'New Product',
    'Description',
    99.99,
    10
) AS new_product_id;
```

#### Update Product
**SQL Server:**
```sql
EXEC dbo.sp_UpdateProduct 
    @ProductId = 1,
    @Name = 'Updated Name',
    @Description = 'Updated Description',
    @Price = 149.99,
    @StockQuantity = 20;
```

**PostgreSQL:**
```sql
SELECT productmanagement_dbo.sp_updateproduct(
    1,
    'Updated Name',
    'Updated Description',
    149.99,
    20
);
```

#### Delete Product
**SQL Server:**
```sql
EXEC dbo.sp_DeleteProduct @ProductId = 1;
```

**PostgreSQL:**
```sql
SELECT productmanagement_dbo.sp_deleteproduct(1);
```

### 3. Direct Table Queries

**Always use schema-qualified table names:**

```sql
-- Select from products
SELECT * FROM productmanagement_dbo.products WHERE categoryid = 1;

-- Join tables
SELECT 
    p.productid,
    p.name,
    c.name AS category_name,
    s.name AS supplier_name
FROM productmanagement_dbo.products p
INNER JOIN productmanagement_dbo.categories c ON p.categoryid = c.categoryid
INNER JOIN productmanagement_dbo.suppliers s ON p.supplierid = s.supplierid;

-- Update
UPDATE productmanagement_dbo.products
SET price = 199.99, modifieddate = CURRENT_TIMESTAMP
WHERE productid = 1;

-- Insert
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES ('New Item', 'Description', 99.99, 10);

-- Delete
DELETE FROM productmanagement_dbo.products WHERE productid = 1;
```

### 4. Viewing Trigger History

```sql
-- View all product history
SELECT * FROM productmanagement_dbo.producthistory ORDER BY actiondate DESC;

-- View history for specific product
SELECT * FROM productmanagement_dbo.producthistory 
WHERE productid = 1 
ORDER BY actiondate DESC;

-- View recent changes
SELECT * FROM productmanagement_dbo.producthistory 
WHERE actiondate > CURRENT_TIMESTAMP - INTERVAL '1 day'
ORDER BY actiondate DESC;
```

### 5. Working with Boolean Columns

**SQL Server used BIT (0/1), PostgreSQL uses BOOLEAN (TRUE/FALSE):**

```sql
-- Filter active suppliers
SELECT * FROM productmanagement_dbo.suppliers WHERE isactive = TRUE;

-- Update boolean value
UPDATE productmanagement_dbo.suppliers 
SET isactive = FALSE 
WHERE supplierid = 1;

-- Toggle boolean
UPDATE productmanagement_dbo.products 
SET isdiscontinued = NOT isdiscontinued 
WHERE productid = 1;
```

### 6. Working with Timestamps

```sql
-- Current timestamp
SELECT CURRENT_TIMESTAMP;

-- Filter by date range
SELECT * FROM productmanagement_dbo.products
WHERE createddate BETWEEN '2024-01-01' AND '2024-12-31';

-- Date arithmetic
SELECT * FROM productmanagement_dbo.products
WHERE createddate > CURRENT_TIMESTAMP - INTERVAL '30 days';
```

### 7. Common PostgreSQL Functions

```sql
-- String functions
SELECT UPPER(name), LOWER(name), LENGTH(name) 
FROM productmanagement_dbo.products;

-- Numeric functions
SELECT ROUND(price, 0), CEIL(price), FLOOR(price)
FROM productmanagement_dbo.products;

-- Aggregate functions
SELECT 
    COUNT(*) AS total_products,
    AVG(price) AS avg_price,
    SUM(stockquantity) AS total_stock,
    MIN(price) AS min_price,
    MAX(price) AS max_price
FROM productmanagement_dbo.products;
```

### 8. Transaction Management

```sql
-- Begin transaction
BEGIN;

-- Perform operations
INSERT INTO productmanagement_dbo.products (...) VALUES (...);
UPDATE productmanagement_dbo.productstats SET ...;

-- Commit or rollback
COMMIT;
-- OR
ROLLBACK;
```

### 9. Checking Schema Objects

```sql
-- List all tables in schema
SELECT tablename 
FROM pg_tables 
WHERE schemaname = 'productmanagement_dbo';

-- List all functions in schema
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'productmanagement_dbo';

-- View table structure
\d productmanagement_dbo.products

-- View function definition
\df+ productmanagement_dbo.sp_getallproducts
```

### 10. Performance Tips

```sql
-- Analyze tables after bulk inserts
ANALYZE productmanagement_dbo.products;

-- Vacuum to reclaim space
VACUUM productmanagement_dbo.products;

-- View query execution plan
EXPLAIN ANALYZE
SELECT * FROM productmanagement_dbo.products WHERE categoryid = 1;

-- Check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'productmanagement_dbo';
```

## C# / .NET Code Examples

### Using Npgsql (PostgreSQL Driver)

```csharp
using Npgsql;

// Connection string
string connectionString = "Host=localhost;Database=productmanagement;Username=myuser;Password=mypassword";

// Call function that returns table
using (var conn = new NpgsqlConnection(connectionString))
{
    conn.Open();
    
    // Get all products
    using (var cmd = new NpgsqlCommand(
        "SELECT * FROM productmanagement_dbo.sp_getallproducts()", conn))
    {
        using (var reader = cmd.ExecuteReader())
        {
            while (reader.Read())
            {
                Console.WriteLine($"{reader["name"]}: ${reader["price"]}");
            }
        }
    }
    
    // Insert product and get ID
    using (var cmd = new NpgsqlCommand(
        "SELECT productmanagement_dbo.sp_insertproduct(@p1, @p2, @p3, @p4)", conn))
    {
        cmd.Parameters.AddWithValue("p1", "New Product");
        cmd.Parameters.AddWithValue("p2", "Description");
        cmd.Parameters.AddWithValue("p3", 99.99m);
        cmd.Parameters.AddWithValue("p4", 10);
        
        int newId = (int)cmd.ExecuteScalar();
        Console.WriteLine($"New product ID: {newId}");
    }
}
```

### Using Entity Framework Core

```csharp
using Microsoft.EntityFrameworkCore;

// DbContext configuration
public class ProductDbContext : DbContext
{
    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        optionsBuilder.UseNpgsql(
            "Host=localhost;Database=productmanagement;Username=myuser;Password=mypassword");
    }
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Specify schema for all entities
        modelBuilder.HasDefaultSchema("productmanagement_dbo");
        
        // Configure entities
        modelBuilder.Entity<Product>(entity =>
        {
            entity.ToTable("products");
            entity.HasKey(e => e.ProductId);
            entity.Property(e => e.ProductId).HasColumnName("productid");
            entity.Property(e => e.Name).HasColumnName("name");
            // ... other properties
        });
    }
    
    public DbSet<Product> Products { get; set; }
}

// Call function using FromSqlRaw
var products = context.Products
    .FromSqlRaw("SELECT * FROM productmanagement_dbo.sp_getallproducts()")
    .ToList();

// Call function with parameter
int productId = 1;
var product = context.Products
    .FromSqlRaw("SELECT * FROM productmanagement_dbo.sp_getproductbyid({0})", productId)
    .FirstOrDefault();
```

## Important Notes

### 1. Case Sensitivity
- PostgreSQL identifiers are case-insensitive unless quoted
- All identifiers in the script use lowercase for simplicity
- If you need mixed case, use quotes: `"ProductId"` instead of `productid`

### 2. Schema Search Path
Optionally set the search path to avoid typing schema names:

```sql
SET search_path TO productmanagement_dbo, public;

-- Now you can omit schema name
SELECT * FROM products;
```

### 3. Sequence Management
Serial columns create sequences. To reset:

```sql
-- Reset auto-increment counter
ALTER SEQUENCE productmanagement_dbo.products_productid_seq RESTART WITH 1;

-- Get current value
SELECT currval('productmanagement_dbo.products_productid_seq');

-- Get next value
SELECT nextval('productmanagement_dbo.products_productid_seq');
```

### 4. Permissions
Grant permissions if needed:

```sql
-- Grant all on schema
GRANT ALL ON SCHEMA productmanagement_dbo TO myuser;

-- Grant all on tables
GRANT ALL ON ALL TABLES IN SCHEMA productmanagement_dbo TO myuser;

-- Grant execute on functions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA productmanagement_dbo TO myuser;

-- Grant usage on sequences
GRANT USAGE ON ALL SEQUENCES IN SCHEMA productmanagement_dbo TO myuser;
```

## Troubleshooting

### Issue: Function not found
**Solution:** Use fully qualified name: `schema.function_name()`

### Issue: Column does not exist
**Solution:** Check column name case - use lowercase or quote identifier

### Issue: Permission denied
**Solution:** Grant appropriate permissions (see section 4 above)

### Issue: Sequence out of sync
**Solution:** Reset sequence after manual inserts:
```sql
SELECT setval('productmanagement_dbo.products_productid_seq', 
    (SELECT MAX(productid) FROM productmanagement_dbo.products));
```

### Issue: Boolean comparison fails
**Solution:** Use `TRUE`/`FALSE` instead of `1`/`0`

### Issue: Date format errors
**Solution:** Use ISO format 'YYYY-MM-DD' or PostgreSQL date functions

## Additional Resources

- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Npgsql Documentation: https://www.npgsql.org/doc/
- EF Core PostgreSQL: https://www.npgsql.org/efcore/
