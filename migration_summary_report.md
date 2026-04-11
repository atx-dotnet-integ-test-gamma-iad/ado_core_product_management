# Migration Summary Report
## MS SQL Server to PostgreSQL Migration for .NET ADO Application

**Migration Date:** 2026-04-11  
**Application:** AdoCore (.NET 9.0 ADO.NET Application)  
**Source Database:** Microsoft SQL Server  
**Target Database:** PostgreSQL  

---

## Executive Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention (DMS failure) | 7 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent (SQL Equivalency tool) | 0 |
| Equivalency validation errors | 7 |

**DMS Tool Status:** All 7 conversion attempts failed with error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

**SQL Equivalency Tool Status:** All 7 validation attempts returned ERROR with: `'uniqueID'`

**Manual Conversion Method:** `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` applied to all 7 statements.

---

## Files Modified

| File | Change Type | Description |
|------|------------|-------------|
| `DataAccess/ProductRepository.cs` | Modified | Replaced all 7 SQL statements, updated ADO.NET classes |
| `AdoCore.csproj` | Modified | Replaced package reference |
| `appsettings.json` | Modified | Updated connection strings |

## Package Changes

| Original Package | Version | Replacement Package | Version |
|-----------------|---------|-------------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.1 |

## ADO.NET Class Changes

| Original (SQL Server) | Replacement (PostgreSQL/Npgsql) |
|-----------------------|-------------------------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

## Connection String Changes

| Parameter | SQL Server Value | PostgreSQL Value |
|-----------|-----------------|-----------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `true` | *(removed - not applicable)* |
| TrustServerCertificate | `True` | *(removed - not applicable)* |

---

## Detailed Statement Conversion Report

### Statement 1: GetAllProductsAsync

**Source Location:** `DataAccess/ProductRepository.cs`, GetAllProductsAsync method  
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  
**Equivalency Status:** ERROR (tool returned: `'uniqueID'`)  
**DMS Failure Reason:** Metadata model creation failed  

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
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name
```

**Converted PostgreSQL:**
```sql
WITH productstats_cte AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name
```

**Changes Applied:** Table/column names to lowercase. CTE renamed from `ProductStats` to `productstats_cte` to avoid conflict with table name.

---

### Statement 2: GetProductByIdAsync

**Source Location:** `DataAccess/ProductRepository.cs`, GetProductByIdAsync method  
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  
**Equivalency Status:** ERROR (tool returned: `'uniqueID'`)  
**DMS Failure Reason:** Metadata model creation failed  

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
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    ph.PreviousPrice,
    ph.PreviousStock,
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
WITH producthistory_cte AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = @productid
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    ph.previousprice,
    ph.previousstock,
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @productid
```

**Changes Applied:** Table/column names to lowercase. CTE renamed to `producthistory_cte`. Parameter `@ProductId` → `@productid`.

---

### Statement 3: InsertProductAsync

**Source Location:** `DataAccess/ProductRepository.cs`, InsertProductAsync method  
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  
**Equivalency Status:** ERROR (tool returned: `'uniqueID'`)  
**DMS Failure Reason:** Metadata model creation failed  

**Original MS SQL:**
```sql
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;
```

**Converted PostgreSQL:**
```sql
WITH new_product AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@name, @description, @price, @stockquantity)
    RETURNING productid
),
log_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @price, NULL, @stockquantity, clock_timestamp()
    FROM new_product
),
update_stats AS (
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1
)
SELECT productid FROM new_product;
```

**Changes Applied:**
- `SCOPE_IDENTITY()` → PostgreSQL `RETURNING` clause with writable CTE
- `GETDATE()` → `clock_timestamp()`
- `DECLARE`/`SET` variables eliminated via CTE restructuring
- `BEGIN TRANSACTION`/`COMMIT` replaced by atomic CTE execution
- All identifiers lowercased

---

### Statement 4: UpdateProductAsync

**Source Location:** `DataAccess/ProductRepository.cs`, UpdateProductAsync method  
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  
**Equivalency Status:** ERROR (tool returned: `'uniqueID'`)  
**DMS Failure Reason:** Metadata model creation failed  

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
```

**Converted PostgreSQL:**
```sql
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @productid
),
do_update AS (
    UPDATE products
    SET 
        name = @name,
        description = @description,
        price = @price,
        stockquantity = @stockquantity,
        modifieddate = clock_timestamp()
    WHERE productid = @productid
),
log_change AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @productid, 'UPDATE', ov.oldprice, @price, ov.oldstock, @stockquantity, clock_timestamp()
    FROM old_values ov
)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;
```

**Changes Applied:**
- `DECLARE`/`SET` variables → CTE `old_values` to capture old values
- `GETDATE()` → `clock_timestamp()`
- `BEGIN TRANSACTION`/`COMMIT` → atomic writable CTE
- All identifiers lowercased

---

### Statement 5: DeleteProductAsync

**Source Location:** `DataAccess/ProductRepository.cs`, DeleteProductAsync method  
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  
**Equivalency Status:** ERROR (tool returned: `'uniqueID'`)  
**DMS Failure Reason:** Metadata model creation failed  

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
```

**Converted PostgreSQL:**
```sql
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @productid
),
log_deletion AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @productid, 'DELETE', ov.oldprice, NULL, ov.oldstock, NULL, clock_timestamp()
    FROM old_values ov
),
do_delete AS (
    DELETE FROM products 
    WHERE productid = @productid
)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = clock_timestamp()
WHERE statid = 1;
```

**Changes Applied:**
- `DECLARE`/`SET` variables → CTE `old_values` to capture old values
- `GETDATE()` → `clock_timestamp()`
- `BEGIN TRANSACTION`/`COMMIT` → atomic writable CTE
- All identifiers lowercased

---

### Statement 6: GetProductsByPriceRangeAsync

**Source Location:** `DataAccess/ProductRepository.cs`, GetProductsByPriceRangeAsync method  
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  
**Equivalency Status:** ERROR (tool returned: `'uniqueID'`)  
**DMS Failure Reason:** Metadata model creation failed  

**Original MS SQL:**
```sql
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as PriceSegment
FROM RankedProducts rp
ORDER BY rp.PriceRank
```

**Converted PostgreSQL:**
```sql
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN @minprice AND @maxprice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as pricesegment
FROM rankedproducts rp
ORDER BY rp.pricerank
```

**Changes Applied:** Table/column names to lowercase. Parameters `@MinPrice`/`@MaxPrice` → `@minprice`/`@maxprice`.

---

### Statement 7: GetLowStockProductsAsync

**Source Location:** `DataAccess/ProductRepository.cs`, GetLowStockProductsAsync method  
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  
**Equivalency Status:** ERROR (tool returned: `'uniqueID'`)  
**DMS Failure Reason:** Metadata model creation failed  

**Original MS SQL:**
```sql
WITH StockAnalysis AS (
    SELECT 
        p.*,
        AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock,
        MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT 
    sa.*,
    CASE 
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity
```

**Converted PostgreSQL:**
```sql
WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT 
    sa.*,
    CASE 
        WHEN stockquantity <= @threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @threshold
ORDER BY stockquantity
```

**Changes Applied:** Table/column names to lowercase. Added `CAST(stockquantity AS NUMERIC)` to prevent integer division. Parameter `@Threshold` → `@threshold`.

---

## Schema Mapping Reference (from DMS schema_mapping_tool)

| Source Table (SQL Server) | Target Table (PostgreSQL) | Schema |
|--------------------------|--------------------------|--------|
| `[dbo].[Products]` | `products` | `productmanagement_dbo` |
| `[dbo].[ProductHistory]` | `producthistory` | `productmanagement_dbo` |
| `[dbo].[ProductStats]` | `productstats` | `productmanagement_dbo` |

**Note:** The DMS schema mapping tool successfully returned mappings even though the statement conversion tool failed. Schema object names follow lowercase PostgreSQL convention.

---

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. **DMS conversion failure** - All statements were manually converted
2. **Equivalency validation error** - The SQL Equivalency tool returned ERROR for all pairs

**Recommendation:** Manual testing against a PostgreSQL database is strongly recommended to verify functional equivalency of all converted statements.

---

## Migration Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | `sourceCode/` | All 7 original MS SQL statements |
| `converted_statements.sql` | `sourceCode/` | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | `sourceCode/` | Comprehensive equivalency validation report |
| `migration_summary_report.md` | `sourceCode/` | This report |

---

*Report generated: 2026-04-11*
