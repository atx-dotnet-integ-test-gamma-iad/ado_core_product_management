# SQL Server to PostgreSQL Migration Report

## Summary
- **Application**: AdoCore Product Management System
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-07-22

## SQL Statement Processing

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements attempted via DMS MCP tool | 7 |
| Statements successfully converted by DMS | 0 |
| Statements requiring manual conversion (DMS failure) | 7 |
| Statements validated as equivalent (SQL Equivalency tool) | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

## DMS Tool Failure Details

All 7 SQL statements were submitted to the DMS MCP tool for conversion. All failed with the same error:

**Error**: `AccessDeniedException` - User `arn:aws:sts::340752807109:assumed-role/ATX_MDE_SECURE_EXECUTION_ROLE/e-0dacf64ba16747e5acd988b7f0d1b0cc` is not authorized to perform `dms:StartMetadataModelCreation` on resource `arn:aws:dms:us-east-1:340752807109:migration-project:*` because no identity-based policy allows the `dms:StartMetadataModelCreation` action.

**Migration Project Identifier**: NXKVMFZHAZFJFF6HU2YPUQHSI4
**Database Name**: ProductManagement
**Region**: us-east-1

## SQL Equivalency Tool Results

All 7 statement pairs were submitted to the SQL Equivalency validation tool. All returned ERROR status with error message `'uniqueID'` indicating a tool infrastructure issue.

## Manual Conversion Approach

Since DMS was unavailable, all statements were manually converted following the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` methodology:

1. All schema object names (tables, columns, CTEs, aliases) converted to lowercase
2. SQL Server-specific functions replaced with PostgreSQL equivalents:
   - `SCOPE_IDENTITY()` → PostgreSQL `RETURNING` clause with writable CTEs
   - `GETDATE()` → `NOW()`
   - `DECLARE @var / SET @var` → Refactored using writable CTEs
   - `BEGIN TRANSACTION / COMMIT` → Handled programmatically via NpgsqlConnection.BeginTransactionAsync()
3. Integer division in `ROUND()` handled with `::numeric` cast where needed
4. Transaction blocks restructured using PostgreSQL writable CTEs for atomicity

## Static Code Changes

### Package Dependencies
| Original | Replacement |
|----------|-------------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.3 |

### Class Replacements
| SQL Server Class | PostgreSQL Class |
|-----------------|-----------------|
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |
| SqlParameter | NpgsqlParameter |

### Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server endpoint | Server=localhost | Host=localhost |
| Database | Database=ProductManagement | Database=ProductManagement |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MARS | MultipleActiveResultSets=true | (removed - not needed) |
| TLS | TrustServerCertificate=True | (removed - not needed) |

### Column Name References in Reader
All reader column references updated to lowercase to match PostgreSQL schema:
- `reader["ProductId"]` → `reader["productid"]`
- `reader["Name"]` → `reader["name"]`
- `reader["Description"]` → `reader["description"]`
- `reader["Price"]` → `reader["price"]`
- `reader["StockQuantity"]` → `reader["stockquantity"]`
- `reader["CreatedDate"]` → `reader["createddate"]`
- `reader["ModifiedDate"]` → `reader["modifieddate"]`

## Files Modified
1. `DataAccess/ProductRepository.cs` - SQL statements, imports, class references, column names
2. `AdoCore.csproj` - Package reference replacement
3. `appsettings.json` - Connection string format update

## Artifacts Generated
1. `extracted_statements.sql` - Complete catalog of original MS SQL statements
2. `converted_statements.sql` - Complete catalog of converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report
4. `migration_report.md` - This report

## Statements Requiring Manual Review
All 7 statements should be manually reviewed since:
1. DMS tool was unavailable for automated conversion
2. SQL Equivalency tool returned errors for all validation attempts
3. Manual conversion applied lowercase schema mapping rules per specification
