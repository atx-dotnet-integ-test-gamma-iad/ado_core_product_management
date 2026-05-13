# SQL Server to PostgreSQL Migration Report

## Summary
- **Total SQL statements processed**: 7
- **Statements successfully converted by DMS**: 0 (all failed with metadata model error)
- **Statements manually converted**: 7 (with lowercase schema mapping)
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 7 (tool returned 'uniqueID' error)

## DMS Tool Failure
All 7 SQL statements were passed to the DMS MCP tool for conversion. All failed with:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Manual conversion was applied using the DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA approach:
- All schema object names converted to lowercase
- SCOPE_IDENTITY() replaced with INSERT ... RETURNING
- GETDATE() replaced with NOW()
- T-SQL variable declarations replaced with CTE-based approach
- BEGIN TRANSACTION/COMMIT blocks replaced with atomic CTE statements

## SQL Equivalency Validation
All 7 statement pairs were submitted to the SQL Equivalency tool. All returned ERROR:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

## Code Changes Applied

### Files Modified:
1. **sourceCode/DataAccess/ProductRepository.cs**
   - Replaced `using Microsoft.Data.SqlClient` with `using Npgsql`
   - Replaced `SqlConnection` with `NpgsqlConnection`
   - Replaced `SqlCommand` with `NpgsqlCommand`
   - Replaced `SqlDataReader` with `NpgsqlDataReader`
   - All SQL statements converted to PostgreSQL syntax with lowercase schema
   - Reader column references updated to lowercase

2. **sourceCode/AdoCore.csproj**
   - Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.1`

3. **sourceCode/appsettings.json**
   - Connection strings updated from SQL Server format to PostgreSQL format
   - `Server=` replaced with `Host=`
   - `Trusted_Connection` and `MultipleActiveResultSets` removed
   - Added `Username` and `Password` parameters

### Files Created:
4. **sourceCode/extracted_statements.sql** - Original SQL statements catalog
5. **sourceCode/converted_statements.sql** - Converted PostgreSQL statements catalog
6. **sourceCode/sql_equivalency_validation_report.json** - Equivalency validation report

## SQL Conversion Details

| # | Method | Source | Key Changes |
|---|--------|--------|-------------|
| 1 | GetAllProductsAsync | SELECT with CTE + window functions | Lowercase schema names |
| 2 | GetProductByIdAsync | SELECT with CTE + LAG | Lowercase schema names |
| 3 | InsertProductAsync | INSERT + SCOPE_IDENTITY + transaction | CTE with RETURNING, NOW() |
| 4 | UpdateProductAsync | UPDATE + variable declarations + transaction | CTE approach, NOW() |
| 5 | DeleteProductAsync | DELETE + variable declarations + transaction | CTE approach, NOW() |
| 6 | GetProductsByPriceRangeAsync | SELECT with CTE + RANK/PERCENT_RANK | Lowercase schema names |
| 7 | GetLowStockProductsAsync | SELECT with CTE + window functions | Lowercase + ::numeric cast |
