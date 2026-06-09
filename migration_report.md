# SQL Server to PostgreSQL Migration Report

## Summary
- **Total SQL statements processed**: 7
- **Statements successfully converted by DMS MCP tool**: 0
- **Statements requiring manual intervention after DMS tool failure**: 7
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## SQL Equivalency Validation Results
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 7
- **Equivalency Tool Error**: {'equivalence_status': 'ERROR', 'error': "'uniqueID'"}

## Conversion Details

### Statement 1: GetAllProductsAsync (SELECT with CTE and window functions)
- **Source File**: DataAccess/ProductRepository.cs
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema mapping
- **Key Changes**: Table/column names lowercased, syntax compatible with PostgreSQL

### Statement 2: GetProductByIdAsync (SELECT with CTE and LAG window function)
- **Source File**: DataAccess/ProductRepository.cs
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema mapping
- **Key Changes**: Table/column names lowercased, syntax compatible with PostgreSQL

### Statement 3: InsertProductAsync (Transaction with INSERT, SCOPE_IDENTITY, history logging)
- **Source File**: DataAccess/ProductRepository.cs
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema mapping + structural changes
- **Key Changes**:
  - SCOPE_IDENTITY() replaced with RETURNING clause via writable CTE
  - GETDATE() replaced with NOW()
  - DECLARE/SET variables eliminated using writable CTEs
  - BEGIN TRANSACTION/COMMIT removed (handled by writable CTE atomicity)

### Statement 4: UpdateProductAsync (Transaction with DECLARE variables, UPDATE, history logging)
- **Source File**: DataAccess/ProductRepository.cs
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema mapping + structural changes
- **Key Changes**:
  - DECLARE variables eliminated using CTE (old_values)
  - GETDATE() replaced with NOW()
  - BEGIN TRANSACTION/COMMIT removed (handled by writable CTE atomicity)

### Statement 5: DeleteProductAsync (Transaction with DECLARE variables, DELETE, history logging)
- **Source File**: DataAccess/ProductRepository.cs
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema mapping + structural changes
- **Key Changes**:
  - DECLARE variables eliminated using CTE (old_values)
  - GETDATE() replaced with NOW()
  - BEGIN TRANSACTION/COMMIT removed (handled by writable CTE atomicity)

### Statement 6: GetProductsByPriceRangeAsync (SELECT with CTE, RANK, PERCENT_RANK)
- **Source File**: DataAccess/ProductRepository.cs
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema mapping
- **Key Changes**: Table/column names lowercased, syntax compatible with PostgreSQL

### Statement 7: GetLowStockProductsAsync (SELECT with CTE and AVG/MIN/MAX window functions)
- **Source File**: DataAccess/ProductRepository.cs
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema mapping
- **Key Changes**: Table/column names lowercased, added CAST(stockquantity AS NUMERIC) to avoid integer division

## Static Code Changes

### Package References (AdoCore.csproj)
- **Removed**: Microsoft.Data.SqlClient 5.1.4
- **Added**: Npgsql 8.0.3

### ADO.NET Class Replacements (ProductRepository.cs)
- `using Microsoft.Data.SqlClient` → `using Npgsql`
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`

### Connection String Updates (appsettings.json)
- `Server=localhost` → `Host=localhost`
- `Database=ProductManagement` → `Database=productmanagement`
- `Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Username=postgres;Password=postgres`

## Files Modified
1. sourceCode/DataAccess/ProductRepository.cs
2. sourceCode/AdoCore.csproj
3. sourceCode/appsettings.json

## Artifacts Created
1. sourceCode/extracted_statements.sql - Original MS SQL statements catalog
2. sourceCode/converted_statements.sql - Converted PostgreSQL statements catalog
3. sourceCode/sql_equivalency_validation_report.json - Comprehensive equivalency report
4. sourceCode/migration_report.md - This report
