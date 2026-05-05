# SQL Server to PostgreSQL Migration Log

## Migration Summary
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Application**: AdoCore (.NET 9.0 ADO.NET Application)
- **Migration Date**: 2026-05-05
- **DMS Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

## DMS Tool Status
The DMS Statement Conversion Tool (dms-mcp___statement_conversion_tool) failed for ALL 7 statements with the following consistent error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

The DMS Schema Mapping Tool (dms-mcp___schema_mapping_tool) was successful and provided target schema information used for manual conversion.

## Schema Mapping (from DMS Schema Mapping Tool)

| Source Table | Target Table | Target Schema |
|---|---|---|
| [dbo].[Products] | products | productmanagement_dbo |
| [dbo].[ProductHistory] | producthistory | productmanagement_dbo |
| [dbo].[ProductStats] | productstats | productmanagement_dbo |

### Column Mappings

**Products:**
| Source Column | Target Column | Source Type | Target Type |
|---|---|---|---|
| ProductId | productid | int IDENTITY | INTEGER GENERATED ALWAYS AS IDENTITY |
| Name | name | nvarchar(100) | VARCHAR(100) |
| Description | description | nvarchar(500) | VARCHAR(500) |
| Price | price | decimal(18,2) | NUMERIC(18,2) |
| StockQuantity | stockquantity | int | INTEGER |
| CreatedDate | createddate | datetime | TIMESTAMP WITHOUT TIME ZONE |
| ModifiedDate | modifieddate | datetime | TIMESTAMP WITHOUT TIME ZONE |

**ProductHistory:**
| Source Column | Target Column | Source Type | Target Type |
|---|---|---|---|
| HistoryId | historyid | int IDENTITY | INTEGER GENERATED ALWAYS AS IDENTITY |
| ProductId | productid | int | INTEGER |
| Action | action | varchar(10) | VARCHAR(10) |
| OldPrice | oldprice | decimal(18,2) | NUMERIC(18,2) |
| NewPrice | newprice | decimal(18,2) | NUMERIC(18,2) |
| OldStock | oldstock | int | INTEGER |
| NewStock | newstock | int | INTEGER |
| ActionDate | actiondate | datetime | TIMESTAMP WITHOUT TIME ZONE |

**ProductStats:**
| Source Column | Target Column | Source Type | Target Type |
|---|---|---|---|
| StatId | statid | int | INTEGER |
| TotalProducts | totalproducts | int | INTEGER |
| AveragePrice | averageprice | decimal(18,2) | NUMERIC(18,2) |
| LastUpdated | lastupdated | datetime | TIMESTAMP WITHOUT TIME ZONE |

---

## Statement 1: GetAllProductsAsync

**Source File**: DataAccess/ProductRepository.cs  
**Method**: GetAllProductsAsync()  
**DMS Status**: FAILED  
**DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}  
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  

### Original MS SQL:
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

### Converted PostgreSQL:
```sql
WITH productstats_cte AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM productmanagement_dbo.products
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
FROM productmanagement_dbo.products p
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END,
    p.name
```

### Manual Intervention Notes:
- Renamed CTE from `ProductStats` to `productstats_cte` to avoid conflict with table name `productstats`
- All identifiers converted to lowercase per DMS schema mapping
- Added `productmanagement_dbo` schema prefix

---

## Statement 2: GetProductByIdAsync

**Source File**: DataAccess/ProductRepository.cs  
**Method**: GetProductByIdAsync(int productId)  
**DMS Status**: FAILED  
**DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}  
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  

### Original MS SQL:
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
    p.CreatedDate, p.ModifiedDate,
    ph.PreviousPrice, ph.PreviousStock,
    CASE 
        WHEN ph.PreviousPrice IS NOT NULL THEN 
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
```

### Converted PostgreSQL:
```sql
WITH producthistory_cte AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId
)
SELECT 
    p.productid, p.name, p.description, p.price, p.stockquantity,
    p.createddate, p.modifieddate,
    ph.previousprice, ph.previousstock,
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END as pricechangepercentage
FROM productmanagement_dbo.products p
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

### Manual Intervention Notes:
- Renamed CTE from `ProductHistory` to `producthistory_cte` to avoid conflict with table name `producthistory`
- LAG window functions are directly compatible with PostgreSQL

---

## Statement 3: InsertProductAsync

**Source File**: DataAccess/ProductRepository.cs  
**Method**: InsertProductAsync(Product product)  
**DMS Status**: FAILED  
**DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}  
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  

### Original MS SQL:
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

### Converted PostgreSQL:
```sql
-- Split into separate commands managed by C# transaction:

-- Command 1: Insert product
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Command 2: Log insertion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- Command 3: Update stats
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;
```

### Manual Intervention Notes:
- SCOPE_IDENTITY() replaced with PostgreSQL RETURNING clause
- Transaction managed by C# code (BeginTransactionAsync/CommitAsync)
- GETDATE() replaced with clock_timestamp()
- Single monolithic SQL block split into separate parameterized commands for Npgsql compatibility

---

## Statement 4: UpdateProductAsync

**Source File**: DataAccess/ProductRepository.cs  
**Method**: UpdateProductAsync(Product product)  
**DMS Status**: FAILED  
**DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}  
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  

### Original MS SQL:
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products WHERE ProductId = @ProductId;
    UPDATE Products
    SET Name = @Name, Description = @Description, Price = @Price,
        StockQuantity = @StockQuantity, ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    UPDATE ProductStats
    SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
```

### Converted PostgreSQL:
```sql
-- Split into separate commands managed by C# transaction:

-- Command 1: Get old values
SELECT price, stockquantity FROM productmanagement_dbo.products WHERE productid = @ProductId;

-- Command 2: Update product
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price,
    stockquantity = @StockQuantity, modifieddate = clock_timestamp()
WHERE productid = @ProductId;

-- Command 3: Log changes
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- Command 4: Update stats
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;
```

### Manual Intervention Notes:
- DECLARE/SET variables replaced with C# variables populated by separate SELECT command
- Transaction managed by C# code (BeginTransactionAsync/CommitAsync)
- GETDATE() replaced with clock_timestamp()

---

## Statement 5: DeleteProductAsync

**Source File**: DataAccess/ProductRepository.cs  
**Method**: DeleteProductAsync(int productId)  
**DMS Status**: FAILED  
**DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}  
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  

### Original MS SQL:
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    DELETE FROM Products WHERE ProductId = @ProductId;
    UPDATE ProductStats
    SET TotalProducts = TotalProducts - 1,
        AveragePrice = CASE WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
```

### Converted PostgreSQL:
```sql
-- Split into separate commands managed by C# transaction:

-- Command 1: Get old values
SELECT price, stockquantity FROM productmanagement_dbo.products WHERE productid = @ProductId;

-- Command 2: Log deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- Command 3: Delete product
DELETE FROM productmanagement_dbo.products WHERE productid = @ProductId;

-- Command 4: Update stats
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1,
    averageprice = CASE WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1) ELSE 0 END,
    lastupdated = clock_timestamp()
WHERE statid = 1;
```

### Manual Intervention Notes:
- Same approach as UpdateProductAsync - variables handled in C#
- CASE expression for AVERAGEPRICE is directly compatible with PostgreSQL

---

## Statement 6: GetProductsByPriceRangeAsync

**Source File**: DataAccess/ProductRepository.cs  
**Method**: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)  
**DMS Status**: FAILED  
**DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}  
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  

### Original MS SQL:
```sql
WITH RankedProducts AS (
    SELECT p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*,
    CASE 
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as PriceSegment
FROM RankedProducts rp
ORDER BY rp.PriceRank
```

### Converted PostgreSQL:
```sql
WITH rankedproducts AS (
    SELECT p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM productmanagement_dbo.products p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as pricesegment
FROM rankedproducts rp
ORDER BY rp.pricerank
```

### Manual Intervention Notes:
- RANK() and PERCENT_RANK() are directly compatible with PostgreSQL
- BETWEEN is compatible with PostgreSQL
- All identifiers converted to lowercase

---

## Statement 7: GetLowStockProductsAsync

**Source File**: DataAccess/ProductRepository.cs  
**Method**: GetLowStockProductsAsync(int threshold)  
**DMS Status**: FAILED  
**DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}  
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  

### Original MS SQL:
```sql
WITH StockAnalysis AS (
    SELECT p.*,
        AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock,
        MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT sa.*,
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

### Converted PostgreSQL:
```sql
WITH stockanalysis AS (
    SELECT p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM productmanagement_dbo.products p
)
SELECT sa.*,
    CASE 
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity
```

### Manual Intervention Notes:
- Added CAST(stockquantity AS NUMERIC) to avoid integer division in PostgreSQL
- AVG/MIN/MAX window functions are directly compatible
