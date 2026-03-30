# DMS Conversion Failure Summary
## Date: 2026-03-30
## Migration Project: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

## Summary
All 7 SQL statements from ProductRepository.cs were submitted to the DMS MCP tool for conversion.
All 7 attempts failed with the same error. Manual conversion was applied using lowercase schema object naming convention.

## DMS Error (consistent across all 7 statements)
```
Status: error
Error: "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}"
```

## Statement-by-Statement DMS Attempts

### Statement 1: GetAllProductsAsync
- **DMS Attempt Timestamp**: 2026-03-30T22:18:59
- **DMS Status**: error
- **DMS Error**: Metadata model conversion failed: Metadata model conversion did not complete after 15 attempts
- **Manual Conversion**: Applied lowercase schema object names; SQL syntax compatible with PostgreSQL

### Statement 2: GetProductByIdAsync  
- **DMS Attempt Timestamp**: 2026-03-30T22:30:11
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
- **Manual Conversion**: Applied lowercase schema object names; LAG window function compatible with PostgreSQL

### Statement 3: InsertProductAsync
- **DMS Attempt Timestamp**: 2026-03-30T22:32:57
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
- **Manual Conversion**: SCOPE_IDENTITY() -> lastval(), GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN, lowercase schema objects

### Statement 4: UpdateProductAsync
- **DMS Attempt Timestamp**: 2026-03-30T22:35:41
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
- **Manual Conversion**: DECLARE/@var pattern -> inline approach, GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN, lowercase schema objects

### Statement 5: DeleteProductAsync
- **DMS Attempt Timestamp**: 2026-03-30T22:38:33
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
- **Manual Conversion**: DECLARE/@var pattern -> inline approach, GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN, lowercase schema objects

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Attempt Timestamp**: 2026-03-30T22:41:17
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
- **Manual Conversion**: Applied lowercase schema object names; RANK/PERCENT_RANK window functions compatible with PostgreSQL

### Statement 7: GetLowStockProductsAsync
- **DMS Attempt Timestamp**: 2026-03-30T22:44:03
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
- **Manual Conversion**: Applied lowercase schema object names; added ::numeric cast for integer division; AVG/MIN/MAX window functions compatible

## Conversion Rules Applied (Manual)
1. All schema object names converted to lowercase (tables, columns, aliases, CTE names)
2. SCOPE_IDENTITY() -> lastval()
3. GETDATE() -> NOW()
4. BEGIN TRANSACTION -> BEGIN
5. DECLARE @var / SET @var pattern -> replaced with subqueries or lastval()
6. Integer division: added ::numeric cast where needed for PostgreSQL
7. Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX OVER) - compatible, only names lowercased
8. ROUND function - compatible, only names lowercased
9. CASE/WHEN - compatible, only names lowercased
10. Parameter syntax (@param) - preserved as Npgsql supports @param style
