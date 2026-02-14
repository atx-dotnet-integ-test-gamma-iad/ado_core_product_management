# SQL Statement Extraction Tracking Document

## Overview
This document provides full traceability for all SQL statements extracted from the ADO Core application for PostgreSQL migration.

## Extraction Summary
- **Total Statements Identified**: 7
- **Total Statements Extracted**: 7
- **Extraction Coverage**: 100%
- **Extraction Date**: 2026-02-14

## Statement Tracking Table

| Statement ID | Method Name | Source File | Line Range | Extraction Status | Parameters | Statement Type | Complexity |
|-------------|-------------|-------------|------------|-------------------|------------|----------------|-----------|
| STMT_001_GetAllProductsAsync | GetAllProductsAsync | DataAccess/ProductRepository.cs | 42-72 | ✅ EXTRACTED | None | CTE + Window Functions | HIGH |
| STMT_002_GetProductByIdAsync | GetProductByIdAsync | DataAccess/ProductRepository.cs | 82-110 | ✅ EXTRACTED | @ProductId | CTE + LAG Window Function | HIGH |
| STMT_003_InsertProductAsync | InsertProductAsync | DataAccess/ProductRepository.cs | 122-145 | ✅ EXTRACTED | @Name, @Description, @Price, @StockQuantity | Multi-Statement Transaction | HIGH |
| STMT_004_UpdateProductAsync | UpdateProductAsync | DataAccess/ProductRepository.cs | 157-188 | ✅ EXTRACTED | @ProductId, @Name, @Description, @Price, @StockQuantity | Multi-Statement Transaction | HIGH |
| STMT_005_DeleteProductAsync | DeleteProductAsync | DataAccess/ProductRepository.cs | 198-229 | ✅ EXTRACTED | @ProductId | Multi-Statement Transaction | HIGH |
| STMT_006_GetProductsByPriceRangeAsync | GetProductsByPriceRangeAsync | DataAccess/ProductRepository.cs | 239-265 | ✅ EXTRACTED | @MinPrice, @MaxPrice | CTE + RANK/PERCENT_RANK | HIGH |
| STMT_007_GetLowStockProductsAsync | GetLowStockProductsAsync | DataAccess/ProductRepository.cs | 275-302 | ✅ EXTRACTED | @Threshold | CTE + Aggregate Window Functions | HIGH |

## Statement Details

### STMT_001_GetAllProductsAsync
- **Purpose**: Retrieves all products with price analysis
- **Key Features**: CTE, AVG() OVER(), COUNT() OVER(), CASE statements
- **Return Type**: List<Product>
- **Migration Considerations**: Window functions need PostgreSQL syntax verification

### STMT_002_GetProductByIdAsync
- **Purpose**: Retrieves specific product with historical analysis
- **Key Features**: CTE, LAG() OVER(), price change calculation
- **Return Type**: Product (single)
- **Migration Considerations**: LAG window function, NULL handling

### STMT_003_InsertProductAsync
- **Purpose**: Inserts new product with transaction management
- **Key Features**: Multi-statement transaction, SCOPE_IDENTITY(), GETDATE()
- **Return Type**: int (ProductId)
- **Migration Considerations**: 
  - SCOPE_IDENTITY() → PostgreSQL RETURNING clause or LASTVAL()
  - GETDATE() → CURRENT_TIMESTAMP or NOW()
  - Transaction syntax: BEGIN TRANSACTION → BEGIN

### STMT_004_UpdateProductAsync
- **Purpose**: Updates product with history logging
- **Key Features**: Multi-statement transaction, variable declarations, GETDATE()
- **Return Type**: void
- **Migration Considerations**: 
  - GETDATE() → CURRENT_TIMESTAMP or NOW()
  - Variable declarations need PostgreSQL DO block syntax

### STMT_005_DeleteProductAsync
- **Purpose**: Deletes product with cleanup and statistics update
- **Key Features**: Multi-statement transaction, conditional logic, GETDATE()
- **Return Type**: void
- **Migration Considerations**: 
  - GETDATE() → CURRENT_TIMESTAMP or NOW()
  - Variable declarations need PostgreSQL DO block syntax

### STMT_006_GetProductsByPriceRangeAsync
- **Purpose**: Retrieves products in price range with ranking
- **Key Features**: CTE, RANK() OVER(), PERCENT_RANK() OVER()
- **Return Type**: List<Product>
- **Migration Considerations**: Window functions ranking and percentile

### STMT_007_GetLowStockProductsAsync
- **Purpose**: Retrieves low stock products with analysis
- **Key Features**: CTE, AVG/MIN/MAX aggregate window functions
- **Return Type**: List<Product>
- **Migration Considerations**: Multiple aggregate window functions

## SQL Server Features Requiring Conversion

### 1. Window Functions (4 statements)
- **AVG() OVER()**: STMT_001, STMT_007
- **COUNT() OVER()**: STMT_001
- **LAG() OVER()**: STMT_002
- **RANK() OVER()**: STMT_006
- **PERCENT_RANK() OVER()**: STMT_006
- **MIN()/MAX() OVER()**: STMT_007

### 2. Transaction Syntax (3 statements)
- **BEGIN TRANSACTION**: STMT_003, STMT_004, STMT_005 → PostgreSQL: BEGIN
- **COMMIT**: Compatible
- **ROLLBACK**: Compatible

### 3. SQL Server Built-in Functions
- **SCOPE_IDENTITY()**: STMT_003 → PostgreSQL: RETURNING clause or LASTVAL()
- **GETDATE()**: STMT_003, STMT_004, STMT_005 → PostgreSQL: CURRENT_TIMESTAMP or NOW()

### 4. Variable Declarations (3 statements)
- **DECLARE @Variable**: STMT_003, STMT_004, STMT_005 → PostgreSQL: DO block or function variables

### 5. Common Table Expressions (CTEs)
- All compatible with PostgreSQL, no conversion needed (syntax verified)

### 6. CASE Statements
- All compatible with PostgreSQL, no conversion needed

## Next Steps
1. ✅ **COMPLETED**: Extract all SQL statements
2. **NEXT**: Convert statements using DMS MCP tool (dms-mcp____statement_conversion_tool)
3. **PENDING**: Validate equivalency using SQL Equivalency tool
4. **PENDING**: Re-integrate converted statements into ProductRepository.cs

## Notes
- No dynamically constructed SQL found in codebase
- All SQL is defined as const string variables
- All statements properly documented with context
- Parameter naming is consistent (@ParameterName format)
- All statements are ready for DMS processing
