# Microsoft SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-04-13 |
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Application Framework** | .NET 9.0, ADO.NET |
| **Migration Tool Used** | AWS DMS (attempted), Manual Conversion (applied) |
| **DMS Migration Project ARN** | arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4 |

---

## SQL Statement Conversion Results

### Overview

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| DMS Conversion Successes | 0 |
| DMS Conversion Failures | 7 |
| Manual Conversions (after DMS failure) | 7 |

### DMS Tool Status

All 7 statements were submitted to the AWS DMS MCP tool (`dms-mcp___statement_conversion_tool`) for conversion. All returned the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Per the transformation rules, when DMS fails, manual conversion was applied with lowercase schema object names (reason: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`).

### Schema Mapping Applied (from DMS Schema Mapping Tool)

The schema mapping tool (`dms-mcp___schema_mapping_tool`) was successful and provided the following mappings:

| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| `dbo.Products` | `productmanagement_dbo.products` |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` |

All column names were converted to lowercase in the target schema.

### Statement Conversion Details

| # | Method | SQL Statement | Key Conversions |
|---|--------|---------------|-----------------|
| 1 | GetAllProductsAsync | CTE with AVG/COUNT OVER(), CASE, ROUND, INNER JOIN | Table/column names to lowercase, schema prefix |
| 2 | GetProductByIdAsync | CTE with LAG OVER(), LEFT JOIN, ROUND, @ProductId param | Table/column names to lowercase, schema prefix |
| 3 | InsertProductAsync | Transaction: INSERT + SCOPE_IDENTITY() + INSERT history + UPDATE stats | SCOPE_IDENTITY() → RETURNING, GETDATE() → clock_timestamp(), split into 3 separate statements with C# transaction |
| 4 | UpdateProductAsync | Transaction: DECLARE/SELECT INTO vars + UPDATE + INSERT history + UPDATE stats | DECLARE/SET → C# variables, GETDATE() → clock_timestamp(), split into 4 statements |
| 5 | DeleteProductAsync | Transaction: DECLARE/SELECT INTO vars + INSERT history + DELETE + UPDATE stats | DECLARE/SET → C# variables, GETDATE() → clock_timestamp(), CASE preserved, split into 4 statements |
| 6 | GetProductsByPriceRangeAsync | CTE with RANK(), PERCENT_RANK(), BETWEEN, CASE | Table/column names to lowercase, schema prefix |
| 7 | GetLowStockProductsAsync | CTE with AVG/MIN/MAX OVER(), CASE, ROUND | Table/column names to lowercase, integer division fix (::numeric cast) |

---

## SQL Equivalency Validation Results

### Overview

| Metric | Count |
|--------|-------|
| Total Pairs Validated | 7 |
| EQUIVALENT | 0 |
| NOT_EQUIVALENT | 0 |
| ERROR | 7 |

### Tool Status

All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All returned:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This is a systemic tool error (not related to our specific statements). Per transformation rules, all pairs are marked as ERROR in the report. **No agent judgment was used to determine equivalency.**

---

## Files Modified

### Source Code Changes

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced all SQL statements with PostgreSQL equivalents; Replaced SqlConnection/SqlCommand/SqlDataReader/SqlParameter with NpgsqlConnection/NpgsqlCommand/NpgsqlDataReader/NpgsqlParameter; Updated using directive; Restructured transactional methods to use C# managed transactions |
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.6` |
| `appsettings.json` | Updated connection strings from SQL Server format to PostgreSQL format |

### Package Changes

| Original Package | New Package |
|------------------|-------------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |

### Class Replacements

| Original Class | Replacement Class |
|----------------|-------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |

### Using Directive Changes

| Original | Replacement |
|----------|-------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |

### Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

---

## Key SQL Syntax Conversions

| SQL Server | PostgreSQL | Notes |
|-----------|-----------|-------|
| `SCOPE_IDENTITY()` | `RETURNING productid` | Used in INSERT with RETURNING clause |
| `GETDATE()` | `clock_timestamp()` | Matches DMS schema default mapping |
| `DECLARE @var TYPE; SET @var = expr` | C# variable assignment | Split into separate SELECT + C# code |
| `BEGIN TRANSACTION; ... COMMIT;` | C# `BeginTransactionAsync()` / `CommitAsync()` | Transaction managed at application level |
| `Products` | `productmanagement_dbo.products` | Schema prefix + lowercase per DMS mapping |
| `ProductId` | `productid` | All columns lowercase per DMS mapping |
| `ROUND(int/int)` | `ROUND(int::numeric/int)` | Added explicit numeric cast for integer division |

---

## Manual Interventions

All 7 statements required manual conversion due to DMS tool failure. The manual conversions followed these rules:
1. Applied lowercase schema object names per DMS schema mapping tool output
2. Used `productmanagement_dbo` schema prefix for all table references
3. Converted SQL Server-specific functions to PostgreSQL equivalents
4. Split T-SQL transaction blocks with DECLARE/SET into individual statements managed by C# transactions
5. Replaced SCOPE_IDENTITY() with INSERT...RETURNING pattern
6. Replaced GETDATE() with clock_timestamp() (matching DMS schema defaults)

---

## Artifacts Generated

| Artifact | Description |
|----------|-------------|
| `extracted_statements.sql` | All 7 original MS SQL statements |
| `converted_statements.sql` | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Complete equivalency validation report with all 7 pairs |
| `migration_summary_report.md` | This report |

---

## Build Status

**Build: SUCCEEDED** (0 errors, 0 vulnerability warnings)

The application compiles successfully with the Npgsql package and all PostgreSQL-compatible code changes.
