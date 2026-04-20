# Migration Report: MS SQL Server to PostgreSQL

## Summary
This report documents the complete migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

## Migration Overview
| Metric | Value |
|--------|-------|
| Migration Date | 2026-04-19 |
| Source Database | Microsoft SQL Server 2019 |
| Target Database | PostgreSQL 13 |
| Application Framework | .NET 9.0 (ADO.NET) |
| Package Replaced | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |

## SQL Statement Conversion Summary

### Application Code (ProductRepository.cs)
| # | Method | Statement Type | DMS Status | Manual Conversion | Equivalency |
|---|--------|---------------|------------|-------------------|-------------|
| 1 | GetAllProductsAsync | SELECT (CTE + Window Functions) | FAILED | Applied | ERROR |
| 2 | GetProductByIdAsync | SELECT (CTE + LAG + LEFT JOIN) | FAILED | Applied | ERROR |
| 3 | InsertProductAsync | INSERT + RETURNING (was SCOPE_IDENTITY) | FAILED | Applied | ERROR |
| 4 | UpdateProductAsync | UPDATE + History Logging | FAILED | Applied | ERROR |
| 5 | DeleteProductAsync | DELETE + History Logging | FAILED | Applied | ERROR |
| 6 | GetProductsByPriceRangeAsync | SELECT (CTE + RANK + PERCENT_RANK) | FAILED | Applied | ERROR |
| 7 | GetLowStockProductsAsync | SELECT (CTE + AVG/MIN/MAX Window) | FAILED | Applied | ERROR |

### Database Scripts
| # | Script | Statement Type | DMS Status | Manual Conversion | Equivalency |
|---|--------|---------------|------------|-------------------|-------------|
| 8 | Database/Scripts/01_InitialSetup.sql | CREATE TABLE Products | FAILED | Applied | ERROR |
| 9 | Scripts/01_InitialSetup.sql | INSERT (sp_InsertProduct) | FAILED | Applied | ERROR |
| 10 | Scripts/01_InitialSetup.sql | UPDATE (sp_UpdateProduct) | FAILED | Applied | ERROR |
| 11 | Scripts/01_InitialSetup.sql | DELETE (sp_DeleteProduct) | FAILED | Applied | ERROR |
| 12 | Scripts/01_InitialSetup.sql | SELECT (sp_GetAllProducts) | FAILED | Applied | ERROR |

### Conversion Statistics
| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 12 |
| Statements Successfully Converted by DMS | 0 |
| Statements Requiring Manual Intervention | 12 |
| Statements Validated as Equivalent | 0 |
| Statements Validated as Non-Equivalent | 0 |
| Statements with Equivalency Validation Errors | 12 |

## DMS Tool Failure Details
- **Tool**: dms-mcp___statement_conversion_tool
- **Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Consistent Failure**: All 12+ DMS conversion attempts failed with the same error
- **Root Cause**: The DMS metadata model creation service was in RECEIVED status and never progressed

## SQL Equivalency Tool Failure Details
- **Tool**: sql-equivalency___validate_sql_equivalence
- **Error**: `{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}`
- **Consistent Failure**: All 12 equivalency validation attempts failed with the same error
- **Root Cause**: Internal tool error ('uniqueID' reference issue)

## Manual Conversion Rules Applied
Since DMS was unavailable, all conversions were performed manually following the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` protocol:

### SQL Syntax Conversions
| MS SQL Server | PostgreSQL |
|--------------|------------|
| `IDENTITY(1,1)` | `SERIAL` |
| `GETDATE()` | `NOW()` |
| `SCOPE_IDENTITY()` | `RETURNING productid` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `BIT` | `BOOLEAN` |
| `DATETIME` | `TIMESTAMP` |
| `GO` batch separator | Removed |
| `SYSTEM_USER` | `current_user` |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `DECLARE @var` blocks | Restructured to separate C# commands |
| `BEGIN TRANSACTION/COMMIT` | C# transaction management |

### Schema Object Name Conversions
All schema object names (tables, columns, aliases, CTEs) converted to lowercase:
- `Products` → `products`
- `ProductId` → `productid`
- `ProductHistory` → `producthistory`
- `ProductStats` → `productstats`
- `Categories` → `categories`
- `Suppliers` → `suppliers`
- etc.

## ADO.NET Class Replacements
| SQL Server Class | Npgsql Equivalent | Occurrences |
|-----------------|-------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 15 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |
| `SqlTransaction` | `NpgsqlTransaction` | 3 |

## Package Reference Changes
| Original | Replacement |
|----------|------------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.6 |

## Configuration Changes
### Connection Strings (appsettings.json)
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Auth | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `true` | Removed (N/A) |
| TrustServerCertificate | `True` | Removed (N/A) |

## Files Modified
1. `sourceCode/DataAccess/ProductRepository.cs` - SQL statements, ADO.NET classes, imports
2. `sourceCode/AdoCore.csproj` - Package reference
3. `sourceCode/appsettings.json` - Connection strings
4. `sourceCode/Database/Scripts/01_InitialSetup.sql` - Full PostgreSQL conversion
5. `sourceCode/Scripts/01_InitialSetup.sql` - Full PostgreSQL conversion

## Artifacts Generated
1. `sourceCode/extracted_statements.sql` - Catalog of all original MS SQL statements
2. `sourceCode/converted_statements.sql` - Catalog of all converted PostgreSQL statements
3. `sourceCode/sql_equivalency_validation_report.json` - Complete equivalency validation report
4. `sourceCode/migration_report.md` - This report

## Build Status
- **Final Build**: ✅ SUCCESS (0 errors)
- All pre-existing warnings preserved (nullable reference types)

## Items Requiring Manual Review
1. **DMS Conversion**: All 12 statements were manually converted due to DMS tool unavailability. Manual review recommended to validate PostgreSQL syntax correctness.
2. **Equivalency Validation**: All 12 statement pairs returned ERROR from the equivalency tool. Manual equivalency review recommended.
3. **Transaction Restructuring**: The InsertProductAsync, UpdateProductAsync, and DeleteProductAsync methods were restructured from single inline SQL blocks with DECLARE/SCOPE_IDENTITY() to multiple separate ADO.NET commands within C# transaction scope. Functional equivalence should be verified with integration testing.
4. **Trigger Conversion**: The SQL Server trigger `trg_Products_History` was converted to a PostgreSQL trigger function pattern. The trigger logic should be verified with integration testing.
5. **Stored Procedure Conversion**: All stored procedures were converted to PostgreSQL functions. Parameter naming conventions changed from `@param` to `p_param`.
