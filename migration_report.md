# Migration Report: MS SQL Server to PostgreSQL for AdoCore .NET Application

## Overview
- **Application**: AdoCore - .NET 9.0 ADO.NET application
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Method**: DMS MCP Tool (attempted) + Manual Conversion with Lowercase Schema Mapping

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS MCP Tool** | 0 |
| **Required Manual Intervention after DMS Failure** | 7 |
| **Validated as Equivalent (by SQL Equivalency Tool)** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |

### DMS Tool Status
All 7 SQL statements were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`). 
All 7 failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

DMS Configuration used:
- **Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Database**: ProductManagement
- **Schema**: dbo
- **Region**: us-east-1
- **Server**: 172.31.83.165

### Manual Conversion Applied
All 7 statements were manually converted with reason code: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

Key conversions applied:
- All schema object names converted to lowercase (PostgreSQL convention)
- `SCOPE_IDENTITY()` → `INSERT ... RETURNING productid`
- `GETDATE()` → `NOW()`
- `BEGIN TRANSACTION / COMMIT` → C# managed transaction with `BeginTransactionAsync() / CommitAsync()`
- `DECLARE @variable` → C# local variables with separate SQL SELECT queries
- Window functions (AVG/COUNT/LAG/RANK/PERCENT_RANK/MIN/MAX OVER) preserved (PostgreSQL compatible)
- CASE expressions preserved (PostgreSQL compatible)
- ROUND function preserved (with `::numeric` cast where needed for integer division)

### SQL Equivalency Validation Status
All 7 statement pairs were validated through the `sql-equivalency___validate_sql_equivalence` tool.
All 7 returned ERROR status with error: `'uniqueID'`

**Note**: No agent judgment was used for equivalency determination. All equivalency statuses came exclusively from the SQL Equivalency tool output.

---

## Detailed Statement List

### Statement 1: GetAllProductsAsync
- **Location**: `DataAccess/ProductRepository.cs` - `GetAllProductsAsync()` method
- **Type**: CTE with window functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **DMS Status**: FAILED
- **Manual Conversion**: Lowercase schema objects, column aliases added for reader compatibility
- **Equivalency**: ERROR (tool error: 'uniqueID')

### Statement 2: GetProductByIdAsync
- **Location**: `DataAccess/ProductRepository.cs` - `GetProductByIdAsync()` method
- **Type**: CTE with LAG window function, LEFT JOIN, parameterized (@ProductId)
- **DMS Status**: FAILED
- **Manual Conversion**: Lowercase schema objects
- **Equivalency**: ERROR (tool error: 'uniqueID')

### Statement 3: InsertProductAsync
- **Location**: `DataAccess/ProductRepository.cs` - `InsertProductAsync()` method
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **DMS Status**: FAILED
- **Manual Conversion**: SCOPE_IDENTITY() → RETURNING, GETDATE() → NOW(), restructured to multi-command C# transaction
- **Equivalency**: ERROR (tool error: 'uniqueID')

### Statement 4: UpdateProductAsync
- **Location**: `DataAccess/ProductRepository.cs` - `UpdateProductAsync()` method
- **Type**: Transaction block with DECLARE, SELECT into vars, UPDATE, INSERT history
- **DMS Status**: FAILED
- **Manual Conversion**: DECLARE → C# variables, GETDATE() → NOW(), restructured to multi-command C# transaction
- **Equivalency**: ERROR (tool error: 'uniqueID')

### Statement 5: DeleteProductAsync
- **Location**: `DataAccess/ProductRepository.cs` - `DeleteProductAsync()` method
- **Type**: Transaction block with DECLARE, SELECT into vars, INSERT history, DELETE, CASE
- **DMS Status**: FAILED
- **Manual Conversion**: DECLARE → C# variables, GETDATE() → NOW(), restructured to multi-command C# transaction
- **Equivalency**: ERROR (tool error: 'uniqueID')

### Statement 6: GetProductsByPriceRangeAsync
- **Location**: `DataAccess/ProductRepository.cs` - `GetProductsByPriceRangeAsync()` method
- **Type**: CTE with RANK, PERCENT_RANK, BETWEEN, parameterized (@MinPrice, @MaxPrice)
- **DMS Status**: FAILED
- **Manual Conversion**: Lowercase schema objects
- **Equivalency**: ERROR (tool error: 'uniqueID')

### Statement 7: GetLowStockProductsAsync
- **Location**: `DataAccess/ProductRepository.cs` - `GetLowStockProductsAsync()` method
- **Type**: CTE with AVG/MIN/MAX OVER window functions, CASE, ROUND, parameterized (@Threshold)
- **DMS Status**: FAILED
- **Manual Conversion**: Lowercase schema objects, added `::numeric` cast for ROUND division
- **Equivalency**: ERROR (tool error: 'uniqueID')

---

## File Changes Summary

### Modified Files

| File | Change Description |
|------|-------------------|
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.1` |
| `DataAccess/ProductRepository.cs` | Updated using directive, all ADO.NET types, and all 7 SQL statements |
| `appsettings.json` | Updated connection strings from SQL Server to PostgreSQL format |

### New Files (Transformation Artifacts)

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report with all 7 statement pairs |
| `dms_conversion_issues.log` | Detailed DMS failure documentation for all 7 statements |
| `migration_report.md` | This migration report |

### Unchanged Files
- `Program.cs` - No SQL imports or database code
- `Business/ProductService.cs` - No SQL imports or database code
- `CLI/CommandLineInterface.cs` - No SQL imports or database code
- `CLI/InteractiveMenu.cs` - No SQL imports or database code
- `Models/Product.cs` - No SQL imports or database code
- `Scripts/01_InitialSetup.sql` - SQL Server DDL (documentation only, not modified)
- `Database/Scripts/01_InitialSetup.sql` - SQL Server DDL (documentation only, not modified)

---

## Detailed Changes in ProductRepository.cs

### Import Changes
- `using Microsoft.Data.SqlClient;` → `using Npgsql;`

### Type Replacements
- `SqlConnection` → `NpgsqlConnection` (3 occurrences)
- `SqlCommand` → `NpgsqlCommand` (15 occurrences)
- `SqlDataReader` → `NpgsqlDataReader` (1 occurrence)
- `SqlTransaction` → `NpgsqlTransaction` (3 occurrences)

### Connection String Changes (appsettings.json)
- `Server=localhost` → `Host=localhost`
- `Database=ProductManagement` → `Database=ProductManagement` (unchanged)
- `Trusted_Connection=True` → Removed, replaced with `Username=postgres;Password=postgres`
- `MultipleActiveResultSets=true` → Removed (not applicable for PostgreSQL)
- `TrustServerCertificate=True` → Removed (not applicable for PostgreSQL)

---

## Build Status
- **Final Build**: SUCCESS (0 errors, 10 warnings)
- **Build Command**: `dotnet build AdoCore.sln`
- **Warnings**: All pre-existing nullable reference type warnings, no new warnings introduced

---

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS tool failure (could not verify automated conversion)
2. SQL Equivalency tool returned ERROR for all pairs (could not verify equivalency)

**Recommendation**: Perform integration testing against a PostgreSQL database to verify all converted SQL statements execute correctly and return expected results.
