# Migration Report: MS SQL Server to PostgreSQL

## Summary

This report documents the complete migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-04-30  
**Source Database:** MS SQL Server 2019  
**Target Database:** PostgreSQL 13  
**Application Framework:** .NET 9.0 with ADO.NET  

---

## Files Modified

| File | Change Type | Description |
|------|-------------|-------------|
| `DataAccess/ProductRepository.cs` | Modified | Replaced all SQL statements, ADO.NET classes, and imports |
| `AdoCore.csproj` | Modified | Replaced Microsoft.Data.SqlClient with Npgsql |
| `appsettings.json` | Modified | Updated connection strings to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Modified | Converted DDL, stored procedures, and sample data to PostgreSQL |
| `Database/Scripts/01_InitialSetup.sql` | Modified | Converted full schema (5 tables, indexes, triggers, stored procedures, sample data) to PostgreSQL |
| `extracted_statements.sql` | Created | Catalog of all 7 original SQL statements |
| `converted_statements.sql` | Created | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Created | Comprehensive equivalency validation report |

---

## SQL Statement Conversion Summary

### DMS Tool Results
- **Total DMS conversion attempts:** 9 (7 application SQL + 2 script blocks)
- **DMS successes:** 0
- **DMS failures:** 9
- **DMS error:** `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual conversions required:** 9 (all with lowercase schema naming convention)

### Application SQL Statements (ProductRepository.cs)

| # | Method | Key Conversions | Status |
|---|--------|-----------------|--------|
| 1 | GetAllProductsAsync | Lowercase schema objects (Products→products, ProductStats→productstats) | Converted |
| 2 | GetProductByIdAsync | Lowercase schema objects (Products→products, ProductHistory→producthistory) | Converted |
| 3 | InsertProductAsync | SCOPE_IDENTITY()→RETURNING, GETDATE()→NOW(), single block→separate C# managed statements | Converted |
| 4 | UpdateProductAsync | DECLARE @var→C# variables, GETDATE()→NOW(), single block→separate statements | Converted |
| 5 | DeleteProductAsync | DECLARE @var→C# variables, GETDATE()→NOW(), single block→separate statements | Converted |
| 6 | GetProductsByPriceRangeAsync | Lowercase schema objects | Converted |
| 7 | GetLowStockProductsAsync | Lowercase schema objects, added ::numeric cast for integer division | Converted |

### Script SQL Statements

| # | Source | Key Conversions |
|---|--------|-----------------|
| 8 | Scripts/01_InitialSetup.sql | IDENTITY→SERIAL, NVARCHAR→VARCHAR, GETDATE()→NOW(), GO→removed, procedures→functions |
| 9 | Database/Scripts/01_InitialSetup.sql | Full schema: IDENTITY→SERIAL, BIT→BOOLEAN, NVARCHAR→VARCHAR, triggers→PL/pgSQL, procedures→functions, SYSTEM_USER→CURRENT_USER |

---

## SQL Equivalency Validation Results

- **Total statement pairs validated:** 9
- **EQUIVALENT:** 0
- **NOT_EQUIVALENT:** 0
- **ERROR:** 9 (all returned `'uniqueID'` error from the equivalency tool - service-side issue)
- **Tool used:** sql-equivalency___validate_sql_equivalence
- **Note:** All errors are due to a service-side issue with the SQL Equivalency tool, not related to the quality of the conversions. All 9 statement pairs returned the same `'uniqueID'` error consistently.

Full details available in `sql_equivalency_validation_report.json`.

---

## Package Dependency Changes

| Original Package | Version | Replacement Package | Version |
|-----------------|---------|---------------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.6 |

**Note:** Npgsql version upgraded from planned 8.0.0 to 8.0.6 to address known vulnerability GHSA-x9vc-6hfv-hg8c.

Packages retained (unchanged):
- Microsoft.Extensions.Configuration 8.0.0
- Microsoft.Extensions.Configuration.Json 8.0.0
- Microsoft.Extensions.DependencyInjection 8.0.0

---

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

---

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent | Occurrences |
|-----------------|-------------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 (field, method return, constructor) |
| `SqlCommand` | `NpgsqlCommand` | 12+ (all command instances) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |

---

## SQL Syntax Conversions Applied

| MS SQL Server | PostgreSQL | Applied In |
|---------------|-----------|------------|
| `SCOPE_IDENTITY()` | `INSERT...RETURNING productid` | InsertProductAsync |
| `GETDATE()` | `NOW()` | All transaction methods, DDL scripts |
| `DECLARE @var TYPE` | C# variables / PL/pgSQL `DECLARE v_var TYPE` | Update/Delete methods, scripts |
| `BEGIN TRANSACTION`/`COMMIT` | C# `BeginTransactionAsync()`/`CommitAsync()` | Insert/Update/Delete methods |
| `IDENTITY(1,1)` | `SERIAL` | DDL scripts |
| `NVARCHAR(n)` | `VARCHAR(n)` | DDL scripts |
| `BIT` | `BOOLEAN` | DDL scripts |
| `[dbo].[table]` | `table` (lowercase) | DDL scripts |
| `GO` | Removed | DDL scripts |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` | DDL scripts |
| `SYSTEM_USER` | `CURRENT_USER` | Trigger scripts |
| `IsDiscontinued = 1` | `isdiscontinued = TRUE` | Stats update script |
| `StockQuantity / AvgStock` (integer division) | `stockquantity::numeric / avgstock` | GetLowStockProductsAsync |

---

## Schema Object Name Mapping

All schema object names were converted to lowercase for PostgreSQL compatibility:

| SQL Server Name | PostgreSQL Name |
|----------------|-----------------|
| `Products` | `products` |
| `ProductHistory` | `producthistory` |
| `ProductStats` | `productstats` |
| `Categories` | `categories` |
| `Suppliers` | `suppliers` |
| `ProductId` | `productid` |
| `StockQuantity` | `stockquantity` |
| `CreatedDate` | `createddate` |
| `ModifiedDate` | `modifieddate` |
| (and all other column names) | (lowercase equivalents) |

---

## Known Issues and Items Requiring Manual Review

1. **DMS Tool Unavailability:** The DMS MCP tool was consistently unavailable during migration, returning "Metadata model creation failed" errors. All conversions were performed manually with lowercase schema naming convention.

2. **SQL Equivalency Tool Errors:** The SQL Equivalency MCP tool returned `'uniqueID'` errors for all 9 statement pairs. This appears to be a service-side issue. Manual review of the converted SQL statements is recommended.

3. **Transaction Restructuring:** The InsertProductAsync, UpdateProductAsync, and DeleteProductAsync methods were restructured from single T-SQL transaction blocks to multiple separate SQL statements managed by C# ADO.NET transactions (BeginTransactionAsync/CommitAsync/RollbackAsync). This maintains the same transactional atomicity but with a different execution pattern. Functional testing is recommended.

4. **Integer Division:** PostgreSQL performs integer division differently from SQL Server. The `::numeric` cast was added in GetLowStockProductsAsync to ensure correct decimal results when dividing integer columns.

5. **Connection String Credentials:** The connection strings use placeholder credentials (`Username=postgres;Password=postgres`). These should be updated with actual production credentials and secured via environment variables or a secrets manager.

6. **Build Warnings:** The project builds successfully with 0 errors but has pre-existing nullable reference warnings (CS8618, CS8600, CS8601, CS8603, CS8625) that were present before migration and are not related to the PostgreSQL migration.

---

## Build Verification

```
Build succeeded.
    12 Warning(s) (pre-existing)
    0 Error(s)
```

---

## Final Checklist

- [x] All SQL Server specific packages replaced with PostgreSQL equivalents
- [x] All SqlConnection/SqlCommand/SqlDataReader classes replaced with Npgsql equivalents
- [x] All 7 application SQL statements processed through DMS tool (all failed, manual conversion applied)
- [x] All 9 SQL statement pairs validated through SQL Equivalency tool (all returned ERROR due to service issue)
- [x] Comprehensive sql_equivalency_validation_report.json generated
- [x] Connection strings updated to PostgreSQL format
- [x] Transaction handling updated for PostgreSQL compatibility
- [x] Application compiles without errors
- [x] SQL setup scripts converted to PostgreSQL syntax
- [x] No remaining references to Microsoft.Data.SqlClient or SQL Server classes
