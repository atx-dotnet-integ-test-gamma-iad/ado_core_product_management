# SQL Server to PostgreSQL Migration - DMS Conversion Summary

## Migration Details
- **Source**: SQL Server 2019 (ProductManagement database)
- **Target**: PostgreSQL 13
- **DMS Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Migration Date**: 2026-05-08

## DMS Tool Status
**ALL DMS conversions FAILED** with consistent error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

All 7 SQL statements were submitted to the DMS MCP tool and all returned the same error.
Manual conversion was applied using lowercase schema object naming conventions per transformation instructions.

## SQL Equivalency Tool Status
**ALL equivalency validations returned ERROR** with consistent error:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

All 7 statement pairs were submitted to the SQL Equivalency tool and all returned the same infrastructure error.
Per transformation instructions, these are marked as ERROR status.

## Statement Conversion Summary

| # | Method | Source Location | SQL Type | Key Changes |
|---|--------|----------------|----------|-------------|
| 1 | GetAllProductsAsync | ProductRepository.cs | SELECT with CTE | Lowercase schema objects |
| 2 | GetProductByIdAsync | ProductRepository.cs | SELECT with CTE + LAG | Lowercase schema objects |
| 3 | InsertProductAsync | ProductRepository.cs | INSERT + Transaction | SCOPE_IDENTITY() → RETURNING, GETDATE() → NOW(), transaction managed in application |
| 4 | UpdateProductAsync | ProductRepository.cs | UPDATE + Transaction | DECLARE vars → application variables, GETDATE() → NOW(), transaction managed in application |
| 5 | DeleteProductAsync | ProductRepository.cs | DELETE + Transaction | DECLARE vars → application variables, GETDATE() → NOW(), transaction managed in application |
| 6 | GetProductsByPriceRangeAsync | ProductRepository.cs | SELECT with CTE + RANK | Lowercase schema objects |
| 7 | GetLowStockProductsAsync | ProductRepository.cs | SELECT with CTE + AVG | Lowercase schema objects, added ::numeric cast for integer division |

## Key Conversion Patterns Applied

### SQL Server → PostgreSQL Mappings:
1. **SCOPE_IDENTITY()** → **RETURNING clause** (PostgreSQL's native way to return inserted row data)
2. **GETDATE()** → **NOW()** (PostgreSQL timestamp function)
3. **BEGIN TRANSACTION / COMMIT** → Application-level `NpgsqlTransaction` (better PostgreSQL pattern)
4. **DECLARE @var / SET @var** → Application-level C# variables with separate queries
5. **NVARCHAR** → **VARCHAR** (PostgreSQL doesn't have NVARCHAR, VARCHAR handles Unicode natively)
6. **IDENTITY(1,1)** → **SERIAL** (PostgreSQL auto-increment)
7. **BIT** → **BOOLEAN** (PostgreSQL native boolean type)
8. **DATETIME/DATETIME2** → **TIMESTAMP** (PostgreSQL timestamp type)
9. **[dbo].** schema prefix → removed (using default public schema)
10. **GO** batch separator → removed (not needed in PostgreSQL)
11. **SET NOCOUNT ON** → removed (not applicable to PostgreSQL)
12. **CREATE OR ALTER PROCEDURE** → **CREATE OR REPLACE FUNCTION** (PostgreSQL uses functions)
13. **SYSTEM_USER** → **current_user** (PostgreSQL equivalent)
14. **IF EXISTS (SELECT * FROM sys.objects...)** → **DROP IF EXISTS** (PostgreSQL pattern)
15. **CREATE TRIGGER ... AFTER INSERT, UPDATE, DELETE** → Trigger function + CREATE TRIGGER with FOR EACH ROW

## Files Modified
1. `sourceCode/DataAccess/ProductRepository.cs` - All SQL statements converted, SqlClient → Npgsql
2. `sourceCode/AdoCore.csproj` - Microsoft.Data.SqlClient → Npgsql package reference
3. `sourceCode/appsettings.json` - SQL Server connection string → PostgreSQL connection string
4. `sourceCode/Database/Scripts/01_InitialSetup.sql` - Full schema conversion to PostgreSQL
5. `sourceCode/Scripts/01_InitialSetup.sql` - Simplified schema conversion to PostgreSQL

## Final Statistics
- **Total SQL statements processed**: 7
- **Statements successfully converted by DMS**: 0
- **Statements requiring manual intervention after DMS failure**: 7
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 7 (tool infrastructure error)
