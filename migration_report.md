# SQL Server to PostgreSQL Migration Report

## Summary
- **Total SQL statements processed**: 7
- **Statements successfully converted by DMS MCP tool**: 0
- **Statements requiring manual intervention after DMS tool failure**: 7
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 7

## DMS Tool Failure Details
All 7 statements failed DMS conversion with the same error:
- **Error**: Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
- **Conversion applied**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Schema mapping rules applied**: All schema object names (tables, columns, aliases) converted to lowercase

## SQL Equivalency Tool Results
All 7 statement pairs returned ERROR from the SQL Equivalency tool:
- **Error**: {'equivalence_status': 'ERROR', 'error': "'uniqueID'"}
- **Note**: Equivalency status marked as ERROR per tool output; no agent judgment applied

## Conversion Details

### Statement 1: GetAllProductsAsync (SELECT with CTE and Window Functions)
- **Source file**: DataAccess/ProductRepository.cs
- **Changes**: Lowercase schema objects (Products→products, ProductId→productid, etc.)
- **SQL features preserved**: CTE, AVG() OVER(), COUNT() OVER(), CASE, ROUND, INNER JOIN, ORDER BY

### Statement 2: GetProductByIdAsync (SELECT with CTE and LAG Window Function)
- **Source file**: DataAccess/ProductRepository.cs
- **Changes**: Lowercase schema objects
- **SQL features preserved**: CTE, LAG() OVER(), CASE, ROUND, LEFT JOIN, parameterized WHERE

### Statement 3: InsertProductAsync (Transaction with INSERT, SCOPE_IDENTITY, History Logging)
- **Source file**: DataAccess/ProductRepository.cs
- **Changes**:
  - SCOPE_IDENTITY() → RETURNING clause with writable CTE
  - GETDATE() → NOW()
  - DECLARE @var / BEGIN TRANSACTION / COMMIT → Writable CTE (atomic single statement)
  - Lowercase schema objects

### Statement 4: UpdateProductAsync (Transaction with Variable Declaration, UPDATE, History Logging)
- **Source file**: DataAccess/ProductRepository.cs
- **Changes**:
  - DECLARE @var → CTE subquery (old_values)
  - SELECT INTO @var → CTE with SELECT
  - GETDATE() → NOW()
  - BEGIN TRANSACTION / COMMIT → Writable CTE (atomic single statement)
  - Lowercase schema objects

### Statement 5: DeleteProductAsync (Transaction with Variable Declaration, DELETE, History Logging)
- **Source file**: DataAccess/ProductRepository.cs
- **Changes**:
  - DECLARE @var → CTE subquery (old_values)
  - GETDATE() → NOW()
  - BEGIN TRANSACTION / COMMIT → Writable CTE (atomic single statement)
  - Lowercase schema objects

### Statement 6: GetProductsByPriceRangeAsync (SELECT with CTE, RANK, PERCENT_RANK)
- **Source file**: DataAccess/ProductRepository.cs
- **Changes**: Lowercase schema objects
- **SQL features preserved**: CTE, RANK() OVER(), PERCENT_RANK() OVER(), BETWEEN, CASE, ORDER BY

### Statement 7: GetLowStockProductsAsync (SELECT with CTE and Window Functions)
- **Source file**: DataAccess/ProductRepository.cs
- **Changes**: Lowercase schema objects, CAST(StockQuantity AS DECIMAL) → CAST(stockquantity AS NUMERIC)
- **SQL features preserved**: CTE, AVG() OVER(), MIN() OVER(), MAX() OVER(), CASE, ROUND

## Static Code Changes

### Package References (AdoCore.csproj)
- **Removed**: `Microsoft.Data.SqlClient` v5.1.4
- **Added**: `Npgsql` v8.0.3 (CVE scan: PASS)

### ADO.NET Class Replacements (ProductRepository.cs)
- `using Microsoft.Data.SqlClient` → `using Npgsql`
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`

### Connection String Updates (appsettings.json)
- `Server=localhost` → `Host=localhost`
- `Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Username=postgres;Password=postgres`

### Column Name References in MapProductFromReader
- Updated reader column access to use lowercase: `reader["ProductId"]` → `reader["productid"]`, etc.

## Artifacts Generated
1. `extracted_statements.sql` - Original MS SQL statements catalog
2. `converted_statements.sql` - Converted PostgreSQL statements catalog
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report
4. `migration_report.md` - This report
