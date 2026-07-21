# SQL Server to PostgreSQL Migration Report

## Summary
- **Application**: AdoCore Product Management (.NET 9.0 Console App)
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-07-21

## SQL Statement Processing

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS | 0 |
| Statements requiring manual conversion (DMS failure) | 7 |
| Statements validated as equivalent | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

## DMS Tool Status
- **Status**: FAILED - All 7 statements failed
- **Error**: `AccessDeniedException: User is not authorized to perform dms:StartMetadataModelCreation`
- **Migration Project**: NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Fallback**: Manual conversion applied with lowercase schema object naming convention (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)

## SQL Equivalency Tool Status
- **Status**: ERROR - All 7 validations returned errors
- **Error**: `'uniqueID'` (internal tool error)
- **Note**: Equivalency tool failed independently of DMS; all statement pairs were submitted and documented

## Key Conversions Applied

### SQL Syntax Changes
| SQL Server | PostgreSQL | Notes |
|-----------|-----------|-------|
| `SCOPE_IDENTITY()` | `RETURNING productid` | Used INSERT...RETURNING pattern |
| `GETDATE()` | `NOW()` | Direct equivalent |
| `DECLARE @var` / T-SQL variables | C# variables + separate queries | PostgreSQL doesn't support T-SQL variable declarations in parameterized queries |
| `BEGIN TRANSACTION` / `COMMIT` (in SQL) | `NpgsqlTransaction` (in C#) | Transaction management moved to application code |
| Integer division | `::numeric` cast | Prevents integer truncation in PostgreSQL |
| Mixed-case identifiers | Lowercase identifiers | PostgreSQL convention for unquoted identifiers |

### Package Changes
| Original | Replacement |
|----------|-------------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.3 |

### Class Replacements
| SQL Server Class | Npgsql Class |
|-----------------|--------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |

### Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=productmanagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Not applicable (removed) |
| TrustServerCertificate | `TrustServerCertificate=True` | Not applicable (removed) |

## Files Modified
1. `DataAccess/ProductRepository.cs` - All SQL statements, ADO.NET classes, transaction handling
2. `AdoCore.csproj` - Package reference (Microsoft.Data.SqlClient → Npgsql)
3. `appsettings.json` - Connection strings
4. `Scripts/01_InitialSetup.sql` - Database setup script converted to PostgreSQL
5. `Database/Scripts/01_InitialSetup.sql` - Database setup script (copy)

## Files Created
1. `sql_equivalency_validation_report.json` - Complete equivalency validation report
2. `extracted_statements.sql` - Catalog of all original SQL statements
3. `converted_statements.sql` - Catalog of all converted PostgreSQL statements
4. `migration_report.md` - This report

## Statements Requiring Manual Review
All 7 statements have equivalency status ERROR due to tool failures. The conversions are logically sound but could not be machine-validated. Manual review is recommended for:
- Statement 3 (InsertProductAsync): Complex transaction with SCOPE_IDENTITY() → RETURNING
- Statement 4 (UpdateProductAsync): T-SQL variable pattern decomposed into multiple queries
- Statement 5 (DeleteProductAsync): T-SQL variable pattern decomposed into multiple queries
- Statement 7 (GetLowStockProductsAsync): Added ::numeric cast for integer division
