# Migration Report: SQL Server to PostgreSQL

## Summary
This report documents the complete migration of the ADO.NET Core application from Microsoft SQL Server to PostgreSQL.
The migration was executed as part of a systematic transformation plan with 6 steps.

## SQL Statement Conversion Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements converted by DMS Tool | 0 |
| Statements requiring manual conversion | 7 |
| Statements validated as equivalent (SQL Equivalency tool) | 0 |
| Statements validated as non-equivalent (SQL Equivalency tool) | 0 |
| Statements with equivalency validation errors | 7 |

### DMS Tool Status
- **DMS statement_conversion_tool**: FAILED for all 7 statements across 2 rounds (16 total attempts)
  - Error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
  - The error occurs at the `create_metadata_model` workflow step
  - Migration Project: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Manual Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
  - Applied lowercase schema object names per PostgreSQL conventions
  - Tables: `Products` → `products`, `ProductHistory` → `producthistory`, `ProductStats` → `productstats`
  - All columns lowercased: `ProductId` → `productid`, `Price` → `price`, etc.
  - SQL Server functions converted: `SCOPE_IDENTITY()` → `INSERT...RETURNING`, `GETDATE()` → `NOW()`
  - Transaction blocks restructured to CTE-based patterns

### SQL Equivalency Tool Status
- **SQL Equivalency tool**: Returned ERROR for all 7 statement pairs
  - Error: `'uniqueID'` (systematic tool error across all pairs)
  - Each pair was individually submitted and independently validated
  - No agent judgment was used to determine equivalency
  - All equivalency statuses recorded as ERROR per tool output

### Detailed Statement Conversion Summary

| # | Method | Original SQL Server Features | PostgreSQL Conversion | Conversion Method |
|---|--------|-----|-----|-----|
| 1 | GetAllProductsAsync | CTE, AVG/COUNT OVER(), INNER JOIN, CASE, ROUND | Lowercase identifiers | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| 2 | GetProductByIdAsync | CTE, LAG OVER(), LEFT JOIN, CASE, ROUND | Lowercase identifiers | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| 3 | InsertProductAsync | DECLARE, BEGIN TRANSACTION, SCOPE_IDENTITY(), GETDATE() | CTE INSERT...RETURNING pattern, NOW() | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| 4 | UpdateProductAsync | DECLARE, BEGIN TRANSACTION, SELECT INTO vars, GETDATE() | CTE old_values capture pattern, NOW() | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| 5 | DeleteProductAsync | DECLARE, BEGIN TRANSACTION, SELECT INTO vars, GETDATE(), CASE | CTE old_values capture pattern, NOW() | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| 6 | GetProductsByPriceRangeAsync | CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE | Lowercase identifiers | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| 7 | GetLowStockProductsAsync | CTE, AVG/MIN/MAX OVER(), CASE, ROUND | Lowercase identifiers, added ::numeric cast | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |

### Statements Requiring Manual Review
All 7 statements require manual review because:
1. DMS tool was unavailable (metadata model creation failure) - manual conversions need validation
2. SQL Equivalency tool returned errors for all pairs - equivalency could not be verified automatically

## Files Modified

### Source Code
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | 7 SQL statements converted to PostgreSQL syntax, ADO.NET classes replaced (SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader), column name references lowercased in MapProductFromReader |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | Connection strings updated to PostgreSQL format (Host=, Username=, Password=) |

### Configuration & Scripts
| File | Changes |
|------|---------|
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL DDL (GENERATED ALWAYS AS IDENTITY, NUMERIC, TIMESTAMP WITHOUT TIME ZONE, plpgsql functions) |
| `Database/Scripts/01_InitialSetup.sql` | Full conversion: tables, triggers (plpgsql), stored functions (plpgsql), indexes, sample data |
| `README.md` | Updated references to PostgreSQL |

### Migration Artifacts
| File | Description | Status |
|------|-------------|--------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements | ✅ Complete (7/7) |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements | ✅ Complete (7/7) |
| `sql_equivalency_validation_report.json` | Equivalency validation results for all 7 statement pairs | ✅ Complete (7/7 entries) |
| `dms_failure_summary.md` | Detailed DMS failure documentation for all attempts | ✅ Complete |
| `migration_report.md` | This comprehensive migration report | ✅ Complete |

## Package Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.6 |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| Certificate | `TrustServerCertificate=True` | Removed |

## ADO.NET Class Replacement Summary

| SQL Server Type | PostgreSQL (Npgsql) Type |
|-----------------|--------------------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` (if used) |
| `BeginTransaction()` | `BeginTransactionAsync()` |

## SQL Syntax Conversion Rules Applied

| SQL Server | PostgreSQL |
|-----------|------------|
| `SCOPE_IDENTITY()` | `INSERT...RETURNING productid` (via CTE) |
| `GETDATE()` | `NOW()` |
| `DECLARE @var TYPE; SET @var = ...` | CTE with `old_values AS (SELECT ...)` |
| `BEGIN TRANSACTION...COMMIT` | CTE-based single statement or Npgsql transaction |
| `DECIMAL(18,2)` | `NUMERIC(18,2)` |
| `INT IDENTITY(1,1)` | `INTEGER GENERATED ALWAYS AS IDENTITY` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `DATETIME` | `TIMESTAMP WITHOUT TIME ZONE` |
| `BIT` | `BOOLEAN` |
| `StockQuantity / AvgStock` (integer division) | `stockquantity::numeric / avgstock` |

## Build Status
- **Final Build**: ✅ SUCCESS (0 errors, 10 warnings)
- **Warnings**: All pre-existing nullable reference warnings (CS8600, CS8601, CS8603, CS8618, CS8625) - not related to migration

## Known Issues & Notes
1. **DMS Tool Unavailable**: DMS statement_conversion_tool failed with metadata model creation error across all 16 attempts (2 rounds × ~8 attempts). All conversions were done manually applying lowercase schema naming conventions.
2. **SQL Equivalency Tool Error**: SQL Equivalency tool returned ERROR with `'uniqueID'` for all 7 statement pairs. This appears to be a systematic tool infrastructure error, not related to conversion quality. Equivalency could not be verified automatically.
3. **Npgsql Version**: Version 8.0.6 was used to address known security vulnerability GHSA-x9vc-6hfv-hg8c.
4. **PostgreSQL Naming**: All schema objects (tables, columns) use lowercase per PostgreSQL conventions.
5. **CTE Pattern**: Transaction blocks with DECLARE/SET variables were restructured as PostgreSQL CTEs (WITH ... AS) to achieve the same functionality in a single statement.
