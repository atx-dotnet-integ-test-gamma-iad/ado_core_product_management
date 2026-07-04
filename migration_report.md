# SQL Server to PostgreSQL Migration Report

## Summary
- **Total SQL statements processed**: 7
- **Statements successfully converted by DMS MCP tool**: 0
- **Statements requiring manual intervention after DMS tool failure**: 7
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 7

## DMS Tool Failure Details
All 7 DMS conversion attempts failed due to network connectivity issues:
- Statement 1: "DMS Schema Conversion couldn't establish a connection to databases using provided subnets"
- Statements 2-7: "Metadata model creation did not complete after 15 attempts"

## SQL Equivalency Tool Details
All 7 equivalency validation attempts returned ERROR with message: `'uniqueID'`
This appears to be an internal tool error unrelated to the SQL statements themselves.

## Manual Conversion Approach
Since DMS was unavailable, all conversions applied:
- Lowercase schema object naming convention for PostgreSQL
- SCOPE_IDENTITY() → RETURNING clause with data-modifying CTEs
- GETDATE() → NOW()
- BEGIN TRANSACTION/COMMIT with DECLARE → Data-modifying CTEs (atomic single-statement execution)
- T-SQL variable declarations → PostgreSQL CTE-based approach

## Files Modified
1. `sourceCode/DataAccess/ProductRepository.cs` - All SQL statements converted, ADO.NET classes replaced
2. `sourceCode/AdoCore.csproj` - Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.3
3. `sourceCode/appsettings.json` - Connection strings updated to PostgreSQL format

## Artifacts Generated
1. `sourceCode/extracted_statements.sql` - Original MS SQL statements catalog
2. `sourceCode/converted_statements.sql` - Converted PostgreSQL statements catalog
3. `sourceCode/sql_equivalency_validation_report.json` - Full equivalency validation report

## Conversion Details per Statement

| # | Method | Source | Key Changes |
|---|--------|--------|-------------|
| 1 | GetAllProductsAsync | CTE + Window functions | Lowercase identifiers only |
| 2 | GetProductByIdAsync | CTE + LAG window | Lowercase identifiers only |
| 3 | InsertProductAsync | Transaction + SCOPE_IDENTITY | RETURNING + data-modifying CTEs + NOW() |
| 4 | UpdateProductAsync | Transaction + DECLARE + GETDATE | Data-modifying CTEs + NOW() |
| 5 | DeleteProductAsync | Transaction + DECLARE + GETDATE | Data-modifying CTEs + NOW() |
| 6 | GetProductsByPriceRangeAsync | CTE + RANK/PERCENT_RANK | Lowercase identifiers only |
| 7 | GetLowStockProductsAsync | CTE + AVG/MIN/MAX | Lowercase + CAST for integer division |

## Static Code Changes
- `using Microsoft.Data.SqlClient` → `using Npgsql`
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`
- Connection string: `Server=` → `Host=`, removed `Trusted_Connection`, `MultipleActiveResultSets`, `TrustServerCertificate`; added `Username`/`Password`
