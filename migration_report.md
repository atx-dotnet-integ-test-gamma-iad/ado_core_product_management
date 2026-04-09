# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Statements Successfully Converted by DMS | 0 |
| Statements Requiring Manual Intervention | 7 |
| Statements Validated as Equivalent | 0 |
| Statements Validated as Non-Equivalent | 0 |
| Statements with Equivalency Validation Errors | 7 |

## DMS Tool Results

All 7 DMS conversion attempts failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**Migration Project ARN:** `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

All statements were manually converted with lowercase schema object names per the transformation rules (`DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`).

## SQL Equivalency Tool Results

All 7 equivalency validations returned ERROR from the SQL Equivalency tool:
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

**Note:** All equivalency statuses are from the SQL Equivalency MCP tool. No agent judgment was used to determine equivalency.

## Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** CTE with AVG/COUNT OVER(), INNER JOIN, CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** Schema objects lowercased (Products → products, ProductId → productid, etc.)

### Statement 2: GetProductByIdAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** CTE with LAG window function, LEFT JOIN, parameterized
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** Schema objects lowercased

### Statement 3: InsertProductAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY(), UPDATE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:**
  - `DECLARE @NewProductId INT` → removed (using `lastval()`)
  - `SCOPE_IDENTITY()` → `lastval()`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Schema objects lowercased

### Statement 4: UpdateProductAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** Transaction block with DECLARE variables, UPDATE, INSERT history
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:**
  - `DECLARE @OldPrice/@OldStock` → replaced with subqueries
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Schema objects lowercased

### Statement 5: DeleteProductAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** Transaction block with DELETE, INSERT history, CASE in UPDATE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:**
  - `DECLARE @OldPrice/@OldStock` → replaced with subqueries
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Schema objects lowercased

### Statement 6: GetProductsByPriceRangeAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** CTE with RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** Schema objects lowercased

### Statement 7: GetLowStockProductsAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** CTE with AVG/MIN/MAX OVER(), CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:**
  - `ROUND((StockQuantity / AvgStock) * 100, 2)` → `ROUND((CAST(stockquantity AS numeric) / avgstock) * 100, 2)` (integer division fix)
  - Schema objects lowercased

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted, `using Microsoft.Data.SqlClient` → `using Npgsql`, SqlConnection → NpgsqlConnection, SqlCommand → NpgsqlCommand, SqlDataReader → NpgsqlDataReader |
| `AdoCore.csproj` | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6` |
| `appsettings.json` | Connection strings converted to PostgreSQL format (Host, Port, Username, Password) |
| `Database/Scripts/01_InitialSetup.sql` | Full DDL conversion to PostgreSQL (SERIAL, varchar, timestamp, boolean, functions, triggers) |
| `Scripts/01_InitialSetup.sql` | Simplified DDL conversion to PostgreSQL |

## Files NOT Modified

| File | Reason |
|------|--------|
| `Business/ProductService.cs` | No database access code; uses business-layer abstractions |
| `Models/Product.cs` | Data model only; no database-specific code |
| `CLI/CommandLineInterface.cs` | CLI logic only; no database-specific code |
| `CLI/InteractiveMenu.cs` | Menu logic only; no database-specific code |
| `Program.cs` | Application entry point; no database-specific code |

## Transformation Artifacts

| Artifact | Description |
|----------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Complete equivalency validation report |
| `migration_report.md` | This migration report |

## Build Validation

- **Build Status:** SUCCESS
- **Errors:** 0
- **Warnings:** 10 (pre-existing nullable reference warnings)
- **SQL Server References Remaining:** None
- **Npgsql Package:** 8.0.6 (upgraded from plan's 8.0.0 due to known vulnerability)
