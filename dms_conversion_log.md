# DMS Conversion Failure Log

## Summary
All 7 SQL statements were passed through the DMS MCP tool (dms-mcp___statement_conversion_tool).
All 7 statements failed with the same error.

## DMS Error Details
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Status**: error
- **Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Database**: ProductManagement
- **Schema**: dbo
- **Region**: us-east-1
- **Server**: 172.31.83.165

## Manual Conversion Applied
Since DMS failed for all statements, manual conversion was applied with the following rules:
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- All schema object names (tables, columns, aliases) converted to lowercase
- T-SQL SCOPE_IDENTITY() replaced with PostgreSQL RETURNING clause via writable CTEs
- T-SQL GETDATE() replaced with PostgreSQL NOW()
- T-SQL DECLARE/SET variable patterns replaced with writable CTEs
- T-SQL BEGIN TRANSACTION/COMMIT replaced with writable CTE (atomicity maintained within single statement)
- Integer division in ROUND() given explicit ::numeric cast for PostgreSQL

## Statements Processed

### Statement 1: GetAllProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **DMS Timestamp**: 2026-05-08T23:26:41.420239
- **DMS Status**: error
- **Conversion**: Direct lowercase mapping, SQL syntax compatible between T-SQL and PostgreSQL

### Statement 2: GetProductByIdAsync
- **Source File**: DataAccess/ProductRepository.cs
- **DMS Timestamp**: 2026-05-08T23:26:45.037590
- **DMS Status**: error
- **Conversion**: Direct lowercase mapping, LAG() window function compatible

### Statement 3: InsertProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **DMS Timestamp**: 2026-05-08T23:26:48.574804
- **DMS Status**: error
- **Conversion**: Major restructure - T-SQL DECLARE/SCOPE_IDENTITY/BEGIN TRANSACTION converted to writable CTE with RETURNING

### Statement 4: UpdateProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **DMS Timestamp**: 2026-05-08T23:26:52.130225
- **DMS Status**: error
- **Conversion**: Major restructure - T-SQL DECLARE/BEGIN TRANSACTION converted to writable CTE

### Statement 5: DeleteProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **DMS Timestamp**: 2026-05-08T23:26:55.878718
- **DMS Status**: error
- **Conversion**: Major restructure - T-SQL DECLARE/BEGIN TRANSACTION converted to writable CTE

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: DataAccess/ProductRepository.cs
- **DMS Timestamp**: 2026-05-08T23:27:12.526588
- **DMS Status**: error
- **Conversion**: Direct lowercase mapping, RANK()/PERCENT_RANK() window functions compatible

### Statement 7: GetLowStockProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **DMS Timestamp**: 2026-05-08T23:27:16.137035
- **DMS Status**: error
- **Conversion**: Lowercase mapping + added ::numeric cast for integer division in ROUND()

## SQL Equivalency Validation
All 7 statement pairs were submitted to the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence).
All 7 returned ERROR status with error "'uniqueID'" - this is a tool-side error, not a statement issue.
