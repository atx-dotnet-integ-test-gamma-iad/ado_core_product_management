# DMS Conversion Log

## Overview
This log documents all interactions with the AWS DMS MCP Statement Conversion Tool during the SQL Server to PostgreSQL migration of the AdoCore .NET application.

**Total DMS Tool Invocations**: 7
**Successful Conversions**: 0
**Failed Conversions**: 7
**Common Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

---

## Statement 1: GetAllProductsAsync

**Source File**: DataAccess/ProductRepository.cs
**Method**: GetAllProductsAsync
**DMS Tool Parameters**:
- schema_name: dbo
- sql_text: `WITH ProductStats AS (SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts FROM Products) SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average' WHEN p.Price < ps.AvgPrice THEN 'Below Average' ELSE 'Average' END as PriceCategory, ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage FROM Products p INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name`

**DMS Output**:
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-05-01T00:49:23.507041"
}
```

**Manual Conversion Applied**: Yes
**Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Conversion Details**: Lowercased all schema object names (Products→products, ProductId→productid, etc.)

---

## Statement 2: GetProductByIdAsync

**Source File**: DataAccess/ProductRepository.cs
**Method**: GetProductByIdAsync
**DMS Tool Parameters**:
- schema_name: dbo
- sql_text: `WITH ProductHistory AS (SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice, LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock FROM Products WHERE ProductId = @ProductId) SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, ph.PreviousPrice, ph.PreviousStock, CASE WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2) ELSE NULL END as PriceChangePercentage FROM Products p LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId WHERE p.ProductId = @ProductId`

**DMS Output**:
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-05-01T00:49:52.991790"
}
```

**Manual Conversion Applied**: Yes
**Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Conversion Details**: Lowercased all schema object names, preserved @ProductId parameter

---

## Statement 3: InsertProductAsync

**Source File**: DataAccess/ProductRepository.cs
**Method**: InsertProductAsync
**DMS Tool Parameters**:
- schema_name: dbo
- sql_text: `DECLARE @NewProductId INT; BEGIN TRANSACTION; INSERT INTO Products (Name, Description, Price, StockQuantity) VALUES (@Name, @Description, @Price, @StockQuantity); SET @NewProductId = SCOPE_IDENTITY(); INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE()); UPDATE ProductStats SET TotalProducts = TotalProducts + 1, AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1), LastUpdated = GETDATE() WHERE StatId = 1; COMMIT; SELECT @NewProductId;`

**DMS Output**:
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-05-01T00:50:07.202197"
}
```

**Manual Conversion Applied**: Yes
**Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Conversion Details**:
- SCOPE_IDENTITY() → RETURNING clause in CTE
- GETDATE() → NOW()
- DECLARE/SET @variable → Eliminated via CTE restructuring
- BEGIN TRANSACTION/COMMIT → Eliminated (CTE is atomic)
- Lowercased all schema object names

---

## Statement 4: UpdateProductAsync

**Source File**: DataAccess/ProductRepository.cs
**Method**: UpdateProductAsync
**DMS Tool Parameters**:
- schema_name: dbo
- sql_text: `BEGIN TRANSACTION; DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT; SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId; UPDATE Products SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE() WHERE ProductId = @ProductId; INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE()); UPDATE ProductStats SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts, LastUpdated = GETDATE() WHERE StatId = 1; COMMIT;`

**DMS Output**:
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-05-01T00:50:19.856216"
}
```

**Manual Conversion Applied**: Yes
**Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Conversion Details**:
- DECLARE @variable → Eliminated via CTE (old_values)
- SELECT INTO variables → CTE subquery
- GETDATE() → NOW()
- BEGIN TRANSACTION/COMMIT → Eliminated (CTE is atomic)
- Lowercased all schema object names

---

## Statement 5: DeleteProductAsync

**Source File**: DataAccess/ProductRepository.cs
**Method**: DeleteProductAsync
**DMS Tool Parameters**:
- schema_name: dbo
- sql_text: `BEGIN TRANSACTION; DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT; SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId; INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE()); DELETE FROM Products WHERE ProductId = @ProductId; UPDATE ProductStats SET TotalProducts = TotalProducts - 1, AveragePrice = CASE WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END, LastUpdated = GETDATE() WHERE StatId = 1; COMMIT;`

**DMS Output**:
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-05-01T00:50:36.013051"
}
```

**Manual Conversion Applied**: Yes
**Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Conversion Details**:
- DECLARE @variable → Eliminated via CTE (old_values)
- SELECT INTO variables → CTE subquery
- GETDATE() → NOW()
- BEGIN TRANSACTION/COMMIT → Eliminated (CTE is atomic)
- Lowercased all schema object names
- CASE expression preserved for conditional average calculation

---

## Statement 6: GetProductsByPriceRangeAsync

**Source File**: DataAccess/ProductRepository.cs
**Method**: GetProductsByPriceRangeAsync
**DMS Tool Parameters**:
- schema_name: dbo
- sql_text: `WITH RankedProducts AS (SELECT p.*, RANK() OVER (ORDER BY p.Price) as PriceRank, PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile FROM Products p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice) SELECT rp.*, CASE WHEN rp.PricePercentile <= 0.25 THEN 'Budget' WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END as PriceSegment FROM RankedProducts rp ORDER BY rp.PriceRank`

**DMS Output**:
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-05-01T00:50:49.144412"
}
```

**Manual Conversion Applied**: Yes
**Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Conversion Details**: Lowercased all schema object names (RankedProducts→rankedproducts, PriceRank→pricerank, etc.)

---

## Statement 7: GetLowStockProductsAsync

**Source File**: DataAccess/ProductRepository.cs
**Method**: GetLowStockProductsAsync
**DMS Tool Parameters**:
- schema_name: dbo
- sql_text: `WITH StockAnalysis AS (SELECT p.*, AVG(StockQuantity) OVER() as AvgStock, MIN(StockQuantity) OVER() as MinStock, MAX(StockQuantity) OVER() as MaxStock FROM Products p) SELECT sa.*, CASE WHEN StockQuantity <= @Threshold THEN 'Critical' WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low' ELSE 'Adequate' END as StockStatus, ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage FROM StockAnalysis sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity`

**DMS Output**:
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "error_timestamp": "2026-05-01T00:51:03.166938"
}
```

**Manual Conversion Applied**: Yes
**Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Conversion Details**:
- Lowercased all schema object names (StockAnalysis→stockanalysis, AvgStock→avgstock, etc.)
- Added `::numeric` cast for `ROUND((stockquantity::numeric / avgstock) * 100, 2)` to handle PostgreSQL integer division behavior
