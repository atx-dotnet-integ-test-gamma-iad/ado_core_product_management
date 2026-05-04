# Migration Summary: SQL Server to PostgreSQL

## Overview
This document summarizes the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL using ADO.NET (Npgsql).

**Migration Date:** 2026-05-04  
**Source Database:** Microsoft SQL Server 2019  
**Target Database:** PostgreSQL 13  
**Application Framework:** .NET 9.0, ADO.NET  

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS** | 0 |
| **Requiring Manual Intervention** | 7 |
| **Validated as Equivalent** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |

### DMS Tool Status
- **Tool:** dms-mcp___statement_conversion_tool
- **Migration Project ARN:** arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Status:** All 7 conversion attempts FAILED
- **Error:** `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Resolution:** Manual conversion applied using DMS schema mapping tool output with lowercase schema objects (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)

### SQL Equivalency Tool Status
- **Tool:** sql-equivalency___validate_sql_equivalence
- **Status:** All 7 validation attempts returned ERROR
- **Error:** `'uniqueID'`
- **Note:** All equivalency statuses reflect the tool's actual output; no agent judgment was used

### Schema Mappings (from DMS schema_mapping_tool)
| Source (SQL Server) | Target (PostgreSQL) |
|---|---|
| `dbo.Products` | `productmanagement_dbo.products` |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` |

---

## SQL Statement Details

### Statement 1: GetAllProductsAsync
- **Type:** SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Lowercase table/column names, `productmanagement_dbo` schema prefix, CTE renamed to `productstats_cte`
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)

### Statement 2: GetProductByIdAsync
- **Type:** SELECT with CTE, LAG Window Function, LEFT JOIN, CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Lowercase names, schema prefix, CTE renamed to `producthistory_cte`
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)

### Statement 3: InsertProductAsync
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY(), INSERT history, UPDATE stats
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** `SCOPE_IDENTITY()` → `RETURNING productid`, `GETDATE()` → `NOW()`, restructured from single SQL block to 3 separate statements with C# transaction management
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)

### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT history, UPDATE stats
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** `GETDATE()` → `NOW()`, SQL Server variables replaced with C# variables, restructured to 4 separate statements
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)

### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO variables, INSERT history, DELETE, UPDATE stats with CASE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** `GETDATE()` → `NOW()`, SQL Server variables replaced with C# variables, restructured to 4 separate statements
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** SELECT with CTE, RANK() OVER, PERCENT_RANK() OVER, CASE, BETWEEN
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Lowercase names, schema prefix, CTE renamed to `rankedproducts`
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)

### Statement 7: GetLowStockProductsAsync
- **Type:** SELECT with CTE, AVG/MIN/MAX OVER(), CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Lowercase names, schema prefix, CTE renamed to `stockanalysis`, added `CAST(stockquantity AS NUMERIC)` for integer division fix
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)

---

## Files Modified

| File | Change Type | Description |
|------|-------------|-------------|
| `DataAccess/ProductRepository.cs` | Modified | Replaced all SQL statements, ADO.NET classes, and using directive |
| `AdoCore.csproj` | Modified | Replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.0 |
| `appsettings.json` | Modified | Converted connection strings to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Modified | Converted to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Modified | Converted to PostgreSQL syntax (full schema) |

---

## Package Changes

| Original Package | Version | Replacement Package | Version |
|--|--|--|--|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.0 |

*Unchanged packages: Microsoft.Extensions.Configuration 8.0.0, Microsoft.Extensions.Configuration.Json 8.0.0, Microsoft.Extensions.DependencyInjection 8.0.0*

---

## Class Replacements

| SQL Server Class | Npgsql Replacement |
|---|---|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |
| `Microsoft.Data.SqlClient` (namespace) | `Npgsql` (namespace) |

---

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|---|---|---|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | *Removed (not supported)* |
| TrustServerCertificate | `TrustServerCertificate=True` | *Removed (not applicable)* |

---

## SQL Script Conversions

### Key SQL Server → PostgreSQL Syntax Changes Applied

| SQL Server Construct | PostgreSQL Equivalent |
|---|---|
| `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` |
| `GETDATE()` | `clock_timestamp()` / `NOW()` |
| `SCOPE_IDENTITY()` | `RETURNING` clause |
| `GO` (batch separator) | *Removed (not needed)* |
| `IF NOT EXISTS (SELECT * FROM sys.objects...)` | `DROP TABLE IF EXISTS` / `CREATE TABLE IF NOT EXISTS` |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `TRIGGER ON table AFTER INSERT, UPDATE, DELETE` | `TRIGGER FUNCTION` + `CREATE TRIGGER` |
| `SYSTEM_USER` | `current_user` |
| `nvarchar(n)` | `VARCHAR(n)` |
| `datetime` | `TIMESTAMP WITHOUT TIME ZONE` |
| `bit` | `NUMERIC(1,0)` |
| `[dbo].[TableName]` | `productmanagement_dbo.tablename` |

---

## Statements Requiring Manual Review

All 7 statements require manual review because:
1. **DMS conversion failed** for all statements (metadata model creation error)
2. **SQL equivalency validation returned ERROR** for all statement pairs (tool internal error)
3. Manual conversions were applied following lowercase schema mapping rules derived from DMS schema_mapping_tool

### Recommended Actions
- Re-attempt DMS conversion when the metadata model creation issue is resolved
- Re-run SQL equivalency validation when the `'uniqueID'` error is resolved
- Perform integration testing with actual PostgreSQL database to validate query correctness
- Review transaction restructuring in Insert/Update/Delete methods for correctness

---

## Transformation Artifacts

| Artifact | Location | Description |
|---|---|---|
| `extracted_statements.sql` | `sourceCode/` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | `sourceCode/` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | `sourceCode/` | Complete equivalency validation report with all 7 statement pairs |
| `migration_summary.md` | `sourceCode/` | This migration summary document |
