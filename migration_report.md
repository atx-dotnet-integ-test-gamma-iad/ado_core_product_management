# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary
This report documents the complete migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-04-17  
**Source Database:** Microsoft SQL Server (ProductManagement)  
**Target Database:** PostgreSQL (ProductManagement)  
**Application Framework:** .NET 9.0, ADO.NET  

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention after DMS tool failure | 7 |
| Statements validated as equivalent (SQL Equivalency tool) | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

### DMS Tool Status
All 7 SQL statements were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`) with the following parameters:
- Migration Project: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- Database: `ProductManagement`
- Schema: `dbo`
- Region: `us-east-1`

**All 7 statements failed** with error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

Per transformation guidelines, manual conversion was performed with lowercase schema object names for PostgreSQL compatibility.
Conversion method: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### SQL Equivalency Validation Status
All 7 statement pairs were validated through the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`).

**All 7 validations returned ERROR** with error: `'uniqueID'`

Per transformation guidelines, these are marked as ERROR (not equivalent or non-equivalent) since tool-based validation could not be completed. No agent judgment was substituted for tool output.

---

## SQL Statement Details

### Statement 1: GetAllProductsAsync
- **Location:** DataAccess/ProductRepository.cs, `GetAllProductsAsync()` method
- **Type:** CTE with window functions (AVG, COUNT OVER), CASE, ROUND, JOIN, ORDER BY with CASE
- **DMS Conversion:** FAILED
- **Manual Conversion:** Applied lowercase schema objects
- **Equivalency Status:** ERROR (tool error)
- **Key Changes:** Schema objects converted to lowercase

### Statement 2: GetProductByIdAsync
- **Location:** DataAccess/ProductRepository.cs, `GetProductByIdAsync()` method
- **Type:** CTE with LAG window function, LEFT JOIN, CASE with NULL handling, ROUND
- **DMS Conversion:** FAILED
- **Manual Conversion:** Applied lowercase schema objects
- **Equivalency Status:** ERROR (tool error)
- **Key Changes:** Schema objects converted to lowercase

### Statement 3: InsertProductAsync
- **Location:** DataAccess/ProductRepository.cs, `InsertProductAsync()` method
- **Type:** Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
- **DMS Conversion:** FAILED
- **Manual Conversion:** Applied lowercase schema objects + SQL Server-specific function replacements
- **Equivalency Status:** ERROR (tool error)
- **Key Changes:**
  - `SCOPE_IDENTITY()` → `currval(pg_get_serial_sequence('products', 'productid'))`
  - `GETDATE()` → `CURRENT_TIMESTAMP`
  - Removed `DECLARE @NewProductId INT` / `SET @NewProductId` pattern

### Statement 4: UpdateProductAsync
- **Location:** DataAccess/ProductRepository.cs, `UpdateProductAsync()` method
- **Type:** Transaction block with DECLARE, SELECT INTO variables, UPDATE, GETDATE(), INSERT
- **DMS Conversion:** FAILED
- **Manual Conversion:** Restructured with subqueries instead of DECLARE/SET
- **Equivalency Status:** ERROR (tool error)
- **Key Changes:**
  - Removed `DECLARE @OldPrice`/`DECLARE @OldStock` and `SELECT INTO` pattern
  - Used subquery `SELECT ... FROM products WHERE productid = @ProductId` for old values
  - `GETDATE()` → `CURRENT_TIMESTAMP`
  - Reordered operations: history insert and stats update before product update

### Statement 5: DeleteProductAsync
- **Location:** DataAccess/ProductRepository.cs, `DeleteProductAsync()` method
- **Type:** Transaction block with DECLARE, SELECT INTO variables, INSERT history, DELETE, UPDATE stats
- **DMS Conversion:** FAILED
- **Manual Conversion:** Restructured with subqueries instead of DECLARE/SET
- **Equivalency Status:** ERROR (tool error)
- **Key Changes:**
  - Removed `DECLARE @OldPrice`/`DECLARE @OldStock` and `SELECT INTO` pattern
  - Used subquery for old values capture
  - `GETDATE()` → `CURRENT_TIMESTAMP`
  - Reordered: history insert and stats update before delete

### Statement 6: GetProductsByPriceRangeAsync
- **Location:** DataAccess/ProductRepository.cs, `GetProductsByPriceRangeAsync()` method
- **Type:** CTE with RANK(), PERCENT_RANK() window functions, BETWEEN, CASE
- **DMS Conversion:** FAILED
- **Manual Conversion:** Applied lowercase schema objects
- **Equivalency Status:** ERROR (tool error)
- **Key Changes:** Schema objects converted to lowercase

### Statement 7: GetLowStockProductsAsync
- **Location:** DataAccess/ProductRepository.cs, `GetLowStockProductsAsync()` method
- **Type:** CTE with AVG, MIN, MAX window functions, CASE, ROUND
- **DMS Conversion:** FAILED
- **Manual Conversion:** Applied lowercase schema objects + CAST for integer division
- **Equivalency Status:** ERROR (tool error)
- **Key Changes:**
  - Schema objects converted to lowercase
  - Added `CAST(stockquantity AS DECIMAL)` for proper division in ROUND

---

## All Statements Requiring Manual Review

**ALL 7 statements require manual review** because:
1. DMS tool failed for all statements (metadata model creation error)
2. SQL Equivalency tool returned ERROR for all statement pairs (uniqueID error)
3. Manual conversion was applied but could not be validated by the equivalency tool

| # | Method | Conversion Status | Equivalency Status | Review Required |
|---|--------|------------------|-------------------|-----------------|
| 1 | GetAllProductsAsync | Manual (DMS failed) | ERROR | YES |
| 2 | GetProductByIdAsync | Manual (DMS failed) | ERROR | YES |
| 3 | InsertProductAsync | Manual (DMS failed) | ERROR | YES |
| 4 | UpdateProductAsync | Manual (DMS failed) | ERROR | YES |
| 5 | DeleteProductAsync | Manual (DMS failed) | ERROR | YES |
| 6 | GetProductsByPriceRangeAsync | Manual (DMS failed) | ERROR | YES |
| 7 | GetLowStockProductsAsync | Manual (DMS failed) | ERROR | YES |

---

## Non-SQL Code Changes

### Package Reference Changes
| Component | Before | After |
|-----------|--------|-------|
| NuGet Package | `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.6 |
| Using Directive | `using Microsoft.Data.SqlClient;` | `using Npgsql;` |

### ADO.NET Class Replacements
| SQL Server Class | PostgreSQL (Npgsql) Class | Occurrences |
|-----------------|--------------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 (field, method return, constructor) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per SQL method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |

### Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TLS | `TrustServerCertificate=True` | Removed |

### SQL Setup Scripts
- `Scripts/01_InitialSetup.sql` - Added migration notice comment (SQL Server scripts need PostgreSQL conversion)
- `Database/Scripts/01_InitialSetup.sql` - Added migration notice comment (SQL Server scripts need PostgreSQL conversion)

---

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | sourceCode/ | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | sourceCode/ | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | sourceCode/ | Comprehensive equivalency validation report with all 7 pairs |
| `migration_report.md` | sourceCode/ | This report |

---

## Build Status
- **Final Build:** ✅ SUCCESS (0 errors, 10 warnings)
- **Warnings:** All pre-existing nullable reference warnings (CS8601, CS8618, CS8600, CS8603, CS8625)
- **Vulnerable Packages:** None (Npgsql upgraded to 8.0.6 to address GHSA-x9vc-6hfv-hg8c)

---

## Recommendations
1. **Test all SQL statements** against a PostgreSQL database to verify correct execution
2. **Validate transaction semantics** for InsertProductAsync, UpdateProductAsync, and DeleteProductAsync
3. **Review the subquery approach** used for Update/Delete statements (replaced DECLARE/SET with subqueries)
4. **Consider PostgreSQL-specific optimizations** such as using RETURNING clause instead of currval() for InsertProductAsync
5. **Convert SQL setup scripts** (Scripts/01_InitialSetup.sql, Database/Scripts/01_InitialSetup.sql) to PostgreSQL syntax
