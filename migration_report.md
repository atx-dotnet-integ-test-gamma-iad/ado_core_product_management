# SQL Server to PostgreSQL Migration Report

## Summary

This report documents the complete migration of the ADO.NET Core application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-02-28  
**Source Database:** Microsoft SQL Server 2019  
**Target Database:** PostgreSQL 13  
**Application Framework:** .NET 9.0 with ADO.NET  

## SQL Statement Processing

### Overview

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 19 |
| Statements from C# code (ProductRepository.cs) | 7 |
| Statements from SQL scripts | 12 |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention (DMS failure) | 19 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| Equivalency validation errors | 19 |

### DMS Tool Status

All 19 SQL statements were submitted to the AWS DMS MCP tool for conversion. All attempts failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

This appears to be a transient infrastructure issue with the DMS metadata model creation service. All statements were subsequently converted manually using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` policy.

### SQL Equivalency Tool Status

All 19 statement pairs were submitted to the SQL Equivalency validation tool. All returned ERROR with:

```
{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}
```

This appears to be a tool infrastructure issue. All equivalency statuses are marked as ERROR per the transformation policy (no agent judgment used for equivalency determination).

### C# Code SQL Statements (7 statements)

| # | Method | Type | Key Conversions |
|---|--------|------|-----------------|
| 1 | GetAllProductsAsync | CTE + SELECT | Schema objects to lowercase |
| 2 | GetProductByIdAsync | CTE + SELECT | Schema objects to lowercase |
| 3 | InsertProductAsync | Transaction block | SCOPE_IDENTITY() → RETURNING, GETDATE() → NOW(), DECLARE removed, transaction restructured to C# |
| 4 | UpdateProductAsync | Transaction block | GETDATE() → NOW(), DECLARE removed, old values fetched via separate query |
| 5 | DeleteProductAsync | Transaction block | GETDATE() → NOW(), DECLARE removed, old values fetched via separate query |
| 6 | GetProductsByPriceRangeAsync | CTE + SELECT | Schema objects to lowercase |
| 7 | GetLowStockProductsAsync | CTE + SELECT | Schema objects to lowercase, CAST for integer division fix |

### SQL Script Statements (12 statements)

| # | Source | Type | Key Conversions |
|---|--------|------|-----------------|
| 8 | Database/Scripts | CREATE TABLE Products | IDENTITY → SERIAL, NVARCHAR → VARCHAR, DATETIME → TIMESTAMP, GETDATE() → NOW() |
| 9 | Database/Scripts | CREATE TABLE Categories | Same as above |
| 10 | Database/Scripts | CREATE TABLE Suppliers | BIT → BOOLEAN, DEFAULT 1 → DEFAULT TRUE |
| 11 | Database/Scripts | CREATE TABLE ProductHistory | Same as Products |
| 12 | Database/Scripts | CREATE TABLE ProductStats | Same as Products |
| 13 | Database/Scripts | sp_GetAllProducts | CREATE OR ALTER PROCEDURE → CREATE OR REPLACE FUNCTION |
| 14 | Database/Scripts | sp_GetProductById | Same as above |
| 15 | Database/Scripts | sp_InsertProduct | SCOPE_IDENTITY() → RETURNING clause |
| 16 | Database/Scripts | sp_UpdateProduct | GETDATE() → NOW() in function |
| 17 | Database/Scripts | sp_DeleteProduct | Procedure → Function conversion |
| 18 | Database/Scripts | trg_Products_History | Single trigger → 3 row-level triggers, INSERTED/DELETED → NEW/OLD, SYSTEM_USER → current_user |
| 19 | Database/Scripts | UPDATE ProductStats | IsDiscontinued = 1 → isdiscontinued = TRUE, GETDATE() → NOW() |

## Files Modified

### Source Code Files
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL; SqlClient → Npgsql types |
| `AdoCore.csproj` | Microsoft.Data.SqlClient v5.1.4 → Npgsql v8.0.1 |
| `appsettings.json` | Connection strings converted to PostgreSQL format |
| `README.md` | Documentation updated for PostgreSQL |

### SQL Script Files
| File | Changes |
|------|---------|
| `Scripts/01_InitialSetup.sql` | Fully converted to PostgreSQL DDL/DML syntax |
| `Database/Scripts/01_InitialSetup.sql` | Fully converted to PostgreSQL DDL/DML/trigger/function syntax |

### New Artifacts
| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements from C# code |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Complete equivalency validation report for all 19 statement pairs |
| `migration_report.md` | This report |

## Package Dependency Changes

| Original | Replacement |
|----------|-------------|
| Microsoft.Data.SqlClient v5.1.4 | Npgsql v8.0.1 |

Unchanged packages:
- Microsoft.Extensions.Configuration v8.0.0
- Microsoft.Extensions.Configuration.Json v8.0.0
- Microsoft.Extensions.DependencyInjection v8.0.0

## Connection String Changes

| Setting | SQL Server | PostgreSQL |
|---------|------------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres;` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| Certificate | `TrustServerCertificate=True` | Removed (not applicable) |

## ADO.NET Class Replacements

| SQL Server Class | PostgreSQL (Npgsql) Class |
|-----------------|--------------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlTransaction` | `NpgsqlTransaction` |
| `Microsoft.Data.SqlClient` (using) | `Npgsql` (using) |

## SQL Syntax Conversions Applied

| SQL Server | PostgreSQL | Context |
|------------|-----------|---------|
| `IDENTITY(1,1)` | `SERIAL` | Table columns |
| `GETDATE()` | `NOW()` | Date/time defaults and expressions |
| `SCOPE_IDENTITY()` | `RETURNING` clause | Insert returning new ID |
| `NVARCHAR(n)` | `VARCHAR(n)` | String columns |
| `BIT` | `BOOLEAN` | Boolean columns |
| `DEFAULT 1` / `DEFAULT 0` (BIT) | `DEFAULT TRUE` / `DEFAULT FALSE` | Boolean defaults |
| `DATETIME` | `TIMESTAMP` | Date/time columns |
| `BEGIN TRANSACTION / COMMIT` | C# `BeginTransactionAsync()` / `CommitAsync()` | Inline transactions |
| `DECLARE @var` | C# variables | Variable declarations |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` | Stored procedures |
| `INSERTED` / `DELETED` pseudo-tables | `NEW` / `OLD` trigger variables | Triggers |
| `SYSTEM_USER` | `current_user` | User context |
| `GO` delimiter | Removed | Script batching |
| `sys.databases` / `sys.objects` checks | PostgreSQL equivalents / `IF NOT EXISTS` | Conditional creation |

## Completeness Checklist

- [x] All `SqlConnection` → `NpgsqlConnection`
- [x] All `SqlCommand` → `NpgsqlCommand`
- [x] All `SqlDataReader` → `NpgsqlDataReader`
- [x] All `SqlTransaction` → `NpgsqlTransaction`
- [x] `Microsoft.Data.SqlClient` → `Npgsql` package
- [x] All 7 C# SQL statements converted to PostgreSQL
- [x] All SQL scripts converted to PostgreSQL
- [x] All connection strings updated
- [x] README.md updated for PostgreSQL
- [x] Build succeeds with zero errors
- [x] `extracted_statements.sql` created with all original statements
- [x] `converted_statements.sql` created with all converted statements
- [x] `sql_equivalency_validation_report.json` complete with all 19 statement pairs

## Statements Requiring Manual Review

All 19 statements require manual review because:
1. DMS MCP tool was unavailable (infrastructure error) - all conversions were done manually
2. SQL Equivalency tool returned ERROR for all pairs (infrastructure error) - equivalency unverified

**Recommendation:** Manually verify the SQL equivalency of all 19 converted statements against the originals before deploying to production.

## Build Status

**Final Build: SUCCESS**
- 0 Errors
- 12 Warnings (pre-existing nullable reference warnings - not related to migration)
