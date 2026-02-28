# Migration Report: Microsoft SQL Server to PostgreSQL
## AdoCore .NET ADO Application

### Migration Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 20 |
| Statements from inline code (ProductRepository.cs) | 7 |
| Statements from SQL scripts | 13 |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention after DMS failure | 20 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| Equivalency validation errors | 20 |

### DMS Tool Status
The DMS MCP tool (`dms-mcp____statement_conversion_tool`) was unavailable during migration. All 20 statements were attempted through DMS and all returned the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```
Manual conversion was applied to all statements using the rule: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### SQL Equivalency Tool Status
The SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`) returned errors for all 20 statement pairs:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```
All equivalency statuses are recorded as ERROR based on tool output. No agent judgment was substituted.

---

### Detailed File Changes

#### 1. sourceCode/AdoCore.csproj
- **Change**: Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.6`
- **Other packages unchanged**: Microsoft.Extensions.Configuration 8.0.0, Microsoft.Extensions.Configuration.Json 8.0.0, Microsoft.Extensions.DependencyInjection 8.0.0

#### 2. sourceCode/DataAccess/ProductRepository.cs
- **Import**: `using Microsoft.Data.SqlClient;` → `using Npgsql;`
- **Types replaced**:
  - `SqlConnection` → `NpgsqlConnection` (3 occurrences)
  - `SqlCommand` → `NpgsqlCommand` (7 occurrences)
  - `SqlDataReader` → `NpgsqlDataReader` (1 occurrence)
- **SQL statements converted** (7 total):
  1. `GetAllProductsAsync` - CTE with window functions, lowercase schema
  2. `GetProductByIdAsync` - CTE with LAG, lowercase schema
  3. `InsertProductAsync` - Writable CTE with INSERT...RETURNING, NOW()
  4. `UpdateProductAsync` - Writable CTE for old value capture, NOW()
  5. `DeleteProductAsync` - Writable CTE for old value capture, NOW()
  6. `GetProductsByPriceRangeAsync` - CTE with RANK/PERCENT_RANK, lowercase
  7. `GetLowStockProductsAsync` - CTE with window functions, CAST for integer division

#### 3. sourceCode/appsettings.json
- **Connection strings updated**:
  - `Server=localhost` → `Host=localhost`
  - Added `Port=5432`
  - Removed `Trusted_Connection=True`, `MultipleActiveResultSets=true`, `TrustServerCertificate=True`
  - Added `Username=postgres;Password=postgres`

#### 4. sourceCode/Scripts/01_InitialSetup.sql
- **CREATE DATABASE**: Added PostgreSQL notes (cannot use IF NOT EXISTS with CREATE DATABASE)
- **CREATE TABLE**: IDENTITY→SERIAL, nvarchar→varchar, datetime→timestamp, GETDATE()→NOW()
- **Stored Procedures → Functions**: 5 procedures converted to `CREATE OR REPLACE FUNCTION ... LANGUAGE plpgsql`
  - `sp_GetAllProducts` → `sp_getallproducts()`
  - `sp_GetProductById` → `sp_getproductbyid(p_productid INT)`
  - `sp_InsertProduct` → `sp_insertproduct(...)` with `RETURNING` clause
  - `sp_UpdateProduct` → `sp_updateproduct(...)` with `NOW()`
  - `sp_DeleteProduct` → `sp_deleteproduct(p_productid INT)`
- **Sample Data**: `EXEC sp_InsertProduct` → `PERFORM sp_insertproduct(...)` in DO block
- **Batch separators**: All `GO` statements removed

#### 5. sourceCode/Database/Scripts/01_InitialSetup.sql
- **All changes from Scripts/01_InitialSetup.sql plus**:
- **DROP objects**: `IF EXISTS (SELECT * FROM sys.objects ...)` → `DROP TABLE IF EXISTS`
- **Additional tables**: Categories, Suppliers, ProductHistory, ProductStats (all converted)
- **Data types**: `[bit]` → `BOOLEAN`, `DEFAULT 1` → `DEFAULT TRUE`
- **Indexes**: Bracket notation removed, names lowercased
- **Trigger**: Complete restructure from SQL Server pattern (inserted/deleted pseudo-tables) to PostgreSQL trigger function + trigger pattern
  - `SYSTEM_USER` → `CURRENT_USER`
  - `inserted`/`deleted` → `NEW`/`OLD` with `TG_OP`
- **Statistics update**: `IsDiscontinued = 1` → `isdiscontinued = TRUE`, `GETDATE()` → `NOW()`

### Files NOT Modified
The following files contain no SQL/database-specific code and were left unchanged:
- `Models/Product.cs` - Data model only
- `Business/ProductService.cs` - Business logic only, no DB code
- `CLI/CommandLineInterface.cs` - UI only
- `CLI/InteractiveMenu.cs` - UI only
- `Program.cs` - DI setup only, no DB-specific code

---

### Transformation Artifacts
| Artifact | Description | Status |
|----------|-------------|--------|
| `extracted_statements.sql` | Catalog of 7 original MS SQL statements from ProductRepository.cs | Complete |
| `converted_statements.sql` | Catalog of 7 converted PostgreSQL statements | Complete |
| `sql_equivalency_validation_report.json` | Equivalency report for all 20 statement pairs | Complete |
| `dms_conversion_log.md` | Detailed DMS interaction log for all 20 statements | Complete |
| `migration_report.md` | This report | Complete |

### Build Status
- **Final build**: SUCCESS
- **Errors**: 0
- **Warnings**: 10 (all pre-existing nullable reference warnings, no new warnings introduced)

### Statements Requiring Manual Review
All 20 statements require manual review due to:
1. DMS tool unavailability (all statements manually converted)
2. SQL Equivalency tool errors (all statements returned ERROR, could not be validated)

**Recommendation**: Once the DMS and SQL Equivalency tools become available, all 20 statement pairs should be re-validated to confirm conversion correctness.

### Key Conversion Patterns Applied

| MS SQL Server | PostgreSQL | Notes |
|---------------|-----------|-------|
| `IDENTITY(1,1)` | `SERIAL` | Auto-increment |
| `SCOPE_IDENTITY()` | `INSERT...RETURNING` | Return new ID |
| `GETDATE()` | `NOW()` | Current timestamp |
| `nvarchar(n)` | `varchar(n)` | String type |
| `datetime` | `timestamp` | Date/time type |
| `[bit]` | `BOOLEAN` | Boolean type |
| `DECLARE @var` | CTE subquery / PL/pgSQL DECLARE | Variable handling |
| `BEGIN TRANSACTION/COMMIT` | Managed by app code | Transaction control |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` | Stored procedures |
| `SET NOCOUNT ON` | Removed | Not needed in PostgreSQL |
| `GO` | Removed | Batch separator |
| `[dbo].[TableName]` | `tablename` | Schema/bracket notation |
| `SYSTEM_USER` | `CURRENT_USER` | Current user function |
| `inserted`/`deleted` | `NEW`/`OLD` + `TG_OP` | Trigger pseudo-tables |
| `@ParameterName` | `@ParameterName` | Compatible with Npgsql |
| `SqlConnection` | `NpgsqlConnection` | ADO.NET connection |
| `SqlCommand` | `NpgsqlCommand` | ADO.NET command |
| `SqlDataReader` | `NpgsqlDataReader` | ADO.NET reader |
| `Microsoft.Data.SqlClient` | `Npgsql` | NuGet package |
