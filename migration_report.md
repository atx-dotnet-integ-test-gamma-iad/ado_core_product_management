# AdoCore Migration Report: SQL Server to PostgreSQL

## Project Overview

| Property | Value |
|----------|-------|
| **Project** | AdoCore (.NET 9.0 Console Application) |
| **Source Database** | Microsoft SQL Server (ProductManagement) |
| **Target Database** | PostgreSQL |
| **Migration Date** | 2026-04-24 |
| **Framework** | .NET 9.0 |

## Files Modified

| File | Changes |
|------|---------|
| `sourceCode/AdoCore.csproj` | Package reference: Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `sourceCode/DataAccess/ProductRepository.cs` | All 7 SQL statements converted; all ADO.NET classes replaced |
| `sourceCode/appsettings.json` | Connection strings updated to PostgreSQL format |

## Package Dependency Changes

| Old Package | Version | New Package | Version |
|------------|---------|-------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.6 |

*Note: Npgsql 8.0.6 was chosen over 8.0.1 to address known vulnerability GHSA-x9vc-6hfv-hg8c (NU1903).*

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Replacement | Occurrences |
|-----------------|-------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 4 (field, method return, constructor, dispose) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per SQL method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |

## Import Changes

| Old Import | New Import |
|-----------|------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |

## Connection String Migration

### Development Connection (DevConnection)
| Property | SQL Server | PostgreSQL |
|----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | *(removed - SQL Server specific)* |
| TrustServerCertificate | `TrustServerCertificate=True` | *(removed - SQL Server specific)* |

### Production Connection (ProdConnection)
Same transformation applied as DevConnection.

## SQL Statement Conversion Summary

| # | Method | Total Statements | DMS Converted | Manually Converted | Equivalency Status |
|---|--------|-----------------|---------------|--------------------|--------------------|
| 1 | GetAllProductsAsync | 1 | 0 | 1 | ERROR |
| 2 | GetProductByIdAsync | 1 | 0 | 1 | ERROR |
| 3 | InsertProductAsync | 1 | 0 | 1 | ERROR |
| 4 | UpdateProductAsync | 1 | 0 | 1 | ERROR |
| 5 | DeleteProductAsync | 1 | 0 | 1 | ERROR |
| 6 | GetProductsByPriceRangeAsync | 1 | 0 | 1 | ERROR |
| 7 | GetLowStockProductsAsync | 1 | 0 | 1 | ERROR |
| **Total** | | **7** | **0** | **7** | **7 ERROR** |

### DMS Tool Results
- **Tool Used**: dms-mcp___statement_conversion_tool
- **Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Schema**: dbo
- **Database**: ProductManagement
- **All 7 statements FAILED** with error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Conversion Method Applied**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### SQL Equivalency Validation Results
- **Tool Used**: sql-equivalency___validate_sql_equivalence
- **All 7 statement pairs returned ERROR** with: `'uniqueID'` (systemic tool error)
- **Status**: ERROR for all pairs - tool-reported, not agent judgment

## Detailed SQL Conversion Changes

### Statement 1: GetAllProductsAsync
- **Type**: CTE with AVG/COUNT window functions, CASE, ROUND, INNER JOIN
- **Changes**: Schema object names to lowercase (Products → products, ProductId → productid, etc.)
- **Syntax compatible**: CTE, window functions, CASE, ROUND, INNER JOIN all PostgreSQL-compatible

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG window function, LEFT JOIN, ROUND
- **Changes**: Schema object names to lowercase
- **Syntax compatible**: LAG window function, LEFT JOIN, ROUND all PostgreSQL-compatible

### Statement 3: InsertProductAsync
- **Type**: Transaction block with SCOPE_IDENTITY(), GETDATE(), INSERT/UPDATE
- **Key Changes**:
  - `DECLARE @NewProductId INT` → removed (used inline lastval())
  - `BEGIN TRANSACTION` → `BEGIN`
  - `SCOPE_IDENTITY()` → `lastval()`
  - `GETDATE()` → `NOW()`
  - `SET @NewProductId = SCOPE_IDENTITY()` → removed (use lastval() directly)
  - `SELECT @NewProductId` → `SELECT lastval()`
  - Schema object names to lowercase

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE variables, SELECT INTO vars, UPDATE, INSERT, GETDATE()
- **Key Changes**:
  - `DECLARE @OldPrice` / `DECLARE @OldStock` → removed
  - `SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products` → Restructured: INSERT...SELECT captures old values before UPDATE
  - `BEGIN TRANSACTION` → `BEGIN`
  - `GETDATE()` → `NOW()`
  - Operation order rearranged: log history first (captures current values), then update stats (captures current price), then update product
  - Schema object names to lowercase

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, DELETE, CASE, GETDATE()
- **Key Changes**:
  - `DECLARE @OldPrice` / `DECLARE @OldStock` → removed
  - Restructured: INSERT...SELECT captures old values before DELETE
  - `BEGIN TRANSACTION` → `BEGIN`
  - `GETDATE()` → `NOW()`
  - Operation order: log history first, update stats (with subquery for current price), then delete product
  - CASE expression preserved (PostgreSQL-compatible)
  - Schema object names to lowercase

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK/PERCENT_RANK window functions, BETWEEN
- **Changes**: Schema object names to lowercase
- **Syntax compatible**: RANK(), PERCENT_RANK(), BETWEEN all PostgreSQL-compatible

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX window functions, ROUND
- **Changes**: Schema object names to lowercase
- **Syntax compatible**: AVG(), MIN(), MAX() window functions, ROUND all PostgreSQL-compatible

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | sourceCode/ | All 7 original MS SQL Server statements |
| `converted_statements.sql` | sourceCode/ | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | sourceCode/ | Complete equivalency validation report for all 7 pairs |
| `migration_report.md` | sourceCode/ | This comprehensive migration report |

## Build Verification

| Build Step | Result |
|-----------|--------|
| Final `dotnet build AdoCore.sln` | **SUCCESS** |
| Errors | 0 |
| Warnings | 10 (pre-existing nullable reference warnings) |

## Statements Requiring Manual Review

All 7 statements require manual review as:
1. DMS tool was unavailable (metadata model creation failure) - manual conversion applied
2. SQL Equivalency tool returned ERROR for all pairs (systemic tool issue with 'uniqueID')
3. Manual conversion applied lowercase schema object naming convention per DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA rules

**Recommendation**: Validate all 7 converted PostgreSQL statements against a live PostgreSQL database to confirm functional equivalency.
