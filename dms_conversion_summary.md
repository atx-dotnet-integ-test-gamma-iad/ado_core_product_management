# DMS Conversion Failure Summary

## Overview
All 7 SQL statements failed DMS conversion with the same error.
Manual conversion was applied using lowercase schema mapping rules for PostgreSQL compatibility.

## DMS Error
All statements received the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

## Statements Converted Manually

### Statement 1: GetAllProductsAsync (SELECT with CTE, window functions)
- **Source file**: DataAccess/ProductRepository.cs
- **DMS Output**: Error - Metadata model creation failed
- **Manual conversion**: Applied lowercase schema object names, SQL syntax is ANSI-compatible

### Statement 2: GetProductByIdAsync (SELECT with CTE, LAG window function)
- **Source file**: DataAccess/ProductRepository.cs
- **DMS Output**: Error - Metadata model creation failed
- **Manual conversion**: Applied lowercase schema object names, SQL syntax is ANSI-compatible

### Statement 3: InsertProductAsync (Transaction with SCOPE_IDENTITY, GETDATE)
- **Source file**: DataAccess/ProductRepository.cs
- **DMS Output**: Error - Metadata model creation failed
- **Manual conversion**: Replaced T-SQL DECLARE/SCOPE_IDENTITY/BEGIN TRANSACTION with PostgreSQL writable CTE + RETURNING clause; GETDATE() → NOW()

### Statement 4: UpdateProductAsync (Transaction with variables, GETDATE)
- **Source file**: DataAccess/ProductRepository.cs
- **DMS Output**: Error - Metadata model creation failed
- **Manual conversion**: Replaced T-SQL DECLARE/BEGIN TRANSACTION with PostgreSQL writable CTE; GETDATE() → NOW()

### Statement 5: DeleteProductAsync (Transaction with variables, GETDATE)
- **Source file**: DataAccess/ProductRepository.cs
- **DMS Output**: Error - Metadata model creation failed
- **Manual conversion**: Replaced T-SQL DECLARE/BEGIN TRANSACTION with PostgreSQL writable CTE; GETDATE() → NOW()

### Statement 6: GetProductsByPriceRangeAsync (SELECT with CTE, RANK, PERCENT_RANK)
- **Source file**: DataAccess/ProductRepository.cs
- **DMS Output**: Error - Metadata model creation failed
- **Manual conversion**: Applied lowercase schema object names, SQL syntax is ANSI-compatible

### Statement 7: GetLowStockProductsAsync (SELECT with CTE, window functions)
- **Source file**: DataAccess/ProductRepository.cs
- **DMS Output**: Error - Metadata model creation failed
- **Manual conversion**: Applied lowercase schema object names, added CAST(stockquantity AS numeric) for proper division

## Migration Report Summary
- **Total SQL statements processed**: 7
- **Successfully converted by DMS**: 0
- **Manual conversion required (DMS failure)**: 7
- **Equivalency validation status**: All 7 returned ERROR from the SQL Equivalency tool
- **Reason**: SQL Equivalency tool returned error "'uniqueID'" for all statement pairs
