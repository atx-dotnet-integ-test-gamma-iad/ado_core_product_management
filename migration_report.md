# Migration Report - MS SQL Server to PostgreSQL

## Project: AdoCore - Product Management Application
## Date: 2026-04-24

---

## Executive Summary

Successfully migrated the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL. All SQL statements, package dependencies, ADO.NET class references, and connection strings have been updated for PostgreSQL compatibility.

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL statements processed** | 7 |
| **Successfully converted by DMS MCP tool** | 0 |
| **Requiring manual intervention (DMS failed)** | 7 |
| **Validated as equivalent (SQL Equivalency tool)** | 0 |
| **Validated as non-equivalent** | 0 |
| **Equivalency validation errors** | 7 |

### DMS Tool Status
All 7 SQL statements were passed through the DMS MCP statement conversion tool (dms-mcp___statement_conversion_tool). All 7 failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```
Manual conversion was applied using lowercase schema object naming convention per the transformation definition.

### SQL Equivalency Tool Status
All 7 statement pairs were validated through the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence). All 7 returned ERROR status:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```
This was a persistent backend infrastructure error, not related to the SQL statements themselves.

---

## SQL Statement Details

| # | Method | Type | DMS Status | Conversion | Key Changes |
|---|--------|------|------------|------------|-------------|
| 1 | GetAllProductsAsync | SELECT (CTE, Window Functions) | FAILED | Manual | Lowercase schema objects |
| 2 | GetProductByIdAsync | SELECT (CTE, LAG, LEFT JOIN) | FAILED | Manual | Lowercase schema objects |
| 3 | InsertProductAsync | Transaction (INSERT, SCOPE_IDENTITY) | FAILED | Manual | RETURNING clause, NOW(), restructured |
| 4 | UpdateProductAsync | Transaction (UPDATE, DECLARE) | FAILED | Manual | NOW(), C# variable handling, restructured |
| 5 | DeleteProductAsync | Transaction (DELETE, DECLARE, CASE) | FAILED | Manual | NOW(), C# variable handling, restructured |
| 6 | GetProductsByPriceRangeAsync | SELECT (CTE, RANK, PERCENT_RANK) | FAILED | Manual | Lowercase schema objects |
| 7 | GetLowStockProductsAsync | SELECT (CTE, AVG/MIN/MAX OVER) | FAILED | Manual | Lowercase, CAST for decimal division |

---

## Files Modified

| File | Changes |
|------|---------|
| DataAccess/ProductRepository.cs | SQL statements converted, ADO.NET classes replaced, reader column names lowercased |
| AdoCore.csproj | Microsoft.Data.SqlClient → Npgsql |
| appsettings.json | Connection strings updated to PostgreSQL format |

---

## Package Dependency Changes

| Action | Package | Version |
|--------|---------|---------|
| **Removed** | Microsoft.Data.SqlClient | 5.1.4 |
| **Added** | Npgsql | 8.0.1 |
| Unchanged | Microsoft.Extensions.Configuration | 8.0.0 |
| Unchanged | Microsoft.Extensions.Configuration.Json | 8.0.0 |
| Unchanged | Microsoft.Extensions.DependencyInjection | 8.0.0 |

---

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server/Host | Server=localhost | Host=localhost |
| Database | Database=ProductManagement | Database=ProductManagement |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets | true | N/A (removed) |
| TrustServerCertificate | True | N/A (removed) |

---

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | Complete catalog of all 7 original MS SQL statements |
| converted_statements.sql | sourceCode/ | Complete catalog of all 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | sourceCode/ | Comprehensive equivalency validation report for all 7 pairs |
| dms_failure_log.md | sourceCode/ | Detailed DMS failure documentation |
| migration_log.md | sourceCode/ | Detailed migration log with per-statement details |
| migration_report.md | sourceCode/ | This final migration summary report |

---

## Known Issues and Recommendations

1. **DMS Tool Unavailability**: The DMS MCP tool was unavailable during migration due to a persistent metadata model creation error. All conversions were performed manually. It is recommended to re-validate the SQL conversions when the DMS tool becomes available.

2. **SQL Equivalency Tool Error**: The SQL Equivalency tool experienced backend errors during all validation attempts. Manual review of the SQL conversions is recommended.

3. **Connection String Credentials**: Placeholder credentials (postgres/postgres) are used in the connection strings. These must be replaced with actual PostgreSQL credentials before deployment.

4. **Transaction Restructuring**: Statements 3, 4, and 5 were restructured from single T-SQL batches to multiple separate SQL statements within C# transactions. This maintains atomicity but changes the execution pattern. Testing is recommended.

5. **Integer Division**: Statement 7 (GetLowStockProductsAsync) adds an explicit CAST(stockquantity AS DECIMAL) to prevent integer truncation in the division, which is a PostgreSQL behavior difference from SQL Server.
