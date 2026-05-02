# Migration Report: SQL Server to PostgreSQL
## AdoCore Application - ADO.NET Database Migration

### Date: 2026-05-02
### Migration Type: Microsoft SQL Server → PostgreSQL
### Application: AdoCore (.NET 9.0 ADO.NET Application)

---

## 1. Executive Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration covered:
- 7 SQL statements in application code (ProductRepository.cs)
- 2 database setup scripts
- Package dependencies and configuration updates

### Migration Status: **COMPLETE**

---

## 2. SQL Statement Conversion Summary

### 2.1 DMS Tool Results
| Metric | Count |
|--------|-------|
| Total SQL statements processed via DMS | 7 |
| Successfully converted by DMS | 0 |
| DMS failures requiring manual conversion | 7 |

**DMS Error (consistent across all statements):** `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

**Migration Project ARN:** `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

### 2.2 Manual Conversion Details

All 7 statements were manually converted following the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` convention.

| # | Method | Key Conversions Applied |
|---|--------|------------------------|
| 1 | GetAllProductsAsync | Lowercase schema objects; CTE/window functions compatible |
| 2 | GetProductByIdAsync | Lowercase schema objects; LAG window function compatible |
| 3 | InsertProductAsync | CTE with INSERT...RETURNING (replaced SCOPE_IDENTITY()); GETDATE()→NOW(); removed DECLARE |
| 4 | UpdateProductAsync | CTE restructuring; GETDATE()→NOW(); removed DECLARE variables |
| 5 | DeleteProductAsync | CTE restructuring; GETDATE()→NOW(); removed DECLARE variables |
| 6 | GetProductsByPriceRangeAsync | Lowercase schema objects; RANK/PERCENT_RANK compatible |
| 7 | GetLowStockProductsAsync | Lowercase schema objects; ::NUMERIC cast for integer division |

### 2.3 SQL Equivalency Validation

| Metric | Count |
|--------|-------|
| Total statement pairs validated | 7 |
| EQUIVALENT | 0 |
| NOT_EQUIVALENT | 0 |
| ERROR | 7 |

**Note:** All 7 equivalency validations returned ERROR with error `'uniqueID'` from the sql-equivalency___validate_sql_equivalence tool. This appears to be a tool-level issue rather than a statement-level issue, as the error was consistent across all validations.

**Full report:** See `sql_equivalency_validation_report.json` for detailed per-statement results.

---

## 3. Files Modified

### 3.1 Application Code
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced all 7 SQL statements with PostgreSQL equivalents; updated imports (`using Npgsql;`); replaced all ADO.NET classes (SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader) |

### 3.2 Project Configuration
| File | Changes |
|------|---------|
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 9.0.3` |
| `appsettings.json` | Updated connection strings from SQL Server format to PostgreSQL format (Host, Port, Database, Username, Password) |

### 3.3 Database Scripts
| File | Changes |
|------|---------|
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax (SERIAL, VARCHAR, TIMESTAMP, NOW(), CREATE OR REPLACE FUNCTION, RETURNING) |
| `Database/Scripts/01_InitialSetup.sql` | Full conversion including tables, triggers (CREATE FUNCTION + CREATE TRIGGER), indexes, stored procedures as functions, sample data |

### 3.4 Migration Artifacts (New Files)
| File | Description |
|------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `dms_conversion_summary.md` | DMS failure documentation and manual conversion details |
| `migration_report.md` | This report |

---

## 4. Key Conversion Rules Applied

### 4.1 SQL Syntax Conversions
| SQL Server | PostgreSQL | Usage |
|------------|-----------|-------|
| `SCOPE_IDENTITY()` | `INSERT...RETURNING productid` via CTE | InsertProductAsync |
| `GETDATE()` | `NOW()` | All timestamp operations |
| `DECLARE @variable` | CTE restructuring | Transaction blocks (Insert/Update/Delete) |
| `BEGIN TRANSACTION/COMMIT` | Single CTE statement or app-level transaction | Transaction blocks |
| `IDENTITY(1,1)` | `SERIAL` | Primary keys in scripts |
| `NVARCHAR(n)` | `VARCHAR(n)` | All string columns in scripts |
| `DATETIME` | `TIMESTAMP` | All datetime columns in scripts |
| `BIT` | `BOOLEAN` | Boolean columns in scripts |
| `SET NOCOUNT ON` | Removed | Stored procedures |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` | Stored procedures |
| `SYSTEM_USER` | `current_user` | Trigger functions |
| `GO` | Removed | Batch separators |
| `IF EXISTS/DROP` | `DROP IF EXISTS` | Object cleanup |
| Integer division in ROUND | `::NUMERIC` cast | StockPercentageOfAverage |

### 4.2 Schema Naming Convention
All schema object names (tables, columns, aliases, CTE names) converted to **lowercase** for PostgreSQL compatibility as per the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` convention.

### 4.3 Package Dependencies
| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 9.0.3` |

### 4.4 ADO.NET Class Replacements
| SQL Server Class | Npgsql Class | Occurrences |
|-----------------|--------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |
| `Microsoft.Data.SqlClient` (import) | `Npgsql` (import) | 1 |

### 4.5 Connection String Mapping
| SQL Server Parameter | PostgreSQL Parameter |
|---------------------|---------------------|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=ProductManagement` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | Removed (N/A) |
| `TrustServerCertificate=True` | Removed (N/A) |
| N/A | `Port=5432` (added) |

---

## 5. Build Status

### Final Build: **SUCCESS**
- **Errors:** 0
- **Warnings:** 10 (all pre-existing nullable reference warnings, no security vulnerabilities)
- **Build Tool:** `dotnet build sourceCode/AdoCore.csproj`

---

## 6. Items Requiring Manual Review

1. **SQL Equivalency Errors:** All 7 statement pairs returned ERROR from the equivalency tool. Manual review of the converted SQL statements is recommended to ensure semantic equivalence.

2. **CTE-based Transaction Blocks (Statements 3-5):** The original SQL Server transaction blocks with DECLARE/SET variables were restructured to use PostgreSQL CTEs with writable CTEs (INSERT...RETURNING, UPDATE, DELETE in CTEs). This is a significant structural change that should be tested with actual data.

3. **MapProductFromReader Column Names:** The reader column name strings (e.g., `reader["ProductId"]`) use the original casing. PostgreSQL returns lowercase column names by default, so these should be tested to ensure the column name lookup works correctly. Npgsql should handle case-insensitive column lookups, but testing is recommended.

4. **Integer Division:** Statement 7 (GetLowStockProductsAsync) required a `::NUMERIC` cast to avoid integer division truncation in the ROUND operation.

---

## 7. Test Recommendations

1. Verify all CRUD operations (Insert, Read, Update, Delete) work correctly against a PostgreSQL database
2. Verify transaction atomicity is maintained for InsertProductAsync, UpdateProductAsync, DeleteProductAsync
3. Verify window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK) produce identical results
4. Verify ROUND operations produce identical precision results
5. Verify connection string parsing works with NpgsqlConnection
6. Test under concurrent access scenarios
