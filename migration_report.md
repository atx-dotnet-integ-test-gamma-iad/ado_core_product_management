# SQL Server to PostgreSQL Migration Report

## Summary
- **Project**: AdoCore (.NET 9.0 Console Application)
- **Source Database**: Microsoft SQL Server (Microsoft.Data.SqlClient v5.1.4)
- **Target Database**: PostgreSQL (Npgsql v8.0.3)
- **Total SQL Statements Processed**: 7
- **DMS Tool Conversion Success**: 0 (all failed due to network connectivity)
- **Manual Conversions (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)**: 7
- **Equivalency Validations - EQUIVALENT**: 0
- **Equivalency Validations - NOT_EQUIVALENT**: 0
- **Equivalency Validations - ERROR**: 7 (tool returned "'uniqueID'" error for all)

## DMS Tool Failure Details
All 7 SQL statements were passed to the DMS MCP tool (dms-mcp___statement_conversion_tool) and all failed with:
- **Error**: "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}"
- **Root Cause**: Network connectivity - DMS Schema Conversion couldn't establish a connection to the source database at 172.31.83.165:1433 using any of the 6 provided subnets.

## SQL Equivalency Tool Failure Details
All 7 statement pairs were validated through the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) and all returned:
- **Status**: ERROR
- **Error**: "'uniqueID'"
- **Note**: This appears to be a system-level issue with the equivalency tool, not related to statement quality.

## Files Modified
1. **sourceCode/DataAccess/ProductRepository.cs** - Main data access layer
   - Replaced `using Microsoft.Data.SqlClient` with `using Npgsql`
   - Replaced `SqlConnection` with `NpgsqlConnection`
   - Replaced `SqlCommand` with `NpgsqlCommand`
   - Replaced `SqlDataReader` with `NpgsqlDataReader`
   - Converted all 7 SQL statements to PostgreSQL syntax
   - Updated column name references in reader to lowercase

2. **sourceCode/AdoCore.csproj** - Project file
   - Replaced `Microsoft.Data.SqlClient v5.1.4` with `Npgsql v8.0.3`

3. **sourceCode/appsettings.json** - Configuration
   - Replaced SQL Server connection strings with PostgreSQL format
   - `Server=localhost` → `Host=localhost`
   - `Database=ProductManagement` → `Database=productmanagement`
   - `Trusted_Connection=True` → `Username=postgres;Password=postgres`
   - Removed `MultipleActiveResultSets=true;TrustServerCertificate=True`

## SQL Conversion Details

### Statement 1: GetAllProductsAsync (SELECT with CTE + Window Functions)
- **Changes**: Schema objects to lowercase
- **T-SQL Features**: AVG() OVER(), COUNT() OVER(), CTE, CASE, ROUND
- **PostgreSQL Compatibility**: Direct translation (all features supported natively)

### Statement 2: GetProductByIdAsync (SELECT with CTE + LAG)
- **Changes**: Schema objects to lowercase
- **T-SQL Features**: LAG() OVER(), CTE, CASE, ROUND
- **PostgreSQL Compatibility**: Direct translation

### Statement 3: InsertProductAsync (Transaction with SCOPE_IDENTITY)
- **Changes**: Major restructure
  - `DECLARE @var / SET @var = SCOPE_IDENTITY()` → Writable CTE with `RETURNING productid`
  - `BEGIN TRANSACTION / COMMIT` → Single atomic CTE statement
  - `GETDATE()` → `NOW()`
  - Schema objects to lowercase
- **PostgreSQL Approach**: Uses writable CTEs (data-modifying statements in WITH)

### Statement 4: UpdateProductAsync (Transaction with DECLARE variables)
- **Changes**: Major restructure
  - `DECLARE @OldPrice / @OldStock` → CTE `old_values` subquery
  - `BEGIN TRANSACTION / COMMIT` → Single atomic CTE statement
  - `GETDATE()` → `NOW()`
  - Schema objects to lowercase
- **PostgreSQL Approach**: Uses writable CTEs with data-modifying statements

### Statement 5: DeleteProductAsync (Transaction with DECLARE variables)
- **Changes**: Major restructure
  - `DECLARE @OldPrice / @OldStock` → CTE `old_values` subquery
  - `BEGIN TRANSACTION / COMMIT` → Single atomic CTE statement
  - `GETDATE()` → `NOW()`
  - Schema objects to lowercase
- **PostgreSQL Approach**: Uses writable CTEs with data-modifying statements

### Statement 6: GetProductsByPriceRangeAsync (SELECT with CTE + RANK)
- **Changes**: Schema objects to lowercase
- **T-SQL Features**: RANK() OVER(), PERCENT_RANK() OVER(), CTE, CASE, BETWEEN
- **PostgreSQL Compatibility**: Direct translation

### Statement 7: GetLowStockProductsAsync (SELECT with CTE + Window Functions)
- **Changes**: Schema objects to lowercase, added `::numeric` cast for integer division
- **T-SQL Features**: AVG() OVER(), MIN() OVER(), MAX() OVER(), CTE, CASE, ROUND
- **PostgreSQL Note**: Added explicit numeric cast for `stockquantity::numeric / avgstock` to ensure proper decimal division

## Artifacts Generated
1. `extracted_statements.sql` - All 7 original MS SQL statements
2. `converted_statements.sql` - All 7 converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report
4. `migration_report.md` - This report
