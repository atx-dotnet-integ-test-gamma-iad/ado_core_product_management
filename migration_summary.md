# SQL Server to PostgreSQL Migration - DMS Conversion Summary

## Migration Overview
- **Source**: Microsoft SQL Server 2019 (ProductManagement database)
- **Target**: PostgreSQL 13
- **Tool Used**: AWS DMS MCP (arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4)
- **Migration Date**: 2026-05-09

## DMS Tool Status
**ALL DMS conversion attempts FAILED** with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

The DMS tool was unable to create the metadata model required for conversion. All 7 SQL statements were submitted to the DMS tool, and all failed. Manual conversion was applied using lowercase schema mapping rules per the transformation instructions.

## Statement Conversion Summary

| # | Method | Source Location | Type | Key Changes |
|---|--------|----------------|------|-------------|
| 1 | GetAllProductsAsync | ProductRepository.cs:40 | SELECT + CTE | Lowercase identifiers |
| 2 | GetProductByIdAsync | ProductRepository.cs:75 | SELECT + CTE + LAG | Lowercase identifiers |
| 3 | InsertProductAsync | ProductRepository.cs:105 | Transaction (INSERT) | SCOPE_IDENTITY() → RETURNING; GETDATE() → NOW(); Transaction split to C# managed |
| 4 | UpdateProductAsync | ProductRepository.cs:135 | Transaction (UPDATE) | GETDATE() → NOW(); Variables to C# vars; Transaction split to C# managed |
| 5 | DeleteProductAsync | ProductRepository.cs:170 | Transaction (DELETE) | GETDATE() → NOW(); Variables to C# vars; Transaction split to C# managed |
| 6 | GetProductsByPriceRangeAsync | ProductRepository.cs:200 | SELECT + CTE + RANK | Lowercase identifiers |
| 7 | GetLowStockProductsAsync | ProductRepository.cs:230 | SELECT + CTE + AVG | Lowercase identifiers; Added CAST for integer division |

## SQL Equivalency Validation Summary
**ALL equivalency validations returned ERROR** from the SQL Equivalency tool:
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

The SQL Equivalency tool experienced an internal error ('uniqueID') for all 7 statement pairs. This is an infrastructure issue with the tool, not a conversion problem.

## Conversion Rules Applied (Manual - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)

### Schema Object Naming
- All table names converted to lowercase (Products → products, ProductHistory → producthistory, ProductStats → productstats)
- All column names converted to lowercase (ProductId → productid, StockQuantity → stockquantity, etc.)
- All CTE aliases converted to lowercase (ProductStats → productstats, RankedProducts → rankedproducts, etc.)

### SQL Syntax Conversions
- `SCOPE_IDENTITY()` → `RETURNING productid` clause on INSERT
- `GETDATE()` → `NOW()`
- `DECLARE @var TYPE` → C# variable management (since PostgreSQL inline SQL doesn't support T-SQL variable declarations)
- `SET @var = SCOPE_IDENTITY()` → `RETURNING productid INTO` (handled via C# ExecuteScalarAsync)
- `BEGIN TRANSACTION / COMMIT` → C# managed NpgsqlTransaction (BeginTransactionAsync/CommitAsync/RollbackAsync)
- Integer division `StockQuantity / AvgStock` → `CAST(stockquantity AS DECIMAL) / avgstock` for proper decimal division

### ADO.NET Class Replacements
- `Microsoft.Data.SqlClient` → `Npgsql`
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`
- `SqlParameter` → `NpgsqlParameter`
- Parameter syntax `@ParamName` retained (Npgsql supports this)

### Connection String Conversion
- `Server=localhost` → `Host=localhost`
- `Database=ProductManagement` → `Database=productmanagement`
- `Trusted_Connection=True` → `Username=postgres;Password=postgres`
- Removed `MultipleActiveResultSets=true` (not applicable to PostgreSQL)
- Removed `TrustServerCertificate=True` (not applicable to PostgreSQL)

### Package Reference Updates
- Removed: `Microsoft.Data.SqlClient` Version 5.1.4
- Added: `Npgsql` Version 8.0.1

## Final Statistics
- Total SQL statements processed: 7
- Statements successfully converted by DMS: 0 (all failed)
- Statements manually converted: 7
- Statements validated as equivalent: 0
- Statements validated as non-equivalent: 0
- Statements with equivalency validation errors: 7 (tool infrastructure error)
