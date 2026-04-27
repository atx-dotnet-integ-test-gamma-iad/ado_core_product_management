# Migration Report: SQL Server to PostgreSQL

## Overview
- **Application**: AdoCore (.NET ADO.NET Application)
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Migration Date**: 2026-04-27
- **Migration Method**: DMS MCP Tool (attempted) + Manual Conversion (fallback)

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS MCP Tool | 0 |
| Required Manual Intervention (DMS Failure) | 7 |
| Validated as Equivalent (SQL Equivalency Tool) | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Validation Errors | 7 |

### DMS Tool Status
- **All 7 statements were submitted to the DMS MCP tool** (migration project: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`)
- **All 7 failed** with error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual conversion applied** with reason: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### SQL Equivalency Tool Status
- **All 7 statement pairs were submitted to the SQL Equivalency tool**
- **All 7 returned ERROR** with error: `'uniqueID'`
- **Equivalency statuses are from the tool only** - no agent judgment was used

---

## SQL Statement Details

### Statement 1: GetAllProductsAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetAllProductsAsync()` method
- **Type**: CTE with window functions (AVG OVER, COUNT OVER), CASE, ROUND, JOIN, ORDER BY
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: All schema objects lowercase
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 2: GetProductByIdAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetProductByIdAsync()` method
- **Type**: CTE with LAG window function, ROUND, CASE, LEFT JOIN
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: All schema objects lowercase
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 3: InsertProductAsync
- **Source**: `DataAccess/ProductRepository.cs` - `InsertProductAsync()` method
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: SCOPE_IDENTITY() → RETURNING clause, GETDATE() → NOW(), DECLARE/SET → CTE with RETURNING, Transaction → Writeable CTE, Lowercase schema
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 4: UpdateProductAsync
- **Source**: `DataAccess/ProductRepository.cs` - `UpdateProductAsync()` method
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT history
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: DECLARE/SET → CTE subquery, GETDATE() → NOW(), Transaction → Writeable CTE, Lowercase schema
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 5: DeleteProductAsync
- **Source**: `DataAccess/ProductRepository.cs` - `DeleteProductAsync()` method
- **Type**: Transaction block with DECLARE, SELECT, INSERT history, DELETE, UPDATE stats with CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: DECLARE/SET → CTE subquery, GETDATE() → NOW(), Transaction → Writeable CTE, Lowercase schema
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetProductsByPriceRangeAsync()` method
- **Type**: CTE with RANK, PERCENT_RANK window functions, BETWEEN, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: All schema objects lowercase
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 7: GetLowStockProductsAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetLowStockProductsAsync()` method
- **Type**: CTE with AVG/MIN/MAX OVER() window aggregates, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: All schema objects lowercase, CAST for integer division in ROUND
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL; `using Microsoft.Data.SqlClient` → `using Npgsql`; `SqlConnection` → `NpgsqlConnection`; `SqlCommand` → `NpgsqlCommand`; `SqlDataReader` → `NpgsqlDataReader` |
| `AdoCore.csproj` | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6` |
| `appsettings.json` | Connection strings updated from SQL Server format to PostgreSQL format |

## Package Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.6 |

Note: Npgsql upgraded from plan-specified v8.0.1 to v8.0.6 to address known high severity vulnerability (GHSA-x9vc-6hfv-hg8c).

## Class Replacements

| SQL Server Class | PostgreSQL (Npgsql) Class | Occurrences |
|-----------------|--------------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

## Connection String Changes

| Parameter | Before (SQL Server) | After (PostgreSQL) |
|-----------|--------------------|--------------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

---

## Statements Requiring Manual Review

All 7 statements require manual review because:
1. DMS MCP tool failed for all conversions (metadata model creation error)
2. SQL Equivalency tool returned ERROR for all validations ('uniqueID' error)
3. Manual conversions were applied with lowercase schema naming convention

### Specific Areas for Review:
- **Statements 3, 4, 5 (Insert, Update, Delete)**: These were significantly restructured from SQL Server transaction blocks with DECLARE/SET variables to PostgreSQL writeable CTEs. The structural changes need careful validation against actual PostgreSQL execution.
- **Statement 7 (GetLowStockProducts)**: Added CAST(stockquantity AS NUMERIC) for integer division compatibility in ROUND function.

---

## Transformation Artifacts

| Artifact | Description | Location |
|----------|-------------|----------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements | Project root |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements | Project root |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency report (JSON) | Project root |
| `dms_conversion_log.md` | Detailed DMS tool output log | Project root |
| `migration_report.md` | This report | Project root |

---

## Build Status
- **Final Build**: SUCCESS (0 errors, 10 warnings)
- **Warnings**: All pre-existing CS8601/CS8618 nullable reference warnings (not introduced by migration)
- **Vulnerable Packages**: None (verified with `dotnet list --vulnerable`)
