# SQL Server to PostgreSQL Migration Report

## Summary
This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

## Migration Statistics

### In-Code SQL Statements (ProductRepository.cs)
| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| DMS conversion attempts | 7 (all 7 + additional retries) |
| DMS conversion successes | 0 |
| DMS conversion failures | 7 |
| Manual conversions performed | 7 |
| Conversion method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |

### SQL Equivalency Validation Results
| Metric | Count |
|--------|-------|
| Total statement pairs validated | 7 |
| EQUIVALENT results | 0 |
| NOT_EQUIVALENT results | 0 |
| ERROR results | 7 |
| Tool error details | All returned `'uniqueID'` error |

### DDL Script Statements
| Metric | Count |
|--------|-------|
| Database/Scripts/01_InitialSetup.sql statements converted | ~25 (CREATE TABLE, triggers, stored procedures, INSERTs, etc.) |
| Scripts/01_InitialSetup.sql statements converted | ~10 (CREATE TABLE, stored procedures, INSERTs) |

## DMS Tool Failure Details
The DMS MCP tool (dms-mcp___statement_conversion_tool) was attempted for all SQL statements but consistently failed with:
- **Error**: `Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}`
- **Migration Project**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Server**: `172.31.83.165`
- **Multiple retry strategies were attempted**: increased poll attempts (30), increased poll intervals (15s), simplified SQL statements

All statements were subsequently converted manually with lowercase schema object naming convention per the transformation rules.

## SQL Equivalency Tool Results
The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) was invoked for all 7 statement pairs.
All returned ERROR status with error `'uniqueID'`. Per transformation rules, these are recorded as ERROR (not determined by agent judgment).

## Key SQL Syntax Conversions Applied

### In-Code Statements
| MS SQL Server | PostgreSQL | Applied In |
|--------------|-----------|------------|
| `SCOPE_IDENTITY()` | `INSERT...RETURNING productid` | Statement 3 (InsertProductAsync) |
| `GETDATE()` | `NOW()` | Statements 3, 4, 5 |
| `DECLARE @var / SET @var` | C# variables + separate SQL commands | Statements 3, 4, 5 |
| `BEGIN TRANSACTION / COMMIT` | C# `BeginTransactionAsync()` / `CommitAsync()` | Statements 3, 4, 5 |
| Table/column names (PascalCase) | lowercase | All 7 statements |
| `StockQuantity / AvgStock` (integer division) | `stockquantity::numeric / avgstock` | Statement 7 |

### DDL Script Conversions
| MS SQL Server | PostgreSQL |
|--------------|-----------|
| `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` |
| `[dbo].[tablename]` | `tablename` (lowercase) |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `[bit]` | `BOOLEAN` |
| `GETDATE()` | `NOW()` |
| `IF EXISTS (SELECT * FROM sys.objects...)` | `DROP TABLE IF EXISTS` |
| `GO` batch separators | Removed |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `CREATE TRIGGER...AS BEGIN...END` | PostgreSQL trigger function + trigger |
| `SYSTEM_USER` | `CURRENT_USER` |
| `SET NOCOUNT ON` | Removed (not applicable) |
| `EXEC sp_name` | `PERFORM sp_name()` |

### Package/Configuration Changes
| Component | Before | After |
|-----------|--------|-------|
| NuGet Package | `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 9.0.3` |
| Using Statement | `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| Connection Class | `SqlConnection` | `NpgsqlConnection` |
| Command Class | `SqlCommand` | `NpgsqlCommand` |
| Reader Class | `SqlDataReader` | `NpgsqlDataReader` |
| Connection String | `Server=localhost;Database=...;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` | `Host=localhost;Port=5432;Database=...;Username=postgres;Password=password` |

## Files Modified
| File | Changes |
|------|---------|
| `sourceCode/DataAccess/ProductRepository.cs` | All 7 SQL statements replaced with PostgreSQL equivalents; all ADO.NET classes updated to Npgsql |
| `sourceCode/AdoCore.csproj` | Microsoft.Data.SqlClient → Npgsql 9.0.3 |
| `sourceCode/appsettings.json` | Connection strings updated to PostgreSQL format |
| `sourceCode/Database/Scripts/01_InitialSetup.sql` | Full conversion from SQL Server DDL to PostgreSQL |
| `sourceCode/Scripts/01_InitialSetup.sql` | Full conversion from SQL Server DDL to PostgreSQL |

## Artifacts Generated
| Artifact | Description |
|----------|-------------|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | JSON report with all 7 equivalency validation results |
| `dms_failure_log.sql` | Documentation of all DMS tool failures |
| `migration_report.md` | This report |

## Manual Interventions Required
All 7 in-code SQL statements required manual conversion due to DMS tool infrastructure timeout. Each conversion applied:
1. Lowercase schema object names (tables, columns, aliases)
2. PostgreSQL-specific function replacements (GETDATE→NOW, SCOPE_IDENTITY→RETURNING)
3. Transaction block restructuring for ADO.NET compatibility

## Schema Name Changes
All schema object names were converted to lowercase per PostgreSQL conventions:
- `Products` → `products`
- `ProductHistory` → `producthistory`
- `ProductStats` → `productstats`
- `Categories` → `categories`
- `Suppliers` → `suppliers`
- All column names similarly lowercased

## Build Status
- **Final build**: ✅ Success (0 errors, 10 warnings - all pre-existing nullable reference warnings)
