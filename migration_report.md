# Migration Report: Microsoft SQL Server to PostgreSQL

## Overview
- **Application**: AdoCore (.NET 9.0 ADO.NET Application)
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-03-27
- **Migration Project ARN**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Statements Successfully Converted by DMS Tool** | 0 |
| **Statements Requiring Manual Intervention** | 7 |
| **Statements Validated as Equivalent** | 0 |
| **Statements Validated as Non-Equivalent** | 0 |
| **Statements with Equivalency Errors** | 7 |

### DMS Tool Status
The DMS MCP tool (dms-mcp___statement_conversion_tool) was unavailable throughout the migration. All attempts timed out with:
- Metadata model conversion timeout after 15 poll attempts
- Command execution timeout after 300 seconds

All 7 statements were manually converted using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` approach, applying lowercase schema object names for PostgreSQL compatibility.

### SQL Equivalency Tool Status
The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) returned ERROR with `'uniqueID'` for all 7 statement pairs. This appears to be a systemic tool issue. All pairs were submitted and results recorded.

---

## Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, AVG/COUNT Window Functions, INNER JOIN, CASE, ROUND
- **Key Changes**: Table/column case lowered, CTE renamed from `ProductStats` to `productstats_cte` to avoid table name conflict
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG Window Function, LEFT JOIN, CASE, ROUND
- **Key Changes**: Table/column case lowered, CTE renamed from `ProductHistory` to `producthistory_cte` to avoid table name conflict
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY, GETDATE, UPDATE
- **Key Changes**: `SCOPE_IDENTITY()` → `RETURNING productid`, `GETDATE()` → `NOW()`, T-SQL transaction/declare blocks replaced with C# managed transactions and separate SQL commands
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE
- **Key Changes**: DECLARE/SELECT INTO @variable → separate SELECT query + C# reader, `GETDATE()` → `NOW()`, T-SQL transaction replaced with C# managed transactions
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE, CASE
- **Key Changes**: Same approach as Statement 4
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK/PERCENT_RANK Window Functions, BETWEEN, CASE
- **Key Changes**: Table/column case lowered only (RANK, PERCENT_RANK, BETWEEN are compatible)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
- **Key Changes**: Table/column case lowered, added `CAST(stockquantity AS DECIMAL)` for integer division fix
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR

---

## Code Changes Summary

### Package Changes
| Before | After |
|--------|-------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |

### Class Replacements
| SQL Server Class | Npgsql Equivalent |
|-----------------|-------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |

### Import Changes
| Before | After |
|--------|-------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |

### Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server Address | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed |
| TLS | `TrustServerCertificate=True` | Removed |

### Transaction Handling Changes
- SQL Server inline `BEGIN TRANSACTION`/`COMMIT` blocks → C# managed transactions via `NpgsqlConnection.BeginTransactionAsync()`
- SQL Server `DECLARE @variable` + `SELECT INTO @variable` → Separate SELECT queries with C# data reader
- Transaction assignment: `(System.Data.Common.DbTransaction)` → `(NpgsqlTransaction)`

---

## Files Modified

| File | Changes |
|------|---------|
| `sourceCode/AdoCore.csproj` | Package reference: Microsoft.Data.SqlClient → Npgsql |
| `sourceCode/DataAccess/ProductRepository.cs` | SQL statements, class references, transaction handling |
| `sourceCode/appsettings.json` | Connection strings updated to PostgreSQL format |

## Migration Artifacts

| Artifact | Description |
|----------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency report with all 7 statement pairs |
| `dms_conversion_log.md` | Detailed DMS conversion log with failure details |
| `migration_report.md` | This report |

## Build Status
- **Final Build**: SUCCESS (0 errors, 10 warnings - all pre-existing nullable reference warnings)
- **Framework**: .NET 9.0
- **Npgsql Version**: 8.0.6

## Items Requiring Manual Review
1. All 7 SQL statement conversions were performed manually due to DMS tool unavailability - manual review recommended
2. All 7 equivalency validations returned ERROR from the tool - manual equivalency review recommended
3. Connection string credentials (`Username=postgres;Password=postgres`) are development placeholders - must be configured for production
4. Transaction blocks were restructured from inline T-SQL to C# managed transactions - integration testing recommended
