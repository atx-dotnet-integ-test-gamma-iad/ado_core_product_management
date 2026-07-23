# SQL Server to PostgreSQL Migration Report

## Summary
- **Project**: AdoCore (Product Management System)
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Framework**: .NET 9.0 with ADO.NET

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention after DMS tool failure | 7 |
| Statements validated as equivalent (SQL Equivalency tool) | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

## DMS Tool Failure Details
- **Error**: AccessDeniedException - User is not authorized to perform `dms:StartMetadataModelCreation` on resource
- **Impact**: All 7 statements required manual conversion
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Schema Mapping**: All schema object names (tables, columns, aliases) converted to lowercase

## SQL Equivalency Tool Failure Details
- **Error**: Internal tool error - `'uniqueID'`
- **Impact**: All 7 statement pairs returned ERROR status
- **Note**: Agent judgment was NOT used to determine equivalency per transformation rules

## Conversion Details

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE and window functions
- **Changes**: Schema objects lowercased, added `::numeric` cast for ROUND function compatibility

### Statement 2: GetProductByIdAsync  
- **Type**: SELECT with CTE using LAG() window function
- **Changes**: Schema objects lowercased, added `::numeric` cast for ROUND function

### Statement 3: InsertProductAsync
- **Type**: Transaction with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Changes**: Restructured from T-SQL DECLARE/SET/BEGIN TRANSACTION to PostgreSQL data-modifying CTEs with RETURNING and NOW()

### Statement 4: UpdateProductAsync
- **Type**: Transaction with DECLARE, SELECT into variables, UPDATE, INSERT
- **Changes**: Restructured from T-SQL DECLARE/SET pattern to PostgreSQL data-modifying CTEs capturing old values

### Statement 5: DeleteProductAsync
- **Type**: Transaction with DECLARE, SELECT into variables, INSERT, DELETE, UPDATE
- **Changes**: Restructured from T-SQL DECLARE/SET pattern to PostgreSQL data-modifying CTEs

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE using RANK() and PERCENT_RANK()
- **Changes**: Schema objects lowercased only (functions are PostgreSQL-compatible)

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE using AVG/MIN/MAX window functions
- **Changes**: Schema objects lowercased, added `::numeric` cast for integer division in ROUND

## Code Changes

### Package Dependencies
| Before | After |
|--------|-------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.3 |

### ADO.NET Class Replacements
| SQL Server Class | PostgreSQL Equivalent |
|-----------------|---------------------|
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |
| SqlParameter | NpgsqlParameter |

### Connection String Changes
| Parameter | Before | After |
|-----------|--------|-------|
| Server/Host | Server=localhost | Host=localhost |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MARS | MultipleActiveResultSets=true | (removed - not applicable) |
| TrustServerCertificate | TrustServerCertificate=True | (removed - not applicable) |

### Column Name References in Code
- Reader access updated from PascalCase (`reader["ProductId"]`) to lowercase (`reader["productid"]`)

## Files Modified
1. `DataAccess/ProductRepository.cs` - SQL statements, ADO.NET classes, reader column names
2. `AdoCore.csproj` - Package reference replacement
3. `appsettings.json` - Connection string format

## Files Created
1. `extracted_statements.sql` - Catalog of all original MS SQL statements
2. `converted_statements.sql` - Catalog of all converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report
4. `migration_report.md` - This report

## SQL Server-Specific Features Converted
| Feature | SQL Server | PostgreSQL |
|---------|-----------|------------|
| Identity retrieval | SCOPE_IDENTITY() | INSERT ... RETURNING |
| Current timestamp | GETDATE() | NOW() |
| Transaction batches | BEGIN TRANSACTION/COMMIT in SQL | Data-modifying CTEs (atomic single statement) |
| Variable declarations | DECLARE @var / SET @var | CTEs to capture intermediate values |
| Type casting for ROUND | Implicit | Explicit ::numeric cast |

## Risks and Recommendations
1. **Equivalency Validation**: All statement pairs could not be validated due to tool unavailability. Manual testing against a PostgreSQL database is recommended.
2. **Data-Modifying CTEs**: The transaction statements (Insert/Update/Delete) were restructured to use PostgreSQL data-modifying CTEs which guarantee atomicity within a single statement.
3. **Integer Division**: Added explicit `::numeric` casts where integer division could produce truncated results.
