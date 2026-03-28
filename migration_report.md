# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-03-28 |
| **Source Database** | Microsoft SQL Server |
| **Target Database** | PostgreSQL |
| **Application Framework** | .NET 9.0 / ADO.NET |
| **Source Package** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Package** | Npgsql 8.0.9 |

---

## SQL Statement Processing Summary

| Category | Count |
|----------|-------|
| **Total SQL statements processed** | 19 |
| **Statements from C# code (ProductRepository.cs)** | 7 |
| **Statements from SQL scripts** | 12 |
| **Statements successfully converted by DMS** | 0 |
| **Statements requiring manual intervention** | 19 |
| **Statements validated as EQUIVALENT** | 0 |
| **Statements validated as NOT_EQUIVALENT** | 0 |
| **Statements with equivalency validation ERROR** | 19 |

---

## DMS Tool Status

The DMS MCP Statement Conversion Tool (dms-mcp___statement_conversion_tool) was **unavailable** throughout the migration due to persistent timeout errors:

- **Error**: `Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}`
- **Attempts**: Multiple attempts with varying poll settings (15, 20, 30 max attempts; 10-15 second intervals)
- **Impact**: All 19 SQL statements required manual conversion

However, the **DMS Schema Mapping Tool** (dms-mcp___schema_mapping_tool) was functional and provided target schema mappings that guided the manual conversions:
- `Products` → `products` (schema: `productmanagement_dbo`)
- `ProductHistory` → `producthistory`
- `ProductStats` → `productstats`
- `Categories` → `categories`
- `Suppliers` → `suppliers`

All schema object names were converted to lowercase per the DMS schema mapping output.

---

## SQL Equivalency Tool Status

The SQL Equivalency Tool (sql-equivalency___validate_sql_equivalence) returned **ERROR** for all 19 statement pairs:

- **Error**: `'uniqueID'`
- **Impact**: No automated equivalency validation was achievable
- **All 19 pairs marked as ERROR** in the equivalency report per the transformation definition requirements

---

## C# Code Changes (ProductRepository.cs)

### SQL Statement Conversions (7 statements)

| # | Method | Key Changes |
|---|--------|-------------|
| 1 | `GetAllProductsAsync` | CTE renamed `productstats_cte`, all identifiers lowercased |
| 2 | `GetProductByIdAsync` | CTE renamed `producthistory_cte`, all identifiers lowercased |
| 3 | `InsertProductAsync` | `SCOPE_IDENTITY()` → `RETURNING productid`, `GETDATE()` → `NOW()`, restructured from single SQL batch to ADO.NET managed transaction with 3 separate commands |
| 4 | `UpdateProductAsync` | `DECLARE @var` → separate SELECT, `GETDATE()` → `NOW()`, restructured to ADO.NET managed transaction with 4 separate commands |
| 5 | `DeleteProductAsync` | `DECLARE @var` → separate SELECT, `GETDATE()` → `NOW()`, restructured to ADO.NET managed transaction with 4 separate commands |
| 6 | `GetProductsByPriceRangeAsync` | All identifiers lowercased, RANK/PERCENT_RANK compatible |
| 7 | `GetLowStockProductsAsync` | All identifiers lowercased, added `CAST(stockquantity AS NUMERIC)` for integer division |

### ADO.NET Type Replacements

| Original (SQL Server) | Replacement (PostgreSQL) |
|----------------------|------------------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlTransaction` | `NpgsqlTransaction` |

### Column Name Mapping in MapProductFromReader

| Original | Converted |
|----------|-----------|
| `reader["ProductId"]` | `reader["productid"]` |
| `reader["Name"]` | `reader["name"]` |
| `reader["Description"]` | `reader["description"]` |
| `reader["Price"]` | `reader["price"]` |
| `reader["StockQuantity"]` | `reader["stockquantity"]` |
| `reader["CreatedDate"]` | `reader["createddate"]` |
| `reader["ModifiedDate"]` | `reader["modifieddate"]` |

---

## Package & Configuration Changes

### AdoCore.csproj
- **Removed**: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added**: `<PackageReference Include="Npgsql" Version="8.0.9" />`
- Note: Npgsql 8.0.0 was initially considered but rejected due to known high severity vulnerability (GHSA-x9vc-6hfv-hg8c)

### appsettings.json
- **DevConnection**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`
- **ProdConnection**: Same conversion as DevConnection
- Removed SQL Server-specific parameters: `Trusted_Connection`, `MultipleActiveResultSets`, `TrustServerCertificate`

---

## SQL Script Conversions

### Scripts/01_InitialSetup.sql (11 statement blocks converted)

| # | Object Type | Key Changes |
|---|------------|-------------|
| 1 | CREATE TABLE Products | `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`, `GETDATE()` → `NOW()`, `nvarchar` → `varchar`, removed `[dbo].` prefix |
| 2 | sp_GetAllProducts | `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION`, `RETURNS TABLE`, `plpgsql` |
| 3 | sp_GetProductById | Same pattern as above with parameter |
| 4 | sp_InsertProduct | `SCOPE_IDENTITY()` → `RETURNING ... INTO` |
| 5 | sp_UpdateProduct | `GETDATE()` → `NOW()` |
| 6 | sp_DeleteProduct | Standard function conversion |

### Database/Scripts/01_InitialSetup.sql (comprehensive)

| # | Object Type | Key Changes |
|---|------------|-------------|
| 7 | CREATE TABLE Categories | Standard conversions + self-referencing FK |
| 8 | CREATE TABLE Suppliers | `[bit]` → `BOOLEAN`, `DEFAULT 1` → `DEFAULT TRUE` |
| 9 | CREATE TABLE Products | Full schema with FK constraints |
| 10 | CREATE TABLE ProductHistory | Standard conversions |
| 11 | CREATE TABLE ProductStats | Standard conversions |
| 12 | Trigger trg_Products_History | Split into `CREATE FUNCTION` + `CREATE TRIGGER`, `SYSTEM_USER` → `current_user`, `inserted/deleted` → `NEW/OLD` with `TG_OP` |
| 13 | Indexes | Removed `[dbo].` prefix, lowercased |
| 14 | INSERT statements | Data preserved, syntax compatible |
| 15 | UPDATE statistics | `IsDiscontinued = 1` → `isdiscontinued = TRUE` |

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted, ADO.NET types replaced |
| `AdoCore.csproj` | Package reference swapped |
| `appsettings.json` | Connection strings updated |
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax |

## New Files Created

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements from C# code |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report for all 19 statement pairs |
| `migration_report.md` | This final migration report |

---

## Build Status

**Final Build: SUCCESS** (0 errors, 10 pre-existing warnings)

All warnings are pre-existing nullable reference warnings and are not related to the migration.

---

## Statements Requiring Manual Review

All 19 statements require manual review due to:
1. DMS tool unavailability (timeout errors) - manual conversions applied
2. SQL Equivalency tool errors ('uniqueID') - automated validation not achievable

**Recommendation**: Test all converted SQL statements against the target PostgreSQL database to validate functional correctness.
