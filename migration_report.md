# AdoCore Migration Report: SQL Server to PostgreSQL

## Migration Summary

| Property | Value |
|----------|-------|
| **Application** | AdoCore (.NET 9.0 ADO.NET Console Application) |
| **Source Database** | Microsoft SQL Server 2019 |
| **Source Package** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Database** | PostgreSQL 13 |
| **Target Package** | Npgsql 8.0.6 |
| **Migration Date** | 2026-03-27 |
| **Build Status** | ✅ SUCCESS (0 errors, 10 warnings - all pre-existing) |

## Files Modified

### 1. DataAccess/ProductRepository.cs
- **SQL Statements**: All 7 inline SQL statements converted from MS SQL Server to PostgreSQL
- **ADO.NET Classes**: All Microsoft.Data.SqlClient classes replaced with Npgsql equivalents
  - `using Microsoft.Data.SqlClient` → `using Npgsql`
  - `SqlConnection` → `NpgsqlConnection`
  - `SqlCommand` → `NpgsqlCommand`
  - `SqlDataReader` → `NpgsqlDataReader`
- **Parameter Syntax**: `@ParameterName` retained (Npgsql supports this syntax)
- **Transaction Handling**: `BeginTransactionAsync`/`CommitAsync`/`RollbackAsync` remain compatible

### 2. AdoCore.csproj
- **Removed**: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added**: `<PackageReference Include="Npgsql" Version="8.0.6" />`
- Other packages unchanged (Microsoft.Extensions.Configuration, Configuration.Json, DependencyInjection)

### 3. appsettings.json
- **DevConnection**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`
- **ProdConnection**: Same transformation applied
- Connection parameter mapping:
  - `Server=` → `Host=`
  - `Database=` → `Database=` (unchanged)
  - `Trusted_Connection=True` → Removed (replaced with Username/Password)
  - `MultipleActiveResultSets=true` → Removed (not applicable to PostgreSQL)
  - `TrustServerCertificate=True` → Removed (not applicable to PostgreSQL)

## SQL Statements Processed

| # | Method | DMS Status | Conversion Method | Equivalency Status |
|---|--------|-----------|-------------------|-------------------|
| 1 | GetAllProductsAsync() | ❌ FAILED | Manual (lowercase) | ERROR |
| 2 | GetProductByIdAsync() | ❌ FAILED | Manual (lowercase) | ERROR |
| 3 | InsertProductAsync() | ❌ FAILED | Manual (lowercase) | ERROR |
| 4 | UpdateProductAsync() | ❌ FAILED | Manual (lowercase) | ERROR |
| 5 | DeleteProductAsync() | ❌ FAILED | Manual (lowercase) | ERROR |
| 6 | GetProductsByPriceRangeAsync() | ❌ FAILED | Manual (lowercase) | ERROR |
| 7 | GetLowStockProductsAsync() | ❌ FAILED | Manual (lowercase) | ERROR |

### DMS Conversion Details
- **Tool Used**: dms-mcp___statement_conversion_tool
- **Migration Project ARN**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Schema**: dbo
- **Result**: All 7 statements failed with DMS metadata model creation/conversion timeout
- **Error**: "Metadata model creation/conversion did not complete after 15 attempts"
- **Fallback**: Manual conversion applied with lowercase schema object names per DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA policy

### Key SQL Conversions Applied
| MS SQL Feature | PostgreSQL Equivalent |
|---------------|----------------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` (writable CTE) |
| `GETDATE()` | `NOW()` |
| `BEGIN TRANSACTION / COMMIT` | Writable CTE (single-statement atomicity) |
| `DECLARE @var / SET @var` | CTE subqueries (`old_values` pattern) |
| Table/column names (PascalCase) | Lowercase (PostgreSQL convention) |
| Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK) | Same syntax (PostgreSQL compatible) |
| `ROUND()`, `CASE`, `BETWEEN` | Same syntax (PostgreSQL compatible) |
| Integer division | Added `CAST(... AS DECIMAL)` where needed |

### SQL Equivalency Validation Details
- **Tool Used**: sql-equivalency___validate_sql_equivalence
- **Result**: All 7 statement pairs returned ERROR with "'uniqueID'" service error
- **Note**: The equivalency tool experienced a service-level error ('uniqueID') that affected all validation attempts. This is a tool infrastructure issue, not a conversion quality issue.
- Per transformation definition policy: All statements marked as ERROR (not substituted with agent judgment)

## Artifacts Generated

| Artifact | Path | Description |
|----------|------|-------------|
| Extracted Statements | `extracted_statements.sql` | All 7 original MS SQL statements with annotations |
| Converted Statements | `converted_statements.sql` | All 7 original + converted PostgreSQL statement pairs |
| Equivalency Report | `sql_equivalency_validation_report.json` | Complete JSON report with 7 statement details |
| Migration Report | `migration_report.md` | This document |

## Files NOT Modified (by design)

| File | Reason |
|------|--------|
| `Scripts/01_InitialSetup.sql` | Reference schema script, not runtime code |
| `Database/Scripts/01_InitialSetup.sql` | Reference schema script, not runtime code |
| `Models/Product.cs` | No SQL or SqlClient references |
| `Business/ProductService.cs` | No SQL or SqlClient references |
| `CLI/CommandLineInterface.cs` | No SQL or SqlClient references |
| `CLI/InteractiveMenu.cs` | No SQL or SqlClient references |
| `Program.cs` | No SQL or SqlClient references |

## Manual Review Items

### ⚠️ Priority Items
1. **All 7 DMS conversions failed** - Manual conversion was applied with lowercase schema objects. Review each converted statement to verify PostgreSQL compatibility.
2. **All 7 equivalency validations returned ERROR** - The SQL Equivalency tool experienced a service error. Manual equivalency review is recommended for all statement pairs.
3. **Writable CTE pattern** (Statements 3, 4, 5) - The INSERT/UPDATE/DELETE transaction blocks were converted to PostgreSQL writable CTEs. While this is valid PostgreSQL syntax, it should be tested against the actual PostgreSQL database to verify expected behavior.

### Connection String Credentials
- Username/Password set to placeholder values (`postgres`/`postgres`)
- Update with actual PostgreSQL credentials before deployment

### PostgreSQL Schema Requirements
- All table and column names are referenced in lowercase
- Ensure PostgreSQL schema has been migrated with lowercase naming convention
- Tables required: `products`, `producthistory`, `productstats`
