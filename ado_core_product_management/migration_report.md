# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS | 0 |
| Statements requiring manual conversion (DMS failure) | 7 |
| Statements validated as equivalent | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

## DMS Tool Status

The DMS MCP tool was unavailable due to an IAM permission error:
```
AccessDeniedException: User arn:aws:sts::340752807109:assumed-role/ATX_MDE_SECURE_EXECUTION_ROLE/e-527ac27e17894c9cbec75a02aaaf5b2a 
is not authorized to perform dms:StartMetadataModelCreation on resource: arn:aws:dms:us-east-1:340752807109:migration-project:*
```

All 7 SQL statements were attempted through DMS first (as required), and upon failure, manual conversion was performed with lowercase schema mapping per the transformation rules.

## SQL Equivalency Tool Status

The SQL Equivalency tool returned ERROR for all 7 statement pairs with the error: `'uniqueID'`
This appears to be a service-side configuration issue unrelated to the SQL statements themselves.

## Conversion Details

### Statement 1: GetAllProductsAsync
- **Source**: ProductRepository.cs, Lines 42-73
- **Type**: SELECT with CTE and window functions
- **Changes**: Lowercase schema objects only (compatible SQL syntax)
- **DMS Output**: AccessDeniedException
- **Manual Conversion**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 2: GetProductByIdAsync
- **Source**: ProductRepository.cs, Lines 85-115
- **Type**: SELECT with CTE, LAG window function, LEFT JOIN
- **Changes**: Lowercase schema objects only (compatible SQL syntax)
- **DMS Output**: AccessDeniedException
- **Manual Conversion**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 3: InsertProductAsync
- **Source**: ProductRepository.cs, Lines 131-155
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), UPDATE
- **Changes**: 
  - Replaced `SCOPE_IDENTITY()` with PostgreSQL writable CTE using `RETURNING` clause
  - Replaced `GETDATE()` with `NOW()`
  - Replaced `BEGIN TRANSACTION/COMMIT` with atomic CTE (single statement = implicit transaction)
  - Replaced `DECLARE @var / SET @var` pattern with CTE references
- **DMS Output**: AccessDeniedException
- **Manual Conversion**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 4: UpdateProductAsync
- **Source**: ProductRepository.cs, Lines 169-200
- **Type**: Transaction block with DECLARE variables, SELECT INTO variables, UPDATE, INSERT
- **Changes**:
  - Replaced `DECLARE @var` and `SELECT INTO @var` with CTE subquery approach
  - Replaced `GETDATE()` with `NOW()`
  - Replaced `BEGIN TRANSACTION/COMMIT` with atomic CTE
- **DMS Output**: AccessDeniedException
- **Manual Conversion**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 5: DeleteProductAsync
- **Source**: ProductRepository.cs, Lines 215-245
- **Type**: Transaction block with DECLARE variables, DELETE, INSERT history, UPDATE stats
- **Changes**:
  - Replaced `DECLARE @var` and `SELECT INTO @var` with CTE subquery approach
  - Replaced `GETDATE()` with `NOW()`
  - Replaced `BEGIN TRANSACTION/COMMIT` with atomic CTE
- **DMS Output**: AccessDeniedException
- **Manual Conversion**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: ProductRepository.cs, Lines 255-278
- **Type**: SELECT with CTE, RANK, PERCENT_RANK window functions
- **Changes**: Lowercase schema objects only (compatible SQL syntax)
- **DMS Output**: AccessDeniedException
- **Manual Conversion**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 7: GetLowStockProductsAsync
- **Source**: ProductRepository.cs, Lines 292-318
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions
- **Changes**: 
  - Lowercase schema objects
  - Added `CAST(stockquantity AS NUMERIC)` to prevent integer division truncation
- **DMS Output**: AccessDeniedException
- **Manual Conversion**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## Static Code Changes

### Package References (AdoCore.csproj)
- Removed: `Microsoft.Data.SqlClient` Version 5.1.4
- Added: `Npgsql` Version 8.0.3

### Import Changes (ProductRepository.cs)
- Removed: `using Microsoft.Data.SqlClient;`
- Added: `using Npgsql;`

### Class Replacements (ProductRepository.cs)
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`

### Connection String Changes (appsettings.json)
- Old: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- New: `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`

### Database Scripts
- `Database/Scripts/01_InitialSetup.sql` - Fully converted to PostgreSQL syntax
- `Scripts/01_InitialSetup.sql` - Fully converted to PostgreSQL syntax
- Stored procedures converted to PostgreSQL functions
- Trigger converted to PostgreSQL trigger + trigger function
- Data types converted (nvarchar→varchar, bit→boolean, datetime→timestamp, IDENTITY→SERIAL)

## Files Modified
1. `DataAccess/ProductRepository.cs` - Main data access code
2. `AdoCore.csproj` - Package references
3. `appsettings.json` - Connection strings
4. `Database/Scripts/01_InitialSetup.sql` - Database setup script
5. `Scripts/01_InitialSetup.sql` - Simple database setup script

## Artifacts Generated
1. `extracted_statements.sql` - Complete catalog of original MS SQL statements
2. `converted_statements.sql` - Complete catalog of converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report
4. `migration_report.md` - This report
