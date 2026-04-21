# Migration Report: MS SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-04-21  
**Application:** AdoCore - Product Management System  
**Source Database:** Microsoft SQL Server  
**Target Database:** PostgreSQL  
**Framework:** .NET 9.0 (net9.0)

---

## SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements sent to DMS MCP tool | 7 |
| Statements successfully converted by DMS | 0 |
| Statements requiring manual intervention | 7 |
| Statements validated for equivalency | 7 |
| Statements marked EQUIVALENT | 0 |
| Statements marked NOT_EQUIVALENT | 0 |
| Statements with equivalency ERROR | 7 |

### DMS Tool Status

All 7 SQL statements were submitted to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) for conversion. All 7 failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Per the migration plan, all statements were then manually converted applying lowercase schema object naming conventions for PostgreSQL compatibility, documented with reason `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`.

### SQL Equivalency Validation Status

All 7 statement pairs were submitted to the SQL Equivalency MCP tool (`sql-equivalency___validate_sql_equivalence`). All 7 returned ERROR status:

```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

Per the migration plan, all pairs are marked as ERROR in the equivalency report. No agent judgment was used to determine equivalency.

**Detailed results:** See `sql_equivalency_validation_report.json` for complete statement-level details.

---

## SQL Statements Converted

### Statement 1: GetAllProductsAsync
- **Location:** `DataAccess/ProductRepository.cs` - `GetAllProductsAsync` method
- **Type:** CTE with AVG/COUNT window functions, CASE, ROUND, INNER JOIN
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** All identifiers lowercased (Products → products, ProductId → productid, etc.)
- **Equivalency Status:** ERROR

### Statement 2: GetProductByIdAsync
- **Location:** `DataAccess/ProductRepository.cs` - `GetProductByIdAsync` method
- **Type:** CTE with LAG window function, parameterized query, LEFT JOIN
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** All identifiers lowercased
- **Equivalency Status:** ERROR

### Statement 3: InsertProductAsync
- **Location:** `DataAccess/ProductRepository.cs` - `InsertProductAsync` method
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY, GETDATE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** SCOPE_IDENTITY() → RETURNING clause, GETDATE() → NOW(), DECLARE/@var → C# variables, BEGIN TRANSACTION → BeginTransactionAsync, all identifiers lowercased
- **Equivalency Status:** ERROR

### Statement 4: UpdateProductAsync
- **Location:** `DataAccess/ProductRepository.cs` - `UpdateProductAsync` method
- **Type:** Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** GETDATE() → NOW(), DECLARE/@var → C# variables with separate SELECT query, all identifiers lowercased
- **Equivalency Status:** ERROR

### Statement 5: DeleteProductAsync
- **Location:** `DataAccess/ProductRepository.cs` - `DeleteProductAsync` method
- **Type:** Transaction block with DECLARE, DELETE, CASE, GETDATE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** GETDATE() → NOW(), DECLARE/@var → C# variables, all identifiers lowercased
- **Equivalency Status:** ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Location:** `DataAccess/ProductRepository.cs` - `GetProductsByPriceRangeAsync` method
- **Type:** CTE with RANK, PERCENT_RANK, BETWEEN, parameterized
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** All identifiers lowercased
- **Equivalency Status:** ERROR

### Statement 7: GetLowStockProductsAsync
- **Location:** `DataAccess/ProductRepository.cs` - `GetLowStockProductsAsync` method
- **Type:** CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** All identifiers lowercased, added CAST(stockquantity AS DECIMAL) to avoid integer division
- **Equivalency Status:** ERROR

---

## Files Modified

### Source Code Files

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL; ADO.NET types replaced with Npgsql equivalents; Transaction handling restructured for PostgreSQL compatibility; Reader column names lowercased |
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.6` |
| `appsettings.json` | Connection strings updated from SQL Server format to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Converted from SQL Server to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Converted from SQL Server to PostgreSQL syntax (including triggers) |

### New Artifact Files

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Complete equivalency validation report for all 7 statement pairs |
| `migration_report.md` | This comprehensive migration report |

---

## Package Dependency Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.6` |

**Note:** Npgsql 8.0.6 was selected instead of 8.0.0 due to a known high-severity vulnerability (GHSA-x9vc-6hfv-hg8c) in version 8.0.0.

---

## ADO.NET Type Replacements

| SQL Server Type | Npgsql Type | Occurrences |
|----------------|-------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 15 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |
| `SqlTransaction` | `NpgsqlTransaction` | 4 |
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |

---

## Connection String Changes

### DevConnection
- **Before:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After:** `Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres`

### ProdConnection
- **Before:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After:** `Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres`

### Connection String Parameter Mapping
| SQL Server | PostgreSQL | Notes |
|-----------|------------|-------|
| `Server=` | `Host=` | Server address |
| `Database=` | `Database=` | Unchanged |
| `Trusted_Connection=True` | `Username=`/`Password=` | Windows auth → explicit credentials |
| `MultipleActiveResultSets=true` | Removed | Not applicable to PostgreSQL |
| `TrustServerCertificate=True` | Removed | Not needed for basic setup |
| N/A | `Port=5432` | Added explicit PostgreSQL port |

---

## Database Script Conversions

### Scripts/01_InitialSetup.sql (Simple)
| SQL Server Syntax | PostgreSQL Syntax |
|------------------|-------------------|
| `IDENTITY(1,1)` | `SERIAL` |
| `GETDATE()` | `CURRENT_TIMESTAMP` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `[dbo].[tablename]` | `tablename` |
| `IF NOT EXISTS (SELECT * FROM sys.databases...)` | Removed (database assumed to exist) |
| `GO` | Removed (not needed in PostgreSQL) |
| `SCOPE_IDENTITY()` | `RETURNING productid INTO` |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `SET NOCOUNT ON` | Removed (not needed) |

### Database/Scripts/01_InitialSetup.sql (Comprehensive)
All above conversions plus:
| SQL Server Syntax | PostgreSQL Syntax |
|------------------|-------------------|
| `[bit]` | `BOOLEAN` |
| `DEFAULT 1`/`DEFAULT 0` (bit) | `DEFAULT TRUE`/`DEFAULT FALSE` |
| `SYSTEM_USER` | `CURRENT_USER` |
| `IF EXISTS ... DROP` | `DROP ... IF EXISTS` |
| SQL Server trigger syntax | PostgreSQL trigger function + trigger pattern |
| `FROM inserted/deleted` | `NEW`/`OLD` record references |
| `IF EXISTS (SELECT 1 FROM inserted)` | `IF TG_OP = 'INSERT'` |

---

## Build Status

**Final Build Result:** ✅ **SUCCESS** (0 errors, 10 warnings)

All warnings are pre-existing nullable reference warnings unrelated to the migration:
- CS8601: Possible null reference assignment
- CS8618: Non-nullable field must contain non-null value
- CS8600: Converting null literal to non-nullable type
- CS8603: Possible null reference return
- CS8625: Cannot convert null literal to non-nullable reference type

---

## Known Issues and Recommendations

1. **DMS Tool Unavailability:** All DMS conversions failed due to metadata model creation issues. Manual conversions were applied following the lowercase schema object naming convention.

2. **SQL Equivalency Tool Errors:** All equivalency validations returned ERROR. The tool appeared to have a systemic `'uniqueID'` error. Manual review of converted statements is recommended.

3. **Connection String Credentials:** The PostgreSQL connection strings use placeholder credentials (`postgres/postgres`). Production deployments should use environment variables or secure configuration management.

4. **Transaction Restructuring:** The INSERT, UPDATE, and DELETE methods were restructured from single SQL batch statements with DECLARE variables to multi-command C# managed transactions. This maintains the same transactional guarantees while being compatible with PostgreSQL's parameterized query model via Npgsql.

5. **Integer Division Fix:** In `GetLowStockProductsAsync`, added `CAST(stockquantity AS DECIMAL)` to prevent integer division truncation in PostgreSQL (which differs from SQL Server's implicit conversion behavior).
