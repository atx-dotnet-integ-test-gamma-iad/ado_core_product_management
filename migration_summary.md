# SQL Migration Summary Report

## Overview
- **Source**: Microsoft SQL Server (MS SQL)
- **Target**: PostgreSQL
- **Application**: AdoCore (.NET ADO.NET Application)
- **Source File**: DataAccess/ProductRepository.cs

## DMS Tool Status
All 7 SQL statements were submitted to the DMS MCP tool for conversion.
**All 7 failed** with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

## Manual Conversion Applied
Since DMS failed for all statements, manual conversion was applied following the rule:
**DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA**

### Conversion Rules Applied:
1. All schema object names (tables, columns, CTEs, aliases) converted to lowercase
2. `SCOPE_IDENTITY()` replaced with PostgreSQL `RETURNING` clause via writable CTEs
3. `GETDATE()` replaced with `NOW()`
4. Transaction blocks with variable declarations restructured as writable CTEs
5. `DECIMAL(18,2)` mapped to `NUMERIC(18,2)`
6. Integer division handled with `::numeric` cast where needed

## SQL Equivalency Validation Status
All 7 statement pairs were submitted to the SQL Equivalency MCP tool.
**All 7 returned ERROR** with: `{'error': "'uniqueID'"}`

## Statistics
| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS | 0 |
| Manual conversion required | 7 |
| Equivalency: EQUIVALENT | 0 |
| Equivalency: NOT_EQUIVALENT | 0 |
| Equivalency: ERROR | 7 |

## Static Code Changes
1. **Package**: `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.1`
2. **Classes replaced**:
   - `SqlConnection` → `NpgsqlConnection`
   - `SqlCommand` → `NpgsqlCommand`
   - `SqlDataReader` → `NpgsqlDataReader`
   - `SqlParameter` → `NpgsqlParameter`
3. **Connection strings**: Updated from SQL Server format to PostgreSQL format
   - `Server=` → `Host=`
   - `Trusted_Connection=True` → `Username=postgres;Password=postgres`
   - Removed `MultipleActiveResultSets` and `TrustServerCertificate` (SQL Server specific)
4. **Import**: `using Microsoft.Data.SqlClient` → `using Npgsql`
