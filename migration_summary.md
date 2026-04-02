# Migration Summary: MS SQL Server to PostgreSQL
## AdoCore .NET Application

### Migration Date: 2026-04-02

---

## Overview
This document summarizes the complete migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

## Files Changed

| File | Change Type | Description |
|------|------------|-------------|
| `DataAccess/ProductRepository.cs` | Modified | Replaced all SQL statements with PostgreSQL equivalents, replaced SqlClient with Npgsql |
| `AdoCore.csproj` | Modified | Replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.0 |
| `appsettings.json` | Modified | Updated connection strings to PostgreSQL format |
| `Database/Scripts/01_InitialSetup.sql` | Modified | Converted from T-SQL to PostgreSQL DDL/DML |
| `Scripts/01_InitialSetup.sql` | Modified | Converted from T-SQL to PostgreSQL DDL/DML |
| `README.md` | Modified | Updated documentation for PostgreSQL |
| `extracted_statements.sql` | Created | Catalog of original MS SQL statements |
| `converted_statements.sql` | Created | Catalog of converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Created | Equivalency validation results |

## SQL Statement Conversion Summary

### Inline SQL Statements (ProductRepository.cs)

| # | Method | Type | DMS Result | Equivalency |
|---|--------|------|-----------|-------------|
| 1 | GetAllProductsAsync | CTE + Window Functions | DMS FAILED | ERROR |
| 2 | GetProductByIdAsync | CTE + LAG | DMS FAILED | ERROR |
| 3 | InsertProductAsync | Transaction Block | DMS FAILED | ERROR |
| 4 | UpdateProductAsync | Transaction Block | DMS FAILED | ERROR |
| 5 | DeleteProductAsync | Transaction Block | DMS FAILED | ERROR |
| 6 | GetProductsByPriceRangeAsync | CTE + RANK | DMS FAILED | ERROR |
| 7 | GetLowStockProductsAsync | CTE + Window Functions | DMS FAILED | ERROR |

### DMS Conversion Results
- **Total statements processed**: 7
- **DMS successful conversions**: 0
- **DMS failed conversions**: 7
- **DMS failure reason**: "Metadata model creation failed: Metadata model creation did not complete after 15 attempts"
- **Manual conversions applied**: 7 (all with DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)

### SQL Equivalency Validation Results
- **Total pairs validated**: 7
- **Equivalent**: 0
- **Not Equivalent**: 0
- **Error**: 7 (tool returned 'uniqueID' error for all pairs)

### Key SQL Conversions Applied (Manual)
| MS SQL Server | PostgreSQL |
|--------------|------------|
| `SCOPE_IDENTITY()` | `lastval()` |
| `GETDATE()` | `NOW()` |
| `BEGIN TRANSACTION` | `BEGIN` |
| `DECLARE @var TYPE; SET @var = ...` | Subqueries or `lastval()` |
| `[dbo].[TableName]` | `tablename` (lowercase) |
| `IDENTITY(1,1)` | `SERIAL` |
| `[nvarchar](N)` | `VARCHAR(N)` |
| `[bit]` | `BOOLEAN` |
| `[datetime]` | `TIMESTAMP` |
| `SYSTEM_USER` | `CURRENT_USER` |
| `GO` statements | Removed |
| `IF EXISTS (SELECT * FROM sys.objects...)` | `DROP ... IF EXISTS` |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `AFTER INSERT, UPDATE, DELETE` trigger | Separate trigger function + trigger |
| Integer division (`int/int`) | `::numeric` cast |

## Package Dependency Changes

| Original | Replacement |
|----------|------------|
| `Microsoft.Data.SqlClient` 5.1.4 | `Npgsql` 8.0.0 |

## ADO.NET Class Replacements

| Original | Replacement |
|----------|------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `using Microsoft.Data.SqlClient` | `using Npgsql` |

## Connection String Changes

| Parameter | MS SQL Server | PostgreSQL |
|-----------|--------------|------------|
| Server | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Auth | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| Options | `MultipleActiveResultSets=true;TrustServerCertificate=True` | Removed |

## Build Status
- **Final build**: SUCCESS (0 errors, 12 warnings - all pre-existing nullable reference warnings)
