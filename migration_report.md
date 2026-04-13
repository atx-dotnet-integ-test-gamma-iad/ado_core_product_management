# Migration Report: Microsoft SQL Server to PostgreSQL

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-04-13 |
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Application Framework** | .NET 9.0 (ADO.NET) |
| **Source Package** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Package** | Npgsql 8.0.6 |

---

## 1. Summary Statistics

| Category | Count |
|----------|-------|
| Total SQL statements processed | 7 |
| Statements converted by DMS tool | 0 |
| Statements requiring manual intervention | 7 |
| Statements validated as equivalent | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency errors | 7 |

### DMS Tool Status
All 7 statements were submitted to the DMS MCP tool (dms-mcp___statement_conversion_tool) using migration project ARN `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`. All 7 conversions failed with the same systemic error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

As per the transformation definition, manual conversion was performed using lowercase schema object names for PostgreSQL compatibility (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

### SQL Equivalency Tool Status
All 7 statement pairs were submitted to the SQL Equivalency MCP tool (sql-equivalency___validate_sql_equivalence). All 7 validations returned ERROR status with a systemic tool error:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

Per the transformation definition, ERROR results are recorded as-is without agent judgment substitution.

---

## 2. Files Modified

### DataAccess/ProductRepository.cs
- **SQL Statements**: All 7 MS SQL statements replaced with PostgreSQL equivalents
- **ADO.NET Classes**: All SqlClient classes replaced with Npgsql equivalents
  - `using Microsoft.Data.SqlClient` → `using Npgsql`
  - `SqlConnection` → `NpgsqlConnection`
  - `SqlCommand` → `NpgsqlCommand`
  - `SqlDataReader` → `NpgsqlDataReader`
- **Column References**: Updated to lowercase in MapProductFromReader (e.g., `reader["ProductId"]` → `reader["productid"]`)

### AdoCore.csproj
- **Package Reference**: `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6`
- Note: Npgsql 8.0.0 was originally targeted per plan, but upgraded to 8.0.6 to address known high severity vulnerability (GHSA-x9vc-6hfv-hg8c)

### appsettings.json
- **DevConnection**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres`
- **ProdConnection**: Same transformation applied
- Removed SQL Server-specific parameters: `MultipleActiveResultSets`, `TrustServerCertificate`, `Trusted_Connection`
- Added PostgreSQL parameters: `Host`, `Port`, `Username`, `Password`

---

## 3. Detailed Statement Log

### Statement 1: GetAllProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetAllProductsAsync()`
- **DMS Status**: FAILED (Metadata model creation failed)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR ('uniqueID')

**Original MS SQL:**
```sql
WITH ProductStats AS (
    SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average'
         WHEN p.Price < ps.AvgPrice THEN 'Below Average'
         ELSE 'Average' END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name
```

**Converted PostgreSQL:**
```sql
WITH productstats AS (
    SELECT productid, AVG(price) OVER() as avgprice, COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE WHEN p.price > ps.avgprice THEN 'Above Average'
         WHEN p.price < ps.avgprice THEN 'Below Average'
         ELSE 'Average' END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END, p.name
```

**Changes**: All schema objects lowercased

---

### Statement 2: GetProductByIdAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetProductByIdAsync(int productId)`
- **DMS Status**: FAILED (Metadata model creation failed)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR ('uniqueID')

**Original MS SQL:**
```sql
WITH ProductHistory AS (
    SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
           LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products WHERE ProductId = @ProductId
)
SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    ph.PreviousPrice, ph.PreviousStock,
    CASE WHEN ph.PreviousPrice IS NOT NULL THEN
        ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2) ELSE NULL
    END as PriceChangePercentage
FROM Products p LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
```

**Converted PostgreSQL:**
```sql
WITH producthistory AS (
    SELECT productid, LAG(price) OVER (ORDER BY modifieddate) as previousprice,
           LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products WHERE productid = @ProductId
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    ph.previousprice, ph.previousstock,
    CASE WHEN ph.previousprice IS NOT NULL THEN
        ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2) ELSE NULL
    END as pricechangepercentage
FROM products p LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

**Changes**: All schema objects lowercased

---

### Statement 3: InsertProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `InsertProductAsync(Product product)`
- **DMS Status**: FAILED (Metadata model creation failed)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR ('uniqueID')

**Original MS SQL:**
```sql
DECLARE @NewProductId INT;
BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity) VALUES (@Name, @Description, @Price, @StockQuantity);
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
BEGIN;
    INSERT INTO products (name, description, price, stockquantity) VALUES (@Name, @Description, @Price, @StockQuantity);
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    UPDATE productstats SET totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW() WHERE statid = 1;
COMMIT;
SELECT lastval();
```

**Changes**: SCOPE_IDENTITY() → lastval(), GETDATE() → NOW(), BEGIN TRANSACTION → BEGIN, DECLARE removed, all schema objects lowercased

---

### Statement 4: UpdateProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `UpdateProductAsync(Product product)`
- **DMS Status**: FAILED (Metadata model creation failed)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR ('uniqueID')

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
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
BEGIN;
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', price, @Price, stockquantity, @StockQuantity, NOW()
    FROM products WHERE productid = @ProductId;
    UPDATE productstats SET averageprice = (averageprice * totalproducts -
        (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = NOW() WHERE statid = 1;
    UPDATE products SET name = @Name, description = @Description, price = @Price,
        stockquantity = @StockQuantity, modifieddate = NOW() WHERE productid = @ProductId;
COMMIT;
```

**Changes**: DECLARE/variable assignment replaced with INSERT...SELECT and subqueries, GETDATE() → NOW(), BEGIN TRANSACTION → BEGIN, all schema objects lowercased. Reordered operations: history capture before update to preserve old values.

---

### Statement 5: DeleteProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `DeleteProductAsync(int productId)`
- **DMS Status**: FAILED (Metadata model creation failed)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR ('uniqueID')

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    DELETE FROM Products WHERE ProductId = @ProductId;
    UPDATE ProductStats SET TotalProducts = TotalProducts - 1,
        AveragePrice = CASE WHEN TotalProducts > 1
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
            ELSE 0 END, LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

**Converted PostgreSQL:**
```sql
BEGIN;
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', price, NULL, stockquantity, NULL, NOW()
    FROM products WHERE productid = @ProductId;
    UPDATE productstats SET totalproducts = totalproducts - 1,
        averageprice = CASE WHEN totalproducts > 1
            THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId)) / (totalproducts - 1)
            ELSE 0 END, lastupdated = NOW() WHERE statid = 1;
    DELETE FROM products WHERE productid = @ProductId;
COMMIT;
```

**Changes**: DECLARE/variable assignment replaced with INSERT...SELECT and subqueries, GETDATE() → NOW(), BEGIN TRANSACTION → BEGIN, all schema objects lowercased. Reordered: stats update before delete to read values while row exists.

---

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **DMS Status**: FAILED (Metadata model creation failed)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR ('uniqueID')

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

**Changes**: All schema objects lowercased

---

### Statement 7: GetLowStockProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **DMS Status**: FAILED (Metadata model creation failed)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR ('uniqueID')

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
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa WHERE stockquantity <= @Threshold ORDER BY stockquantity
```

**Changes**: All schema objects lowercased, added CAST(stockquantity AS NUMERIC) for integer division

---

## 4. Artifacts Generated

| Artifact | Path | Description |
|----------|------|-------------|
| extracted_statements.sql | sourceCode/extracted_statements.sql | All 7 original MS SQL statements |
| converted_statements.sql | sourceCode/converted_statements.sql | All 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | sourceCode/sql_equivalency_validation_report.json | Complete equivalency validation report |
| migration_report.md | sourceCode/migration_report.md | This comprehensive migration report |

---

## 5. Build Verification

| Check | Result |
|-------|--------|
| No SqlConnection references remaining | ✅ PASS |
| No SqlCommand references remaining | ✅ PASS |
| No SqlDataReader references remaining | ✅ PASS |
| No SqlParameter references remaining | ✅ PASS |
| No Microsoft.Data.SqlClient references | ✅ PASS |
| All 7 SQL statements sent through DMS tool | ✅ PASS (all failed) |
| All 7 statement pairs sent through equivalency tool | ✅ PASS (all returned ERROR) |
| Project builds successfully | ✅ PASS (0 errors, 10 warnings) |
| Npgsql package properly referenced | ✅ PASS (v8.0.6) |
| Connection strings updated to PostgreSQL format | ✅ PASS |

### Build Warnings (pre-existing, not introduced by migration)
- CS8600: Converting null literal or possible null value to non-nullable type (2 occurrences)
- CS8601: Possible null reference assignment (3 occurrences)
- CS8603: Possible null reference return (1 occurrence)
- CS8618: Non-nullable field must contain a non-null value (3 occurrences)
- CS8625: Cannot convert null literal to non-nullable reference type (1 occurrence)

---

## 6. Key SQL Server → PostgreSQL Conversion Rules Applied

| SQL Server | PostgreSQL | Notes |
|------------|-----------|-------|
| `SCOPE_IDENTITY()` | `lastval()` | Returns last auto-generated value |
| `GETDATE()` | `NOW()` | Current timestamp |
| `BEGIN TRANSACTION` | `BEGIN` | Transaction start |
| `DECLARE @var TYPE` | Removed | Used subqueries/INSERT...SELECT instead |
| `SET @var = expr` | Removed | Used subqueries/INSERT...SELECT instead |
| Schema objects (PascalCase) | lowercase | PostgreSQL convention |
| `DECIMAL(18,2)` | `NUMERIC(18,2)` | In table DDL (unchanged in queries) |
| `NVARCHAR(n)` | `VARCHAR(n)` | In table DDL |
| `DATETIME` | `TIMESTAMP` | In table DDL |
| `INT IDENTITY(1,1)` | `SERIAL` | In table DDL |

---

## 7. Recommendations for Manual Review

1. **DMS Tool**: The DMS MCP tool was unavailable during this migration. Once the DMS service is restored, re-running the conversions through DMS may provide additional optimization or catch edge cases.

2. **SQL Equivalency**: The SQL Equivalency tool returned errors for all 7 pairs. Once the tool is available, re-validation is recommended to confirm functional equivalence.

3. **Transaction Handling**: Statements 3, 4, and 5 were restructured from T-SQL variable-based patterns to subquery-based patterns. These should be tested with actual data to confirm correct behavior.

4. **Integer Division**: Statement 7 includes `CAST(stockquantity AS NUMERIC)` to prevent integer division. Verify this matches the original SQL Server behavior.

5. **Connection Strings**: The PostgreSQL connection strings use placeholder credentials. Update with actual production credentials before deployment.
