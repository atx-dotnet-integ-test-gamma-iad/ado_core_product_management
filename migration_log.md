# Migration Log: SQL Server to PostgreSQL

## Migration Overview
- **Source**: Microsoft SQL Server (T-SQL) with Microsoft.Data.SqlClient
- **Target**: PostgreSQL with Npgsql
- **Application**: AdoCore (.NET 9.0 ADO.NET Application)
- **Migration Date**: 2026-04-21

---

## Files Modified During Migration

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted, ADO.NET classes replaced |
| `AdoCore.csproj` | Package reference: Microsoft.Data.SqlClient -> Npgsql |
| `appsettings.json` | Connection strings updated for PostgreSQL |

## New Files Created

| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `migration_log.md` | This file - detailed migration log |
| `final_migration_report.md` | Summary migration report |

---

## SQL Statement Processing Detail

### Statement 1: GetAllProductsAsync
- **Source File**: `DataAccess/ProductRepository.cs` (lines ~43-69)
- **Type**: CTE with AVG/COUNT window functions, CASE, ROUND, JOIN, ORDER BY
- **DMS Tool Call**: dms-mcp___statement_conversion_tool with schema_name='dbo', database_name='ProductManagement'
- **DMS Output**: ERROR - "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
- **Manual Conversion Applied**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
  - All schema objects lowercased (Products->products, ProductId->productid, etc.)
  - ROUND((p.Price / ps.AvgPrice) * 100, 2) -> ROUND((p.price / ps.avgprice * 100)::numeric, 2)
- **Equivalency Check**: ERROR - "'uniqueID'" (tool-level error)

### Statement 2: GetProductByIdAsync
- **Source File**: `DataAccess/ProductRepository.cs` (lines ~78-103)
- **Type**: CTE with LAG window function, CASE, LEFT JOIN, parameterized @ProductId
- **DMS Tool Call**: dms-mcp___statement_conversion_tool with schema_name='dbo', database_name='ProductManagement'
- **DMS Output**: ERROR - "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
- **Manual Conversion Applied**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
  - All schema objects lowercased
  - ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2) -> ROUND(((p.price - ph.previousprice) / ph.previousprice * 100)::numeric, 2)
- **Equivalency Check**: ERROR - "'uniqueID'" (tool-level error)

### Statement 3: InsertProductAsync
- **Source File**: `DataAccess/ProductRepository.cs` (lines ~111-138)
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE(), SELECT
- **DMS Tool Call**: dms-mcp___statement_conversion_tool with schema_name='dbo', database_name='ProductManagement'
- **DMS Output**: ERROR - "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
- **Manual Conversion Applied**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
  - SCOPE_IDENTITY() -> lastval()
  - GETDATE() -> NOW()
  - BEGIN TRANSACTION -> BEGIN
  - DECLARE @NewProductId INT removed (using lastval() directly)
  - All schema objects lowercased
- **Equivalency Check**: ERROR - "'uniqueID'" (tool-level error)

### Statement 4: UpdateProductAsync
- **Source File**: `DataAccess/ProductRepository.cs` (lines ~147-180)
- **Type**: Transaction block with DECLARE, variable assignment, UPDATE, INSERT history, GETDATE()
- **DMS Tool Call**: dms-mcp___statement_conversion_tool with schema_name='dbo', database_name='ProductManagement'
- **DMS Output**: ERROR - "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
- **Manual Conversion Applied**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
  - DECLARE @OldPrice/@OldStock -> Restructured operations order (INSERT history before UPDATE to capture old values)
  - GETDATE() -> NOW()
  - BEGIN TRANSACTION -> BEGIN
  - Used subquery (SELECT price FROM products WHERE productid = @ProductId) instead of T-SQL variable
  - All schema objects lowercased
- **Equivalency Check**: ERROR - "'uniqueID'" (tool-level error)

### Statement 5: DeleteProductAsync
- **Source File**: `DataAccess/ProductRepository.cs` (lines ~188-224)
- **Type**: Transaction block with DECLARE, variable assignment, DELETE, INSERT history, CASE, GETDATE()
- **DMS Tool Call**: dms-mcp___statement_conversion_tool with schema_name='dbo', database_name='ProductManagement'
- **DMS Output**: ERROR - "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
- **Manual Conversion Applied**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
  - DECLARE @OldPrice/@OldStock -> Restructured operations order (INSERT history and UPDATE stats before DELETE)
  - GETDATE() -> NOW()
  - BEGIN TRANSACTION -> BEGIN
  - Used subquery for old price instead of T-SQL variable
  - All schema objects lowercased
- **Equivalency Check**: ERROR - "'uniqueID'" (tool-level error)

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: `DataAccess/ProductRepository.cs` (lines ~258-275)
- **Type**: CTE with RANK/PERCENT_RANK window functions, BETWEEN, CASE
- **DMS Tool Call**: dms-mcp___statement_conversion_tool with schema_name='dbo', database_name='ProductManagement'
- **DMS Output**: ERROR - "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
- **Manual Conversion Applied**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
  - All schema objects lowercased
  - No SQL Server-specific functions to convert (RANK, PERCENT_RANK, BETWEEN work identically)
- **Equivalency Check**: ERROR - "'uniqueID'" (tool-level error)

### Statement 7: GetLowStockProductsAsync
- **Source File**: `DataAccess/ProductRepository.cs` (lines ~295-314)
- **Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **DMS Tool Call**: dms-mcp___statement_conversion_tool with schema_name='dbo', database_name='ProductManagement'
- **DMS Output**: ERROR - "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
- **Manual Conversion Applied**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
  - All schema objects lowercased
  - ROUND((StockQuantity / AvgStock) * 100, 2) -> ROUND((stockquantity::numeric / avgstock * 100)::numeric, 2)
- **Equivalency Check**: ERROR - "'uniqueID'" (tool-level error)

---

## Static Code Changes

### Package Dependencies
- **Removed**: `Microsoft.Data.SqlClient` Version 5.1.4
- **Added**: `Npgsql` Version 8.0.6

### ADO.NET Class Replacements
| Original (SQL Server) | Replacement (PostgreSQL) | Occurrences |
|------------------------|--------------------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 (field, method return type, constructor) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per data access method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader) |

### Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|-----------|------------|------------|
| Server | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Auth | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TLS | `TrustServerCertificate=True` | Removed (not applicable) |

---

## DMS Tool Summary
- **Total DMS Calls**: 7 (all 7 SQL statements)
- **Successful Conversions**: 0
- **Failed Conversions**: 7
- **Error**: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}" (consistent across all calls)
- **Retry Attempts**: Tried with default parameters, explicit migration_project_identifier, and increased poll_attempts (30) / poll_interval (15s)

## SQL Equivalency Tool Summary
- **Total Validations**: 7
- **EQUIVALENT**: 0
- **NOT_EQUIVALENT**: 0
- **ERROR**: 7
- **Error**: "'uniqueID'" (consistent across all calls - appears to be a tool-level issue)
