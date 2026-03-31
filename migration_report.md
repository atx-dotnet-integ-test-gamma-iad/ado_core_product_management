# Migration Report: SQL Server to PostgreSQL

## Overview
- **Project**: AdoCore - Product Management Application
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-03-31
- **DMS Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

---

## SQL Statement Conversion Summary

| Metric | Count |
|---|---|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention after DMS failure | 7 |
| Validated as equivalent by SQL Equivalency tool | 0 |
| Validated as non-equivalent | 0 |
| With equivalency validation errors | 7 |

### DMS Tool Status
All 7 statements were submitted to the DMS MCP conversion tool. All 7 failed due to metadata model creation/conversion timeout errors. Manual conversion was applied for all statements following the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` protocol.

### SQL Equivalency Tool Status
All 7 statement pairs were submitted to the SQL Equivalency validation tool. All 7 returned ERROR status with error `'uniqueID'`. This appears to be a tool-side issue unrelated to the quality of the conversions. Equivalency statuses were recorded exactly as returned by the tool.

---

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS conversion failure (all statements manually converted)
2. SQL Equivalency tool errors (all statement pairs returned ERROR)

### Statement Details

| # | Method | SQL Type | Key Conversions |
|---|---|---|---|
| 1 | GetAllProductsAsync | CTE + Window Functions | Lowercase schema objects |
| 2 | GetProductByIdAsync | CTE + LAG | Lowercase schema objects |
| 3 | InsertProductAsync | Transaction Block | SCOPE_IDENTITY() → RETURNING, GETDATE() → NOW(), refactored to separate parameterized commands in C#-managed transaction |
| 4 | UpdateProductAsync | Transaction Block | Refactored from DO $ to separate parameterized commands in C#-managed transaction, GETDATE() → NOW() |
| 5 | DeleteProductAsync | Transaction Block | Refactored from DO $ to separate parameterized commands in C#-managed transaction, GETDATE() → NOW() |
| 6 | GetProductsByPriceRangeAsync | CTE + RANK/PERCENT_RANK | Lowercase schema objects |
| 7 | GetLowStockProductsAsync | CTE + AVG/MIN/MAX | Lowercase schema objects, added ::NUMERIC cast |

---

## Code Changes Summary

### Package Dependencies
| Change | Before | After |
|---|---|---|
| Database Client | Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |

### ADO.NET Class Replacements
| SQL Server Class | Npgsql Equivalent | Occurrences |
|---|---|---|
| SqlConnection | NpgsqlConnection | 3 (field, method return, constructor) |
| SqlCommand | NpgsqlCommand | 7 (one per query method) |
| SqlDataReader | NpgsqlDataReader | 1 (MapProductFromReader parameter) |
| using Microsoft.Data.SqlClient | using Npgsql | 1 |

### Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|---|---|---|
| Server | Server=localhost | Host=localhost |
| Database | Database=ProductManagement | Database=ProductManagement |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets | true | Removed (not applicable) |
| TrustServerCertificate | True | Removed (not applicable) |

### SQL Syntax Changes Applied
| SQL Server Syntax | PostgreSQL Syntax |
|---|---|
| SCOPE_IDENTITY() | RETURNING productid (via ExecuteScalar) |
| GETDATE() | NOW() |
| DECIMAL(18,2) | NUMERIC(18,2) |
| BEGIN TRANSACTION / COMMIT | C#-managed transaction (BeginTransactionAsync/CommitAsync/RollbackAsync) |
| DECLARE @var TYPE / SELECT @var = col | C# variables with separate parameterized SELECT commands |
| Schema object names (PascalCase) | lowercase (PostgreSQL convention) |
| Integer division | Added ::NUMERIC cast where needed |

---

## Files Modified
1. **sourceCode/DataAccess/ProductRepository.cs** - SQL statements, ADO.NET classes, column name references
2. **sourceCode/AdoCore.csproj** - Package reference (Microsoft.Data.SqlClient → Npgsql)
3. **sourceCode/appsettings.json** - Connection strings (SQL Server → PostgreSQL format)

## Artifacts Generated
1. **extracted_statements.sql** - Complete catalog of all 7 original MS SQL statements
2. **converted_statements.sql** - Complete catalog of all 7 converted PostgreSQL statements
3. **sql_equivalency_validation_report.json** - Comprehensive JSON report with all statement pairs, conversion methods, and equivalency results
4. **dms_conversion_log.md** - Detailed log of DMS tool output for each statement
5. **migration_report.md** - This report

---

## Build Verification
- **Final Build Status**: SUCCESS
- **Errors**: 0
- **Warnings**: 10 (all pre-existing nullable reference type warnings, no new warnings introduced)
- **Build Command**: `dotnet build`
- **Target Framework**: net9.0

---

## Notes and Recommendations
1. All SQL statements should be manually reviewed and tested against the target PostgreSQL database to verify functional correctness, since both the DMS conversion tool and SQL Equivalency validation tool experienced errors.
2. **[FIXED]** The DO $ anonymous blocks previously used for UpdateProductAsync, DeleteProductAsync, and InsertProductAsync have been refactored to use separate parameterized NpgsqlCommand instances within C#-managed transactions (BeginTransactionAsync/CommitAsync/RollbackAsync). This resolves the Npgsql parameter binding incompatibility with DO $ blocks.
3. Connection strings use placeholder credentials (postgres/postgres). Production deployments should use environment variables or a secrets manager for credentials.
4. Npgsql version 8.0.6 was chosen to avoid the known vulnerability (GHSA-x9vc-6hfv-hg8c) present in version 8.0.0.
5. Runtime validation (Criteria 12, 13, 14) requires a live PostgreSQL database instance which is not available in this environment. These should be validated during deployment/integration testing.
