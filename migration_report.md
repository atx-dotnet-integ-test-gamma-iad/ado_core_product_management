# SQL Server to PostgreSQL Migration Report

## Summary
- **Project**: AdoCore - Product Management System
- **Source Database**: SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-05-09
- **DMS Migration Project ARN**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

## SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements submitted to DMS MCP tool | 7 |
| Statements successfully converted by DMS | 0 |
| Statements requiring manual conversion (DMS failure) | 7 |
| Statements validated as equivalent (SQL Equivalency tool) | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

## DMS Tool Failure Details

All 7 SQL statements were submitted to the DMS MCP Statement Conversion tool. All failed with the same error:

```
Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

The DMS tool was unable to create the metadata model required for conversion. This appears to be a service-side issue with the DMS migration project.

## SQL Equivalency Tool Results

All 7 statement pairs were submitted to the SQL Equivalency validation tool. All returned ERROR:

```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be a configuration or connectivity issue with the SQL Equivalency tool service.

## Manual Conversion Methodology

Since DMS failed for all statements, manual conversion was performed applying the following rules per the transformation instructions (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA):

1. **Schema object names** converted to lowercase (tables, columns, aliases, CTEs)
2. **SCOPE_IDENTITY()** → `RETURNING productid` clause
3. **GETDATE()** → `NOW()`
4. **BEGIN TRANSACTION / COMMIT** → ADO.NET programmatic transaction (BeginTransactionAsync/CommitAsync)
5. **DECLARE @variable / SET @variable** → C# variables with separate SELECT INTO queries
6. **NVARCHAR** → `VARCHAR` in PostgreSQL
7. **DATETIME** → `TIMESTAMP` in PostgreSQL
8. **INT IDENTITY(1,1)** → `SERIAL` in PostgreSQL
9. **Window functions** (AVG OVER, LAG, RANK, PERCENT_RANK, COUNT OVER, MIN OVER, MAX OVER) → Same syntax, compatible with PostgreSQL
10. **CTEs** → Same syntax, compatible with PostgreSQL

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced Microsoft.Data.SqlClient with Npgsql; converted all 7 SQL statements; restructured transaction blocks |
| `AdoCore.csproj` | Replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.1 |
| `appsettings.json` | Updated connection strings from SQL Server format to PostgreSQL format |

## Artifacts Generated

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Complete catalog of all original MS SQL statements |
| `converted_statements.sql` | Complete catalog of all converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `migration_report.md` | This report |

## Detailed Statement Conversion Log

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE and window functions
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**: Lowercase schema objects; no SQL Server-specific functions to convert
- **Equivalency Check**: ERROR - Tool returned 'uniqueID' error

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG window function
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**: Lowercase schema objects; no SQL Server-specific functions to convert
- **Equivalency Check**: ERROR - Tool returned 'uniqueID' error

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY, GETDATE
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**: SCOPE_IDENTITY() → RETURNING; GETDATE() → NOW(); Transaction block → ADO.NET transaction with separate commands
- **Equivalency Check**: ERROR - Tool returned 'uniqueID' error

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variable, UPDATE, INSERT, GETDATE
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**: GETDATE() → NOW(); DECLARE/SET → C# variables; Transaction → ADO.NET transaction
- **Equivalency Check**: ERROR - Tool returned 'uniqueID' error

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variable, INSERT, DELETE, CASE, GETDATE
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**: GETDATE() → NOW(); DECLARE/SET → C# variables; Transaction → ADO.NET transaction
- **Equivalency Check**: ERROR - Tool returned 'uniqueID' error

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK, PERCENT_RANK window functions
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**: Lowercase schema objects; no SQL Server-specific functions to convert
- **Equivalency Check**: ERROR - Tool returned 'uniqueID' error

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**: Lowercase schema objects; no SQL Server-specific functions to convert
- **Equivalency Check**: ERROR - Tool returned 'uniqueID' error

## Static Code Changes

### Package References
- **Removed**: `Microsoft.Data.SqlClient` v5.1.4
- **Added**: `Npgsql` v8.0.1

### ADO.NET Class Replacements
| Original (SQL Server) | Replacement (PostgreSQL) |
|----------------------|--------------------------|
| `Microsoft.Data.SqlClient` (namespace) | `Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |

### Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Auth | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| Extra | `MultipleActiveResultSets=true;TrustServerCertificate=True` | (removed - not applicable) |

### Transaction Handling
- SQL Server inline `BEGIN TRANSACTION`/`COMMIT` blocks converted to ADO.NET programmatic transactions using `BeginTransactionAsync()`/`CommitAsync()`/`RollbackAsync()`
- SQL Server `DECLARE @variable` blocks restructured to use C# variables with separate SQL queries
