# Migration Report: Microsoft SQL Server to PostgreSQL
## AdoCore Application - ADO.NET Database Migration

### Migration Date: 2026-04-14
### Migration Project ARN: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

---

## 1. Executive Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating ADO.NET client libraries, connection strings, configuration, and database setup scripts.

### Key Results
| Metric | Value |
|--------|-------|
| Total SQL Statements Processed (ProductRepository.cs) | 7 |
| SQL Statements Successfully Converted by DMS Tool | 0 |
| SQL Statements Requiring Manual Intervention | 7 |
| SQL Equivalency Validations Performed | 9 (7 repository + 2 script statements) |
| SQL Equivalency Results - EQUIVALENT | 0 |
| SQL Equivalency Results - NOT_EQUIVALENT | 0 |
| SQL Equivalency Results - ERROR | 9 |
| Total Files Modified | 6 |
| Build Status | SUCCESS (0 errors, 10 warnings) |

---

## 2. DMS Tool Usage

### 2.1 Statement Conversion Tool (dms-mcp___statement_conversion_tool)
- **Status**: FAILED for all statements
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Total Calls Made**: 12 (7 for ProductRepository.cs statements, 3 retries, 2 for script statements)
- **Fallback**: Manual conversion with lowercase schema object names (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)

### 2.2 Schema Mapping Tool (dms-mcp___schema_mapping_tool)
- **Status**: SUCCESS for all tables
- **Tables Mapped**: Products, ProductHistory, ProductStats, Categories, Suppliers
- **Key Mappings Used**: Table/column name lowercasing, type conversions (NVARCHAR→VARCHAR, DECIMAL→NUMERIC, DATETIME→TIMESTAMP, BIT→BOOLEAN, IDENTITY→GENERATED ALWAYS AS IDENTITY, GETDATE()→clock_timestamp())

---

## 3. SQL Equivalency Validation

### 3.1 Tool: sql-equivalency___validate_sql_equivalence
- **Status**: ERROR for all statement pairs
- **Error**: `'uniqueID'`
- **Note**: All 9 statement pairs were submitted to the tool; all returned ERROR status
- **Full report available**: sourceCode/sql_equivalency_validation_report.json

---

## 4. SQL Statements Processed (ProductRepository.cs)

### Statement 1: GetAllProductsAsync
- **Source**: DataAccess/ProductRepository.cs, line 43-71
- **Type**: SELECT with CTE (ProductStats), Window Functions (AVG, COUNT OVER), INNER JOIN, CASE, ROUND, ORDER BY CASE
- **Conversion**: Table/column names lowercased
- **DMS Status**: FAILED
- **Equivalency**: ERROR

### Statement 2: GetProductByIdAsync
- **Source**: DataAccess/ProductRepository.cs, line 81-107
- **Type**: SELECT with CTE (ProductHistory), LAG OVER(), LEFT JOIN, CASE with NULL check, ROUND
- **Conversion**: Table/column names lowercased
- **DMS Status**: FAILED
- **Equivalency**: ERROR

### Statement 3: InsertProductAsync
- **Source**: DataAccess/ProductRepository.cs, line 117-140
- **Type**: DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE stats, COMMIT, SELECT
- **Conversion**: DO $$ block with PL/pgSQL variables, LASTVAL(), clock_timestamp()
- **DMS Status**: FAILED
- **Equivalency**: ERROR

### Statement 4: UpdateProductAsync
- **Source**: DataAccess/ProductRepository.cs, line 150-182
- **Type**: BEGIN TRANSACTION, DECLARE variables, SELECT INTO variables, UPDATE, INSERT history, UPDATE stats, COMMIT
- **Conversion**: DO $$ block with PL/pgSQL variables, SELECT INTO, clock_timestamp()
- **DMS Status**: FAILED
- **Equivalency**: ERROR

### Statement 5: DeleteProductAsync
- **Source**: DataAccess/ProductRepository.cs, line 192-224
- **Type**: BEGIN TRANSACTION, DECLARE, SELECT INTO, INSERT history, DELETE, UPDATE stats with CASE, COMMIT
- **Conversion**: DO $$ block with PL/pgSQL variables, clock_timestamp(), CASE preserved
- **DMS Status**: FAILED
- **Equivalency**: ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: DataAccess/ProductRepository.cs, line 234-252
- **Type**: SELECT with CTE (RankedProducts), RANK(), PERCENT_RANK() OVER(), BETWEEN, CASE
- **Conversion**: Table/column names lowercased, window functions preserved
- **DMS Status**: FAILED
- **Equivalency**: ERROR

### Statement 7: GetLowStockProductsAsync
- **Source**: DataAccess/ProductRepository.cs, line 262-281
- **Type**: SELECT with CTE (StockAnalysis), AVG/MIN/MAX OVER(), CASE, ROUND
- **Conversion**: Table/column names lowercased, added CAST for integer division
- **DMS Status**: FAILED
- **Equivalency**: ERROR

---

## 5. Files Modified

### 5.1 Source Code Files
| File | Changes |
|------|---------|
| DataAccess/ProductRepository.cs | Replaced 7 SQL statements with PostgreSQL equivalents; Replaced SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader; Updated using directive from Microsoft.Data.SqlClient to Npgsql; Updated MapProductFromReader column names to lowercase |
| AdoCore.csproj | Replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.6 |
| appsettings.json | Updated connection strings from SQL Server to PostgreSQL format |

### 5.2 Database Script Files
| File | Changes |
|------|---------|
| Scripts/01_InitialSetup.sql | Converted to PostgreSQL syntax: IDENTITY→GENERATED ALWAYS AS IDENTITY, NVARCHAR→VARCHAR, GETDATE()→clock_timestamp(), CREATE OR ALTER PROCEDURE→CREATE OR REPLACE FUNCTION, removed GO separators, SCOPE_IDENTITY()→RETURNING |
| Database/Scripts/01_InitialSetup.sql | Full conversion: Tables, indexes, trigger (SQL Server trigger→PostgreSQL trigger function + trigger), stored procedures→functions, INSERT statements, SYSTEM_USER→CURRENT_USER, BIT→BOOLEAN |

### 5.3 Artifact Files Created
| File | Purpose |
|------|---------|
| extracted_statements.sql | Catalog of all 7 original SQL Server statements |
| converted_statements.sql | Catalog of all 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | Comprehensive equivalency validation report |
| dms_failure_summary.md | DMS failure documentation |
| migration_report.md | This file |

---

## 6. Connection String Changes

### DevConnection
- **Before**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After**: `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres;`

### ProdConnection
- **Before**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After**: `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres;`

### Parameter Mapping
| SQL Server Parameter | PostgreSQL Parameter | Notes |
|---------------------|---------------------|-------|
| Server= | Host= | Direct mapping |
| Database= | Database= | Unchanged |
| Trusted_Connection=True | Removed | Windows Auth not supported; use Username/Password |
| MultipleActiveResultSets=true | Removed | Not applicable to PostgreSQL |
| TrustServerCertificate=True | Removed | Not applicable; use SSL Mode if needed |
| N/A | Username=postgres | Added for PostgreSQL authentication |
| N/A | Password=postgres | Added for PostgreSQL authentication |

---

## 7. Package Dependency Changes

| Action | Package | Version |
|--------|---------|---------|
| REMOVED | Microsoft.Data.SqlClient | 5.1.4 |
| ADDED | Npgsql | 8.0.6 |
| RETAINED | Microsoft.Extensions.Configuration | 8.0.0 |
| RETAINED | Microsoft.Extensions.Configuration.Json | 8.0.0 |
| RETAINED | Microsoft.Extensions.DependencyInjection | 8.0.0 |

---

## 8. ADO.NET Class Replacements

| SQL Server Class | Npgsql Class | Locations |
|-----------------|-------------|-----------|
| SqlConnection | NpgsqlConnection | Field declaration, GetConnectionAsync() return type, constructor |
| SqlCommand | NpgsqlCommand | All 7 SQL statement execution blocks |
| SqlDataReader | NpgsqlDataReader | MapProductFromReader parameter, all reader declarations |
| SqlParameter | NpgsqlParameter | N/A (AddWithValue pattern used, compatible with Npgsql) |

---

## 9. SQL Syntax Conversion Summary

| SQL Server Construct | PostgreSQL Equivalent | Statements Affected |
|---------------------|----------------------|-------------------|
| SCOPE_IDENTITY() | LASTVAL() | Statement 3 |
| GETDATE() | clock_timestamp() | Statements 3, 4, 5 |
| BEGIN TRANSACTION | DO $$ BEGIN | Statements 3, 4, 5 |
| DECLARE @var TYPE | DECLARE v_var TYPE (in DO block) | Statements 3, 4, 5 |
| SET @var = value | v_var := value | Statement 3 |
| SELECT @var = col FROM | SELECT col INTO v_var FROM | Statements 4, 5 |
| NVARCHAR | VARCHAR | Script files |
| IDENTITY(1,1) | GENERATED ALWAYS AS IDENTITY | Script files |
| BIT | BOOLEAN | Script files |
| CREATE OR ALTER PROCEDURE | CREATE OR REPLACE FUNCTION | Script files |
| SQL Server Trigger | PostgreSQL Trigger Function + Trigger | Script files |
| SYSTEM_USER | CURRENT_USER | Script files |
| GO | Removed (use ;) | Script files |
| IF NOT EXISTS (sys.objects) | DROP TABLE IF EXISTS / CREATE TABLE IF NOT EXISTS | Script files |

---

## 10. Build Verification

### Final Build Results
- **Command**: `dotnet build AdoCore.sln`
- **Result**: **Build succeeded**
- **Errors**: 0
- **Warnings**: 10 (all pre-existing nullable reference warnings, not introduced by migration)
- **Output**: AdoCore.dll generated successfully

---

## 11. Known Limitations and Recommendations

1. **DMS Statement Conversion**: The DMS statement_conversion_tool was unavailable during this migration. All SQL conversions were performed manually using schema mappings from the DMS schema_mapping_tool. A re-run through DMS is recommended when the tool is available.

2. **SQL Equivalency Validation**: The SQL equivalency validation tool returned errors for all statement pairs. Manual review of converted statements is recommended.

3. **Connection String Credentials**: The connection string uses placeholder credentials (postgres/postgres). These should be replaced with actual credentials or use environment variable injection in production.

4. **PL/pgSQL DO Blocks**: Statements 3, 4, 5 use DO $$ blocks for PL/pgSQL variable support. This approach works with Npgsql but may have different error handling behavior than the original SQL Server T-SQL batches.

5. **Integer Division**: Statement 7 (GetLowStockProductsAsync) includes a CAST to NUMERIC for the stockquantity/avgstock division to avoid integer truncation in PostgreSQL.

6. **Transaction Handling**: The DO $$ blocks in statements 3, 4, 5 are atomic within the DO block. The C# ExecuteInTransactionAsync method uses NpgsqlTransaction which is fully compatible.
