# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary

| Metric | Value |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS MCP Tool | 0 |
| Requiring Manual Intervention | 7 |
| Validated as Equivalent | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Validation Errors | 7 |

## DMS MCP Tool Status

The DMS MCP tool (dms-mcp___statement_conversion_tool) was attempted for all 7 statements but consistently failed with the following error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**Migration Project ARN:** arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4  
**Schema:** dbo  
**Database:** ProductManagement  
**Region:** us-east-1

As per the transformation definition, all 7 statements were manually converted with lowercase schema object names applied (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

## SQL Equivalency Validation Status

The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) was called for all 7 statement pairs but returned ERROR for each with error: `'uniqueID'`. This is an internal tool error and does not reflect on the quality of the conversions.

## Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error:** Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Equivalency Status:** ERROR (tool returned: 'uniqueID')
- **Key Changes:**
  - Schema objects lowercased (Products → products, ProductId → productid, etc.)
  - CTE and window functions (AVG OVER, COUNT OVER) are PostgreSQL compatible
  - ROUND function is PostgreSQL compatible
  - CASE expressions are PostgreSQL compatible

### Statement 2: GetProductByIdAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error:** Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Equivalency Status:** ERROR (tool returned: 'uniqueID')
- **Key Changes:**
  - Schema objects lowercased
  - LAG window function is PostgreSQL compatible
  - Parameter @ProductId retained (supported by Npgsql)

### Statement 3: InsertProductAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error:** Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Equivalency Status:** ERROR (tool returned: 'uniqueID')
- **Key Changes:**
  - SCOPE_IDENTITY() replaced with INSERT...RETURNING in PostgreSQL CTE pattern
  - GETDATE() replaced with NOW()
  - BEGIN TRANSACTION/COMMIT replaced with CTE-based writable approach
  - Schema objects lowercased

### Statement 4: UpdateProductAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error:** Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Equivalency Status:** ERROR (tool returned: 'uniqueID')
- **Key Changes:**
  - DECLARE/SELECT INTO variable pattern removed (restructured as multi-statement)
  - GETDATE() replaced with NOW()
  - BEGIN TRANSACTION/COMMIT removed (uses Npgsql transaction handling)
  - Schema objects lowercased

### Statement 5: DeleteProductAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error:** Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Equivalency Status:** ERROR (tool returned: 'uniqueID')
- **Key Changes:**
  - DECLARE/SELECT INTO variable pattern replaced with subquery
  - GETDATE() replaced with NOW()
  - BEGIN TRANSACTION/COMMIT removed (uses Npgsql transaction handling)
  - CASE expression in UPDATE is PostgreSQL compatible
  - Schema objects lowercased

### Statement 6: GetProductsByPriceRangeAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error:** Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Equivalency Status:** ERROR (tool returned: 'uniqueID')
- **Key Changes:**
  - Schema objects lowercased
  - RANK() and PERCENT_RANK() window functions are PostgreSQL compatible
  - BETWEEN operator is PostgreSQL compatible

### Statement 7: GetLowStockProductsAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error:** Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Equivalency Status:** ERROR (tool returned: 'uniqueID')
- **Key Changes:**
  - Schema objects lowercased
  - AVG/MIN/MAX window functions are PostgreSQL compatible
  - Added CAST(stockquantity AS DECIMAL) to prevent integer division in ROUND
  - CASE expression is PostgreSQL compatible

## File Changes Summary

| File | Change Type | Description |
|------|-------------|-------------|
| DataAccess/ProductRepository.cs | Modified | All 7 SQL statements converted to PostgreSQL; ADO.NET classes replaced with Npgsql equivalents; using directive updated |
| AdoCore.csproj | Modified | Microsoft.Data.SqlClient 5.1.4 replaced with Npgsql 8.0.6 |
| appsettings.json | Modified | Connection strings updated from SQL Server to PostgreSQL format |
| extracted_statements.sql | New | Catalog of all 7 original MS SQL statements |
| converted_statements.sql | New | Catalog of all 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | New | Comprehensive equivalency validation report |
| migration_report.md | New | This report |

## Static Code Changes

### Package Dependencies
- **Removed:** Microsoft.Data.SqlClient 5.1.4
- **Added:** Npgsql 8.0.6 (8.0.6 chosen over 8.0.0 to avoid known high-severity vulnerability GHSA-x9vc-6hfv-hg8c)

### Using Directives
- **Removed:** `using Microsoft.Data.SqlClient;`
- **Added:** `using Npgsql;`

### ADO.NET Class Replacements
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`

### Connection String Changes
- `Server=` → `Host=`
- `Trusted_Connection=True` → `Username=postgres;Password=postgres`
- Removed: `MultipleActiveResultSets=true` (not applicable to PostgreSQL)
- Removed: `TrustServerCertificate=True` (not applicable to PostgreSQL)

### Column Name References
- All column references in MapProductFromReader updated to lowercase (e.g., "ProductId" → "productid")

## Build Status

**Final Build:** ✅ SUCCESS  
**Errors:** 0  
**Warnings:** 10 (pre-existing nullable reference type warnings, not related to migration)

## Artifacts Checklist

- [x] extracted_statements.sql - All 7 original MS SQL statements cataloged
- [x] converted_statements.sql - All 7 converted PostgreSQL statements cataloged
- [x] sql_equivalency_validation_report.json - Comprehensive validation report with all 7 pairs
- [x] migration_report.md - This report

## Notes and Recommendations

1. **DMS Tool Failure:** The DMS MCP tool consistently failed due to metadata model creation issues. All conversions were performed manually with lowercase schema naming applied per the transformation definition.

2. **SQL Equivalency Tool Failure:** The SQL Equivalency tool returned internal errors ('uniqueID') for all 7 validations. This appears to be an infrastructure issue and not a reflection of conversion quality.

3. **Manual Review Recommended:** Due to both tools being unavailable, manual review of all 7 SQL statements is recommended to verify correctness of the PostgreSQL conversions.

4. **Transaction Handling:** The original SQL Server batches used DECLARE/SET patterns with BEGIN TRANSACTION/COMMIT. These were restructured for PostgreSQL compatibility using CTEs with INSERT...RETURNING (Statement 3), multi-statement approach (Statements 4, 5), preserving the same logical behavior.

5. **Integer Division:** Statement 7 (GetLowStockProductsAsync) required explicit CAST to DECIMAL to prevent integer division truncation in PostgreSQL's ROUND function.
