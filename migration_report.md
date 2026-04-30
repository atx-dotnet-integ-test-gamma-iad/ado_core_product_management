# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS MCP Tool | 0 |
| Requiring Manual Intervention (DMS Failure) | 7 |
| Validated as Equivalent (SQL Equivalency Tool) | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Validation Errors | 7 |

## DMS Tool Status

**All 7 DMS conversion attempts failed** with the same error:
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Database**: ProductManagement
- **Schema**: dbo

All statements were manually converted using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` approach as specified by the transformation rules.

## SQL Equivalency Tool Status

**All 7 equivalency validation attempts returned ERROR** with error: `'uniqueID'`

This was a consistent infrastructure error across all statement pairs. Per transformation rules, all pairs are marked as ERROR in the report and no agent judgment was substituted.

---

## Detailed Statement Listing

### Statement 1: GetAllProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetAllProductsAsync()`
- **Type**: SELECT with CTE and Window Functions (AVG, COUNT)

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

- **DMS Output**: Error - Metadata model creation failed
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**: All table/column names lowercased

---

### Statement 2: GetProductByIdAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetProductByIdAsync(int productId)`
- **Type**: SELECT with CTE and LAG Window Functions

**Original MS SQL:**
```sql
WITH ProductHistory AS (
    SELECT ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products WHERE ProductId = @ProductId
)
SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity,
    p.CreatedDate, p.ModifiedDate, ph.PreviousPrice, ph.PreviousStock,
    CASE WHEN ph.PreviousPrice IS NOT NULL THEN 
        ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
    ELSE NULL END as PriceChangePercentage
FROM Products p LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
```

**Converted PostgreSQL:**
```sql
WITH producthistory AS (
    SELECT productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products WHERE productid = @ProductId
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity,
    p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE WHEN ph.previousprice IS NOT NULL THEN 
        ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
    ELSE NULL END as pricechangepercentage
FROM products p LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

- **DMS Output**: Error - Metadata model creation failed
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**: All table/column names lowercased

---

### Statement 3: InsertProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `InsertProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, SCOPE_IDENTITY(), GETDATE()

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

**Converted PostgreSQL (restructured as separate commands in C# transaction):**
```sql
-- Command 1: Insert with RETURNING
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Command 2: Log insertion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Command 3: Update statistics
UPDATE productstats SET totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW() WHERE statid = 1;
```

- **DMS Output**: Error - Metadata model creation failed
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**: SCOPE_IDENTITY()→RETURNING, GETDATE()→NOW(), DECLARE→C# variables, single statement→multiple commands in C# managed transaction

---

### Statement 4: UpdateProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `UpdateProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, GETDATE()

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

**Converted PostgreSQL (restructured as separate commands in C# transaction):**
```sql
-- Command 1: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Command 2: Update product
UPDATE products SET name = @Name, description = @Description, price = @Price,
    stockquantity = @StockQuantity, modifieddate = NOW() WHERE productid = @ProductId;

-- Command 3: Log changes
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Command 4: Update statistics
UPDATE productstats SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW() WHERE statid = 1;
```

- **DMS Output**: Error - Metadata model creation failed
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**: GETDATE()→NOW(), DECLARE→C# variables, single statement→multiple commands

---

### Statement 5: DeleteProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `DeleteProductAsync(int productId)`
- **Type**: Transaction block with DECLARE, GETDATE(), CASE

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    DELETE FROM Products WHERE ProductId = @ProductId;
    UPDATE ProductStats SET TotalProducts = TotalProducts - 1,
        AveragePrice = CASE WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END,
        LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

**Converted PostgreSQL (restructured as separate commands in C# transaction):**
```sql
-- Command 1: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Command 2: Log deletion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Command 3: Delete product
DELETE FROM products WHERE productid = @ProductId;

-- Command 4: Update statistics
UPDATE productstats SET totalproducts = totalproducts - 1,
    averageprice = CASE WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1) ELSE 0 END,
    lastupdated = NOW() WHERE statid = 1;
```

- **DMS Output**: Error - Metadata model creation failed
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**: GETDATE()→NOW(), DECLARE→C# variables, single statement→multiple commands

---

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type**: SELECT with CTE, RANK, PERCENT_RANK Window Functions

**Original MS SQL:**
```sql
WITH RankedProducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*,
    CASE WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
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
SELECT rp.*,
    CASE WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
         WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END as pricesegment
FROM rankedproducts rp ORDER BY rp.pricerank
```

- **DMS Output**: Error - Metadata model creation failed
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**: All table/column names lowercased

---

### Statement 7: GetLowStockProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions

**Original MS SQL:**
```sql
WITH StockAnalysis AS (
    SELECT p.*, AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock, MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT sa.*,
    CASE WHEN StockQuantity <= @Threshold THEN 'Critical'
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
SELECT sa.*,
    CASE WHEN stockquantity <= @Threshold THEN 'Critical'
         WHEN stockquantity <= avgstock * 0.5 THEN 'Low' ELSE 'Adequate' END as stockstatus,
    ROUND((CAST(stockquantity AS numeric) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa WHERE stockquantity <= @Threshold ORDER BY stockquantity
```

- **DMS Output**: Error - Metadata model creation failed
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**: All table/column names lowercased, added CAST(stockquantity AS numeric) for integer division in ROUND

---

## Files Modified During Migration

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All SQL statements converted, ADO.NET classes replaced with Npgsql equivalents |
| `AdoCore.csproj` | Package reference changed from Microsoft.Data.SqlClient 5.1.4 to Npgsql 8.0.6 |
| `appsettings.json` | Connection strings updated from SQL Server to PostgreSQL format |

## Migration Artifacts Created

| Artifact | Description |
|----------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Complete equivalency report with all 7 statement pairs |
| `dms_failure_summary.md` | Detailed DMS failure documentation |
| `migration_report.md` | This comprehensive migration report |

## Package Dependency Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.6 |

**Note**: Npgsql v8.0.6 was chosen instead of v8.0.0 to avoid a known high severity vulnerability (GHSA-x9vc-6hfv-hg8c).

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| SQL Server Specific (removed) | `MultipleActiveResultSets=true;TrustServerCertificate=True` | N/A |

## ADO.NET Class Replacements

| SQL Server Class | PostgreSQL (Npgsql) Class |
|-----------------|-------------------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |

## SQL Syntax Conversions Applied

| SQL Server Syntax | PostgreSQL Equivalent |
|------------------|---------------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` (with restructured C# code) |
| `GETDATE()` | `NOW()` |
| `DECLARE @variable` | C# variables with separate SQL commands |
| `BEGIN TRANSACTION / COMMIT` | C# managed transactions (`BeginTransactionAsync` / `CommitAsync`) |
| `ROUND(expr, n)` | `ROUND(expr, n)` (compatible, added CAST for integer division) |
| PascalCase identifiers | lowercase identifiers |

## Build Status

**Final build: SUCCESS** (0 errors, 10 warnings - all pre-existing nullable reference type warnings)
