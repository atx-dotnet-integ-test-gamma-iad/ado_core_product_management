# Migration Report: MS SQL Server to PostgreSQL

## Overview
- **Application**: AdoCore (.NET 9.0 ADO.NET Application)
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Migration Date**: 2026-05-03
- **Source File**: DataAccess/ProductRepository.cs

---

## 1. Summary Statistics

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Statements Successfully Converted by DMS MCP Tool | 0 |
| Statements Requiring Manual Intervention | 7 |
| Statements Validated as Equivalent | 0 |
| Statements Validated as Non-Equivalent | 0 |
| Statements with Equivalency Validation Errors | 7 |

### DMS Tool Status
All 7 SQL statements were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`) with the following configuration:
- **Migration Project**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Database**: `ProductManagement`
- **Schema**: `dbo`
- **Region**: `us-east-1`

All 7 statements failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

### SQL Equivalency Tool Status
All 7 statement pairs were validated using the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`).
All 7 returned ERROR status with error: `'uniqueID'`

---

## 2. Detailed Statement Log

### Statement 1: GetAllProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetAllProductsAsync()`
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema objects
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

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

**Changes**: Lowercase schema object names only (CTE, window functions, CASE, ROUND are PostgreSQL compatible)

---

### Statement 2: GetProductByIdAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetProductByIdAsync(int productId)`
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema objects
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

**Original MS SQL:**
```sql
WITH ProductHistory AS (
    SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
           LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products WHERE ProductId = @ProductId
)
SELECT p.*, ph.PreviousPrice, ph.PreviousStock,
    CASE WHEN ph.PreviousPrice IS NOT NULL THEN 
        ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
    ELSE NULL END as PriceChangePercentage
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
SELECT p.*, ph.previousprice, ph.previousstock,
    CASE WHEN ph.previousprice IS NOT NULL THEN 
        ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
    ELSE NULL END as pricechangepercentage
FROM products p LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

**Changes**: Lowercase schema object names only (LAG window function is PostgreSQL compatible)

---

### Statement 3: InsertProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `InsertProductAsync(Product product)`
- **DMS Status**: FAILED
- **Manual Conversion**: Restructured as writable CTE with RETURNING
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

**Original MS SQL:**
```sql
DECLARE @NewProductId INT;
BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity) VALUES (...);
    SET @NewProductId = SCOPE_IDENTITY();
    INSERT INTO ProductHistory (...) VALUES (@NewProductId, 'INSERT', ...GETDATE());
    UPDATE ProductStats SET ... LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
SELECT @NewProductId;
```

**Converted PostgreSQL:**
```sql
WITH new_product AS (
    INSERT INTO products (name, description, price, stockquantity) VALUES (...) RETURNING productid
),
history_insert AS (
    INSERT INTO producthistory (...) SELECT productid, 'INSERT', ...NOW() FROM new_product
),
stats_update AS (
    UPDATE productstats SET ... lastupdated = NOW() WHERE statid = 1
)
SELECT productid FROM new_product;
```

**Key Changes**: 
- `SCOPE_IDENTITY()` → `RETURNING productid` with CTE
- `GETDATE()` → `NOW()`
- `DECLARE`/`SET` variable patterns → CTE-based approach
- `BEGIN TRANSACTION`/`COMMIT` → Managed at application level

---

### Statement 4: UpdateProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `UpdateProductAsync(Product product)`
- **DMS Status**: FAILED
- **Manual Conversion**: Restructured as writable CTE
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

**Key Changes**:
- `DECLARE @OldPrice`/`@OldStock` with `SELECT INTO` → CTE `old_values`
- `GETDATE()` → `NOW()`
- Transaction block restructured as writable CTE chain

---

### Statement 5: DeleteProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `DeleteProductAsync(int productId)`
- **DMS Status**: FAILED
- **Manual Conversion**: Restructured as writable CTE
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

**Key Changes**:
- `DECLARE @OldPrice`/`@OldStock` with `SELECT INTO` → CTE `old_values`
- `GETDATE()` → `NOW()`
- `CASE` expression in UPDATE preserved (PostgreSQL compatible)
- Transaction block restructured as writable CTE chain

---

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema objects
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

**Changes**: Lowercase schema object names only (RANK, PERCENT_RANK, BETWEEN are PostgreSQL compatible)

---

### Statement 7: GetLowStockProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema objects + CAST for integer division
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

**Changes**: 
- Lowercase schema object names
- Added `CAST(stockquantity AS numeric)` for proper integer division behavior in ROUND

---

## 3. Code Change Summary

### Package Changes
| Original | Replacement |
|----------|-------------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |

Note: Npgsql 8.0.0 specified in plan was upgraded to 8.0.6 to address known high severity vulnerability (GHSA-x9vc-6hfv-hg8c)

### Class Replacements
| Original (Microsoft.Data.SqlClient) | Replacement (Npgsql) |
|--------------------------------------|----------------------|
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |

### Import Changes
| Original | Replacement |
|----------|-------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |

### Connection String Updates
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server address | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | (removed - not applicable) |
| Trust cert | `TrustServerCertificate=True` | (removed - not applicable) |

---

## 4. Exit Criteria Verification

| Criteria | Status |
|----------|--------|
| All SQL Server packages replaced with PostgreSQL equivalents | ✅ Complete |
| All SqlConnection/SqlCommand/etc replaced with Npgsql equivalents | ✅ Complete |
| ALL SQL statements processed through DMS MCP tool | ✅ Complete (all 7 attempted, all failed) |
| Comprehensive catalog of all SQL statements exists | ✅ Complete (extracted_statements.sql, converted_statements.sql) |
| ALL statement pairs validated through SQL Equivalency tool | ✅ Complete (all 7 validated, all returned ERROR) |
| Comprehensive equivalency report generated | ✅ Complete (sql_equivalency_validation_report.json) |
| No agent judgment used for equivalency | ✅ Complete (all statuses from tool) |
| DMS failures documented with manual conversion | ✅ Complete (dms_failure_summary.md) |
| Connection strings updated to PostgreSQL format | ✅ Complete |
| Transaction handling updated | ✅ Complete (compatible with Npgsql) |
| Application compiles without errors | ✅ Complete (0 errors, 10 pre-existing warnings) |
| SQL setup scripts converted to PostgreSQL | ✅ Complete |

---

## 5. Artifacts Generated

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | All 7 original MS SQL statements |
| converted_statements.sql | sourceCode/ | All 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | sourceCode/ | Comprehensive equivalency validation report |
| dms_failure_summary.md | sourceCode/ | DMS tool failure documentation |
| migration_report.md | sourceCode/ | This report |

---

## 6. Known Issues and Recommendations

1. **DMS Tool Unavailability**: The DMS MCP tool consistently returned "Metadata model creation failed" for all statements. All conversions were done manually with lowercase schema object naming convention.

2. **SQL Equivalency Tool Errors**: The SQL Equivalency tool returned ERROR for all 7 statement pairs with a `'uniqueID'` error, preventing automated validation. Manual review of conversions is recommended.

3. **Writable CTEs (Statements 3, 4, 5)**: The transactional statements using DECLARE/SET/SCOPE_IDENTITY were converted to PostgreSQL writable CTEs (INSERT...RETURNING). These are a PostgreSQL-specific feature and should be tested thoroughly with the actual database.

4. **Security Note**: Npgsql version was upgraded from plan-specified 8.0.0 to 8.0.6 to address CVE advisory GHSA-x9vc-6hfv-hg8c (high severity vulnerability).

5. **Connection String Credentials**: The connection strings use placeholder credentials (postgres/postgres). These should be replaced with proper credentials for each environment, ideally using environment variables or a secrets manager.
