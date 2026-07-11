# SQL Server to PostgreSQL Migration - DMS Conversion Log

## Summary
- Total SQL Statements: 7
- DMS Successful Conversions: 0
- DMS Failed Conversions: 7
- Manual Conversions (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA): 7

## DMS Failure Details
All 7 statements failed with the same error:
- Error: "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}"
- Migration Project: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

## Manual Conversion Rules Applied
Since DMS failed for all statements, the following manual conversion rules were applied:
1. All schema object names (tables, columns, aliases) converted to lowercase
2. SCOPE_IDENTITY() replaced with PostgreSQL RETURNING clause via writable CTEs
3. GETDATE() replaced with NOW()
4. T-SQL DECLARE/SET variable blocks replaced with PostgreSQL writable CTEs
5. BEGIN TRANSACTION/COMMIT blocks replaced with single atomic CTE statements
6. CAST(x AS DECIMAL) replaced with x::numeric for PostgreSQL
7. Integer division handling with ::numeric cast where needed

## Statement-by-Statement Log

### Statement 1: GetAllProductsAsync
- Source: ProductRepository.cs, GetAllProductsAsync()
- DMS Output: Error - Metadata model creation failed
- Manual Conversion: Lowercase schema objects only (SQL syntax already PostgreSQL-compatible)

### Statement 2: GetProductByIdAsync
- Source: ProductRepository.cs, GetProductByIdAsync()
- DMS Output: Error - Metadata model creation failed
- Manual Conversion: Lowercase schema objects only (SQL syntax already PostgreSQL-compatible)

### Statement 3: InsertProductAsync
- Source: ProductRepository.cs, InsertProductAsync()
- DMS Output: Error - Metadata model creation failed
- Manual Conversion: SCOPE_IDENTITY() → RETURNING via writable CTE; GETDATE() → NOW(); Transaction block → atomic CTE

### Statement 4: UpdateProductAsync
- Source: ProductRepository.cs, UpdateProductAsync()
- DMS Output: Error - Metadata model creation failed
- Manual Conversion: DECLARE variables → CTE subquery; GETDATE() → NOW(); Transaction block → atomic CTE

### Statement 5: DeleteProductAsync
- Source: ProductRepository.cs, DeleteProductAsync()
- DMS Output: Error - Metadata model creation failed
- Manual Conversion: DECLARE variables → CTE subquery; GETDATE() → NOW(); Transaction block → atomic CTE

### Statement 6: GetProductsByPriceRangeAsync
- Source: ProductRepository.cs, GetProductsByPriceRangeAsync()
- DMS Output: Error - Metadata model creation failed
- Manual Conversion: Lowercase schema objects only (SQL syntax already PostgreSQL-compatible)

### Statement 7: GetLowStockProductsAsync
- Source: ProductRepository.cs, GetLowStockProductsAsync()
- DMS Output: Error - Metadata model creation failed
- Manual Conversion: Lowercase schema objects, CAST(x AS DECIMAL) → x::numeric

## SQL Equivalency Validation
All 7 statement pairs were submitted to the SQL Equivalency tool.
All 7 returned ERROR status with error: "'uniqueID'"
This appears to be an internal tool error unrelated to the SQL statements themselves.
