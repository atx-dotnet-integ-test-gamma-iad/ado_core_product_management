# Migration Report: MS SQL Server to PostgreSQL

## Project: AdoCore - Product Management System
## Date: 2026-05-05

---

## Executive Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The application uses ADO.NET for database access and has been migrated from `Microsoft.Data.SqlClient` to `Npgsql`.

---

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Statements Successfully Converted by DMS MCP Tool | 0 |
| Statements Requiring Manual Intervention (DMS Failure) | 7 |
| Statements Validated as Equivalent | 0 |
| Statements Validated as Non-Equivalent | 0 |
| Statements with Equivalency Validation Errors | 7 |

---

## DMS Tool Results

All 7 SQL statements were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`) as required. All attempts failed with the same error:

**Error:** `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

Per the transformation definition, manual conversion was applied using lowercase schema object names for PostgreSQL compatibility (documented as `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`).

---

## SQL Equivalency Validation Results

All 7 SQL statement pairs were passed through the SQL Equivalency MCP tool (`sql-equivalency___validate_sql_equivalence`). All validations returned ERROR status:

**Error:** `'uniqueID'`

Per the transformation definition: "If sql-equivalency___validate_sql_equivalence returns an error, mark the equivalency status as ERROR." All pairs are marked as ERROR in the validation report.

---

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS conversion tool failure (all statements manually converted)
2. SQL Equivalency tool returning errors for all pairs (unable to validate programmatically)

### Statement List:

| # | Method | Conversion Notes |
|---|--------|-----------------|
| 1 | GetAllProductsAsync | Direct lowercase conversion; CTE + window functions compatible |
| 2 | GetProductByIdAsync | Direct lowercase conversion; CTE + LAG compatible |
| 3 | InsertProductAsync | Restructured: SCOPE_IDENTITY() → CTE with RETURNING clause |
| 4 | UpdateProductAsync | Restructured: DECLARE variables → CTE with old_values capture |
| 5 | DeleteProductAsync | Restructured: DECLARE variables → CTE with old_values capture |
| 6 | GetProductsByPriceRangeAsync | Direct lowercase conversion; RANK/PERCENT_RANK compatible |
| 7 | GetLowStockProductsAsync | Direct lowercase + CAST for integer division |

---

## Changes Made to Codebase

### 1. SQL Statement Conversion (Step 3)
- **File:** `DataAccess/ProductRepository.cs`
- All 7 SQL statements replaced with PostgreSQL-compatible equivalents
- Key transformations:
  - `SCOPE_IDENTITY()` → CTE with `RETURNING productid` clause
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → Writable CTEs (single-statement approach)
  - `DECLARE @var` → CTE-based `old_values` pattern
  - All schema objects (tables, columns, aliases) → lowercase
  - `ROUND(int/int)` → `ROUND(CAST(int AS NUMERIC)/int)` for proper division

### 2. Package Dependencies (Step 4)
- **File:** `AdoCore.csproj`
- Removed: `Microsoft.Data.SqlClient` Version 5.1.4
- Added: `Npgsql` Version 8.0.6

### 3. ADO.NET Class Replacements (Step 5)
- **File:** `DataAccess/ProductRepository.cs`
- `using Microsoft.Data.SqlClient;` → `using Npgsql;`
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`

### 4. Connection String Configuration (Step 6)
- **File:** `appsettings.json`
- `Server=` → `Host=`
- Removed: `Trusted_Connection`, `MultipleActiveResultSets`, `TrustServerCertificate`
- Added: `Username=postgres;Password=postgres`

---

## Artifacts Generated

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | All 7 original MS SQL statements |
| converted_statements.sql | sourceCode/ | All 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | sourceCode/ | Complete equivalency validation report |
| migration_report.md | sourceCode/ | This report |

---

## Build Verification

The application compiles successfully after all migration changes:

```
dotnet build AdoCore.sln
Build succeeded.
    10 Warning(s) - All pre-existing nullability warnings
    0 Error(s)
```

---

## Known Limitations and Recommendations

1. **DMS Tool Unavailable:** The DMS conversion tool was unavailable during this migration. All conversions were done manually with lowercase schema mapping. A re-validation with DMS when available is recommended.

2. **Equivalency Validation Failed:** The SQL Equivalency tool returned errors for all pairs. Manual review of all 7 converted statements is recommended to verify logical equivalence.

3. **Writable CTEs for Transactions:** The Update and Delete operations use PostgreSQL's writable CTEs to achieve the same transactional behavior as the original SQL Server DECLARE/SET pattern. These should be tested against a live PostgreSQL database.

4. **Integer Division:** Statement 7 (GetLowStockProductsAsync) adds an explicit `CAST(stockquantity AS NUMERIC)` to avoid integer division issues in PostgreSQL.

5. **Connection String Security:** The connection string uses placeholder credentials (`postgres/postgres`). Production deployment should use environment variables or a secrets manager.

---

## Conclusion

The migration from MS SQL Server to PostgreSQL has been completed successfully at the code level. The application compiles without errors. All SQL statements have been converted to PostgreSQL-compatible syntax, all ADO.NET classes have been replaced with Npgsql equivalents, and connection strings have been updated to PostgreSQL format.

Further testing against a live PostgreSQL database is recommended to validate runtime behavior, especially for the transactional operations that were restructured using writable CTEs.
