# Migration Report: SQL Server to PostgreSQL

## 1. Migration Summary

| Attribute | Details |
|-----------|---------|
| **Source Database** | Microsoft SQL Server 2019 |
| **Source Database Name** | ProductManagement |
| **Target Database** | PostgreSQL 13 |
| **Target Database Name** | postgres |
| **Application** | AdoCore (.NET 9.0 console application) |
| **Migration Date** | 2026-04-09 |
| **Migration Method** | Manual conversion with DMS schema mapping guidance |

## 2. Files Modified

| File | Change Description |
|------|-------------------|
| `AdoCore.csproj` | Package reference: `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6` |
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL, ADO.NET classes replaced with Npgsql equivalents |
| `appsettings.json` | Connection strings updated from SQL Server format to PostgreSQL format |
| `README.md` | Documentation updated to reflect PostgreSQL usage |

## 3. SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total Statements Processed** | 7 |
| **Converted by DMS Tool** | 0 (DMS statement conversion tool failed for all 7) |
| **Manually Converted** | 7 (using DMS schema mapping + lowercase convention) |
| **DMS Schema Mapping Used** | Yes (successful for table/column name mappings) |

### DMS Tool Status
- **Statement Conversion Tool**: Failed for all 7 statements
  - Error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Schema Mapping Tool**: Successful - provided target schema names for Products, ProductHistory, ProductStats tables
  - All table names converted to lowercase (e.g., Products → products)
  - All column names converted to lowercase (e.g., ProductId → productid)
  - Target schema: `productmanagement_dbo`

### Conversion Details by Statement

| # | Method | Key Conversions |
|---|--------|----------------|
| 1 | `GetAllProductsAsync()` | Table/column names → lowercase |
| 2 | `GetProductByIdAsync()` | Table/column names → lowercase |
| 3 | `InsertProductAsync()` | `SCOPE_IDENTITY()` → CTE with `RETURNING`, `GETDATE()` → `NOW()`, `BEGIN TRANSACTION/COMMIT` → removed |
| 4 | `UpdateProductAsync()` | `DECLARE @var` → CTE subquery, `GETDATE()` → `NOW()`, `BEGIN TRANSACTION/COMMIT` → removed |
| 5 | `DeleteProductAsync()` | `DECLARE @var` → CTE subquery, `GETDATE()` → `NOW()`, `BEGIN TRANSACTION/COMMIT` → removed |
| 6 | `GetProductsByPriceRangeAsync()` | Table/column names → lowercase |
| 7 | `GetLowStockProductsAsync()` | Table/column names → lowercase, `CAST(stockquantity AS NUMERIC)` for integer division |

### SQL Equivalency Validation
- **Tool**: sql-equivalency___validate_sql_equivalence
- **Results**: All 7 statement pairs returned **ERROR** status
  - Error: `'uniqueID'` (service-side issue, consistent across all queries)
- **Detailed Report**: See `sql_equivalency_validation_report.json`
- **Note**: The ERROR status is from the equivalency tool itself, not from the SQL conversion. All equivalency statuses are determined solely by the tool output, not agent judgment.

## 4. ADO.NET Class Replacements

| Original (SQL Server) | Replacement (PostgreSQL) | Occurrences |
|----------------------|-------------------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 (field, method return type, instantiation) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per method with SQL) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |

## 5. Connection String Changes

### Before (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL)
```
Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=postgres
```

### Parameter Mapping
| SQL Server Parameter | PostgreSQL Parameter |
|---------------------|---------------------|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=postgres` |
| `Trusted_Connection=True` | Removed (Windows auth N/A) |
| `MultipleActiveResultSets=true` | Removed (not a PG concept) |
| `TrustServerCertificate=True` | Removed (SQL Server specific) |
| N/A | `Port=5432` (added) |
| N/A | `Username=postgres` (added) |
| N/A | `Password=postgres` (added) |

## 6. Artifact Verification

| Artifact | Status | Content |
|----------|--------|---------|
| `extracted_statements.sql` | ✅ EXISTS | 7 original MS SQL statements with headers |
| `converted_statements.sql` | ✅ EXISTS | 7 converted PostgreSQL statements with headers |
| `sql_equivalency_validation_report.json` | ✅ EXISTS | 7 statement pairs with equivalency status |
| Application Build | ✅ SUCCESS | 0 errors, 10 warnings (pre-existing nullable type warnings) |

## 7. Known Issues / Manual Review Items

### DMS Statement Conversion Failures
All 7 SQL statements failed DMS statement conversion with the error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```
This appears to be a transient service-side issue with the DMS metadata model creation. The DMS schema mapping tool worked correctly and was used to guide manual conversions.

### SQL Equivalency Validation Errors
All 7 statement pairs returned ERROR from the SQL Equivalency validation tool:
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```
This appears to be a consistent service-side issue with the equivalency tool. Manual review of the conversions is recommended.

### Statements Requiring Special Attention
1. **Statement 3 (InsertProductAsync)**: Restructured from T-SQL `SCOPE_IDENTITY()` to PostgreSQL CTE with `INSERT...RETURNING`. The CTE approach chains INSERT, history logging, and stats update in a single atomic query.

2. **Statement 4 (UpdateProductAsync)**: Restructured from T-SQL `DECLARE @var` pattern to PostgreSQL CTE approach. Old values are captured via CTE subquery instead of T-SQL variables.

3. **Statement 5 (DeleteProductAsync)**: Similar restructuring as Statement 4, using CTE for old value capture before delete.

4. **Statement 7 (GetLowStockProductsAsync)**: Added `CAST(stockquantity AS NUMERIC)` to prevent integer division truncation in PostgreSQL (SQL Server implicitly handles mixed arithmetic differently).

## 8. Build Verification

```
Build succeeded.
    10 Warning(s)
    0 Error(s)
```

All 10 warnings are pre-existing nullable reference type warnings (CS8618, CS8601, CS8600, CS8603, CS8625) that existed before the migration and are not related to the SQL Server → PostgreSQL conversion.
