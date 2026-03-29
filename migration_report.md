# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary

| Metric | Value |
|--------|-------|
| **Migration Type** | Microsoft SQL Server → PostgreSQL |
| **Application** | AdoCore (.NET 9.0 ADO.NET Application) |
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS Tool** | 0 |
| **Requiring Manual Intervention (DMS Failure)** | 7 |
| **Validated as Equivalent (SQL Equivalency Tool)** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |
| **Build Status** | ✅ Success (0 errors, 12 pre-existing warnings) |

## Tool Status

### DMS MCP Tool (dms-mcp___statement_conversion_tool)
- **Status**: All 7 conversions failed
- **Error**: `Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}`
- **Action Taken**: Manual conversion applied with lowercase schema object names per transformation definition
- **Conversion Rule Applied**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### SQL Equivalency Tool (sql-equivalency___validate_sql_equivalence)
- **Status**: All 7 validations returned ERROR
- **Error**: `'uniqueID'` (systemic tool error)
- **Action Taken**: All 7 pairs marked as ERROR per transformation definition (tool output, not agent judgment)

## Files Modified

| File | Change Type | Description |
|------|-------------|-------------|
| `DataAccess/ProductRepository.cs` | Modified | Replaced 7 SQL statements, replaced ADO.NET classes, updated using directive |
| `AdoCore.csproj` | Modified | Replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.1 |
| `appsettings.json` | Modified | Converted connection strings to PostgreSQL format |

## Migration Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | sourceCode/ | All 7 original MS SQL statements |
| `converted_statements.sql` | sourceCode/ | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | sourceCode/ | Comprehensive equivalency validation report |
| `migration_report.md` | sourceCode/ | This report |

## Detailed Statement Conversions

### Statement 1: GetAllProductsAsync

**Source**: `DataAccess/ProductRepository.cs` - Method `GetAllProductsAsync()`
**Type**: SELECT with CTE, window functions (AVG OVER, COUNT OVER), CASE WHEN, ROUND, INNER JOIN

**DMS Conversion Status**: ❌ FAILED - Metadata model creation timeout
**Equivalency Status**: ERROR - Tool returned `'uniqueID'` error
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

**Original MS SQL:**
```sql
WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT 
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity,
    p.CreatedDate, p.ModifiedDate,
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END,
    p.Name
```

**Converted PostgreSQL:**
```sql
WITH productstats AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT 
    p.productid, p.name, p.description, p.price, p.stockquantity,
    p.createddate, p.modifieddate,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY 
    CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END,
    p.name
```

**Changes**: All schema objects converted to lowercase.

---

### Statement 2: GetProductByIdAsync

**Source**: `DataAccess/ProductRepository.cs` - Method `GetProductByIdAsync(int productId)`
**Type**: SELECT with CTE, LAG window function, CASE WHEN, ROUND, LEFT JOIN, parameterized

**DMS Conversion Status**: ❌ FAILED - Metadata model creation timeout
**Equivalency Status**: ERROR - Tool returned `'uniqueID'` error
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

**Original MS SQL:**
```sql
WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = @ProductId
)
SELECT 
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity,
    p.CreatedDate, p.ModifiedDate, ph.PreviousPrice, ph.PreviousStock,
    CASE 
        WHEN ph.PreviousPrice IS NOT NULL THEN 
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
```

**Converted PostgreSQL:**
```sql
WITH producthistory AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = @ProductId
)
SELECT 
    p.productid, p.name, p.description, p.price, p.stockquantity,
    p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

**Changes**: All schema objects converted to lowercase.

---

### Statement 3: InsertProductAsync

**Source**: `DataAccess/ProductRepository.cs` - Method `InsertProductAsync(Product product)`
**Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), UPDATE, GETDATE()

**DMS Conversion Status**: ❌ FAILED - Metadata model creation timeout
**Equivalency Status**: ERROR - Tool returned `'uniqueID'` error
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

**Original MS SQL:**
```sql
DECLARE @NewProductId INT;
BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    SET @NewProductId = SCOPE_IDENTITY();
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    UPDATE ProductStats SET TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
SELECT @NewProductId;
```

**Converted PostgreSQL:**
```sql
BEGIN TRANSACTION;
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, now());
    UPDATE productstats SET totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = now() WHERE statid = 1;
COMMIT;
SELECT lastval();
```

**Changes**:
- `SCOPE_IDENTITY()` → `lastval()`
- `GETDATE()` → `now()`
- Removed `DECLARE @NewProductId INT` and `SET @NewProductId =` (used `lastval()` directly)
- All schema objects converted to lowercase

---

### Statement 4: UpdateProductAsync

**Source**: `DataAccess/ProductRepository.cs` - Method `UpdateProductAsync(Product product)`
**Type**: Transaction block with DECLARE, SELECT into variables, UPDATE, INSERT, GETDATE()

**DMS Conversion Status**: ❌ FAILED - Metadata model creation timeout
**Equivalency Status**: ERROR - Tool returned `'uniqueID'` error
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
    UPDATE Products SET Name = @Name, Description = @Description, Price = @Price,
        StockQuantity = @StockQuantity, ModifiedDate = GETDATE() WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    UPDATE ProductStats SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

**Converted PostgreSQL:**
```sql
BEGIN TRANSACTION;
    UPDATE products SET name = @Name, description = @Description, price = @Price,
        stockquantity = @StockQuantity, modifieddate = now() WHERE productid = @ProductId;
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', p.price, @Price, p.stockquantity, @StockQuantity, now()
    FROM products p WHERE p.productid = @ProductId;
    UPDATE productstats SET averageprice = (averageprice * totalproducts - 
        (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = now() WHERE statid = 1;
COMMIT;
```

**Changes**:
- Eliminated `DECLARE` variables (not supported in PostgreSQL raw SQL)
- Replaced variable references with subqueries
- `GETDATE()` → `now()`
- All schema objects converted to lowercase

---

### Statement 5: DeleteProductAsync

**Source**: `DataAccess/ProductRepository.cs` - Method `DeleteProductAsync(int productId)`
**Type**: Transaction block with DECLARE, SELECT into variables, INSERT, DELETE, UPDATE with CASE

**DMS Conversion Status**: ❌ FAILED - Metadata model creation timeout
**Equivalency Status**: ERROR - Tool returned `'uniqueID'` error
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    DELETE FROM Products WHERE ProductId = @ProductId;
    UPDATE ProductStats SET TotalProducts = TotalProducts - 1,
        AveragePrice = CASE WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END,
        LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

**Converted PostgreSQL:**
```sql
BEGIN TRANSACTION;
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', p.price, NULL, p.stockquantity, NULL, now()
    FROM products p WHERE p.productid = @ProductId;
    UPDATE productstats SET totalproducts = totalproducts - 1,
        averageprice = CASE WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId)) / (totalproducts - 1) ELSE 0 END,
        lastupdated = now() WHERE statid = 1;
    DELETE FROM products WHERE productid = @ProductId;
COMMIT;
```

**Changes**:
- Eliminated `DECLARE` variables
- Used subqueries to capture old values before delete
- Reordered operations: history insert and stats update before delete (to capture old values)
- `GETDATE()` → `now()`
- All schema objects converted to lowercase

---

### Statement 6: GetProductsByPriceRangeAsync

**Source**: `DataAccess/ProductRepository.cs` - Method `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
**Type**: SELECT with CTE, RANK, PERCENT_RANK window functions, BETWEEN, CASE WHEN

**DMS Conversion Status**: ❌ FAILED - Metadata model creation timeout
**Equivalency Status**: ERROR - Tool returned `'uniqueID'` error
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

**Original MS SQL:**
```sql
WITH RankedProducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*, CASE WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
    WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END as PriceSegment
FROM RankedProducts rp ORDER BY rp.PriceRank
```

**Converted PostgreSQL:**
```sql
WITH rankedproducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*, CASE WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
    WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END as pricesegment
FROM rankedproducts rp ORDER BY rp.pricerank
```

**Changes**: All schema objects converted to lowercase.

---

### Statement 7: GetLowStockProductsAsync

**Source**: `DataAccess/ProductRepository.cs` - Method `GetLowStockProductsAsync(int threshold)`
**Type**: SELECT with CTE, AVG/MIN/MAX window functions, CASE WHEN, ROUND, parameterized

**DMS Conversion Status**: ❌ FAILED - Metadata model creation timeout
**Equivalency Status**: ERROR - Tool returned `'uniqueID'` error
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

**Original MS SQL:**
```sql
WITH StockAnalysis AS (
    SELECT p.*, AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock, MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT sa.*, CASE WHEN StockQuantity <= @Threshold THEN 'Critical'
    WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low' ELSE 'Adequate' END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity
```

**Converted PostgreSQL:**
```sql
WITH stockanalysis AS (
    SELECT p.*, AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock, MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT sa.*, CASE WHEN stockquantity <= @Threshold THEN 'Critical'
    WHEN stockquantity <= avgstock * 0.5 THEN 'Low' ELSE 'Adequate' END as stockstatus,
    ROUND((CAST(stockquantity AS DECIMAL) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa WHERE stockquantity <= @Threshold ORDER BY stockquantity
```

**Changes**:
- All schema objects converted to lowercase
- Added `CAST(stockquantity AS DECIMAL)` to avoid integer division in PostgreSQL

---

## ADO.NET Class Replacements

| Original (SQL Server) | Replacement (PostgreSQL/Npgsql) | Occurrences |
|----------------------|-------------------------------|-------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| Certificate | `TrustServerCertificate=True` | Removed (not applicable) |

## Package Dependency Changes

| Original | Replacement |
|----------|-------------|
| `Microsoft.Data.SqlClient` 5.1.4 | `Npgsql` 8.0.1 |

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. **DMS Tool Failure**: All DMS conversions failed with metadata model creation timeout
2. **Equivalency Tool Error**: All equivalency validations returned ERROR with `'uniqueID'`
3. **Manual Conversion Applied**: Lowercase schema object names applied per DMS failure procedure

### Specific Areas for Review:
- **Statements 3, 4, 5** (Insert, Update, Delete): Transaction blocks were restructured to eliminate T-SQL `DECLARE`/`SET` variables. Subqueries were used instead. Verify the ordering of operations within transactions produces the same results.
- **Statement 3** (Insert): `SCOPE_IDENTITY()` replaced with `lastval()`. Verify this returns the correct auto-generated ID after INSERT.
- **Statement 7** (GetLowStockProducts): Added explicit `CAST(stockquantity AS DECIMAL)` for division. Verify numeric precision matches SQL Server behavior.
