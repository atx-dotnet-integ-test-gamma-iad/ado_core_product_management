# Migration Report: MS SQL Server to PostgreSQL

## Overview
This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-04-14  
**Source Database:** Microsoft SQL Server 2019  
**Target Database:** PostgreSQL 13  
**Application Framework:** .NET 9.0 / ADO.NET  

---

## 1. SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| DMS Conversion Successful | 0 |
| DMS Conversion Failed | 7 |
| Manual Conversion Applied | 7 |
| Equivalency Validated (EQUIVALENT) | 0 |
| Equivalency Validated (NOT_EQUIVALENT) | 0 |
| Equivalency Validation ERROR | 7 |

### DMS Tool Results
All 7 SQL statements were passed to the DMS MCP Statement Conversion Tool (`dms-mcp___statement_conversion_tool`). All failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

### Manual Conversion Applied
Since DMS conversion failed for all statements, manual conversion was applied with lowercase schema object names per the DMS schema mapping tool results:
- **Schema mapping tool** (`dms-mcp___schema_mapping_tool`) was used successfully to retrieve the target schema mappings
- **Products** → `products` (schema: `productmanagement_dbo`)
- **ProductHistory** → `producthistory` (schema: `productmanagement_dbo`)
- **ProductStats** → `productstats` (schema: `productmanagement_dbo`)
- All column names converted to lowercase (e.g., `ProductId` → `productid`, `StockQuantity` → `stockquantity`)

### SQL Equivalency Validation
All 7 statement pairs were passed to the SQL Equivalency MCP Tool (`sql-equivalency___validate_sql_equivalence`). All returned ERROR:
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```
This appears to be a service-level issue unrelated to the statement conversions.

---

## 2. Detailed Statement Conversion Results

### SQL1: GetAllProductsAsync
- **Method:** `GetAllProductsAsync()`
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:** All identifiers lowercased per DMS schema mapping
- **Key Conversions:** None needed - window functions (AVG OVER, COUNT OVER), CTE, CASE, ROUND are compatible
- **Equivalency Status:** ERROR (tool service error)

### SQL2: GetProductByIdAsync
- **Method:** `GetProductByIdAsync(int productId)`
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:** All identifiers lowercased per DMS schema mapping
- **Key Conversions:** LAG window function, LEFT JOIN, CASE, ROUND preserved as-is
- **Equivalency Status:** ERROR (tool service error)

### SQL3: InsertProductAsync
- **Method:** `InsertProductAsync(Product product)`
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:**
  - `SCOPE_IDENTITY()` → `RETURNING productid` clause
  - `GETDATE()` → `CURRENT_TIMESTAMP`
  - `DECLARE @NewProductId INT` → removed (PostgreSQL doesn't support inline DECLARE)
  - `BEGIN TRANSACTION` / `COMMIT` → split into separate ADO.NET commands
  - Multi-statement transaction block → separate INSERT, history INSERT, and stats UPDATE commands
- **Equivalency Status:** ERROR (tool service error)

### SQL4: UpdateProductAsync
- **Method:** `UpdateProductAsync(Product product)`
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:**
  - `DECLARE @OldPrice / @OldStock` → separate SELECT query in C# code
  - `GETDATE()` → `CURRENT_TIMESTAMP`
  - `BEGIN TRANSACTION` / `COMMIT` → split into separate ADO.NET commands
  - Multi-statement transaction block → separate SELECT, UPDATE, history INSERT, stats UPDATE commands
- **Equivalency Status:** ERROR (tool service error)

### SQL5: DeleteProductAsync
- **Method:** `DeleteProductAsync(int productId)`
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:**
  - `DECLARE @OldPrice / @OldStock` → separate SELECT query in C# code
  - `GETDATE()` → `CURRENT_TIMESTAMP`
  - `BEGIN TRANSACTION` / `COMMIT` → split into separate ADO.NET commands
  - Multi-statement transaction block → separate SELECT, history INSERT, DELETE, stats UPDATE commands
- **Equivalency Status:** ERROR (tool service error)

### SQL6: GetProductsByPriceRangeAsync
- **Method:** `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:** All identifiers lowercased per DMS schema mapping
- **Key Conversions:** RANK, PERCENT_RANK window functions, BETWEEN, CASE preserved as-is
- **Equivalency Status:** ERROR (tool service error)

### SQL7: GetLowStockProductsAsync
- **Method:** `GetLowStockProductsAsync(int threshold)`
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:**
  - All identifiers lowercased per DMS schema mapping
  - Added `CAST(stockquantity AS NUMERIC)` for integer division compatibility in ROUND
- **Key Conversions:** AVG, MIN, MAX window functions, CASE preserved as-is
- **Equivalency Status:** ERROR (tool service error)

---

## 3. Package Dependency Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.1 |

---

## 4. ADO.NET Class Replacements

| SQL Server Class | PostgreSQL Equivalent | Occurrences |
|-----------------|----------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 15 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |

---

## 5. Connection String Changes

### Development Connection
- **Before:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After:** `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`

### Production Connection
- **Before:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After:** `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`

### Parameter Mapping
| SQL Server | PostgreSQL | Notes |
|-----------|-----------|-------|
| `Server=` | `Host=` | Server hostname |
| `Database=` | `Database=` | Same parameter |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` | Windows auth → explicit credentials |
| `MultipleActiveResultSets=true` | (removed) | Not supported in PostgreSQL |
| `TrustServerCertificate=True` | (removed) | Not applicable to PostgreSQL |

---

## 6. Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements, ADO.NET classes, imports |
| `AdoCore.csproj` | Package reference |
| `appsettings.json` | Connection strings |

---

## 7. Transformation Artifacts

| Artifact | Description |
|----------|-------------|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | JSON report with all 7 statement pairs and equivalency results |
| `migration_report.md` | This report |

---

## 8. Manual Interventions Required

1. **All 7 SQL statements** required manual conversion due to DMS tool failure
   - Applied lowercase schema object names per DMS schema mapping tool results
   - Reason: DMS metadata model creation consistently failed with "Unknown metadata model creation status: RECEIVED"

2. **Transaction-based SQL (SQL3, SQL4, SQL5)** were restructured from single multi-statement SQL strings to multiple separate ADO.NET command calls
   - PostgreSQL does not support inline `DECLARE @variable` in plain SQL sent via ADO.NET
   - `SCOPE_IDENTITY()` replaced with `RETURNING productid` clause
   - Variable-based old value capture replaced with separate SELECT queries

3. **SQL7 (GetLowStockProductsAsync)** required `CAST(stockquantity AS NUMERIC)` to avoid integer division in PostgreSQL's ROUND function

---

## 9. Build Verification

- **Final Build Status:** ✅ Success
- **Errors:** 0
- **Warnings:** 10 (pre-existing nullable reference warnings, not introduced by migration)
