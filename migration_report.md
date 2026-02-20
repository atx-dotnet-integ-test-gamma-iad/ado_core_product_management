# Migration Report: MS SQL Server to PostgreSQL

## Summary
Migration of ADO.NET application from Microsoft SQL Server to PostgreSQL, including conversion of all SQL statements, ADO.NET class replacements, connection string updates, and SQL script file conversions.

## Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 18 |
| Statements from C# code (ProductRepository.cs) | 7 |
| Statements from SQL scripts | 11 |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention (DMS failure) | 18 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| With equivalency validation errors | 18 |

## DMS Tool Status
- **Status**: All calls failed
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Total DMS attempts**: 8 (7 for code statements, 1 for script statement representative)
- **Conversion Method Applied**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## SQL Equivalency Tool Status
- **Status**: All calls returned ERROR
- **Error**: 'uniqueID' (consistent across all 18 calls)
- **Note**: The equivalency tool failure is independent of DMS - it was called for every statement pair as required

## Files Modified

### Source Code Files
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced `using Microsoft.Data.SqlClient` → `using Npgsql`; Replaced SqlConnection → NpgsqlConnection, SqlCommand → NpgsqlCommand, SqlDataReader → NpgsqlDataReader; Replaced all 7 SQL statements with PostgreSQL equivalents |
| `AdoCore.csproj` | Already had Npgsql 8.0.3 reference (no change needed) |
| `appsettings.json` | Already had PostgreSQL connection string format (no change needed) |

### SQL Script Files
| File | Changes |
|------|---------|
| `Scripts/01_InitialSetup.sql` | Converted from MS SQL to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Converted from MS SQL to PostgreSQL syntax |

### Transformation Artifacts Created
| File | Description |
|------|-------------|
| `extracted_statements.sql` | Complete catalog of all 18 original MS SQL statements |
| `converted_statements.sql` | Complete catalog of all 18 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive validation report with all 18 pairs |
| `dms_failure_summary.md` | Detailed DMS failure documentation |
| `migration_report.md` | This file |

## Detailed Statement Conversion Log

### Code Statements (ProductRepository.cs)

#### Statement 1: GetAllProductsAsync
- **Source**: ProductRepository.cs, GetAllProductsAsync method
- **Type**: CTE with window functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND
- **DMS Status**: FAILED
- **Manual Conversion**: Lowercased all schema objects
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

#### Statement 2: GetProductByIdAsync
- **Source**: ProductRepository.cs, GetProductByIdAsync method
- **Type**: CTE with LAG window function, LEFT JOIN, CASE with ROUND
- **DMS Status**: FAILED
- **Manual Conversion**: Lowercased all schema objects
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

#### Statement 3: InsertProductAsync
- **Source**: ProductRepository.cs, InsertProductAsync method
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE()
- **DMS Status**: FAILED
- **Manual Conversion**: Converted to writable CTE with RETURNING clause; SCOPE_IDENTITY() → RETURNING; GETDATE() → NOW(); Lowercased schema objects
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

#### Statement 4: UpdateProductAsync
- **Source**: ProductRepository.cs, UpdateProductAsync method
- **Type**: Transaction block with DECLARE variables, UPDATE, INSERT history, UPDATE stats
- **DMS Status**: FAILED
- **Manual Conversion**: Converted to writable CTE with old_values subquery; GETDATE() → NOW(); Lowercased schema objects
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

#### Statement 5: DeleteProductAsync
- **Source**: ProductRepository.cs, DeleteProductAsync method
- **Type**: Transaction block with DECLARE variables, INSERT history, DELETE, UPDATE stats with CASE
- **DMS Status**: FAILED
- **Manual Conversion**: Converted to writable CTE with old_values subquery; GETDATE() → NOW(); Lowercased schema objects
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

#### Statement 6: GetProductsByPriceRangeAsync
- **Source**: ProductRepository.cs, GetProductsByPriceRangeAsync method
- **Type**: CTE with RANK and PERCENT_RANK window functions, BETWEEN, CASE
- **DMS Status**: FAILED
- **Manual Conversion**: Lowercased all schema objects
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

#### Statement 7: GetLowStockProductsAsync
- **Source**: ProductRepository.cs, GetLowStockProductsAsync method
- **Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **DMS Status**: FAILED
- **Manual Conversion**: Added CAST for integer division in ROUND; Lowercased schema objects
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

### Script Statements (Database/Scripts/01_InitialSetup.sql)

#### Statement 8: CREATE TABLE Categories
- **Conversion**: INT IDENTITY → SERIAL, NVARCHAR → VARCHAR, DATETIME → TIMESTAMP, GETDATE() → NOW()
- **Equivalency Status**: ERROR

#### Statement 9: CREATE TABLE Suppliers
- **Conversion**: INT IDENTITY → SERIAL, NVARCHAR → VARCHAR, BIT → BOOLEAN, DATETIME → TIMESTAMP, GETDATE() → NOW()
- **Equivalency Status**: ERROR

#### Statement 10: CREATE TABLE Products
- **Conversion**: INT IDENTITY → SERIAL, NVARCHAR → VARCHAR, BIT → BOOLEAN, DATETIME → TIMESTAMP, GETDATE() → NOW()
- **Equivalency Status**: ERROR

#### Statement 11: CREATE TABLE ProductHistory
- **Conversion**: INT IDENTITY → SERIAL, NVARCHAR → VARCHAR, DATETIME → TIMESTAMP, GETDATE() → NOW()
- **Equivalency Status**: ERROR

#### Statement 12: CREATE TABLE ProductStats
- **Conversion**: DATETIME → TIMESTAMP, GETDATE() → NOW()
- **Equivalency Status**: ERROR

#### Statement 13: UPDATE ProductStats (initial statistics)
- **Conversion**: Schema objects lowercased, GETDATE() → NOW(), IsDiscontinued = 1 → isdiscontinued = TRUE
- **Equivalency Status**: ERROR

#### Statement 14: sp_GetAllProducts
- **Conversion**: CREATE OR ALTER PROCEDURE → CREATE OR REPLACE FUNCTION, SET NOCOUNT ON removed
- **Equivalency Status**: ERROR

#### Statement 15: sp_GetProductById
- **Conversion**: CREATE OR ALTER PROCEDURE → CREATE OR REPLACE FUNCTION, @param → p_param
- **Equivalency Status**: ERROR

#### Statement 16: sp_InsertProduct
- **Conversion**: CREATE OR ALTER PROCEDURE → CREATE OR REPLACE FUNCTION, SCOPE_IDENTITY() → RETURNING
- **Equivalency Status**: ERROR

#### Statement 17: sp_UpdateProduct
- **Conversion**: CREATE OR ALTER PROCEDURE → CREATE OR REPLACE FUNCTION, GETDATE() → NOW()
- **Equivalency Status**: ERROR

#### Statement 18: sp_DeleteProduct
- **Conversion**: CREATE OR ALTER PROCEDURE → CREATE OR REPLACE FUNCTION
- **Equivalency Status**: ERROR

## Key Conversion Rules Applied

| MS SQL Server | PostgreSQL |
|---------------|------------|
| `INT IDENTITY(1,1)` | `SERIAL` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `DATETIME` | `TIMESTAMP` |
| `BIT` | `BOOLEAN` |
| `GETDATE()` | `NOW()` |
| `SCOPE_IDENTITY()` | `RETURNING` clause |
| `DECLARE @var` | Writable CTE / function DECLARE |
| `BEGIN TRANSACTION / COMMIT` | Writable CTE (single statement atomicity) |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `SET NOCOUNT ON` | Removed (not needed in PostgreSQL) |
| `SYSTEM_USER` | `current_user` |
| `IF NOT EXISTS (SELECT * FROM sys.objects ...)` | `DROP IF EXISTS` / `CREATE TABLE IF NOT EXISTS` |
| `GO` batch separator | Removed (not needed in PostgreSQL) |
| Schema `[dbo].[TableName]` | Lowercase `tablename` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `Microsoft.Data.SqlClient` | `Npgsql` |

## Build Status
- **Build Result**: SUCCESS
- **Errors**: 0
- **Warnings**: 10 (pre-existing nullable reference type warnings, not caused by migration)

## Statements Requiring Manual Review
All 18 statements require manual review because:
1. DMS tool failed for all conversions (infrastructure error)
2. SQL Equivalency tool returned ERROR for all validations (infrastructure error)
3. Manual conversions were applied with lowercase schema object naming convention

**CRITICAL**: The transaction block conversions (Statements 3, 4, 5) used writable CTEs which is a PostgreSQL-specific feature. These should be tested against a live PostgreSQL database to verify correct behavior.
