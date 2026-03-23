# Migration Report: MS SQL Server to PostgreSQL

## Overview
- **Application**: AdoCore (.NET 9.0 ADO.NET Application)
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-03-23
- **DMS Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

---

## SQL Statement Migration Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS tool | 0 |
| Requiring manual intervention (DMS failure) | 7 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| Equivalency validation errors | 7 |

### DMS Tool Status
All 7 DMS conversion attempts failed with timeout errors (metadata model creation/conversion did not complete after 15 attempts). The DMS `schema_mapping_tool` was successfully used to retrieve table schema mappings, which guided the manual conversions.

### SQL Equivalency Tool Status
All 7 equivalency validations returned ERROR with `'uniqueID'` - a systemic tool error not specific to any statement. Results are recorded exactly as returned by the tool.

---

## Detailed Statement Listing

### Statement 1: GetAllProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**: Table/column names lowercased; CTE, window functions, CASE, ROUND are PostgreSQL-compatible

### Statement 2: GetProductByIdAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**: Table/column names lowercased; LAG window function, LEFT JOIN are PostgreSQL-compatible

### Statement 3: InsertProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**: 
  - SCOPE_IDENTITY() → INSERT...RETURNING in writable CTE
  - GETDATE() → clock_timestamp()
  - DECLARE @variable → CTE-based approach
  - BEGIN TRANSACTION/COMMIT → Removed (managed by C# ADO.NET)

### Statement 4: UpdateProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**:
  - DECLARE/SELECT INTO @variable → WITH old_values AS (SELECT...)
  - GETDATE() → clock_timestamp()
  - BEGIN TRANSACTION/COMMIT → Removed (managed by C# ADO.NET)

### Statement 5: DeleteProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**:
  - DECLARE/SELECT INTO @variable → WITH old_values AS (SELECT...)
  - GETDATE() → clock_timestamp()
  - BEGIN TRANSACTION/COMMIT → Removed (managed by C# ADO.NET)
  - CASE expression in UPDATE preserved (PostgreSQL-compatible)

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**: Table/column names lowercased; RANK(), PERCENT_RANK(), BETWEEN, CTE are PostgreSQL-compatible

### Statement 7: GetLowStockProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**: 
  - Table/column names lowercased
  - Added CAST(stockquantity AS NUMERIC) for integer division in ROUND()

---

## Files Modified

### 1. AdoCore.csproj
- **Change**: Package reference replacement
- **Before**: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **After**: `<PackageReference Include="Npgsql" Version="8.0.6" />`

### 2. DataAccess/ProductRepository.cs
- **Changes**:
  - Using directive: `Microsoft.Data.SqlClient` → `Npgsql`
  - Field type: `SqlConnection` → `NpgsqlConnection`
  - Method return type: `Task<SqlConnection>` → `Task<NpgsqlConnection>`
  - Constructor: `new SqlConnection()` → `new NpgsqlConnection()`
  - Command creation: `new SqlCommand()` → `new NpgsqlCommand()` (7 occurrences)
  - Reader parameter: `SqlDataReader` → `NpgsqlDataReader`
  - All 7 SQL string literals replaced with PostgreSQL-compatible equivalents

### 3. appsettings.json
- **Change**: Connection string format
- **Before**: `"Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True"`
- **After**: `"Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres"`
- Applied to both DevConnection and ProdConnection

---

## Dependency Changes

| Package | Old Version | New Version | Notes |
|---------|-------------|-------------|-------|
| Microsoft.Data.SqlClient | 5.1.4 | (removed) | SQL Server client removed |
| Npgsql | (new) | 8.0.6 | PostgreSQL client added; 8.0.6 chosen to avoid GHSA-x9vc-6hfv-hg8c vulnerability in 8.0.0 |

---

## Class Replacements

| Original (SQL Server) | Replacement (PostgreSQL) | Occurrences |
|-----------------------|--------------------------|-------------|
| SqlConnection | NpgsqlConnection | 4 |
| SqlCommand | NpgsqlCommand | 7 |
| SqlDataReader | NpgsqlDataReader | 1 |

---

## Connection String Mapping

| SQL Server Parameter | PostgreSQL Parameter | Notes |
|---------------------|---------------------|-------|
| Server= | Host= | Server hostname |
| Database= | Database= | Same parameter |
| Trusted_Connection=True | Username=; Password= | Different auth model |
| MultipleActiveResultSets=true | (removed) | Not applicable to PostgreSQL |
| TrustServerCertificate=True | (removed) | Not applicable to PostgreSQL |

---

## Schema Mapping (from DMS schema_mapping_tool)

| SQL Server Object | PostgreSQL Object |
|------------------|-------------------|
| [dbo].[Products] | products |
| [dbo].[ProductHistory] | producthistory |
| [dbo].[ProductStats] | productstats |
| All column names | lowercase equivalents |
| GETDATE() | clock_timestamp() |
| SCOPE_IDENTITY() | INSERT...RETURNING |
| IDENTITY(1,1) | GENERATED ALWAYS AS IDENTITY |
| decimal(18,2) | NUMERIC(18,2) |
| datetime | TIMESTAMP WITHOUT TIME ZONE |
| nvarchar | VARCHAR |

---

## SQL Scripts Requiring Separate Migration
The following SQL scripts contain SQL Server-specific DDL, stored procedures, and triggers that are NOT executed by the C# application directly. They would need separate PostgreSQL migration if the database schema is being migrated:

- `Scripts/01_InitialSetup.sql` - Basic DDL, stored procedures, sample data
- `Database/Scripts/01_InitialSetup.sql` - Full DDL including tables, indexes, triggers, stored procedures, categories, suppliers, products, and stats

---

## Migration Artifacts

| Artifact | Status |
|----------|--------|
| extracted_statements.sql | ✅ Complete - 7 original SQL statements cataloged |
| converted_statements.sql | ✅ Complete - 7 converted PostgreSQL statements cataloged |
| sql_equivalency_validation_report.json | ✅ Complete - 7 statement pairs with tool results |
| dms_conversion_log.md | ✅ Complete - All DMS tool outputs documented |
| migration_report.md | ✅ Complete - This report |

---

## Build Verification
- **Build Command**: `dotnet build sourceCode/AdoCore.sln`
- **Result**: Build succeeded
- **Errors**: 0
- **Warnings**: 10 (pre-existing nullability warnings, not related to migration)
- **No SQL Server references remain in C# code**
- **No Microsoft.Data.SqlClient references remain**
