# Migration Report: MS SQL Server to PostgreSQL

## Overview
- **Application**: AdoCore (.NET ADO.NET Application)
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-04-27
- **Framework**: .NET 9.0

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| DMS conversion failures (manual conversion applied) | 7 |
| Validated as EQUIVALENT by SQL Equivalency tool | 0 |
| Validated as NOT_EQUIVALENT by SQL Equivalency tool | 0 |
| SQL Equivalency tool returned ERROR | 7 |

### DMS MCP Tool Status
- **Tool**: dms-mcp___statement_conversion_tool
- **Migration Project ARN**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Status**: All 7 conversion attempts failed
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Fallback**: Manual conversion with lowercase schema object naming rules (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)

### SQL Equivalency Tool Status
- **Tool**: sql-equivalency___validate_sql_equivalence
- **Status**: All 7 validation attempts returned ERROR
- **Error**: `'uniqueID'`
- **Note**: Tool failures are independent of DMS failures; both tools experienced issues

---

## Statement-by-Statement Details

### Statement 1: GetAllProductsAsync
- **Source**: DataAccess/ProductRepository.cs (line 43)
- **Type**: SELECT with CTE, Window Functions (AVG, COUNT), INNER JOIN, CASE, ROUND
- **DMS Result**: FAILED
- **Manual Conversion**: Lowercased schema object names
- **Equivalency**: ERROR (tool failure)

### Statement 2: GetProductByIdAsync
- **Source**: DataAccess/ProductRepository.cs (line 88)
- **Type**: SELECT with CTE, Window Function (LAG), LEFT JOIN, CASE, ROUND
- **Parameters**: @ProductId
- **DMS Result**: FAILED
- **Manual Conversion**: Lowercased schema object names
- **Equivalency**: ERROR (tool failure)

### Statement 3: InsertProductAsync
- **Source**: DataAccess/ProductRepository.cs (line 132)
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
- **Parameters**: @Name, @Description, @Price, @StockQuantity
- **DMS Result**: FAILED
- **Manual Conversion**: 
  - SCOPE_IDENTITY() → INSERT...RETURNING productid (writable CTE)
  - GETDATE() → NOW()
  - DECLARE @var → eliminated via CTE structure
  - BEGIN TRANSACTION/COMMIT → removed (managed by ADO.NET)
- **Equivalency**: ERROR (tool failure)

### Statement 4: UpdateProductAsync
- **Source**: DataAccess/ProductRepository.cs (line 170)
- **Type**: Transaction block with DECLARE, SELECT INTO vars, UPDATE, INSERT, GETDATE()
- **Parameters**: @ProductId, @Name, @Description, @Price, @StockQuantity
- **DMS Result**: FAILED
- **Manual Conversion**:
  - DECLARE @var → old_values CTE
  - GETDATE() → NOW()
  - BEGIN TRANSACTION/COMMIT → removed (managed by ADO.NET)
  - Restructured as writable CTE chain
- **Equivalency**: ERROR (tool failure)

### Statement 5: DeleteProductAsync
- **Source**: DataAccess/ProductRepository.cs (line 216)
- **Type**: Transaction block with DECLARE, SELECT INTO vars, INSERT, DELETE, UPDATE with CASE
- **Parameters**: @ProductId
- **DMS Result**: FAILED
- **Manual Conversion**:
  - DECLARE @var → old_values CTE
  - GETDATE() → NOW()
  - BEGIN TRANSACTION/COMMIT → removed (managed by ADO.NET)
  - Restructured as writable CTE chain
- **Equivalency**: ERROR (tool failure)

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: DataAccess/ProductRepository.cs (line 258)
- **Type**: SELECT with CTE, Window Functions (RANK, PERCENT_RANK), CASE
- **Parameters**: @MinPrice, @MaxPrice
- **DMS Result**: FAILED
- **Manual Conversion**: Lowercased schema object names
- **Equivalency**: ERROR (tool failure)

### Statement 7: GetLowStockProductsAsync
- **Source**: DataAccess/ProductRepository.cs (line 295)
- **Type**: SELECT with CTE, Window Functions (AVG, MIN, MAX), CASE, ROUND
- **Parameters**: @Threshold
- **DMS Result**: FAILED
- **Manual Conversion**: Lowercased schema object names, added ::numeric cast for ROUND integer division
- **Equivalency**: ERROR (tool failure)

---

## Files Modified

| File | Changes |
|------|---------|
| DataAccess/ProductRepository.cs | SQL statements converted to PostgreSQL; SqlClient → Npgsql classes |
| AdoCore.csproj | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| appsettings.json | SQL Server connection strings → PostgreSQL format |
| Scripts/01_InitialSetup.sql | Converted to PostgreSQL DDL and functions |
| Database/Scripts/01_InitialSetup.sql | Converted to PostgreSQL DDL, functions, and triggers |

## Files Created

| File | Purpose |
|------|---------|
| extracted_statements.sql | Catalog of all original MS SQL statements |
| converted_statements.sql | Catalog of all converted PostgreSQL statements |
| sql_equivalency_validation_report.json | Detailed equivalency validation results for all 7 statement pairs |
| migration_report.md | This report |

---

## Package Changes

| Original Package | Version | Replacement Package | Version |
|-----------------|---------|-------------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.6 |

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Class |
|-----------------|-------------|
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |
| SqlParameter | NpgsqlParameter |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server/Host | Server=localhost | Host=localhost |
| Database | Database=ProductManagement | Database=ProductManagement |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets | true | (removed - not applicable) |
| TrustServerCertificate | True | (removed - not applicable) |

---

## SQL Script Conversion Summary

### Scripts/01_InitialSetup.sql
- Database creation: Converted to comment (done externally in PostgreSQL)
- Table creation: IF NOT EXISTS syntax, SERIAL for auto-increment, TIMESTAMP for datetime
- Stored procedures: Converted to PostgreSQL functions (plpgsql)
- Sample data: Wrapped in DO block with IF NOT EXISTS check

### Database/Scripts/01_InitialSetup.sql
- Drop statements: Converted to DROP IF EXISTS
- Table creation: SERIAL, VARCHAR, BOOLEAN, TIMESTAMP types
- Indexes: Converted to PostgreSQL syntax
- Trigger: Converted to PostgreSQL trigger function + trigger
- Stored procedures: Converted to PostgreSQL functions (plpgsql)
- SYSTEM_USER → current_user
- GETDATE() → NOW()
- SCOPE_IDENTITY() → RETURNING clause

---

## Build Status
- **Final Build**: ✅ **SUCCESS** (0 errors, 10 warnings - all pre-existing nullable warnings)

## Issues and Warnings
1. **DMS MCP Tool Unavailable**: All 7 DMS conversion attempts failed with metadata model creation error. Manual conversion was applied per transformation definition guidelines.
2. **SQL Equivalency Tool Error**: All 7 equivalency validation attempts returned ERROR with `'uniqueID'`. This is a tool-side issue, not a conversion issue.
3. **Npgsql Version**: Initially used 8.0.0, upgraded to 8.0.6 to resolve NU1903 high-severity vulnerability warning.
4. **Pre-existing Warnings**: 10 nullable reference warnings exist in the codebase (CS8601, CS8603, CS8618, CS8625) - these are pre-existing and not introduced by the migration.
