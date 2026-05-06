# DMS Conversion Failure Summary Log
# Date: 2026-05-06
# Project: AdoCore - MS SQL Server to PostgreSQL Migration

## DMS Tool Error Details

All 7 SQL statements failed DMS conversion with the same error:
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Timestamp Range**: 2026-05-06T18:07:28 to 2026-05-06T18:08:58
- **Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Database**: ProductManagement
- **Schema**: dbo
- **Region**: us-east-1
- **Server**: 172.31.83.165

## Manual Conversion Applied

Since DMS failed for all statements, manual conversion was applied with:
- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- All schema object names (tables, columns, aliases) converted to lowercase
- SQL Server-specific functions converted to PostgreSQL equivalents:
  - SCOPE_IDENTITY() -> lastval()
  - GETDATE() -> NOW()
  - BEGIN TRANSACTION -> BEGIN
  - DECLARE @var -> Removed (handled via subqueries or application logic)
  - ROUND() -> ROUND() with CAST for integer division cases

## Statement Conversion Summary

| # | Method | Source Location | DMS Status | Manual Conversion |
|---|--------|----------------|------------|-------------------|
| 1 | GetAllProductsAsync | ProductRepository.cs | FAILED | Applied lowercase + compatible syntax |
| 2 | GetProductByIdAsync | ProductRepository.cs | FAILED | Applied lowercase + compatible syntax |
| 3 | InsertProductAsync | ProductRepository.cs | FAILED | Applied lowercase + RETURNING/lastval/NOW |
| 4 | UpdateProductAsync | ProductRepository.cs | FAILED | Applied lowercase + NOW/subqueries |
| 5 | DeleteProductAsync | ProductRepository.cs | FAILED | Applied lowercase + NOW/subqueries |
| 6 | GetProductsByPriceRangeAsync | ProductRepository.cs | FAILED | Applied lowercase + compatible syntax |
| 7 | GetLowStockProductsAsync | ProductRepository.cs | FAILED | Applied lowercase + CAST for division |
