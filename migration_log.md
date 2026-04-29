# Migration Log: MS SQL Server to PostgreSQL

## Summary
- **Project**: AdoCore - Product Management Application
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Migration Type**: ADO.NET application code migration (Microsoft.Data.SqlClient → Npgsql)

## SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS | 0 |
| Requiring manual intervention (DMS failure) | 7 |
| Validated as equivalent (by tool) | 0 |
| Validated as non-equivalent (by tool) | 0 |
| Equivalency validation errors | 7 |

## DMS Tool Results
All 7 SQL statements from ProductRepository.cs were passed to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) with `schema_name='dbo'`.

**All 7 failed with the same error:**
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**DMS schema_mapping_tool results (successful):**
- `Products` → `products` (schema: `productmanagement_dbo`)
- `ProductHistory` → `producthistory` (schema: `productmanagement_dbo`)
- `ProductStats` → `productstats` (schema: `productmanagement_dbo`)
- All column names converted to lowercase

## Manual Conversion Applied
Since DMS failed, manual conversion was applied following the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` protocol:
- All schema object names (tables, columns) converted to lowercase
- Schema mapping from DMS schema_mapping_tool was used as reference
- Key SQL Server → PostgreSQL syntax conversions:
  - `SCOPE_IDENTITY()` → `RETURNING productid`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → C# managed Npgsql transactions
  - `DECLARE @var` → C# variable management with separate SQL commands
  - `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`
  - `NVARCHAR` → `VARCHAR`
  - `BIT` → `BOOLEAN`
  - `SYSTEM_USER` → `current_user`
  - Integer division fix: Added `CAST(stockquantity AS NUMERIC)` for division operations

## SQL Equivalency Tool Results
All 7 statement pairs were passed to the SQL Equivalency MCP tool (`sql-equivalency___validate_sql_equivalence`).

**All 7 returned ERROR:**
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

The equivalency tool experienced a consistent internal error (`'uniqueID'`). Per the transformation definition, these are documented as ERROR status - agent judgment was NOT used to determine equivalency.

## Files Modified

### 1. sourceCode/DataAccess/ProductRepository.cs
- **Using directive**: `Microsoft.Data.SqlClient` → `Npgsql`
- **Types replaced**:
  - `SqlConnection` → `NpgsqlConnection` (field, method return, constructor)
  - `SqlCommand` → `NpgsqlCommand` (all 15 usages)
  - `SqlDataReader` → `NpgsqlDataReader` (MapProductFromReader parameter)
- **SQL statements replaced** (7 total):
  1. `GetAllProductsAsync`: CTE with lowercase tables/columns, CTE renamed to `productstats_cte`
  2. `GetProductByIdAsync`: CTE with lowercase, CTE renamed to `producthistory_cte`
  3. `InsertProductAsync`: Restructured from single SQL block to 3 commands with C# transaction, `SCOPE_IDENTITY()` → `RETURNING productid`
  4. `UpdateProductAsync`: Restructured from single SQL block to 4 commands with C# transaction, `GETDATE()` → `NOW()`
  5. `DeleteProductAsync`: Restructured from single SQL block to 4 commands with C# transaction
  6. `GetProductsByPriceRangeAsync`: CTE with lowercase
  7. `GetLowStockProductsAsync`: CTE with lowercase, added `CAST` for integer division
- **MapProductFromReader**: Column names updated to lowercase (`productid`, `name`, `description`, `price`, `stockquantity`, `createddate`, `modifieddate`)

### 2. sourceCode/AdoCore.csproj
- **Removed**: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added**: `<PackageReference Include="Npgsql" Version="8.0.6" />`

### 3. sourceCode/appsettings.json
- **DevConnection**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`
- **ProdConnection**: Same transformation pattern

### 4. sourceCode/Scripts/01_InitialSetup.sql
- Converted from MS SQL Server DDL to PostgreSQL
- `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`
- `GETDATE()` → `clock_timestamp()`
- `NVARCHAR` → `VARCHAR`
- `GO` statements removed
- `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION`
- Stored procedures converted to PostgreSQL functions with `LANGUAGE plpgsql`

### 5. sourceCode/Database/Scripts/01_InitialSetup.sql
- Full conversion from MS SQL Server DDL to PostgreSQL
- All table names lowercased
- All column names lowercased
- `BIT` → `BOOLEAN`
- Trigger converted to PostgreSQL trigger function
- `SYSTEM_USER` → `current_user`
- All stored procedures converted to PostgreSQL functions
- `IF NOT EXISTS/IF EXISTS` patterns converted to PostgreSQL equivalents
- All indexes and constraints maintained with lowercase names

## Artifacts Created
1. `sourceCode/extracted_statements.sql` - Complete catalog of all 7 original MS SQL statements
2. `sourceCode/converted_statements.sql` - Complete catalog of all 7 converted PostgreSQL statements
3. `sourceCode/sql_equivalency_validation_report.json` - Comprehensive equivalency report with all 7 statement pairs
4. `sourceCode/migration_log.md` - This file

## Statement Details

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, window functions, CASE, ROUND, JOIN
- **DMS Result**: Failed (metadata model creation error)
- **Conversion**: Manual with lowercase schema
- **Equivalency**: ERROR ('uniqueID')

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG window function, LEFT JOIN, CASE, parameterized
- **DMS Result**: Failed (metadata model creation error)
- **Conversion**: Manual with lowercase schema
- **Equivalency**: ERROR ('uniqueID')

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), INSERT history, UPDATE stats
- **DMS Result**: Failed (metadata model creation error)
- **Conversion**: Manual with lowercase schema, restructured for Npgsql
- **Key Change**: SCOPE_IDENTITY() → RETURNING productid, transaction managed in C#
- **Equivalency**: ERROR ('uniqueID')

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with SELECT INTO vars, UPDATE, INSERT history, UPDATE stats
- **DMS Result**: Failed (metadata model creation error)
- **Conversion**: Manual with lowercase schema, restructured for Npgsql
- **Key Change**: DECLARE/SELECT INTO → C# reader, transaction managed in C#
- **Equivalency**: ERROR ('uniqueID')

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with SELECT INTO vars, INSERT history, DELETE, UPDATE stats with CASE
- **DMS Result**: Failed (metadata model creation error)
- **Conversion**: Manual with lowercase schema, restructured for Npgsql
- **Key Change**: DECLARE/SELECT INTO → C# reader, transaction managed in C#
- **Equivalency**: ERROR ('uniqueID')

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE
- **DMS Result**: Failed (metadata model creation error)
- **Conversion**: Manual with lowercase schema
- **Equivalency**: ERROR ('uniqueID')

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND
- **DMS Result**: Failed (metadata model creation error)
- **Conversion**: Manual with lowercase schema, added CAST for integer division
- **Equivalency**: ERROR ('uniqueID')
