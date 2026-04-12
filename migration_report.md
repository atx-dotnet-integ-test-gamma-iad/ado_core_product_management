# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary
- **Migration Type**: ADO.NET Application - SQL Server to PostgreSQL
- **Application**: AdoCore - Product Management System
- **Framework**: .NET 9.0
- **Date**: 2026-04-12

---

## SQL Statement Conversion

### Statistics
| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| DMS Successful Conversions | 0 |
| DMS Failed Conversions | 7 |
| Manual Conversions (with lowercase schema) | 7 |
| Equivalency: EQUIVALENT | 0 |
| Equivalency: NOT_EQUIVALENT | 0 |
| Equivalency: ERROR | 7 |

### DMS Tool Status
- **Tool**: dms-mcp___statement_conversion_tool
- **Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Status**: All 7 attempts FAILED
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Action Taken**: Manual conversion applied with lowercase schema object names per transformation definition rules

### SQL Equivalency Validation Status
- **Tool**: sql-equivalency___validate_sql_equivalence
- **Status**: All 7 validation attempts returned ERROR
- **Error**: `'uniqueID'`
- **Note**: Per transformation definition, all statements marked as ERROR (agent judgment NOT used for equivalency)

### Statement Details

| # | Method | Conversion Method | Key Changes |
|---|--------|-------------------|-------------|
| 1 | GetAllProductsAsync | Manual (lowercase) | Identifiers lowercased; CTE/window functions preserved |
| 2 | GetProductByIdAsync | Manual (lowercase) | CTE renamed to producthistory_cte; LAG preserved |
| 3 | InsertProductAsync | Manual (lowercase) | SCOPE_IDENTITY() → INSERT...RETURNING; GETDATE() → NOW(); Writable CTE pattern |
| 4 | UpdateProductAsync | Manual (lowercase) | DECLARE/@var → CTE approach; GETDATE() → NOW(); Writable CTE pattern |
| 5 | DeleteProductAsync | Manual (lowercase) | DECLARE/@var → CTE approach; GETDATE() → NOW(); Writable CTE pattern |
| 6 | GetProductsByPriceRangeAsync | Manual (lowercase) | Identifiers lowercased; RANK/PERCENT_RANK preserved |
| 7 | GetLowStockProductsAsync | Manual (lowercase) | Added CAST for int division; AVG/MIN/MAX preserved |

---

## Files Modified

### 1. DataAccess/ProductRepository.cs
- **SQL Statements**: All 7 SQL string literals replaced with PostgreSQL equivalents
- **Using Directive**: `using Microsoft.Data.SqlClient` → `using Npgsql`
- **Class References**:
  - `SqlConnection` → `NpgsqlConnection` (field declaration, GetConnectionAsync method)
  - `SqlCommand` → `NpgsqlCommand` (7 occurrences)
  - `SqlDataReader` → `NpgsqlDataReader` (MapProductFromReader parameter)

### 2. AdoCore.csproj
- **Package Removed**: `Microsoft.Data.SqlClient` Version 5.1.4
- **Package Added**: `Npgsql` Version 8.0.6

### 3. appsettings.json
- **Connection String Changes**:
  - `Server=` → `Host=`
  - Removed: `Trusted_Connection=True`, `MultipleActiveResultSets=true`, `TrustServerCertificate=True`
  - Added: `Username=postgres`, `Password=postgres`

### 4. README.md
- Updated all references from SQL Server to PostgreSQL
- Updated prerequisites, setup instructions, NuGet packages list
- Updated connection string documentation

---

## SQL Server → PostgreSQL Syntax Conversions Applied

| SQL Server Syntax | PostgreSQL Syntax |
|-------------------|-------------------|
| `SCOPE_IDENTITY()` | `INSERT...RETURNING productid` |
| `GETDATE()` | `NOW()` |
| `DECLARE @var TYPE` | PostgreSQL writable CTE pattern |
| `SET @var = value` | CTE subquery approach |
| `IDENTITY(1,1)` | `SERIAL` (in table DDL) |
| Schema object names (PascalCase) | Lowercase identifiers |
| `NVARCHAR` | `VARCHAR` (in table DDL) |
| `BIT` | `BOOLEAN` (in table DDL) |
| `DATETIME` | `TIMESTAMP` (in table DDL) |

---

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Class | Occurrences |
|------------------|--------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 (field, method return, constructor) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per SQL method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader) |
| `Microsoft.Data.SqlClient` | `Npgsql` | 1 (using directive) |

---

## Migration Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | sourceCode/ | All 7 original MS SQL statements |
| `converted_statements.sql` | sourceCode/ | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | sourceCode/ | Complete equivalency report for all 7 pairs |
| `dms_conversion_log.md` | sourceCode/ | Detailed DMS tool output log |
| `migration_report.md` | sourceCode/ | This report |

---

## Manual Interventions and Reasoning

All 7 SQL statements required manual conversion due to DMS tool failure. The manual conversion applied:
1. **Lowercase schema object names**: All table names, column names, and aliases converted to lowercase for PostgreSQL identifier compatibility
2. **Function replacements**: `GETDATE()` → `NOW()`, `SCOPE_IDENTITY()` → `INSERT...RETURNING`
3. **Transaction restructuring**: T-SQL `DECLARE`/`SET`/`BEGIN TRANSACTION`/`COMMIT` blocks restructured using PostgreSQL writable CTE patterns
4. **Integer division**: Added `CAST(... AS DECIMAL)` where integer division could lose precision in PostgreSQL

---

## Verification Results
- **Build Status**: Succeeded with 0 errors, 10 warnings (all pre-existing nullable reference warnings)
- **SQL Server Reference Check**: No remaining SQL Server references in any .cs or .csproj file
- **Equivalency Report Completeness**: All 7 statements accounted for with proper fields
- **All Artifacts Present**: Confirmed all 5 migration artifacts exist
