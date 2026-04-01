# DMS Conversion Failure Summary

## Overview
All 7 SQL statements from ProductRepository.cs failed DMS conversion. The DMS tool consistently returned errors related to metadata model creation timeouts.

## DMS Error Details
- **Error**: Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
- **Migration Project ARN**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Schema**: dbo
- **Region**: us-east-1

## Manual Conversion Applied
All 7 statements were manually converted applying the following rules per the transformation definition:
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- All schema object names (tables, columns, views, aliases) converted to lowercase
- SQL Server functions converted to PostgreSQL equivalents:
  - `SCOPE_IDENTITY()` → `lastval()`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - `DECLARE @var` → Removed (replaced with subqueries)
  - `ROUND()` with integer division → Added `::numeric` cast where needed

## Statement-by-Statement DMS Attempt Log

### Statement 1: GetAllProductsAsync
- **DMS Attempt Timestamp**: 2026-04-01T02:22:55
- **DMS Status**: error
- **DMS Error**: Metadata model conversion failed (timeout after 15 attempts)
- **Manual Changes**: Lowercase all table/column names

### Statement 2: GetProductByIdAsync
- **DMS Attempt Timestamp**: 2026-04-01T02:38:51
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed (timeout after 15 attempts)
- **Manual Changes**: Lowercase all table/column names

### Statement 3: InsertProductAsync
- **DMS Attempt Timestamp**: 2026-04-01T02:41:35
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed (timeout after 15 attempts)
- **Manual Changes**: Lowercase, SCOPE_IDENTITY() → lastval(), GETDATE() → NOW(), removed DECLARE, BEGIN TRANSACTION → BEGIN

### Statement 4: UpdateProductAsync
- **DMS Attempt Timestamp**: 2026-04-01T02:44:18
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed (timeout after 15 attempts)
- **Manual Changes**: Lowercase, GETDATE() → NOW(), removed DECLARE variables, replaced variable usage with subqueries, BEGIN TRANSACTION → BEGIN

### Statement 5: DeleteProductAsync
- **DMS Attempt Timestamp**: 2026-04-01T02:47:00
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed (timeout after 15 attempts)
- **Manual Changes**: Lowercase, GETDATE() → NOW(), removed DECLARE variables, replaced variable usage with subqueries, BEGIN TRANSACTION → BEGIN

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Attempt Timestamp**: 2026-04-01T02:49:43
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed (timeout after 15 attempts)
- **Manual Changes**: Lowercase all table/column names

### Statement 7: GetLowStockProductsAsync
- **DMS Attempt Timestamp**: 2026-04-01T02:52:26
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed (timeout after 15 attempts)
- **Manual Changes**: Lowercase all table/column names, added ::numeric cast for ROUND integer division

## SQL Equivalency Validation
All 7 statement pairs were validated through the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence).
All 7 returned ERROR status with error: "'uniqueID'"
See sql_equivalency_validation_report.json for full details.
