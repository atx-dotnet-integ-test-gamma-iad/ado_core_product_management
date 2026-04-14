# Migration Report: SQL Server to PostgreSQL
## ADO.NET Application Migration

### Migration Date: 2026-04-14
### Source: Microsoft SQL Server 2019
### Target: PostgreSQL 13

---

## 1. Summary

This migration converted an ADO.NET application from Microsoft SQL Server to PostgreSQL. All SQL statements, database access code, connection strings, and setup scripts were converted.

### Key Statistics:
- **Total SQL Statements Processed**: 7 (from ProductRepository.cs)
- **DMS Tool Conversion Attempts**: 7
- **DMS Tool Successes**: 0 (tool experienced metadata model creation failure)
- **Manual Conversions (with lowercase schema)**: 7
- **SQL Equivalency Validations**: 7
- **Equivalency Results - Equivalent**: 0
- **Equivalency Results - Non-Equivalent**: 0
- **Equivalency Results - Error**: 7 (tool returned internal 'uniqueID' error for all pairs)

---

## 2. DMS Tool Status

The DMS statement_conversion_tool was attempted for all 7 SQL statements. All attempts failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

The DMS schema_mapping_tool was successful and provided the PostgreSQL table mappings:
- `Products` → `products` (schema: `productmanagement_dbo`)
- `ProductHistory` → `producthistory`
- `ProductStats` → `productstats`

All column names were mapped to lowercase as per the DMS schema mapping results.

---

## 3. SQL Equivalency Validation Status

The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) was called for all 7 statement pairs. All calls returned:
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be a tool-level internal error, not a statement-level issue. All 7 statements are marked as ERROR in the validation report.

---

## 4. Files Modified

### Source Code Changes:
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL syntax, ADO.NET types replaced with Npgsql equivalents |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.1 |
| `appsettings.json` | Connection strings updated from SQL Server to PostgreSQL format |

### SQL Script Changes:
| File | Changes |
|------|---------|
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax (stored procedures → functions, data types, etc.) |
| `Database/Scripts/01_InitialSetup.sql` | Full conversion including tables, triggers, functions, indexes, sample data |

### Artifacts Created:
| File | Description |
|------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Detailed equivalency validation report |

---

## 5. Conversion Details

### 5.1 SQL Statement Conversions

| # | Method | Key Conversions |
|---|--------|-----------------|
| 1 | GetAllProductsAsync | CTE renamed to avoid table name conflict, lowercase schema |
| 2 | GetProductByIdAsync | CTE renamed, lowercase schema, LAG window function compatible |
| 3 | InsertProductAsync | SCOPE_IDENTITY() → RETURNING, GETDATE() → NOW(), transaction restructured to separate commands |
| 4 | UpdateProductAsync | DECLARE @var → C# variables, GETDATE() → NOW(), transaction restructured |
| 5 | DeleteProductAsync | DECLARE @var → C# variables, GETDATE() → NOW(), CASE preserved, transaction restructured |
| 6 | GetProductsByPriceRangeAsync | RANK()/PERCENT_RANK() compatible, lowercase schema |
| 7 | GetLowStockProductsAsync | AVG/MIN/MAX window functions compatible, CAST for integer division |

### 5.2 ADO.NET Type Replacements

| SQL Server Type | PostgreSQL Type |
|----------------|-----------------|
| `Microsoft.Data.SqlClient` | `Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlTransaction` | `NpgsqlTransaction` |

### 5.3 Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server | `Server=localhost` | `Host=localhost` |
| Port | N/A | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Auth | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not needed) |
| TLS | `TrustServerCertificate=True` | Removed (not needed) |

### 5.4 SQL Script Conversions

| SQL Server Syntax | PostgreSQL Syntax |
|-------------------|-------------------|
| `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` |
| `[dbo].[tablename]` | `tablename` (lowercase) |
| `[nvarchar](n)` | `VARCHAR(n)` |
| `[datetime]` | `TIMESTAMP WITHOUT TIME ZONE` |
| `[bit]` | `BOOLEAN` |
| `GETDATE()` | `NOW()` |
| `SYSTEM_USER` | `CURRENT_USER` |
| `GO` | Removed |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `CREATE TRIGGER ... AFTER INSERT, UPDATE, DELETE` | Separate trigger function + `CREATE TRIGGER` |

---

## 6. Build Verification

- **Step 1 (SQL Conversion)**: Build succeeded - 0 errors, 10 warnings
- **Step 2 (Package Migration)**: Build succeeded - 0 errors, 12 warnings  
- **Step 3 (Config & Scripts)**: Build succeeded - 0 errors, 12 warnings

All warnings are pre-existing nullable reference warnings, not introduced by the migration.

---

## 7. Items Requiring Manual Review

1. **DMS Tool Failures**: All 7 SQL statement conversions were done manually due to DMS tool failure. Manual review recommended.
2. **SQL Equivalency**: All 7 equivalency validations returned ERROR due to tool-level issue. Manual equivalency review recommended.
3. **Connection String Credentials**: Placeholder credentials (postgres/postgres) used. Update for production environments.
4. **Transaction Restructuring**: Statements 3, 4, 5 were restructured from single T-SQL blocks to multiple parameterized commands with C# transaction management. Verify atomicity in production.
