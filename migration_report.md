# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS MCP Tool | 0 |
| Requiring Manual Intervention (DMS Failure) | 7 |
| Validated as Equivalent (SQL Equivalency Tool) | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Validation Errors | 7 |

## DMS MCP Tool Results

The DMS Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) was attempted for all 7 SQL statements but consistently failed with timeout errors:

- **Error Type**: Metadata model conversion timeout
- **Error Message**: "Metadata model conversion failed: Metadata model conversion did not complete after 15 attempts"
- **Secondary Error**: "Command execution timed out after 300 seconds"
- **Attempts**: Multiple attempts with varying `max_poll_attempts` (15, 25, 30) and `poll_interval_seconds` (10, 12, 15)

The DMS Schema Mapping Tool (`dms-mcp___schema_mapping_tool`) **succeeded** and provided complete schema mappings for all tables:
- Products → products (productmanagement_dbo schema)
- ProductHistory → producthistory
- ProductStats → productstats
- Categories → categories
- Suppliers → suppliers

These schema mappings were used as the basis for manual SQL statement conversions.

## SQL Equivalency Tool Results

The SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`) was called for all 7 statement pairs but returned ERROR for all:

- **Error**: `'uniqueID'` (persistent system-level error)
- **Status**: All 7 statements marked as ERROR per transformation rules
- **Note**: The error was consistent across all statements, including trivial test statements, indicating a system-level issue rather than a statement-specific problem

## Conversion Method

All 7 statements were converted using: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

Schema mappings from DMS schema_mapping_tool were applied:
- All table names: lowercase (Products → products, ProductHistory → producthistory, etc.)
- All column names: lowercase (ProductId → productid, Price → price, etc.)
- GETDATE() → clock_timestamp()
- SCOPE_IDENTITY() → RETURNING clause (writable CTE pattern)
- DECLARE/SET variables → Eliminated via writable CTEs
- BEGIN TRANSACTION/COMMIT → Removed (CTEs are atomic; C# manages transactions)
- IDENTITY(1,1) → GENERATED ALWAYS AS IDENTITY
- nvarchar → VARCHAR
- datetime → TIMESTAMP WITHOUT TIME ZONE
- bit → NUMERIC(1,0)

## SQL Statements Converted

### Statement 1: GetAllProductsAsync
- **Method**: GetAllProductsAsync()
- **Type**: SELECT with CTE, window functions, CASE, ROUND, JOIN
- **Key Changes**: CTE renamed to `productstats_cte` (avoid clash with table), lowercase identifiers

### Statement 2: GetProductByIdAsync
- **Method**: GetProductByIdAsync(int productId)
- **Type**: SELECT with CTE, LAG window function, parameterized
- **Key Changes**: CTE renamed to `producthistory_cte`, lowercase identifiers

### Statement 3: InsertProductAsync
- **Method**: InsertProductAsync(Product product)
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), INSERT, UPDATE
- **Key Changes**: Rewritten as writable CTE with RETURNING clause, clock_timestamp()

### Statement 4: UpdateProductAsync
- **Method**: UpdateProductAsync(Product product)
- **Type**: Transaction block with DECLARE, SELECT, UPDATE, INSERT, UPDATE
- **Key Changes**: Rewritten as writable CTE, DECLARE/variables eliminated

### Statement 5: DeleteProductAsync
- **Method**: DeleteProductAsync(int productId)
- **Type**: Transaction block with DECLARE, SELECT, INSERT, DELETE, UPDATE
- **Key Changes**: Rewritten as writable CTE, DECLARE/variables eliminated

### Statement 6: GetProductsByPriceRangeAsync
- **Method**: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK(), CASE
- **Key Changes**: Lowercase identifiers

### Statement 7: GetLowStockProductsAsync
- **Method**: GetLowStockProductsAsync(int threshold)
- **Type**: SELECT with CTE, AVG/MIN/MAX OVER(), CASE, ROUND
- **Key Changes**: Lowercase identifiers, added CAST for integer division

## Files Changed

### Code Files
| File | Changes |
|------|---------|
| DataAccess/ProductRepository.cs | 7 SQL statements replaced; using Microsoft.Data.SqlClient → using Npgsql; SqlConnection → NpgsqlConnection; SqlCommand → NpgsqlCommand; SqlDataReader → NpgsqlDataReader |
| AdoCore.csproj | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| appsettings.json | SQL Server connection strings → PostgreSQL connection strings |

### SQL Scripts
| File | Changes |
|------|---------|
| Scripts/01_InitialSetup.sql | Complete rewrite for PostgreSQL DDL (CREATE TABLE, CREATE FUNCTION replacing stored procedures) |
| Database/Scripts/01_InitialSetup.sql | Complete rewrite for PostgreSQL DDL (all tables, indexes, trigger function, sample data, stored procedures → functions) |

### Migration Artifacts
| File | Description |
|------|-------------|
| extracted_statements.sql | Catalog of all 7 original MS SQL statements |
| converted_statements.sql | Catalog of all 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | Comprehensive equivalency validation report for all 7 pairs |
| migration_report.md | This report |

## Package Dependency Changes

| Original Package | Version | New Package | Version |
|-----------------|---------|-------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.6 |

Note: Npgsql 8.0.0 was initially considered but had a known vulnerability (GHSA-x9vc-6hfv-hg8c). Upgraded to 8.0.6.

## Class Replacement Summary

| Original (Microsoft.Data.SqlClient) | New (Npgsql) | Occurrences |
|--------------------------------------|--------------|-------------|
| using Microsoft.Data.SqlClient | using Npgsql | 1 |
| SqlConnection | NpgsqlConnection | 4 |
| SqlCommand | NpgsqlCommand | 7 |
| SqlDataReader | NpgsqlDataReader | 1 |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server | Server=localhost | Host=localhost |
| Database | Database=ProductManagement | Database=ProductManagement |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets | true | Removed (not applicable) |
| TrustServerCertificate | True | Removed |

## Build Status

- **Final Build**: ✅ **Succeeded** (0 errors, 10 warnings - all pre-existing nullable reference warnings)
- **Build Command**: `dotnet build`
- **Output**: AdoCore.dll compiled successfully

## Statements Requiring Manual Review

All 7 statements should be reviewed due to:
1. DMS Statement Conversion Tool timeout (manual conversion applied)
2. SQL Equivalency Tool returning ERROR for all pairs (system-level issue)

Priority review items:
- **Statements 3, 4, 5** (Insert, Update, Delete): These were significantly restructured from DECLARE/TRANSACTION blocks to writable CTEs. The writable CTE pattern in PostgreSQL has specific execution semantics that should be tested against the actual database.
- **Statement 7** (GetLowStockProductsAsync): Added explicit CAST for integer division to avoid truncation.
