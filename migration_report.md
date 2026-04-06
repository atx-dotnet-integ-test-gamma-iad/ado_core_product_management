# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS | 0 |
| Manual Conversion (DMS Failure) | 7 |
| Validated as Equivalent | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Validation Errors | 7 |

## DMS Tool Status

The DMS MCP tool (`dms-mcp___statement_conversion_tool`) was **unavailable** during this migration. All 7 SQL statements were attempted through the tool, but all failed with metadata model creation/conversion timeout errors.

- **Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Error Type**: Metadata model creation/conversion timeout
- **Fallback**: Manual conversion with lowercase schema object naming (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)

## SQL Equivalency Tool Status

The SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`) returned ERROR status for all 7 statement pairs with error `'uniqueID'`. This appears to be a service-side issue. All equivalency statuses in the report are direct tool outputs - no agent judgment was used.

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced 7 SQL statements, updated all ADO.NET classes to Npgsql |
| `AdoCore.csproj` | Replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.0 |
| `appsettings.json` | Updated connection strings to PostgreSQL format |
| `Database/Scripts/01_InitialSetup.sql` | Full PostgreSQL conversion (DDL, triggers, functions) |
| `Scripts/01_InitialSetup.sql` | Full PostgreSQL conversion (DDL, functions) |

## Files Not Modified (No Changes Needed)

| File | Reason |
|------|--------|
| `Program.cs` | No SQL Server imports or database code |
| `Business/ProductService.cs` | Business logic layer, no SQL or database code |
| `CLI/CommandLineInterface.cs` | CLI layer, no SQL or database code |
| `CLI/InteractiveMenu.cs` | CLI layer, no SQL or database code |
| `Models/Product.cs` | Data model, no SQL or database code |

## SQL Server → PostgreSQL Class Replacements

| SQL Server Class | PostgreSQL Class | Occurrences |
|-----------------|-----------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 15 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

## SQL Statement Conversions

### Statement 1: GetAllProductsAsync
- **Type**: CTE with AVG/COUNT window functions, INNER JOIN, CASE, ROUND
- **Changes**: Lowercase schema objects (Products→products, ProductId→productid, etc.)
- **SQL Syntax**: Fully PostgreSQL-compatible after casing changes

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG window functions, LEFT JOIN, CASE, ROUND
- **Changes**: Lowercase schema objects
- **SQL Syntax**: Fully PostgreSQL-compatible after casing changes

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), history logging, stats update
- **Changes**:
  - `SCOPE_IDENTITY()` → `INSERT...RETURNING productid`
  - `GETDATE()` → `NOW()`
  - `DECLARE @NewProductId` → Eliminated (using RETURNING clause)
  - Multi-statement batch → Separate commands in application-managed transaction
  - All schema objects lowercased

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with variable capture, UPDATE, history logging, stats update
- **Changes**:
  - `GETDATE()` → `NOW()`
  - `DECLARE @OldPrice/@OldStock` → C# variables with separate SELECT command
  - Multi-statement batch → Separate commands in application-managed transaction
  - All schema objects lowercased

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with variable capture, DELETE, history logging, stats update
- **Changes**:
  - `GETDATE()` → `NOW()`
  - `DECLARE @OldPrice/@OldStock` → C# variables with separate SELECT command
  - Multi-statement batch → Separate commands in application-managed transaction
  - CASE expression in UPDATE preserved (PostgreSQL compatible)
  - All schema objects lowercased

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK/PERCENT_RANK window functions, CASE, BETWEEN
- **Changes**: Lowercase schema objects
- **SQL Syntax**: Fully PostgreSQL-compatible after casing changes

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Changes**:
  - Lowercase schema objects
  - `ROUND((StockQuantity / AvgStock) * 100, 2)` → `ROUND((stockquantity::NUMERIC / avgstock) * 100, 2)` (explicit NUMERIC cast to prevent integer division)

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|------------|------------|
| Server identifier | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| Removed params | `MultipleActiveResultSets=true;TrustServerCertificate=True` | N/A |

## Database Setup Script Changes (01_InitialSetup.sql)

| Feature | SQL Server | PostgreSQL |
|---------|------------|------------|
| Auto-increment | `IDENTITY(1,1)` | `SERIAL` |
| DateTime type | `datetime` | `TIMESTAMP` |
| Boolean type | `bit` | `BOOLEAN` |
| String types | `nvarchar(N)` | `VARCHAR(N)` |
| Decimal type | `decimal(18,2)` | `NUMERIC(18,2)` |
| Current timestamp | `GETDATE()` | `NOW()` |
| Current user | `SYSTEM_USER` | `CURRENT_USER` |
| Batch separator | `GO` | Removed (not needed) |
| Stored procedures | `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION ... LANGUAGE plpgsql` |
| Triggers | `CREATE TRIGGER ... AFTER INSERT, UPDATE, DELETE AS BEGIN ... (inserted/deleted tables)` | `CREATE FUNCTION ... RETURNS TRIGGER ... (TG_OP, NEW/OLD) + CREATE TRIGGER ... FOR EACH ROW EXECUTE FUNCTION` |
| Conditional exists | `IF NOT EXISTS (SELECT * FROM sys.objects WHERE ...)` | `DROP TABLE IF EXISTS ... CASCADE` / `CREATE TABLE IF NOT EXISTS` |

## Issues and Warnings for Manual Review

1. **DMS Tool Unavailability**: All 7 SQL statements required manual conversion due to DMS tool timeout failures. Manual conversions follow lowercase schema naming conventions but should be reviewed for correctness.

2. **SQL Equivalency Validation Errors**: All 7 equivalency validations returned ERROR status from the tool (`'uniqueID'` error). These should be manually reviewed to confirm functional equivalence.

3. **Transaction Restructuring**: Statements 3, 4, and 5 (InsertProductAsync, UpdateProductAsync, DeleteProductAsync) were restructured from single multi-statement SQL batches to separate commands within application-managed transactions. This maintains atomicity but changes the execution pattern.

4. **Integer Division Fix**: Statement 7 (GetLowStockProductsAsync) added an explicit `::NUMERIC` cast to prevent integer division in PostgreSQL, which differs from SQL Server's implicit decimal promotion.

5. **Column Name Case Sensitivity**: PostgreSQL reader column access strings updated to lowercase (e.g., `reader["ProductId"]` → `reader["productid"]`). If the actual database schema uses different casing, these may need adjustment.

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | sourceCode/ | Original SQL Server statements catalog |
| `converted_statements.sql` | sourceCode/ | Converted PostgreSQL statements catalog |
| `sql_equivalency_validation_report.json` | sourceCode/ | Complete equivalency validation results |
| `dms_conversion_log.md` | sourceCode/ | DMS conversion attempt documentation |
| `migration_report.md` | sourceCode/ | This report |
