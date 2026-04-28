# Migration Report: MS SQL Server to PostgreSQL

## Overview
Migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL using Npgsql ADO.NET driver.

**Migration Date:** 2026-04-28  
**Application:** AdoCore - Product Management System  
**Framework:** .NET 9.0  
**Source Database:** Microsoft SQL Server  
**Target Database:** PostgreSQL  

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| DMS Tool Conversion Successes | 0 |
| DMS Tool Conversion Failures | 7 |
| Manual Conversions (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA) | 7 |
| Equivalency Validated as EQUIVALENT | 0 |
| Equivalency Validated as NOT_EQUIVALENT | 0 |
| Equivalency Validation ERRORs | 7 |

### DMS Tool Status
All 7 SQL statements were submitted to the DMS MCP statement conversion tool (dms-mcp___statement_conversion_tool) with:
- `schema_name`: dbo
- `migration_project_identifier`: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

All 7 attempts failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

### Schema Mapping (from DMS schema_mapping_tool)
The DMS schema_mapping_tool successfully provided schema mappings used for manual conversion:

| Source Table (MS SQL) | Target Table (PostgreSQL) | Schema |
|----------------------|--------------------------|--------|
| Products | products | productmanagement_dbo |
| ProductHistory | producthistory | productmanagement_dbo |
| ProductStats | productstats | productmanagement_dbo |

All column names converted to lowercase per DMS schema mapping.

### SQL Equivalency Validation
All 7 statement pairs were submitted to the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence).
All 7 returned ERROR with: `'uniqueID'`

---

## SQL Statements Converted

### Statement 1: GetAllProductsAsync
- **Type:** SELECT with CTE, window functions (AVG, COUNT), CASE, ROUND, INNER JOIN
- **Key Changes:** Table/column names lowercased, CTE renamed to `productstats_cte` to avoid conflict with `productstats` table
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 2: GetProductByIdAsync
- **Type:** SELECT with CTE, LAG window function, parameterized query
- **Key Changes:** Table/column names lowercased, CTE renamed to `producthistory_cte` to avoid conflict with `producthistory` table
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 3: InsertProductAsync
- **Type:** Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE()
- **Key Changes:** Restructured as CTE chain with RETURNING clause, SCOPE_IDENTITY() replaced with RETURNING productid, GETDATE() replaced with clock_timestamp(), DECLARE/@var removed
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE, SELECT into variables, UPDATE, INSERT
- **Key Changes:** Restructured as CTE chain, GETDATE() replaced with clock_timestamp(), DECLARE/@var replaced with CTE old_values query, table/column names lowercased
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE, SELECT into variables, INSERT, DELETE, UPDATE with CASE
- **Key Changes:** Restructured as CTE chain, GETDATE() replaced with clock_timestamp(), DECLARE/@var replaced with CTE old_values query, table/column names lowercased
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** SELECT with CTE, RANK(), PERCENT_RANK() window functions, BETWEEN, CASE
- **Key Changes:** Table/column names lowercased
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 7: GetLowStockProductsAsync
- **Type:** SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND
- **Key Changes:** Table/column names lowercased, added CAST(stockquantity AS NUMERIC) for integer division compatibility
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

---

## Files Modified

| File | Changes |
|------|---------|
| sourceCode/DataAccess/ProductRepository.cs | All 7 SQL statements converted to PostgreSQL syntax; using statement changed; ADO.NET classes replaced with Npgsql equivalents; MapProductFromReader column references lowercased |
| sourceCode/AdoCore.csproj | Microsoft.Data.SqlClient 5.1.4 replaced with Npgsql 8.0.1 |
| sourceCode/appsettings.json | Connection strings updated from SQL Server to PostgreSQL format |

---

## Package Dependency Changes

| Action | Package | Version |
|--------|---------|---------|
| Removed | Microsoft.Data.SqlClient | 5.1.4 |
| Added | Npgsql | 8.0.1 |

---

## Connection String Changes

### DevConnection
- **Before:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After:** `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`

### ProdConnection
- **Before:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After:** `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`

### Parameter Mapping
| SQL Server Parameter | PostgreSQL Parameter |
|---------------------|---------------------|
| Server= | Host= |
| Database= | Database= (unchanged) |
| Trusted_Connection=True | Removed (not applicable) |
| MultipleActiveResultSets=true | Removed (not applicable) |
| TrustServerCertificate=True | Removed (not applicable) |
| N/A | Username=postgres (added) |
| N/A | Password=postgres (added) |

---

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent |
|-----------------|-------------------|
| Microsoft.Data.SqlClient (using) | Npgsql (using) |
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |

---

## SQL Syntax Conversions Applied

| MS SQL Syntax | PostgreSQL Syntax |
|--------------|-------------------|
| GETDATE() | clock_timestamp() |
| SCOPE_IDENTITY() | RETURNING productid (CTE chain) |
| DECLARE @var TYPE; SET @var = ... | CTE with subquery |
| BEGIN TRANSACTION / COMMIT | CTE chain (C# manages transactions) |
| Table/Column names (PascalCase) | Table/Column names (lowercase) |
| Integer division | CAST(col AS NUMERIC) / divisor |

---

## Build Status
**Final Build:** SUCCESS  
**Errors:** 0  
**Warnings:** 12 (all pre-existing nullable reference warnings, not introduced by migration)

---

## Migration Artifacts

| Artifact | Description |
|----------|-------------|
| sql_equivalency_validation_report.json | Complete equivalency validation report for all 7 statement pairs |
| extracted_statements.sql | Catalog of all 7 original MS SQL statements |
| converted_statements.sql | Catalog of all 7 converted PostgreSQL statements |
| migration_report.md | This comprehensive migration report |

---

## Manual Interventions Required

All 7 SQL statements required manual conversion due to DMS tool failure. The manual conversion was performed using:
1. Schema mapping information retrieved from the DMS schema_mapping_tool
2. Lowercase naming convention for all schema objects (tables, columns)
3. PostgreSQL-specific syntax replacements (GETDATE -> clock_timestamp, SCOPE_IDENTITY -> RETURNING)
4. Restructuring of transaction blocks with DECLARE variables into CTE chains

All manual conversions are documented in the sql_equivalency_validation_report.json with conversion_method "DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA".
