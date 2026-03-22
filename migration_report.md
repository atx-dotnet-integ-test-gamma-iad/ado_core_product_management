# AdoCore Migration Report: Microsoft SQL Server to PostgreSQL

## 1. Migration Summary

| Property | Value |
|----------|-------|
| **Source Database** | Microsoft SQL Server (via Microsoft.Data.SqlClient 5.1.4) |
| **Target Database** | PostgreSQL (via Npgsql 8.0.6) |
| **Application Framework** | .NET 9.0, ADO.NET |
| **Total Files Modified** | 5 |
| **Total SQL Statements Processed** | 7 |
| **Migration Date** | 2026-03-22 |

### Files Modified
1. `DataAccess/ProductRepository.cs` - SQL statements, ADO.NET classes, using directives
2. `AdoCore.csproj` - Package reference replacement
3. `appsettings.json` - Connection string format
4. `Scripts/01_InitialSetup.sql` - T-SQL to PostgreSQL DDL
5. `Database/Scripts/01_InitialSetup.sql` - T-SQL to PostgreSQL DDL (comprehensive)

### Files Created (Artifacts)
1. `extracted_statements.sql` - Catalog of all original MS SQL statements
2. `converted_statements.sql` - Catalog of all converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Detailed equivalency validation results
4. `migration_report.md` - This report

---

## 2. SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total Statements** | 7 |
| **Successfully Converted by DMS** | 0 |
| **Manual Conversion After DMS Failure** | 7 |

### DMS Tool Status
- **DMS Statement Conversion Tool**: FAILED for all queries
  - Error: "Metadata model conversion failed: Metadata model conversion did not complete after 15 attempts"
  - 4 separate attempts made (including with increased poll intervals)
  - Even simplest queries (e.g., `SELECT GETDATE()`) failed consistently
- **DMS Schema Mapping Tool**: SUCCEEDED
  - Successfully retrieved table/column mappings for Products, ProductHistory, ProductStats
  - Mappings used to guide manual conversion (all lowercase naming confirmed)

### Statement-by-Statement Conversion

| # | Method | Type | Conversion Method | Key Changes |
|---|--------|------|-------------------|-------------|
| 1 | `GetAllProductsAsync` | SELECT (CTE) | Manual (DMS Failed) | Table/column names lowercase |
| 2 | `GetProductByIdAsync` | SELECT (CTE+LAG) | Manual (DMS Failed) | Table/column names lowercase |
| 3 | `InsertProductAsync` | Transaction Block | Manual (DMS Failed) | SCOPE_IDENTITY() → RETURNING + writable CTE; GETDATE() → clock_timestamp() |
| 4 | `UpdateProductAsync` | Transaction Block | Manual (DMS Failed) | DECLARE @var → CTE approach; GETDATE() → clock_timestamp() |
| 5 | `DeleteProductAsync` | Transaction Block | Manual (DMS Failed) | DECLARE @var → CTE approach; GETDATE() → clock_timestamp() |
| 6 | `GetProductsByPriceRangeAsync` | SELECT (CTE+RANK) | Manual (DMS Failed) | Table/column names lowercase |
| 7 | `GetLowStockProductsAsync` | SELECT (CTE+AGG) | Manual (DMS Failed) | Table/column names lowercase; integer division fix with CAST |

### Key Conversion Patterns Applied
- **Schema Objects**: All table and column names converted to lowercase per DMS schema mapping
  - `Products` → `products`, `ProductId` → `productid`, etc.
- **SCOPE_IDENTITY()**: Replaced with PostgreSQL writable CTE using `INSERT ... RETURNING productid`
- **GETDATE()**: Replaced with `clock_timestamp()` (per DMS schema mapping defaults)
- **DECLARE @Variable**: Replaced with CTE-based approach (PostgreSQL doesn't support T-SQL DECLARE in plain SQL)
- **BEGIN TRANSACTION/COMMIT**: Restructured as writable CTEs for atomic operations
- **Integer Division**: Added `CAST(stockquantity AS NUMERIC)` for proper decimal division in PostgreSQL
- **Window Functions**: CTEs and window functions (AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK, MIN/MAX) are compatible between SQL Server and PostgreSQL

---

## 3. SQL Equivalency Validation Summary

| Metric | Count |
|--------|-------|
| **Total Pairs Validated** | 7 |
| **Equivalent** | 0 |
| **Non-Equivalent** | 0 |
| **Errors** | 7 |

### Equivalency Tool Status
- The SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`) returned ERROR with `'uniqueID'` for all 7 statement pairs
- This appears to be a systemic tool infrastructure error, not related to statement content
- The tool was called independently for each of the 7 statement pairs
- All equivalency statuses come directly from the tool output — no agent judgment was used

> **See `sql_equivalency_validation_report.json` for complete details including original statements, converted statements, tool outputs, and DMS failure reasons.**

---

## 4. Package/Dependency Changes

| Original | Replacement |
|----------|-------------|
| `Microsoft.Data.SqlClient` 5.1.4 | `Npgsql` 8.0.6 |

### ADO.NET Class Replacements
| SQL Server Class | PostgreSQL (Npgsql) Class |
|-----------------|--------------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

### Note on Npgsql Version
- Originally targeted Npgsql 8.0.0 as specified in the plan
- Upgraded to Npgsql 8.0.6 to address known high-severity vulnerability (GHSA-x9vc-6hfv-hg8c)

---

## 5. Configuration Changes

### Connection String Format
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | *(removed - N/A)* |
| TLS | `TrustServerCertificate=True` | *(removed)* |

---

## 6. Database Script Changes

### Scripts/01_InitialSetup.sql (Simple Version)
- Converted table creation, stored procedures, and sample data
- `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`
- `nvarchar` → `VARCHAR`
- `datetime` → `TIMESTAMP`
- `GETDATE()` → `clock_timestamp()`
- `GO` statements removed
- `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION` (PL/pgSQL)

### Database/Scripts/01_InitialSetup.sql (Comprehensive Version)
- Full conversion of 5 tables: categories, suppliers, products, producthistory, productstats
- All indexes converted
- Trigger converted from T-SQL `inserted`/`deleted` tables to PostgreSQL `NEW`/`OLD` row variables
- `bit` → `BOOLEAN`
- `SYSTEM_USER` → `current_user`
- All stored procedures → PL/pgSQL functions
- Sample data preserved with lowercase column names

---

## 7. Statements Requiring Manual Review

**All 7 statements require manual review** due to:

1. **DMS Conversion Tool Failure**: The DMS statement conversion tool failed for all statements. Manual conversion was applied using DMS schema mapping as reference.

2. **SQL Equivalency Tool Error**: The equivalency tool returned systemic errors for all pairs. Manual verification of SQL equivalency is recommended.

### Specific Areas for Review

| Statement | Review Concern |
|-----------|---------------|
| **InsertProductAsync** | Writable CTE chain replacing SCOPE_IDENTITY(). Verify that `ExecuteScalarAsync` correctly returns the new productid from `SELECT productid FROM new_product` |
| **UpdateProductAsync** | CTE-based approach replacing DECLARE variables. Verify old_values CTE correctly captures pre-update values before the UPDATE CTE executes |
| **DeleteProductAsync** | CTE-based approach with DELETE...RETURNING. Verify the order of operations (history insert before delete) works correctly with PostgreSQL CTE execution semantics |
| **GetLowStockProductsAsync** | Added CAST(stockquantity AS NUMERIC) for division. Verify this doesn't change precision expectations |

---

## 8. Build Status

| Build Step | Result |
|-----------|--------|
| Step 3 (SQL Re-integration) | ✅ **Build Succeeded** (0 errors, 10 warnings) |
| Step 4 (Package Update) | ✅ **Build Succeeded** (0 errors, 10 warnings) |
| Step 5 (Configuration) | ✅ **Build Succeeded** (0 errors, 10 warnings) |
| **Final Build** | ✅ **Build Succeeded** (0 errors, 10 warnings) |

All warnings are pre-existing nullable reference type warnings (CS8601, CS8603, CS8618, CS8625, CS8600) — not introduced by the migration.

---

## 9. Artifacts Checklist

| Artifact | Status | Contents |
|----------|--------|----------|
| `extracted_statements.sql` | ✅ Complete | 7 original MS SQL statements with source locations |
| `converted_statements.sql` | ✅ Complete | 7 converted PostgreSQL statements with conversion notes |
| `sql_equivalency_validation_report.json` | ✅ Complete | 7 statement pairs with tool outputs |
| `migration_report.md` | ✅ Complete | This comprehensive report |
