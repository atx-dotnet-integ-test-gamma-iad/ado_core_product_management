# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary
- **Project**: AdoCore - .NET ADO Application
- **Source Database**: Microsoft SQL Server (ProductManagement)
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-05-04
- **Migration Status**: COMPLETED

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL statements processed** | 7 |
| **Successfully converted by DMS** | 0 |
| **Manually converted (DMS failure)** | 7 |
| **Validated as equivalent** | 0 |
| **Validated as non-equivalent** | 0 |
| **Equivalency validation errors** | 7 |

### DMS Tool Status
- **DMS Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **DMS Error**: All 7 statements failed with: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Total DMS Attempts**: 8 (7 individual statements + 1 retry with extended polling)
- **Manual Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### SQL Equivalency Tool Status
- All 7 statement pairs were validated through the `sql-equivalency___validate_sql_equivalence` tool
- All 7 returned `ERROR` status with error: `'uniqueID'`
- The ERROR status is from the tool itself, not agent judgment

---

## Statement-by-Statement Details

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, window functions (AVG OVER, COUNT OVER), INNER JOIN
- **DMS**: FAILED
- **Manual Conversion**: Lowercase schema objects
- **Equivalency**: ERROR

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG window function, LEFT JOIN
- **Parameters**: @ProductId
- **DMS**: FAILED
- **Manual Conversion**: Lowercase schema objects
- **Equivalency**: ERROR

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), UPDATE
- **Parameters**: @Name, @Description, @Price, @StockQuantity
- **DMS**: FAILED
- **Manual Conversion**: SCOPE_IDENTITY() → INSERT...RETURNING in writable CTE, GETDATE() → NOW()
- **Equivalency**: ERROR

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT, UPDATE, INSERT
- **Parameters**: @ProductId, @Name, @Description, @Price, @StockQuantity
- **DMS**: FAILED
- **Manual Conversion**: Writable CTE with old_values capture, GETDATE() → NOW()
- **Equivalency**: ERROR

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, SELECT, INSERT, DELETE, UPDATE
- **Parameters**: @ProductId
- **DMS**: FAILED
- **Manual Conversion**: Writable CTE with old_values capture, GETDATE() → NOW()
- **Equivalency**: ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK(), BETWEEN
- **Parameters**: @MinPrice, @MaxPrice
- **DMS**: FAILED
- **Manual Conversion**: Lowercase schema objects
- **Equivalency**: ERROR

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions
- **Parameters**: @Threshold
- **DMS**: FAILED
- **Manual Conversion**: Lowercase schema objects, CAST for integer division
- **Equivalency**: ERROR

---

## Files Modified

### Source Code Files
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL; SqlClient → Npgsql class replacements |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.9 |
| `appsettings.json` | Connection strings converted to PostgreSQL format |

### Database Scripts
| File | Changes |
|------|---------|
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax |

### Migration Artifacts Generated
| File | Description |
|------|-------------|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `dms_failure_summary.txt` | Detailed DMS failure documentation |
| `migration_report.md` | This report |

---

## Key Conversion Patterns Applied

| MS SQL Server | PostgreSQL |
|--------------|------------|
| `SCOPE_IDENTITY()` | `INSERT...RETURNING` in writable CTE |
| `GETDATE()` | `NOW()` |
| `DECLARE @var / SET @var` | Writable CTEs with old_values capture |
| `BEGIN TRANSACTION / COMMIT` | Application-level NpgsqlTransaction |
| `IDENTITY(1,1)` | `SERIAL` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `BIT` | `BOOLEAN` |
| `[dbo].[TableName]` | `tablename` (lowercase) |
| `GO` | Removed (not needed in PostgreSQL) |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `SYSTEM_USER` | `current_user` |
| `IF EXISTS (SELECT * FROM sys.objects...)` | `DROP TABLE IF EXISTS` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `Microsoft.Data.SqlClient` | `Npgsql` |
| `Server=localhost` | `Host=localhost;Port=5432` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |

---

## Package Dependencies

### Removed
```xml
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />
```

### Added
```xml
<PackageReference Include="Npgsql" Version="8.0.9" />
```

Note: Npgsql 8.0.9 was used instead of 8.0.1 (specified in plan) to address security vulnerability GHSA-x9vc-6hfv-hg8c.

---

## Connection String Changes

### Before (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL)
```
Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres
```

---

## Build Status
- **Final Build**: SUCCESS (0 errors, 10 warnings - all pre-existing nullable reference warnings)
- **Target Framework**: net9.0

---

## Known Issues and Recommendations

1. **DMS Tool Unavailable**: The DMS MCP tool was consistently unavailable during this migration. All SQL conversions were performed manually with lowercase schema object names per the fallback procedure.

2. **SQL Equivalency Tool Errors**: The SQL equivalency tool returned ERROR for all 7 statement pairs with error `'uniqueID'`. This appears to be a systemic tool issue, not related to the statement quality.

3. **Connection String Security**: The PostgreSQL connection strings use placeholder credentials (postgres/postgres). Production deployments should use environment variables or a secret management service.

4. **Writable CTEs**: Statements 3, 4, and 5 use PostgreSQL writable CTEs for multi-statement operations. These require PostgreSQL 9.1+ (supported by target PostgreSQL 13).

5. **Integer Division**: Statement 7 (GetLowStockProductsAsync) includes an explicit CAST to DECIMAL to prevent integer division truncation in PostgreSQL.
