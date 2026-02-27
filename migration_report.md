# Migration Report: Microsoft SQL Server to PostgreSQL

## Overview
- **Application**: AdoCore - .NET ADO Application
- **Source Database**: Microsoft SQL Server (ProductManagement database)
- **Target Database**: PostgreSQL 13
- **Framework**: .NET 9.0
- **Migration Date**: 2026-02-27

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 9 |
| Statements Successfully Converted by DMS MCP Tool | 0 |
| Statements Requiring Manual Intervention (DMS Failure) | 9 |
| Statements Validated as Equivalent | 0 |
| Statements Validated as Non-Equivalent | 0 |
| Statements with Equivalency Validation Errors | 9 |

## DMS Tool Status
- **All 9 statements** were submitted to the DMS MCP tool for conversion
- **All 9 failed** with `AccessDeniedException` - User is not authorized to perform `dms:StartMetadataModelCreation`
- Manual conversion was applied using lowercase schema mapping rules per transformation definition
- Conversion method documented as: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

## SQL Equivalency Tool Status
- **All 9 statement pairs** were submitted to the SQL Equivalency MCP tool
- **All 9 returned ERROR** with error `'uniqueID'`
- Equivalency statuses recorded exactly as returned by tool (not by agent judgment)

## Statements Requiring Manual Review

All 9 statements require manual review due to:
1. DMS tool failure (AccessDeniedException) necessitated manual conversion
2. SQL Equivalency tool returned ERROR for all pairs

### Statement Details

| # | Source | Method | Key Conversions |
|---|--------|--------|-----------------|
| 1 | ProductRepository.cs | GetAllProductsAsync | Lowercase schema objects |
| 2 | ProductRepository.cs | GetProductByIdAsync | Lowercase schema objects |
| 3 | ProductRepository.cs | InsertProductAsync | SCOPE_IDENTITY()→lastval(), GETDATE()→NOW(), BEGIN TRANSACTION→BEGIN |
| 4 | ProductRepository.cs | UpdateProductAsync | DECLARE/@var→subqueries, GETDATE()→NOW() |
| 5 | ProductRepository.cs | DeleteProductAsync | DECLARE/@var→subqueries, GETDATE()→NOW(), reordered operations |
| 6 | ProductRepository.cs | GetProductsByPriceRangeAsync | Lowercase schema objects |
| 7 | ProductRepository.cs | GetLowStockProductsAsync | Lowercase, ::numeric cast for integer division |
| 8 | Database/Scripts/01_InitialSetup.sql | DDL - CREATE TABLE | IDENTITY→SERIAL, NVARCHAR→VARCHAR, BIT→BOOLEAN, DATETIME→TIMESTAMP |
| 9 | Database/Scripts/01_InitialSetup.sql | DML - UPDATE Stats | Lowercase, GETDATE()→NOW(), IsDiscontinued=1→isdiscontinued=TRUE |

## Files Modified

### C# Source Files
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced all 7 SQL statements with PostgreSQL equivalents; replaced SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader; replaced `using Microsoft.Data.SqlClient` → `using Npgsql` |

### Project/Config Files
| File | Changes |
|------|---------|
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.0` |
| `appsettings.json` | Connection strings converted to PostgreSQL format |

### SQL Scripts
| File | Changes |
|------|---------|
| `Database/Scripts/01_InitialSetup.sql` | Full PostgreSQL DDL conversion (tables, triggers, functions, indexes, seed data) |
| `Scripts/01_InitialSetup.sql` | Full PostgreSQL DDL conversion (tables, functions, seed data) |

## Package Dependency Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.0` |

## Connection String Changes

| Before | After |
|--------|-------|
| `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` | `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres` |

### Parameter Mapping
| SQL Server | PostgreSQL | Notes |
|-----------|------------|-------|
| `Server=` | `Host=` | Hostname parameter |
| `Database=` | `Database=` | Unchanged |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` | PostgreSQL auth |
| `MultipleActiveResultSets=true` | Removed | SQL Server specific |
| `TrustServerCertificate=True` | Removed | SQL Server specific |

## SQL Syntax Conversion Rules Applied

| MS SQL Server | PostgreSQL | Applied In |
|--------------|------------|------------|
| `SCOPE_IDENTITY()` | `lastval()` | InsertProductAsync |
| `GETDATE()` | `NOW()` | InsertProductAsync, UpdateProductAsync, DeleteProductAsync, DDL scripts |
| `BEGIN TRANSACTION` | `BEGIN` | InsertProductAsync, UpdateProductAsync, DeleteProductAsync |
| `DECLARE @var TYPE` | Restructured with subqueries | UpdateProductAsync, DeleteProductAsync |
| `SET @var = expr` | Restructured with subqueries/lastval() | InsertProductAsync |
| `IDENTITY(1,1)` | `SERIAL` | DDL scripts |
| `[dbo].[TableName]` | `tablename` (lowercase, no brackets) | DDL scripts |
| `NVARCHAR(n)` | `VARCHAR(n)` | DDL scripts |
| `BIT` | `BOOLEAN` | DDL scripts |
| `DATETIME` | `TIMESTAMP` | DDL scripts |
| `GO` | Removed | DDL scripts |
| `SYSTEM_USER` | `current_user` | Trigger function |
| Stored Procedures | PostgreSQL Functions (`LANGUAGE plpgsql`) | DDL scripts |
| SQL Server Trigger | PostgreSQL Trigger Function + TRIGGER | DDL scripts |

## Migration Artifacts

| Artifact | Location | Status |
|----------|----------|--------|
| `extracted_statements.sql` | sourceCode/ | Complete (7 original SQL statements) |
| `converted_statements.sql` | sourceCode/ | Complete (7 converted PostgreSQL statements) |
| `sql_equivalency_validation_report.json` | sourceCode/ | Complete (9 statement pairs with tool results) |
| `migration_report.md` | sourceCode/ | This file |

## Build Status
- **Final Build**: ✅ SUCCESS (0 errors, 10 warnings - all pre-existing nullable reference warnings)
- **No SQL Server references remain** in any .cs files
- **All SQL statements** use PostgreSQL syntax
- **Connection strings** use PostgreSQL format
- **Package references** use Npgsql instead of Microsoft.Data.SqlClient
