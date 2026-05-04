# Migration Report: MS SQL Server to PostgreSQL

## Summary

| Metric | Value |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS MCP Tool | 0 |
| Requiring Manual Intervention (DMS Failed) | 7 |
| Validated as Equivalent (SQL Equivalency Tool) | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Validation Errors | 7 |

## Migration Overview

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved:

1. **SQL Statement Extraction and Conversion** - 7 SQL statements extracted from `DataAccess/ProductRepository.cs`
2. **DMS Tool Conversion Attempts** - All 7 statements submitted to AWS DMS MCP tool; all failed
3. **Manual Conversion** - Applied PostgreSQL conversion with lowercase schema object naming
4. **SQL Equivalency Validation** - All 7 pairs validated through SQL Equivalency tool; all returned ERROR
5. **Code Migration** - Package, class, and configuration updates

## DMS Tool Results

**Tool**: dms-mcp___statement_conversion_tool  
**Migration Project ARN**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4  
**Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`  
**Affected Statements**: All 7  
**Resolution**: Manual conversion applied with lowercase schema object names per DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA rules

## SQL Equivalency Tool Results

**Tool**: sql-equivalency___validate_sql_equivalence  
**Error**: `{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}`  
**Affected Statements**: All 7  
**Note**: Tool returned ERROR for all statements, which per rules are marked as ERROR in the report

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS tool failure preventing automated conversion verification
2. SQL Equivalency tool returning errors for all pairs

### Statement 1: GetAllProductsAsync
- **Source**: CTE with AVG/COUNT window functions and CASE expressions
- **Conversion**: Schema objects lowercased, SQL syntax unchanged (PostgreSQL compatible)
- **Risk Level**: Low (standard SQL syntax, no MS SQL-specific functions)

### Statement 2: GetProductByIdAsync
- **Source**: CTE with LAG window functions, parameterized query
- **Conversion**: Schema objects lowercased, SQL syntax unchanged
- **Risk Level**: Low (standard SQL syntax)

### Statement 3: InsertProductAsync
- **Source**: DECLARE, SCOPE_IDENTITY(), GETDATE(), BEGIN TRANSACTION/COMMIT
- **Conversion**: Restructured to use RETURNING clause, NOW(), C# managed transactions
- **Risk Level**: Medium (significant restructuring of transaction block)

### Statement 4: UpdateProductAsync
- **Source**: DECLARE variables, SELECT INTO variables, GETDATE()
- **Conversion**: Restructured to separate queries within C# transaction, NOW()
- **Risk Level**: Medium (variable elimination, separate command execution)

### Statement 5: DeleteProductAsync
- **Source**: DECLARE variables, SELECT INTO variables, DELETE, CASE, GETDATE()
- **Conversion**: Restructured to separate queries within C# transaction, NOW()
- **Risk Level**: Medium (variable elimination, separate command execution)

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: CTE with RANK(), PERCENT_RANK(), BETWEEN
- **Conversion**: Schema objects lowercased, SQL syntax unchanged
- **Risk Level**: Low (standard SQL syntax)

### Statement 7: GetLowStockProductsAsync
- **Source**: CTE with AVG/MIN/MAX window functions and CASE
- **Conversion**: Schema objects lowercased, added CAST for integer division
- **Risk Level**: Low (minor CAST addition for PostgreSQL integer division handling)

## Code Changes Summary

### Package Changes (AdoCore.csproj)
| Before | After |
|--------|-------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.0 |

### Class Replacements (DataAccess/ProductRepository.cs)
| MS SQL Server | PostgreSQL (Npgsql) |
|---------------|---------------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlTransaction` | `NpgsqlTransaction` |

### Connection String Changes (appsettings.json)
| Parameter | Before | After |
|-----------|--------|-------|
| Server connection | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (N/A) |
| Certificate | `TrustServerCertificate=True` | Removed (N/A) |

### SQL Syntax Changes
| MS SQL Server | PostgreSQL |
|---------------|------------|
| `GETDATE()` | `NOW()` |
| `SCOPE_IDENTITY()` | `RETURNING productid` |
| `BEGIN TRANSACTION;...COMMIT;` | C# managed `BeginTransactionAsync()/CommitAsync()` |
| `DECLARE @var TYPE; SET @var = ...` | Separate SELECT queries in C# |
| Schema object casing (e.g., `Products`) | Lowercase (e.g., `products`) |

## Artifacts Generated

1. **extracted_statements.sql** - All 7 original MS SQL statements with source annotations
2. **converted_statements.sql** - All 7 converted PostgreSQL statements with method annotations
3. **sql_equivalency_validation_report.json** - Complete equivalency validation results
4. **migration_report.md** - This report
5. **dms_conversion_log.md** - DMS failure documentation

## Build Status

Final build: **SUCCESS** (dotnet build AdoCore.sln)

## Recommendations

1. **Integration Testing Required**: Since both DMS and SQL Equivalency tools returned errors, thorough integration testing against a real PostgreSQL database is essential
2. **Transaction Statements**: Statements 3, 4, 5 were significantly restructured from T-SQL batches to individual parameterized commands - verify transaction atomicity
3. **Schema Case Sensitivity**: PostgreSQL is case-sensitive for quoted identifiers - verify the actual database schema uses lowercase names
4. **Integer Division**: Statement 7 added CAST to handle PostgreSQL integer division (integer/integer returns integer in PostgreSQL, unlike SQL Server)
