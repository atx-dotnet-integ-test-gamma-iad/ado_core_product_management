# SQL Server to PostgreSQL Migration Report

## Summary
- **Total SQL statements processed**: 7
- **Statements successfully converted by DMS MCP tool**: 0
- **Statements requiring manual intervention after DMS tool failure**: 7
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 7

## DMS Tool Failure Details
All 7 SQL statements were submitted to the DMS MCP tool and all failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

## SQL Equivalency Tool Details
All 7 statement pairs were submitted to the SQL Equivalency validation tool and all returned ERROR:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

## Manual Conversion Approach
Since DMS failed for all statements, manual conversion was applied with the following rules:
1. All schema object names converted to lowercase (tables, columns, aliases)
2. `SCOPE_IDENTITY()` → `RETURNING ... INTO` + `currval(pg_get_serial_sequence(...))`
3. `GETDATE()` → `NOW()`
4. `DECLARE @var` → `DECLARE v_var` in PL/pgSQL DO blocks
5. `BEGIN TRANSACTION / COMMIT` → `DO $$ BEGIN ... END $$;` (PL/pgSQL anonymous blocks)
6. `SET @var = expr` → `SELECT ... INTO v_var`
7. Integer division in ROUND → `CAST(... AS DECIMAL)` for proper decimal division

## Files Modified
1. `DataAccess/ProductRepository.cs` - All SQL statements, class types, imports
2. `AdoCore.csproj` - Package reference (Microsoft.Data.SqlClient → Npgsql)
3. `appsettings.json` - Connection strings (SQL Server → PostgreSQL format)

## Static Code Changes
- `using Microsoft.Data.SqlClient;` → `using Npgsql;`
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`
- Connection string: `Server=` → `Host=`, removed `MultipleActiveResultSets`, `TrustServerCertificate`, `Trusted_Connection`; added `Username`/`Password`

## Statement Catalog

### Statement 1 - GetAllProductsAsync (SELECT with CTE + Window Functions)
- **Source**: DataAccess/ProductRepository.cs, line ~42
- **DMS Result**: ERROR
- **Conversion**: Lowercase schema objects, syntax compatible as-is
- **Equivalency**: ERROR (tool failure)

### Statement 2 - GetProductByIdAsync (SELECT with CTE + LAG Window Function)
- **Source**: DataAccess/ProductRepository.cs, line ~76
- **DMS Result**: ERROR
- **Conversion**: Lowercase schema objects, syntax compatible as-is
- **Equivalency**: ERROR (tool failure)

### Statement 3 - InsertProductAsync (Transaction with SCOPE_IDENTITY)
- **Source**: DataAccess/ProductRepository.cs, line ~107
- **DMS Result**: ERROR
- **Conversion**: SCOPE_IDENTITY() → RETURNING + currval, GETDATE() → NOW(), DO $$ block
- **Equivalency**: ERROR (tool failure)

### Statement 4 - UpdateProductAsync (Transaction with DECLARE/SET)
- **Source**: DataAccess/ProductRepository.cs, line ~141
- **DMS Result**: ERROR
- **Conversion**: T-SQL variables → PL/pgSQL variables, GETDATE() → NOW(), DO $$ block
- **Equivalency**: ERROR (tool failure)

### Statement 5 - DeleteProductAsync (Transaction with CASE expression)
- **Source**: DataAccess/ProductRepository.cs, line ~176
- **DMS Result**: ERROR
- **Conversion**: T-SQL variables → PL/pgSQL variables, GETDATE() → NOW(), DO $$ block
- **Equivalency**: ERROR (tool failure)

### Statement 6 - GetProductsByPriceRangeAsync (CTE with RANK/PERCENT_RANK)
- **Source**: DataAccess/ProductRepository.cs, line ~209
- **DMS Result**: ERROR
- **Conversion**: Lowercase schema objects, syntax compatible as-is
- **Equivalency**: ERROR (tool failure)

### Statement 7 - GetLowStockProductsAsync (CTE with AVG/MIN/MAX OVER)
- **Source**: DataAccess/ProductRepository.cs, line ~237
- **DMS Result**: ERROR
- **Conversion**: Lowercase schema objects, CAST for integer division fix
- **Equivalency**: ERROR (tool failure)
