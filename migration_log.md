# Migration Log - SQL Server to PostgreSQL

## Project: AdoCore Product Management Application
## Date: 2026-05-07
## Migration Tool: DMS MCP Tool (attempted) + Manual Conversion (applied)

---

## DMS Tool Configuration

- **Migration Project ARN**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Schema**: dbo
- **Database**: ProductManagement
- **Server**: 172.31.83.165
- **Region**: us-east-1

## DMS Tool Status

**FAILED** - All conversion attempts failed with error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Multiple attempts made with different configurations:
1. Default parameters (poll_interval=10, max_poll=15) - FAILED
2. Extended parameters (poll_interval=20, max_poll=30) - FAILED
3. Explicit database_name parameter - FAILED
4. Explicit server_name parameter - FAILED

---

## Statement 1: GetAllProductsAsync

### Source
- **File**: DataAccess/ProductRepository.cs
- **Method**: GetAllProductsAsync()
- **Line**: ~44-72

### Original MS SQL Statement
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

### DMS Tool Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-05-07T14:03:26.052307"
}
```

### Converted PostgreSQL Statement (Manual)
```sql
WITH productstats AS (
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
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name
```

### Conversion Notes
- All identifiers converted to lowercase
- Window functions (AVG OVER, COUNT OVER) are compatible with PostgreSQL
- CASE expressions compatible with PostgreSQL
- ROUND function compatible with PostgreSQL

---

## Statement 2: GetProductByIdAsync

### Source
- **File**: DataAccess/ProductRepository.cs
- **Method**: GetProductByIdAsync(int productId)
- **Parameters**: @ProductId

### Original MS SQL Statement
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

### DMS Tool Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
}
```

### Converted PostgreSQL Statement (Manual)
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
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

### Conversion Notes
- LAG window function compatible with PostgreSQL
- All identifiers converted to lowercase
- Parameter @ProductId maintained for Npgsql compatibility

---

## Statement 3: InsertProductAsync

### Source
- **File**: DataAccess/ProductRepository.cs
- **Method**: InsertProductAsync(Product product)
- **Parameters**: @Name, @Description, @Price, @StockQuantity

### Original MS SQL Statement
```sql
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;
```

### DMS Tool Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
}
```

### Converted PostgreSQL Statement (Manual - C# managed transaction)
The monolithic T-SQL block was split into separate statements managed by C# transaction:
1. INSERT with RETURNING productid
2. INSERT INTO producthistory with NOW()
3. UPDATE productstats with NOW()

### Conversion Notes
- SCOPE_IDENTITY() → RETURNING productid clause
- GETDATE() → NOW()
- T-SQL transaction block → C# managed transaction (BeginTransactionAsync/CommitAsync)
- DECLARE @var → C# variable

---

## Statement 4: UpdateProductAsync

### Source
- **File**: DataAccess/ProductRepository.cs
- **Method**: UpdateProductAsync(Product product)
- **Parameters**: @ProductId, @Name, @Description, @Price, @StockQuantity

### Original MS SQL Statement
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products WHERE ProductId = @ProductId;
    
    UPDATE Products SET Name = @Name, Description = @Description,
        Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    UPDATE ProductStats SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

### DMS Tool Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
}
```

### Converted PostgreSQL Statement (Manual - C# managed transaction)
Split into separate statements with C# managed transaction and variables.

### Conversion Notes
- DECLARE @OldPrice → C# `decimal oldPrice` variable
- SELECT @OldPrice = Price → C# reader with SELECT price, stockquantity
- GETDATE() → NOW()
- Transaction managed in C#

---

## Statement 5: DeleteProductAsync

### Source
- **File**: DataAccess/ProductRepository.cs
- **Method**: DeleteProductAsync(int productId)
- **Parameters**: @ProductId

### Original MS SQL Statement
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
    DELETE FROM Products WHERE ProductId = @ProductId;
    
    UPDATE ProductStats SET TotalProducts = TotalProducts - 1,
        AveragePrice = CASE WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END,
        LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

### DMS Tool Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
}
```

### Converted PostgreSQL Statement (Manual - C# managed transaction)
Split into separate statements with C# managed transaction and variables.

### Conversion Notes
- Same pattern as UpdateProductAsync
- CASE expression in UPDATE compatible with PostgreSQL
- Transaction managed in C#

---

## Statement 6: GetProductsByPriceRangeAsync

### Source
- **File**: DataAccess/ProductRepository.cs
- **Method**: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
- **Parameters**: @MinPrice, @MaxPrice

### Original MS SQL Statement
```sql
WITH RankedProducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*, CASE 
    WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
    WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
    ELSE 'Premium' END as PriceSegment
FROM RankedProducts rp
ORDER BY rp.PriceRank
```

### DMS Tool Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
}
```

### Converted PostgreSQL Statement (Manual)
```sql
WITH rankedproducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*, CASE 
    WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
    WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
    ELSE 'Premium' END as pricesegment
FROM rankedproducts rp
ORDER BY rp.pricerank
```

### Conversion Notes
- RANK() and PERCENT_RANK() window functions compatible with PostgreSQL
- BETWEEN compatible with PostgreSQL
- All identifiers lowercase

---

## Statement 7: GetLowStockProductsAsync

### Source
- **File**: DataAccess/ProductRepository.cs
- **Method**: GetLowStockProductsAsync(int threshold)
- **Parameters**: @Threshold

### Original MS SQL Statement
```sql
WITH StockAnalysis AS (
    SELECT p.*, AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock,
        MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT sa.*, CASE 
    WHEN StockQuantity <= @Threshold THEN 'Critical'
    WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
    ELSE 'Adequate' END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity
```

### DMS Tool Output
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
}
```

### Converted PostgreSQL Statement (Manual)
```sql
WITH stockanalysis AS (
    SELECT p.*, AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT sa.*, CASE 
    WHEN stockquantity <= @Threshold THEN 'Critical'
    WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
    ELSE 'Adequate' END as stockstatus,
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity
```

### Conversion Notes
- Added `::numeric` cast for integer division in ROUND to avoid integer truncation
- AVG/MIN/MAX window functions compatible with PostgreSQL
- All identifiers lowercase

---

## SQL Equivalency Validation

All 7 statement pairs were validated using the sql-equivalency___validate_sql_equivalence tool.
The tool returned ERROR for all statements with: `{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}`
This was a service-side issue affecting all validation attempts.

See `sql_equivalency_validation_report.json` for the complete validation report.
