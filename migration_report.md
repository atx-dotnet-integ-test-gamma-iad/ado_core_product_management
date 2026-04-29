# Migration Report: MS SQL Server to PostgreSQL

## 1. Migration Summary

| Property | Value |
|---|---|
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Application** | AdoCore (.NET 9.0) |
| **Application Type** | ADO.NET Console Application |
| **Migration Date** | 2026-04-29 |
| **DMS Migration Project ARN** | arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4 |

## 2. Files Modified

| File | Changes |
|---|---|
| `DataAccess/ProductRepository.cs` | Replaced all 7 SQL statements with PostgreSQL equivalents; replaced all ADO.NET classes (SqlConnection → NpgsqlConnection, SqlCommand → NpgsqlCommand, SqlDataReader → NpgsqlDataReader); refactored transaction-based methods from single multi-statement SQL blocks to programmatic transactions with separate commands |
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.6` |
| `appsettings.json` | Updated connection strings from SQL Server format to PostgreSQL format |

## 3. SQL Statement Processing Summary

| Metric | Count |
|---|---|
| **Total SQL statements processed** | 7 |
| **Statements converted by DMS MCP tool** | 0 |
| **Statements requiring manual conversion** | 7 |
| **DMS failure reason** | Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'} |

## 4. SQL Equivalency Validation Results

| Metric | Count |
|---|---|
| **Statements validated** | 7 |
| **Equivalent** | 0 |
| **Non-equivalent** | 0 |
| **Errors (tool infrastructure issue)** | 7 |
| **Equivalency tool error** | 'uniqueID' |

**Note:** All 7 equivalency validations returned ERROR status due to a tool infrastructure issue. The error was consistent across all statements.

## 5. Package Dependency Changes

| Before | After |
|---|---|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.6` |
| `Microsoft.Extensions.Configuration 8.0.0` | `Microsoft.Extensions.Configuration 8.0.0` (unchanged) |
| `Microsoft.Extensions.Configuration.Json 8.0.0` | `Microsoft.Extensions.Configuration.Json 8.0.0` (unchanged) |
| `Microsoft.Extensions.DependencyInjection 8.0.0` | `Microsoft.Extensions.DependencyInjection 8.0.0` (unchanged) |

## 6. Class Replacements

| SQL Server Class | PostgreSQL (Npgsql) Class |
|---|---|
| `Microsoft.Data.SqlClient` (namespace) | `Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` (via AddWithValue) |

## 7. Connection String Updates

### DevConnection
- **Before:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After:** `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`

### ProdConnection
- **Before:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After:** `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`

### Parameter Mapping
| SQL Server | PostgreSQL | Action |
|---|---|---|
| `Server=` | `Host=` | Replaced |
| `Database=` | `Database=` | Kept |
| `Trusted_Connection=True` | - | Removed |
| `MultipleActiveResultSets=true` | - | Removed (not applicable) |
| `TrustServerCertificate=True` | - | Removed |
| - | `Username=postgres` | Added (placeholder) |
| - | `Password=postgres` | Added (placeholder) |

## 8. Detailed SQL Statement Conversion Listing

### Statement 1: GetAllProductsAsync
- **Method:** `GetAllProductsAsync()`
- **Type:** CTE with AVG/COUNT window functions, CASE, ROUND, INNER JOIN
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool infrastructure issue)
- **Key Changes:** Table/column names to lowercase

### Statement 2: GetProductByIdAsync
- **Method:** `GetProductByIdAsync(int productId)`
- **Type:** CTE with LAG window functions, CASE, ROUND, LEFT JOIN
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool infrastructure issue)
- **Key Changes:** Table/column names to lowercase

### Statement 3: InsertProductAsync
- **Method:** `InsertProductAsync(Product product)`
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool infrastructure issue)
- **Key Changes:**
  - `SCOPE_IDENTITY()` → `RETURNING productid` clause
  - `GETDATE()` → `NOW()`
  - `DECLARE @NewProductId INT` → Removed (using C# variables with RETURNING)
  - `BEGIN TRANSACTION/COMMIT` → Programmatic transaction via `BeginTransactionAsync/CommitAsync`
  - Single multi-statement SQL → Multiple separate NpgsqlCommand calls within programmatic transaction

### Statement 4: UpdateProductAsync
- **Method:** `UpdateProductAsync(Product product)`
- **Type:** Transaction block with DECLARE variables, SELECT INTO vars, UPDATE, GETDATE()
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool infrastructure issue)
- **Key Changes:**
  - `DECLARE @OldPrice/@OldStock` → Removed (using C# variables with separate SELECT)
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → Programmatic transaction
  - Single multi-statement SQL → Multiple separate NpgsqlCommand calls

### Statement 5: DeleteProductAsync
- **Method:** `DeleteProductAsync(int productId)`
- **Type:** Transaction block with DECLARE variables, CASE, GETDATE()
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool infrastructure issue)
- **Key Changes:**
  - `DECLARE @OldPrice/@OldStock` → Removed (using C# variables)
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → Programmatic transaction
  - Single multi-statement SQL → Multiple separate NpgsqlCommand calls

### Statement 6: GetProductsByPriceRangeAsync
- **Method:** `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type:** CTE with RANK(), PERCENT_RANK() window functions, BETWEEN, CASE
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool infrastructure issue)
- **Key Changes:** Table/column names to lowercase

### Statement 7: GetLowStockProductsAsync
- **Method:** `GetLowStockProductsAsync(int threshold)`
- **Type:** CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool infrastructure issue)
- **Key Changes:** Table/column names to lowercase, added `::numeric` cast for integer division in ROUND

## 9. Statements Requiring Manual Review

All 7 statements require manual review because:
1. **DMS conversion was unavailable** - All statements were manually converted due to DMS infrastructure failure
2. **Equivalency could not be validated** - All equivalency checks returned ERROR due to tool infrastructure issue

**Recommended Actions:**
- Verify each converted SQL statement against the PostgreSQL database schema
- Run integration tests with actual PostgreSQL database
- Validate that RETURNING clause works correctly for InsertProductAsync
- Verify window functions (LAG, RANK, PERCENT_RANK, AVG OVER, etc.) produce identical results
- Test transaction handling (BEGIN/COMMIT/ROLLBACK) under error conditions

## 10. Build Status

| Step | Build Status |
|---|---|
| Step 3 (Code changes) | Failed (expected - Npgsql package not yet added) |
| Step 4 (Dependencies + connection strings) | **Success** |
| Final build | **Success** (0 errors, 10 warnings - all pre-existing nullable reference warnings) |

## 11. Transformation Artifacts

| Artifact | Location | Description |
|---|---|---|
| `extracted_statements.sql` | sourceCode/ | All 7 original MS SQL statements |
| `converted_statements.sql` | sourceCode/ | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | sourceCode/ | Comprehensive equivalency report |
| `dms_failure_log.md` | sourceCode/ | DMS failure documentation |
| `migration_report.md` | sourceCode/ | This report |
