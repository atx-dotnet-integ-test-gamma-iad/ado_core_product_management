# Migration Report: SQL Server to PostgreSQL - AdoCore Application

## Executive Summary

This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, replacing database access libraries, and updating connection configuration.

## Migration Statistics

| Metric | Value |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Statements Converted by DMS Tool | 0 (all timed out) |
| Statements Manually Converted | 7 |
| Equivalency Validations Performed | 7 |
| Equivalency Status: EQUIVALENT | 0 |
| Equivalency Status: NOT_EQUIVALENT | 0 |
| Equivalency Status: ERROR | 7 (tool returned systemic 'uniqueID' error) |
| Files Modified | 3 |
| Files Unchanged | 6 (Program.cs, ProductService.cs, Product.cs, CommandLineInterface.cs, InteractiveMenu.cs, README.md) |

## DMS Tool Status

The DMS MCP Statement Conversion Tool (dms-mcp___statement_conversion_tool) was attempted for ALL 7 SQL statements. Every attempt failed with timeout errors:
- **Statements 1, 2, 6, 7**: "Metadata model conversion did not complete after 15 attempts"
- **Statements 3, 4, 5**: "Metadata model creation did not complete after 15 attempts"

The DMS Schema Mapping Tool successfully returned schema mappings that were used to guide manual conversion:
- `dbo.Products` → `productmanagement_dbo.products`
- `dbo.ProductHistory` → `productmanagement_dbo.producthistory`
- `dbo.ProductStats` → `productmanagement_dbo.productstats`

## SQL Equivalency Validation Status

The SQL Equivalency Tool (sql-equivalency___validate_sql_equivalence) was called for ALL 7 statement pairs. Every call returned an ERROR with `'uniqueID'` - this appears to be a systemic tool issue, not related to the quality of the conversions. All results are documented in `sql_equivalency_validation_report.json`.

## SQL Statement Conversions

### Statement 1: GetAllProductsAsync
- **Type**: CTE with AVG/COUNT window functions, CASE, ROUND, JOIN
- **Key Changes**: Table/column names lowercased, schema prefix added (`productmanagement_dbo.products`), CTE alias renamed to `productstats_cte` to avoid conflict with table name
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG window function, CASE, ROUND, LEFT JOIN
- **Key Changes**: Table/column names lowercased, schema prefix added, CTE alias renamed to `producthistory_cte`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 3: InsertProductAsync
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
- **Key Changes**: 
  - `SCOPE_IDENTITY()` → `RETURNING productid` clause
  - `GETDATE()` → `clock_timestamp()`
  - Transaction restructured from single SQL batch to multiple C# commands with BeginTransactionAsync/CommitAsync
  - All table/column names lowercased with `productmanagement_dbo` schema prefix
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **Key Changes**:
  - `DECLARE @var / SELECT @var = col` → C# reader to fetch values
  - `GETDATE()` → `clock_timestamp()`
  - Transaction restructured to multiple C# commands
  - All table/column names lowercased with schema prefix
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE CASE, GETDATE()
- **Key Changes**: Same pattern as Statement 4
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK, PERCENT_RANK window functions, BETWEEN, CASE
- **Key Changes**: Table/column names lowercased, schema prefix added
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Key Changes**: Table/column names lowercased, schema prefix added, added `CAST(stockquantity AS NUMERIC)` for integer division fix
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## Package Dependency Changes

| Before | After |
|--------|-------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.9 |

Note: Npgsql 8.0.9 was chosen instead of 8.0.1 (specified in plan) to address known high severity vulnerability GHSA-x9vc-6hfv-hg8c in Npgsql 8.0.1.

## ADO.NET Class Replacements

| SQL Server Class | PostgreSQL (Npgsql) Equivalent | Occurrences |
|-----------------|-------------------------------|-------------|
| SqlConnection | NpgsqlConnection | 3 |
| SqlCommand | NpgsqlCommand | 15 |
| SqlDataReader | NpgsqlDataReader | 1 |
| SqlTransaction | NpgsqlTransaction | 4 |
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | Server=localhost | Host=localhost |
| Database | Database=ProductManagement | Database=ProductManagement |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets | true | (removed - not applicable) |
| TrustServerCertificate | True | (removed - not applicable) |

## Files Modified

1. **sourceCode/AdoCore.csproj** - Package reference: Microsoft.Data.SqlClient → Npgsql
2. **sourceCode/DataAccess/ProductRepository.cs** - SQL statements, using statements, ADO.NET class references, transaction handling
3. **sourceCode/appsettings.json** - Connection strings converted to PostgreSQL format

## Files Not Requiring Changes

1. **sourceCode/Program.cs** - DI configuration and application entry point remain unchanged
2. **sourceCode/Business/ProductService.cs** - Business logic layer, no database-specific code
3. **sourceCode/Models/Product.cs** - Data model, no database-specific code
4. **sourceCode/CLI/CommandLineInterface.cs** - CLI interface, no database-specific code
5. **sourceCode/CLI/InteractiveMenu.cs** - Interactive menu, no database-specific code
6. **sourceCode/README.md** - Documentation

## Artifacts Generated

1. **extracted_statements.sql** - Complete catalog of all 7 original MS SQL statements
2. **converted_statements.sql** - Complete catalog of all 7 converted PostgreSQL statements
3. **sql_equivalency_validation_report.json** - Comprehensive equivalency validation report
4. **migration_report.md** - This report

## Known Issues & Recommendations

1. **SQL Equivalency Validation**: All 7 statement pairs returned ERROR from the equivalency tool due to a systemic `'uniqueID'` error. Manual review of the converted statements is recommended.
2. **DMS Tool Timeout**: The DMS conversion tool consistently timed out. If DMS becomes available, re-running the conversions may provide additional validation.
3. **Transaction Restructuring**: The original SQL Server code used multi-statement SQL batches with `DECLARE`/`SET` and `BEGIN TRANSACTION`/`COMMIT` within single command strings. These were restructured into multiple separate SQL commands within C# managed transactions, which is the idiomatic approach for Npgsql/PostgreSQL.
4. **Schema Prefix**: All table references now use `productmanagement_dbo` schema prefix as indicated by the DMS schema mapping tool. Ensure this schema exists in the target PostgreSQL database.
