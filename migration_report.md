# Migration Report: MS SQL Server to PostgreSQL

## Executive Summary

This report documents the migration of the **AdoCore** .NET ADO application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, replacing database access libraries, and updating connection configuration.

**Migration Date:** 2026-04-12  
**Source Database:** MS SQL Server 2019 (ProductManagement)  
**Target Database:** PostgreSQL 13 (postgres)  
**Application Framework:** .NET 9.0 with ADO.NET  

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS Tool | 0 |
| Requiring Manual Intervention (DMS Failed) | 7 |
| Validated as Equivalent (SQL Equivalency Tool) | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Validation Errors | 7 |

### DMS Tool Status
- **DMS Statement Conversion Tool:** All 7 statements were submitted but all failed with error: `"Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"`
- **DMS Schema Mapping Tool:** Successfully retrieved schema mappings for all 3 tables (Products, ProductHistory, ProductStats)
- **Manual Conversion:** All 7 statements were manually converted using the DMS schema mappings with lowercase schema object names per `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` protocol

### SQL Equivalency Tool Status
- All 7 statement pairs were submitted to the SQL Equivalency validation tool
- All 7 returned ERROR status with error `'uniqueID'` (tool infrastructure issue)
- No agent judgment was used for equivalency determination

---

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Source Method:** `GetAllProductsAsync()`
- **SQL Features:** CTE, Window Functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN, ORDER BY with CASE
- **Key Changes:** Table/column names lowercased per DMS schema mapping
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 2: GetProductByIdAsync
- **Source Method:** `GetProductByIdAsync(int productId)`
- **SQL Features:** CTE, Window Functions (LAG OVER), LEFT JOIN, CASE with NULL checks, ROUND
- **Key Changes:** Table/column names lowercased per DMS schema mapping
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 3: InsertProductAsync
- **Source Method:** `InsertProductAsync(Product product)`
- **SQL Features:** DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE, Transaction
- **Key Changes:**
  - `SCOPE_IDENTITY()` → `RETURNING productid`
  - `GETDATE()` → `clock_timestamp()`
  - SQL DECLARE/SET variables → C# managed variables
  - SQL transaction block → C# `BeginTransactionAsync()` managed
  - Single SQL statement → 3 separate PostgreSQL statements
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 4: UpdateProductAsync
- **Source Method:** `UpdateProductAsync(Product product)`
- **SQL Features:** DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE(), Transaction
- **Key Changes:**
  - `GETDATE()` → `clock_timestamp()`
  - SQL DECLARE variables → C# managed variables (reader)
  - SQL transaction block → C# `BeginTransactionAsync()` managed
  - Single SQL statement → 4 separate PostgreSQL statements
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 5: DeleteProductAsync
- **Source Method:** `DeleteProductAsync(int productId)`
- **SQL Features:** DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE, GETDATE(), Transaction
- **Key Changes:**
  - `GETDATE()` → `clock_timestamp()`
  - SQL DECLARE variables → C# managed variables (reader)
  - SQL transaction block → C# `BeginTransactionAsync()` managed
  - Single SQL statement → 4 separate PostgreSQL statements
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Source Method:** `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **SQL Features:** CTE, Window Functions (RANK, PERCENT_RANK), BETWEEN, CASE, ORDER BY
- **Key Changes:** Table/column names lowercased per DMS schema mapping
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 7: GetLowStockProductsAsync
- **Source Method:** `GetLowStockProductsAsync(int threshold)`
- **SQL Features:** CTE, Window Functions (AVG, MIN, MAX OVER), CASE, ROUND, WHERE, ORDER BY
- **Key Changes:**
  - Table/column names lowercased per DMS schema mapping
  - Added `CAST(stockquantity AS NUMERIC)` for integer division compatibility
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

---

## Files Modified

### 1. DataAccess/ProductRepository.cs
- **SQL Statements:** All 7 SQL statements replaced with PostgreSQL equivalents
- **Using Statements:** `using Microsoft.Data.SqlClient` → `using Npgsql`
- **ADO.NET Classes:**
  - `SqlConnection` → `NpgsqlConnection` (3 occurrences)
  - `SqlCommand` → `NpgsqlCommand` (15 occurrences)
  - `SqlDataReader` → `NpgsqlDataReader` (1 occurrence)
- **Transaction Handling:** Restructured for PostgreSQL compatibility
- **Column References in MapProductFromReader:** Updated to lowercase

### 2. AdoCore.csproj
- **Removed:** `Microsoft.Data.SqlClient` Version 5.1.4
- **Added:** `Npgsql` Version 8.0.6 (upgraded from plan's 8.0.1 to fix vulnerability GHSA-x9vc-6hfv-hg8c)

### 3. appsettings.json
- **Connection String Format:** SQL Server → PostgreSQL
  - `Server=localhost` → `Host=localhost`
  - Added `Port=5432`
  - `Database=ProductManagement` → `Database=postgres`
  - Removed: `Trusted_Connection`, `MultipleActiveResultSets`, `TrustServerCertificate`
  - Added: `Username=postgres`, `Password=postgres`

---

## Schema Mapping Applied

Schema mappings retrieved from DMS Schema Mapping Tool:

| Source (MS SQL) | Target (PostgreSQL) |
|-----------------|---------------------|
| `dbo.Products` | `products` |
| `dbo.ProductHistory` | `producthistory` |
| `dbo.ProductStats` | `productstats` |
| `ProductId` | `productid` |
| `Name` | `name` |
| `Description` | `description` |
| `Price` | `price` |
| `StockQuantity` | `stockquantity` |
| `CreatedDate` | `createddate` |
| `ModifiedDate` | `modifieddate` |
| `GETDATE()` | `clock_timestamp()` |
| `SCOPE_IDENTITY()` | `RETURNING productid` |
| `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` |
| `datetime` | `TIMESTAMP WITHOUT TIME ZONE` |
| `decimal(18,2)` | `NUMERIC(18,2)` |

---

## Transformation Artifacts

| Artifact | Location | Status |
|----------|----------|--------|
| Original SQL Catalog | `sourceCode/extracted_statements.sql` | ✅ Complete (7 statements) |
| Converted SQL Catalog | `sourceCode/converted_statements.sql` | ✅ Complete (7 statements) |
| SQL Equivalency Report | `sourceCode/sql_equivalency_validation_report.json` | ✅ Complete (7 entries) |
| Migration Report | `sourceCode/migration_report.md` | ✅ Complete |

---

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. **DMS conversion failure** - All statements were manually converted
2. **SQL Equivalency tool errors** - All equivalency validations returned ERROR due to tool infrastructure issue

**Recommended Actions:**
- Manually verify each converted SQL statement against PostgreSQL syntax
- Run integration tests against a PostgreSQL database to validate correctness
- Review transaction restructuring (Statements 3, 4, 5) for atomicity guarantees

---

## Build Status

- **Build Result:** ✅ Success (0 errors, 10 pre-existing warnings)
- **Vulnerable Dependencies:** None (Npgsql 8.0.6 has no known vulnerabilities)
