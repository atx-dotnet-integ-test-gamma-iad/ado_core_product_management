# DMS Conversion Failure Summary

## Overview
All 7 SQL statements failed DMS conversion with the same error. Manual conversion was applied using lowercase schema mapping for PostgreSQL compatibility.

## DMS Error
All statements returned:
```
Status: error
Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

## SQL Equivalency Tool Error
All 7 statement pairs returned:
```
Status: ERROR
Error: 'uniqueID'
```

## Statements Processed

### Statement 1: GetAllProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion**: CTE with window functions - converted schema objects to lowercase
- **Key Changes**: Products → products, ProductId → productid, Price → price, etc.

### Statement 2: GetProductByIdAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion**: CTE with LAG window function - converted schema objects to lowercase
- **Key Changes**: Products → products, ModifiedDate → modifieddate, etc.

### Statement 3: InsertProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion**: T-SQL transaction with SCOPE_IDENTITY() → PostgreSQL writable CTE with RETURNING clause
- **Key Changes**: SCOPE_IDENTITY() → RETURNING productid, GETDATE() → NOW(), BEGIN TRANSACTION/COMMIT → writable CTE

### Statement 4: UpdateProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion**: T-SQL transaction with DECLARE variables → PostgreSQL writable CTE
- **Key Changes**: DECLARE @var → CTE subquery, GETDATE() → NOW(), variable assignment → CTE old_values

### Statement 5: DeleteProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion**: T-SQL transaction with DECLARE variables → PostgreSQL writable CTE
- **Key Changes**: DECLARE @var → CTE subquery, GETDATE() → NOW(), variable assignment → CTE old_values

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion**: CTE with RANK() and PERCENT_RANK() - converted schema objects to lowercase
- **Key Changes**: Products → products, Price → price, etc.

### Statement 7: GetLowStockProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion**: CTE with AVG/MIN/MAX OVER() - converted schema objects to lowercase, added CAST for integer division
- **Key Changes**: Products → products, StockQuantity → stockquantity, added CAST(stockquantity AS DECIMAL)

## Migration Summary
- **Total Statements**: 7
- **DMS Successful Conversions**: 0
- **Manual Conversions (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)**: 7
- **Equivalency Validated (EQUIVALENT)**: 0
- **Equivalency Errors**: 7
- **Non-Equivalent**: 0
