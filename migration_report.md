# Migration Report: Microsoft SQL Server → PostgreSQL

## Summary
This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating database access code (ADO.NET classes), updating package dependencies, and transforming connection strings.

**Migration Date:** 2026-04-04  
**Source Database:** Microsoft SQL Server 2019 (ProductManagement)  
**Target Database:** PostgreSQL 13 (postgres)  
**Application Framework:** .NET 9.0, ADO.NET  

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS | 0 |
| Statements requiring manual intervention | 7 |
| Statements validated as equivalent | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

### DMS Tool Status
The DMS MCP Statement Conversion Tool (dms-mcp___statement_conversion_tool) was invoked for all 7 SQL statements but consistently failed with metadata model creation/conversion timeouts. All statements were subsequently converted manually using the DMS Schema Mapping Tool results (which was successful) to apply lowercase schema object names per PostgreSQL convention.

### SQL Equivalency Tool Status
The SQL Equivalency Tool (sql-equivalency___validate_sql_equivalence) was invoked for all 7 statement pairs but returned ERROR with `'uniqueID'` for every invocation. All equivalency statuses are marked as ERROR per the tool output.

---

## Converted SQL Statements

### Statement 1: GetAllProductsAsync
- **Method:** `GetAllProductsAsync()`
- **Parameters:** None
- **Conversion:** CTE with window functions, lowercase schema names, column aliases for reader compatibility
- **Key Changes:** `Products` → `productmanagement_dbo.products`, column aliases added

### Statement 2: GetProductByIdAsync
- **Method:** `GetProductByIdAsync(int productId)`
- **Parameters:** @ProductId
- **Conversion:** CTE with LAG window function, lowercase schema names
- **Key Changes:** `Products` → `productmanagement_dbo.products`, column aliases added

### Statement 3: InsertProductAsync
- **Method:** `InsertProductAsync(Product product)`
- **Parameters:** @Name, @Description, @Price, @StockQuantity
- **Conversion:** Restructured as CTE chain with INSERT...RETURNING
- **Key Changes:**
  - `SCOPE_IDENTITY()` → `INSERT...RETURNING productid`
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION/COMMIT` → CTE chain (single atomic statement)
  - `DECLARE @var / SET @var` → CTE intermediate results

### Statement 4: UpdateProductAsync
- **Method:** `UpdateProductAsync(Product product)`
- **Parameters:** @ProductId, @Name, @Description, @Price, @StockQuantity
- **Conversion:** Restructured as CTE chain with old_values capture
- **Key Changes:**
  - `DECLARE @OldPrice/@OldStock` → CTE `old_values` subquery
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION/COMMIT` → CTE chain

### Statement 5: DeleteProductAsync
- **Method:** `DeleteProductAsync(int productId)`
- **Parameters:** @ProductId
- **Conversion:** Restructured as CTE chain with old_values capture
- **Key Changes:**
  - `DECLARE @OldPrice/@OldStock` → CTE `old_values` subquery
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION/COMMIT` → CTE chain
  - `DELETE FROM Products` → `DELETE FROM productmanagement_dbo.products...RETURNING`

### Statement 6: GetProductsByPriceRangeAsync
- **Method:** `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Parameters:** @MinPrice, @MaxPrice
- **Conversion:** CTE with RANK/PERCENT_RANK, lowercase schema names
- **Key Changes:** `Products` → `productmanagement_dbo.products`, explicit column list replaces `rp.*`

### Statement 7: GetLowStockProductsAsync
- **Method:** `GetLowStockProductsAsync(int threshold)`
- **Parameters:** @Threshold
- **Conversion:** CTE with AVG/MIN/MAX window functions, lowercase schema names
- **Key Changes:** `Products` → `productmanagement_dbo.products`, `CAST(stockquantity AS NUMERIC)` for integer division fix

---

## File Changes

### AdoCore.csproj
- **Removed:** `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added:** `<PackageReference Include="Npgsql" Version="8.0.6" />`

### DataAccess/ProductRepository.cs
- **Using Statement:** `using Microsoft.Data.SqlClient` → `using Npgsql`
- **Class Replacements:**
  - `SqlConnection` → `NpgsqlConnection` (field, method return type, constructor)
  - `SqlCommand` → `NpgsqlCommand` (7 instances)
  - `SqlDataReader` → `NpgsqlDataReader` (1 instance)
- **SQL Statements:** All 7 SQL strings replaced with PostgreSQL equivalents
- **Schema Mapping Applied:**
  - `dbo.Products` → `productmanagement_dbo.products`
  - `dbo.ProductHistory` → `productmanagement_dbo.producthistory`
  - `dbo.ProductStats` → `productmanagement_dbo.productstats`
  - All column names converted to lowercase

### appsettings.json
- **DevConnection:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=postgres;`
- **ProdConnection:** Same transformation applied

---

## Schema Mapping (from DMS Schema Mapping Tool)

| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| `dbo.Products` | `productmanagement_dbo.products` |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` |
| `ProductId` (int IDENTITY) | `productid` (INTEGER GENERATED ALWAYS AS IDENTITY) |
| `nvarchar(N)` | `VARCHAR(N)` |
| `decimal(18,2)` | `NUMERIC(18,2)` |
| `datetime` | `TIMESTAMP WITHOUT TIME ZONE` |
| `bit` | `NUMERIC(1,0)` |
| `getdate()` | `clock_timestamp()` |

---

## Build Verification

**Final Build:** ✅ **Succeeded**
- 0 Errors
- 10 Warnings (all pre-existing nullable reference warnings, not related to migration)
- Output: `AdoCore.dll` compiled successfully

---

## Artifacts

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL Server statements |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report for all 7 pairs |
| `migration_report.md` | This report |

---

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. **DMS conversion failure** - All statements were manually converted due to DMS timeout
2. **Equivalency validation error** - The SQL equivalency tool returned errors for all 7 pairs

**Recommended actions:**
- Verify each converted SQL statement against a live PostgreSQL database
- Test all CRUD operations (Insert, Update, Delete, Select) end-to-end
- Validate that CTE-based transaction replacements maintain atomicity
- Confirm schema `productmanagement_dbo` exists in the target PostgreSQL database
- Test connection string configuration with actual PostgreSQL credentials
