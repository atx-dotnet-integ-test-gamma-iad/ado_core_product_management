# DMS Conversion Failure Summary
## Date: 2026-05-05
## Migration Project: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

## DMS Error (consistent across all 7 statements):
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

## Summary
All 7 SQL statements were submitted to the DMS MCP tool (dms-mcp___statement_conversion_tool) with schema_name='dbo'.
All 7 statements failed with the same error. Manual conversion was applied with lowercase schema object names per the transformation definition rules.

## Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**: 
  - Schema object names (tables, columns, CTE names) converted to lowercase
  - SQL logic and structure preserved
  - Window functions (AVG OVER, COUNT OVER) preserved (PostgreSQL compatible)

### Statement 2: GetProductByIdAsync
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**: 
  - Schema object names converted to lowercase
  - LAG window function preserved (PostgreSQL compatible)
  - ROUND function preserved

### Statement 3: InsertProductAsync
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**: 
  - SCOPE_IDENTITY() replaced with RETURNING clause
  - GETDATE() replaced with NOW()
  - DECLARE @variable pattern restructured for PostgreSQL (separate operations)
  - BEGIN TRANSACTION/COMMIT managed by C# code (ADO.NET transaction)
  - Schema object names converted to lowercase

### Statement 4: UpdateProductAsync
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**: 
  - DECLARE @variable / SELECT INTO variable -> separate SELECT query
  - GETDATE() replaced with NOW()
  - BEGIN TRANSACTION/COMMIT managed by C# code (ADO.NET transaction)
  - Schema object names converted to lowercase

### Statement 5: DeleteProductAsync
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**: 
  - DECLARE @variable / SELECT INTO variable -> separate SELECT query
  - GETDATE() replaced with NOW()
  - CASE expression for division safety preserved (PostgreSQL compatible)
  - BEGIN TRANSACTION/COMMIT managed by C# code (ADO.NET transaction)
  - Schema object names converted to lowercase

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**: 
  - Schema object names converted to lowercase
  - RANK() and PERCENT_RANK() preserved (PostgreSQL compatible)
  - BETWEEN operator preserved

### Statement 7: GetLowStockProductsAsync
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**: 
  - Schema object names converted to lowercase
  - AVG, MIN, MAX window functions preserved (PostgreSQL compatible)
  - ROUND with CAST to NUMERIC for integer division handling
  - CASE expressions preserved
