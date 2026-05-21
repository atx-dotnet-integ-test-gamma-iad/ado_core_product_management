# SQL Server to PostgreSQL Migration Report

## Summary
- **Project**: AdoCore (.NET 9.0 ADO.NET Application)
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-05-21

## Statistics
- **Total SQL statements processed**: 7
- **Statements successfully converted by DMS MCP tool**: 0
- **Statements requiring manual intervention after DMS tool failure**: 7
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 7

## DMS Tool Failure
All 7 statements failed DMS conversion with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Manual conversion was applied using lowercase schema object names per the transformation rules (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

## SQL Equivalency Validation
All 7 statement pairs returned ERROR from the SQL Equivalency tool:
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

## Key Conversion Changes

### SQL Syntax Conversions
| MS SQL Server | PostgreSQL |
|---|---|
| `SCOPE_IDENTITY()` | `INSERT ... RETURNING productid` (writable CTE) |
| `GETDATE()` | `NOW()` |
| `DECLARE @variable` + `BEGIN TRANSACTION` | Writable CTEs with RETURNING |
| `NVARCHAR` | `VARCHAR` |
| `DECIMAL(18,2)` | `NUMERIC(18,2)` |
| `IDENTITY(1,1)` | `SERIAL` |
| `DATETIME` | `TIMESTAMP` |

### Schema Object Name Changes
All table and column names converted to lowercase for PostgreSQL compatibility:
- `Products` → `products`
- `ProductId` → `productid`
- `StockQuantity` → `stockquantity`
- `CreatedDate` → `createddate`
- `ModifiedDate` → `modifieddate`
- `ProductHistory` → `producthistory`
- `ProductStats` → `productstats`

### Code Changes
| Component | Before | After |
|---|---|---|
| Package | `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.1` |
| Import | `using Microsoft.Data.SqlClient` | `using Npgsql` |
| Connection | `SqlConnection` | `NpgsqlConnection` |
| Command | `SqlCommand` | `NpgsqlCommand` |
| Reader | `SqlDataReader` | `NpgsqlDataReader` |
| Connection String | `Server=localhost;Database=...;Trusted_Connection=True;...` | `Host=localhost;Database=...;Username=postgres;Password=postgres` |

### Connection String Mapping
| SQL Server Parameter | PostgreSQL Parameter |
|---|---|
| `Server=` | `Host=` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | (removed - not applicable) |
| `TrustServerCertificate=True` | (removed - not applicable) |

## Files Modified
1. `sourceCode/DataAccess/ProductRepository.cs` - All SQL statements converted, ADO.NET classes replaced with Npgsql equivalents
2. `sourceCode/AdoCore.csproj` - Package reference updated from Microsoft.Data.SqlClient to Npgsql
3. `sourceCode/appsettings.json` - Connection strings updated to PostgreSQL format

## Artifacts Generated
1. `sourceCode/extracted_statements.sql` - Catalog of all original MS SQL statements
2. `sourceCode/converted_statements.sql` - Catalog of all converted PostgreSQL statements
3. `sourceCode/sql_equivalency_validation_report.json` - Comprehensive equivalency validation report
4. `sourceCode/migration_report.md` - This migration report

## Statements Requiring Manual Review
All 7 statements require manual review due to:
1. DMS tool failure preventing automated conversion
2. SQL Equivalency tool returning errors for all validation attempts

### Critical Conversions (Structural Changes)
- **Statement 3 (InsertProductAsync)**: T-SQL transaction with SCOPE_IDENTITY() → PostgreSQL writable CTE with RETURNING
- **Statement 4 (UpdateProductAsync)**: T-SQL transaction with DECLARE variables → PostgreSQL writable CTE
- **Statement 5 (DeleteProductAsync)**: T-SQL transaction with DECLARE variables → PostgreSQL writable CTE

### Straightforward Conversions (Case + Syntax Only)
- **Statement 1 (GetAllProductsAsync)**: CTE with window functions - lowercase only
- **Statement 2 (GetProductByIdAsync)**: CTE with LAG - lowercase only
- **Statement 6 (GetProductsByPriceRangeAsync)**: CTE with RANK/PERCENT_RANK - lowercase only
- **Statement 7 (GetLowStockProductsAsync)**: CTE with AVG/MIN/MAX OVER - lowercase + cast for ROUND
