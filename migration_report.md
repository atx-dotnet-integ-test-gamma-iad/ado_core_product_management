# Migration Report: SQL Server to PostgreSQL for AdoCore Application

## Summary

This report documents the complete migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating package dependencies, replacing ADO.NET class references, and updating connection string configurations.

## Migration Overview

| Metric | Value |
|--------|-------|
| Total SQL Statements Processed | 7 |
| DMS Tool Conversion Attempts | 7 |
| DMS Tool Successful Conversions | 0 |
| DMS Tool Failures | 7 |
| Manual Conversions Required | 7 |
| Equivalency Validations Performed | 7 |
| Equivalency Status: EQUIVALENT | 0 |
| Equivalency Status: NOT_EQUIVALENT | 0 |
| Equivalency Status: ERROR | 7 |
| Files Modified | 3 |
| Files Created | 4 |

## DMS Tool Results

All 7 SQL statements were submitted to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) for conversion. All attempts failed with the following error:

**Error Type:** `AccessDeniedException`  
**Error Message:** User `arn:aws:sts::812756961751:assumed-role/AWSTransform-Connector-role-mi98stgw-wWlUW/AWSTransformConnectorDataPlane` is not authorized to perform `dms:StartMetadataModelCreation` on resource `arn:aws:dms:us-east-1:812756961751:migration-project:*` because no identity-based policy allows the `dms:StartMetadataModelCreation` action.

**Fallback Action:** Per the transformation definition, when DMS fails, manual conversion was applied with lowercase schema object names for PostgreSQL compatibility. All manual conversions are documented with reason `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`.

## SQL Statement Conversions

### Statement 1: GetAllProductsAsync

| Property | Value |
|----------|-------|
| Source Method | `GetAllProductsAsync()` |
| Conversion Method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| Equivalency Status | ERROR (tool returned internal error: 'uniqueID') |

**Key Changes:**
- All table/column names converted to lowercase (Products → products, ProductId → productid, etc.)
- `ROUND((p.Price / ps.AvgPrice) * 100, 2)` → `ROUND(CAST(p.price AS numeric) / ps.avgprice * 100, 2)` (explicit numeric cast for PostgreSQL integer division)

### Statement 2: GetProductByIdAsync

| Property | Value |
|----------|-------|
| Source Method | `GetProductByIdAsync(int productId)` |
| Conversion Method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| Equivalency Status | ERROR (tool returned internal error: 'uniqueID') |

**Key Changes:**
- All table/column names converted to lowercase
- `ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)` → `ROUND((CAST(p.price - ph.previousprice AS numeric) / ph.previousprice) * 100, 2)`
- LAG window function syntax preserved (compatible with PostgreSQL)

### Statement 3: InsertProductAsync

| Property | Value |
|----------|-------|
| Source Method | `InsertProductAsync(Product product)` |
| Conversion Method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| Equivalency Status | ERROR (tool returned internal error: 'uniqueID') |

**Key Changes:**
- `DECLARE @NewProductId INT; SET @NewProductId = SCOPE_IDENTITY()` → Removed, using `lastval()` instead
- `SCOPE_IDENTITY()` → `lastval()`
- `GETDATE()` → `NOW()`
- `BEGIN TRANSACTION` → `BEGIN`
- `SELECT @NewProductId` → `SELECT lastval()`

### Statement 4: UpdateProductAsync

| Property | Value |
|----------|-------|
| Source Method | `UpdateProductAsync(Product product)` |
| Conversion Method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| Equivalency Status | ERROR (tool returned internal error: 'uniqueID') |

**Key Changes:**
- `DECLARE @OldPrice / @OldStock` and `SELECT INTO` variable → Restructured using subqueries
- History INSERT now uses `SELECT ... FROM products WHERE productid = @ProductId` to capture old values
- Stats UPDATE uses subquery `(SELECT price FROM products WHERE productid = @ProductId)` for old price
- Order restructured: History INSERT → Stats UPDATE → Product UPDATE (to capture old values before update)
- `GETDATE()` → `NOW()`
- `BEGIN TRANSACTION` → `BEGIN`

### Statement 5: DeleteProductAsync

| Property | Value |
|----------|-------|
| Source Method | `DeleteProductAsync(int productId)` |
| Conversion Method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| Equivalency Status | ERROR (tool returned internal error: 'uniqueID') |

**Key Changes:**
- `DECLARE @OldPrice / @OldStock` and `SELECT INTO` variable → Restructured using subqueries
- History INSERT now uses `SELECT ... FROM products WHERE productid = @ProductId`
- Stats UPDATE uses subquery for old price
- Order restructured: History INSERT → Stats UPDATE → DELETE (to capture old values before delete)
- `GETDATE()` → `NOW()`
- `BEGIN TRANSACTION` → `BEGIN`

### Statement 6: GetProductsByPriceRangeAsync

| Property | Value |
|----------|-------|
| Source Method | `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)` |
| Conversion Method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| Equivalency Status | ERROR (tool returned internal error: 'uniqueID') |

**Key Changes:**
- All table/column names converted to lowercase
- RANK(), PERCENT_RANK(), BETWEEN syntax preserved (compatible with PostgreSQL)

### Statement 7: GetLowStockProductsAsync

| Property | Value |
|----------|-------|
| Source Method | `GetLowStockProductsAsync(int threshold)` |
| Conversion Method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| Equivalency Status | ERROR (tool returned internal error: 'uniqueID') |

**Key Changes:**
- All table/column names converted to lowercase
- `ROUND((StockQuantity / AvgStock) * 100, 2)` → `ROUND(CAST(stockquantity AS numeric) / avgstock * 100, 2)` (explicit numeric cast)

## SQL Equivalency Validation Results

All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All returned an ERROR status with an internal tool error (`'uniqueID'`). This appears to be a systemic issue with the equivalency tool infrastructure, not related to the SQL statements themselves.

**Important:** Per the transformation definition, equivalency status is determined solely by the tool output and never by agent judgment. All statements are marked as ERROR as returned by the tool.

The complete equivalency validation report is available in `sql_equivalency_validation_report.json`.

## Package Dependency Changes

| Change | From | To |
|--------|------|-----|
| Package Reference | `Microsoft.Data.SqlClient` 5.1.4 | `Npgsql` 8.0.9 |

**Note:** Npgsql version was upgraded from the planned 8.0.1 to 8.0.9 to address a known high-severity vulnerability (GHSA-x9vc-6hfv-hg8c).

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent | Occurrences |
|-----------------|-------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 (field, return type, constructor) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per SQL method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader) |
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |

## Connection String Changes

| Connection | From (SQL Server) | To (PostgreSQL) |
|------------|-------------------|-----------------|
| DevConnection | `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` | `Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres` |
| ProdConnection | Same as above | Same as above |

**Parameters Removed:** `Trusted_Connection`, `MultipleActiveResultSets`, `TrustServerCertificate`  
**Parameters Added:** `Host` (replaces `Server`), `Port=5432`, `Username`, `Password`

## Modified Files

1. **sourceCode/DataAccess/ProductRepository.cs**
   - All 7 SQL statements converted to PostgreSQL syntax
   - Import changed from `Microsoft.Data.SqlClient` to `Npgsql`
   - All ADO.NET class references updated to Npgsql equivalents

2. **sourceCode/AdoCore.csproj**
   - Package reference changed from `Microsoft.Data.SqlClient` 5.1.4 to `Npgsql` 8.0.9

3. **sourceCode/appsettings.json**
   - Both connection strings converted to PostgreSQL format

## Created Files

1. **sourceCode/extracted_statements.sql** - Complete catalog of all 7 original MS SQL statements
2. **sourceCode/converted_statements.sql** - Complete catalog of all 7 converted PostgreSQL statements
3. **sourceCode/sql_equivalency_validation_report.json** - Comprehensive equivalency validation report
4. **sourceCode/migration_report.md** - This migration report

## Build Verification

The application compiles successfully after all changes:
- **Build Result:** Succeeded
- **Errors:** 0
- **Warnings:** 10 (pre-existing nullable reference warnings, not introduced by migration)

## Manual Interventions

All 7 SQL statements required manual conversion due to DMS tool access failure. The following conversion rules were applied:

1. **Schema Object Names:** All table names, column names, and aliases converted to lowercase for PostgreSQL compatibility
2. **SCOPE_IDENTITY():** Replaced with `lastval()` for retrieving the last auto-generated ID
3. **GETDATE():** Replaced with `NOW()` for current timestamp
4. **BEGIN TRANSACTION / COMMIT:** Replaced with `BEGIN / COMMIT` (PostgreSQL syntax)
5. **DECLARE @variable / SET @variable:** Restructured using subqueries to avoid PL/pgSQL variable syntax in plain SQL
6. **ROUND with division:** Added explicit `CAST(... AS numeric)` to prevent integer division in PostgreSQL
7. **Transaction block ordering:** For UPDATE and DELETE statements, reordered operations to capture old values via subqueries before the modifying statement executes

## Recommendations for Further Testing

1. **Integration Testing:** Run the application against a PostgreSQL database to verify all operations work correctly
2. **Transaction Integrity:** Test the INSERT, UPDATE, and DELETE transaction blocks to ensure atomicity and correct value capture
3. **Window Function Verification:** Verify CTE/window function queries return expected results with sample data
4. **Equivalency Re-validation:** If the SQL Equivalency tool becomes available, re-validate all 7 statement pairs
5. **DMS Re-conversion:** If DMS access is restored, re-convert all 7 statements through DMS for authoritative conversion
