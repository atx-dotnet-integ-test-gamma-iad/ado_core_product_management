# Migration Report: MS SQL Server to PostgreSQL

## Overview
- **Application**: AdoCore (.NET 9.0 ADO.NET Application)
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-05-05
- **DMS Project ARN**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention after DMS failure | 7 |
| Validated as equivalent by SQL Equivalency tool | 0 |
| Validated as non-equivalent | 0 |
| With equivalency validation errors | 7 |

### DMS Tool Status
All 7 statements were passed through the DMS MCP tool (dms-mcp___statement_conversion_tool). All failed with error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Manual conversion was applied for all statements using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` method, which converts all schema object names to lowercase for PostgreSQL compatibility.

### SQL Equivalency Tool Status
All 7 statement pairs were passed through the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence). All returned ERROR status:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be a tool infrastructure issue unrelated to the statements themselves.

---

## Statement Details

### Statement 1: GetAllProductsAsync
- **Method**: `GetAllProductsAsync()`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Changes**: Lowercase schema objects only; CTE and window functions (AVG, COUNT OVER) are PostgreSQL-compatible as-is

### Statement 2: GetProductByIdAsync
- **Method**: `GetProductByIdAsync(int productId)`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Changes**: Lowercase schema objects only; LAG window function is PostgreSQL-compatible as-is

### Statement 3: InsertProductAsync
- **Method**: `InsertProductAsync(Product product)`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Changes**:
  - `SCOPE_IDENTITY()` → `INSERT...RETURNING productid`
  - `GETDATE()` → `NOW()`
  - `DECLARE @variable` → Application-level variables
  - Transaction management moved to application code (NpgsqlTransaction)
  - Lowercase schema object names

### Statement 4: UpdateProductAsync
- **Method**: `UpdateProductAsync(Product product)`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Changes**:
  - `DECLARE @OldPrice`, `DECLARE @OldStock` → Separate SELECT query + C# variables
  - `GETDATE()` → `NOW()`
  - Transaction management moved to application code (NpgsqlTransaction)
  - Lowercase schema object names

### Statement 5: DeleteProductAsync
- **Method**: `DeleteProductAsync(int productId)`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Changes**:
  - `DECLARE @OldPrice`, `DECLARE @OldStock` → Separate SELECT query + C# variables
  - `GETDATE()` → `NOW()`
  - Transaction management moved to application code (NpgsqlTransaction)
  - Lowercase schema object names

### Statement 6: GetProductsByPriceRangeAsync
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Changes**: Lowercase schema objects only; RANK/PERCENT_RANK window functions are PostgreSQL-compatible as-is

### Statement 7: GetLowStockProductsAsync
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Changes**:
  - Lowercase schema objects
  - Added `CAST(stockquantity AS NUMERIC)` to avoid integer division truncation in ROUND

---

## Code Changes Summary

### Package Dependencies
| Before | After |
|--------|-------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |

### Class Replacements
| MS SQL Server Class | PostgreSQL/Npgsql Equivalent |
|---------------------|----------------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `using Microsoft.Data.SqlClient` | `using Npgsql` |

### Connection String Changes
| Parameter | Before (SQL Server) | After (PostgreSQL) |
|-----------|--------------------|--------------------|
| Server | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `true` | (removed - not applicable) |
| TrustServerCertificate | `True` | (removed - not applicable) |

### Transaction Handling Changes
- Statements 3, 4, 5 (Insert, Update, Delete) were restructured from single SQL batch transactions to application-managed transactions using `NpgsqlTransaction`
- `BeginTransactionAsync()` / `CommitAsync()` / `RollbackAsync()` pattern preserved with proper try/catch

### SQL Syntax Changes
| MS SQL Server | PostgreSQL |
|---------------|-----------|
| `SCOPE_IDENTITY()` | `RETURNING productid` |
| `GETDATE()` | `NOW()` |
| `DECLARE @variable` | C# local variables + separate queries |
| Mixed-case identifiers | Lowercase identifiers |
| `BEGIN TRANSACTION / COMMIT` (in SQL) | `BeginTransactionAsync()` / `CommitAsync()` (in code) |

---

## Files Modified

1. **sourceCode/DataAccess/ProductRepository.cs** - All SQL statements, ADO.NET classes, and transaction handling
2. **sourceCode/AdoCore.csproj** - Package references
3. **sourceCode/appsettings.json** - Connection strings
4. **sourceCode/Database/Scripts/01_InitialSetup.sql** - PostgreSQL DDL
5. **sourceCode/Scripts/01_InitialSetup.sql** - PostgreSQL DDL (simplified)

## Artifacts Generated

1. **extracted_statements.sql** - All 7 original MS SQL statements
2. **converted_statements.sql** - All 7 converted PostgreSQL statements
3. **sql_equivalency_validation_report.json** - Comprehensive equivalency report with all 7 statement pairs
4. **dms_failure_summary.md** - DMS failure documentation
5. **migration_report.md** - This report

---

## Build Status
- **Final Build**: ✅ Succeeded (0 errors, 10 warnings - all pre-existing nullable reference type warnings)
- **Compilation Target**: net9.0
- **Output**: AdoCore.dll

---

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS tool failure (could not validate automated conversion)
2. SQL Equivalency tool ERROR (could not validate semantic equivalency)

**Recommendation**: Conduct manual testing against a PostgreSQL 13 instance to verify all SQL statements produce correct results.

---

## Notes
- All warnings in the build output are pre-existing nullable reference type warnings (CS8601, CS8618, CS8600, CS8603, CS8625) that existed before the migration
- The Npgsql version was set to 8.0.6 to avoid a known high-severity vulnerability (GHSA-x9vc-6hfv-hg8c) in version 8.0.0
- Parameter syntax (@param) is compatible between SQL Server and PostgreSQL/Npgsql, so no parameter placeholder changes were needed
