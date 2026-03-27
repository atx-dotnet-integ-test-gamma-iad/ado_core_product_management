# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-03-27  
**Source Database:** Microsoft SQL Server (ProductManagement)  
**Target Database:** PostgreSQL (postgres)  
**Application Framework:** .NET 9.0 with ADO.NET  

---

## SQL Statement Conversion

### Overview

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS | 0 |
| Statements requiring manual intervention | 7 |
| Statements validated as equivalent | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

### DMS Tool Status

The DMS Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) was attempted for all 7 SQL statements but consistently failed with metadata model creation/conversion timeout errors:

- **Attempt 1:** GetAllProductsAsync SQL - Error: "Metadata model conversion did not complete after 15 attempts"
- **Attempt 2:** GetAllProductsAsync SQL (increased poll attempts to 30) - Timeout after 300 seconds
- **Attempt 3:** Simple SELECT query test - Error: "Metadata model creation did not complete after 15 attempts"
- **Attempt 4:** Minimal SELECT query test - Error: "Metadata model creation did not complete after 15 attempts"

**DMS Schema Mapping Tool Status:** Successfully retrieved schema mappings for all 3 tables:
- `Products` → `productmanagement_dbo.products` (all columns lowercase)
- `ProductHistory` → `productmanagement_dbo.producthistory` (all columns lowercase)
- `ProductStats` → `productmanagement_dbo.productstats` (all columns lowercase)

### SQL Equivalency Tool Status

The SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`) was called for all 7 statement pairs but returned internal ERROR for all:
- All 7 pairs returned: `{"equivalence_status": "ERROR", "error": "'uniqueID'"}`
- This appears to be an internal tool error (KeyError) unrelated to the SQL statements themselves
- Per the transformation definition, all pairs are marked as ERROR status

### Converted Statements Detail

| # | Statement | Source Method | Conversion Method | Key Changes |
|---|-----------|--------------|-------------------|-------------|
| 1 | GetAllProductsAsync | CTE + Window Functions | Manual (DMS Failure) | Lowercase identifiers, CTE rename to avoid conflict |
| 2 | GetProductByIdAsync | CTE + LAG + LEFT JOIN | Manual (DMS Failure) | Lowercase identifiers, CTE rename |
| 3 | InsertProductAsync | Transaction + SCOPE_IDENTITY | Manual (DMS Failure) | Writable CTE with RETURNING, NOW() for GETDATE() |
| 4 | UpdateProductAsync | Transaction + DECLARE vars | Manual (DMS Failure) | Subquery approach, NOW() for GETDATE() |
| 5 | DeleteProductAsync | Transaction + DECLARE vars | Manual (DMS Failure) | Subquery approach, NOW() for GETDATE() |
| 6 | GetProductsByPriceRangeAsync | CTE + RANK/PERCENT_RANK | Manual (DMS Failure) | Lowercase identifiers |
| 7 | GetLowStockProductsAsync | CTE + AVG/MIN/MAX | Manual (DMS Failure) | Lowercase identifiers, CAST for integer division |

### Key SQL Syntax Transformations Applied

| SQL Server Syntax | PostgreSQL Equivalent | Applied In |
|-------------------|----------------------|------------|
| `SCOPE_IDENTITY()` | `RETURNING` clause + writable CTE | InsertProductAsync |
| `GETDATE()` | `NOW()` | Insert, Update, Delete methods |
| `BEGIN TRANSACTION`/`COMMIT` | Removed (multi-statement batch or app-level) | Insert, Update, Delete methods |
| `DECLARE @var`/`SET @var` | Subquery approach | Update, Delete methods |
| `Products`, `ProductHistory`, `ProductStats` | `products`, `producthistory`, `productstats` | All statements |
| `ProductId`, `Name`, `Price`, etc. | `productid`, `name`, `price`, etc. | All statements |
| Integer division `StockQuantity / AvgStock` | `CAST(stockquantity AS NUMERIC) / avgstock` | GetLowStockProductsAsync |

---

## Package Dependency Changes

| Original Package | Version | New Package | Version |
|-----------------|---------|-------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.6 |

No other packages were modified. The following packages remain unchanged:
- Microsoft.Extensions.Configuration 8.0.0
- Microsoft.Extensions.Configuration.Json 8.0.0
- Microsoft.Extensions.DependencyInjection 8.0.0

---

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent | Locations |
|-----------------|-------------------|-----------|
| `SqlConnection` | `NpgsqlConnection` | Field declaration, GetConnectionAsync(), constructor |
| `SqlCommand` | `NpgsqlCommand` | 7 method usages |
| `SqlDataReader` | `NpgsqlDataReader` | MapProductFromReader() parameter |

**Using Directive Change:**
- Removed: `using Microsoft.Data.SqlClient;`
- Added: `using Npgsql;`

---

## Connection String Changes

### DevConnection
| Parameter | SQL Server | PostgreSQL |
|-----------|------------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=postgres` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | (removed - not applicable) |
| Certificate | `TrustServerCertificate=True` | (removed - not applicable) |

### ProdConnection
Same transformation applied as DevConnection.

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted, ADO.NET classes replaced, using directive updated, column name references lowercased |
| `AdoCore.csproj` | Package reference: Microsoft.Data.SqlClient → Npgsql |
| `appsettings.json` | Connection strings updated to PostgreSQL format |

## Files Created

| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `migration_report.md` | This migration summary report |

---

## Build Verification

All steps completed with successful builds:

| Step | Build Result | Errors | Warnings |
|------|-------------|--------|----------|
| Step 1: SQL Statement Conversion | ✅ Success | 0 | 10 (pre-existing) |
| Step 2: Package & Class Replacement | ✅ Success | 0 | 10 (pre-existing) |
| Step 3: Connection String Update | ✅ Success | 0 | 10 (pre-existing) |
| Step 4: Final Report & Verification | ✅ Success | 0 | 10 (pre-existing) |

All 10 warnings are pre-existing nullable reference type warnings (CS8601, CS8618, CS8600, CS8603, CS8625) that existed before the migration.

---

## Issues Encountered

### 1. DMS Statement Conversion Tool Unavailable
- **Issue:** The DMS `statement_conversion_tool` consistently failed with metadata model creation/conversion timeout
- **Impact:** All 7 SQL statements required manual conversion
- **Resolution:** Used DMS Schema Mapping Tool (which worked) to determine target schema, then manually converted applying lowercase naming conventions per DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### 2. SQL Equivalency Tool Internal Error
- **Issue:** The SQL Equivalency tool returned `'uniqueID'` KeyError for all 7 statement pairs
- **Impact:** Could not programmatically verify SQL equivalency
- **Resolution:** Per transformation definition, all pairs marked as ERROR status. Manual review recommended.

### 3. Transaction Handling in PostgreSQL
- **Issue:** SQL Server uses `BEGIN TRANSACTION`/`COMMIT` and `DECLARE`/`SET` for variable management within transaction blocks
- **Impact:** PostgreSQL doesn't support the same multi-statement batch with variables
- **Resolution:** Restructured InsertProductAsync to use writable CTEs with RETURNING; restructured Update/Delete to use subquery approach for capturing old values before modification

---

## Recommendations for Post-Migration

1. **Manual SQL Equivalency Review:** Since the automated equivalency tool had internal errors, a manual review of all 7 SQL statement pairs is recommended
2. **Integration Testing:** Run full integration tests against a PostgreSQL database to verify all queries execute correctly
3. **Transaction Testing:** Pay special attention to the Insert, Update, and Delete operations which were significantly restructured
4. **Performance Testing:** Compare query performance between SQL Server and PostgreSQL, especially for CTE-based queries with window functions
5. **Connection String Security:** Replace placeholder credentials (postgres/postgres) with proper secure credentials before deployment
