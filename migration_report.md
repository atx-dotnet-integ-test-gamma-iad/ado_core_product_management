# Migration Report: MS SQL Server to PostgreSQL

## Overview
- **Application**: AdoCore (.NET 9.0 ADO.NET Application)
- **Source Database**: Microsoft SQL Server 2019 (ProductManagement)
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-04-08
- **DMS Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention after DMS tool processing | 7 |
| Statements validated as equivalent (by SQL Equivalency tool) | 0 |
| Statements validated as non-equivalent (by SQL Equivalency tool) | 0 |
| Statements with equivalency validation errors (by SQL Equivalency tool) | 7 |

## DMS Tool Status

The DMS MCP statement conversion tool (`dms-mcp___statement_conversion_tool`) consistently failed for all 7 statements with the following error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Multiple retry attempts were made with varying configurations (different poll intervals, max poll attempts, server names). All attempts returned the same error. This appears to be an infrastructure/service-level issue with the DMS metadata model creation process.

**However**, the DMS schema mapping tool (`dms-mcp___schema_mapping_tool`) was successful and provided accurate schema transformations for all three tables. These mappings were used to guide the manual conversion with lowercase schema object names.

### DMS Schema Mapping Results

| Source Table (MS SQL) | Target Table (PostgreSQL) | Target Schema |
|----------------------|--------------------------|---------------|
| dbo.Products | products | productmanagement_dbo |
| dbo.ProductHistory | producthistory | productmanagement_dbo |
| dbo.ProductStats | productstats | productmanagement_dbo |

Key column mappings from DMS:
- `ProductId` → `productid`
- `Name` → `name`
- `Description` → `description`
- `Price` → `price`
- `StockQuantity` → `stockquantity`
- `CreatedDate` → `createddate`
- `ModifiedDate` → `modifieddate`
- `datetime` → `TIMESTAMP WITHOUT TIME ZONE`
- `decimal(18,2)` → `NUMERIC(18,2)`
- `int IDENTITY(1,1)` → `INTEGER GENERATED ALWAYS AS IDENTITY`
- `GETDATE()` default → `clock_timestamp()` default

## SQL Equivalency Tool Status

The SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`) consistently returned ERROR for all 7 statement pairs with the following error:

```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be an infrastructure/service-level issue. All 7 statement pairs were submitted to the tool and all returned the same error. The equivalency status for all statements is marked as ERROR per the tool's output.

## Detailed Statement Conversion Log

### Statement 1: GetAllProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetAllProductsAsync()
- **Type**: SELECT with CTE, AVG/COUNT Window Functions, CASE, JOIN, ORDER BY
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion Applied**:
  - Table names: Products → products
  - Column names: All lowercased (ProductId → productid, Name → name, etc.)
  - CTE alias: ProductStats → productstats_cte (to avoid conflict with physical table)
  - SQL functions: No changes needed (AVG, COUNT, ROUND, CASE are PostgreSQL-compatible)
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

### Statement 2: GetProductByIdAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetProductByIdAsync(int productId)
- **Type**: SELECT with CTE, LAG Window Function, Parameterized Query
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion Applied**:
  - Table names: Products → products
  - Column names: All lowercased
  - CTE alias: ProductHistory → producthistory_cte
  - Parameter @ProductId preserved (Npgsql supports @param syntax)
  - SQL functions: LAG, ROUND, CASE are PostgreSQL-compatible
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

### Statement 3: InsertProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: InsertProductAsync(Product product)
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), UPDATE, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion Applied**:
  - Table names: Products → products, ProductHistory → producthistory, ProductStats → productstats
  - Column names: All lowercased
  - SCOPE_IDENTITY() → lastval()
  - GETDATE() → clock_timestamp()
  - DECLARE @NewProductId / SET → Removed; used lastval() for product ID reference
  - BEGIN TRANSACTION/COMMIT → Removed (transaction managed by C# BeginTransactionAsync)
  - SELECT @NewProductId → SELECT lastval()
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

### Statement 4: UpdateProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: UpdateProductAsync(Product product)
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion Applied**:
  - Table names: All lowercased
  - Column names: All lowercased
  - DECLARE @OldPrice/@OldStock + SELECT INTO → INSERT...SELECT subquery (captures old values before update)
  - GETDATE() → clock_timestamp()
  - BEGIN TRANSACTION/COMMIT → Removed (transaction managed by C# code)
  - ProductStats UPDATE uses subquery to fetch old price from producthistory
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

### Statement 5: DeleteProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: DeleteProductAsync(int productId)
- **Type**: Transaction block with DECLARE, SELECT INTO, INSERT, DELETE, UPDATE with CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion Applied**:
  - Table names: All lowercased
  - Column names: All lowercased
  - DECLARE @OldPrice/@OldStock + SELECT INTO → INSERT...SELECT subquery
  - GETDATE() → clock_timestamp()
  - BEGIN TRANSACTION/COMMIT → Removed
  - CASE expression in UPDATE preserved (PostgreSQL-compatible)
  - ProductStats UPDATE uses subquery to fetch old price from producthistory
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion Applied**:
  - Table names: Products → products
  - Column names: All lowercased
  - CTE alias: RankedProducts → rankedproducts
  - Window functions: RANK(), PERCENT_RANK() are PostgreSQL-compatible
  - BETWEEN, CASE are PostgreSQL-compatible
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

### Statement 7: GetLowStockProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetLowStockProductsAsync(int threshold)
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion Applied**:
  - Table names: Products → products
  - Column names: All lowercased
  - CTE alias: StockAnalysis → stockanalysis
  - Added CAST(stockquantity AS NUMERIC) for integer division fix
  - Window functions: AVG, MIN, MAX are PostgreSQL-compatible
  - CASE, ROUND are PostgreSQL-compatible
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

## Code Changes Summary

### Package Dependencies
| Original | Replacement |
|----------|-------------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.3 |

### ADO.NET Type Replacements
| Original Type | Replacement Type |
|--------------|-----------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

### Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server name | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `true` | (removed - not applicable) |
| TrustServerCertificate | `True` | (removed - not applicable) |

### SQL Syntax Transformations
| MS SQL Server | PostgreSQL |
|--------------|------------|
| `SCOPE_IDENTITY()` | `lastval()` |
| `GETDATE()` | `clock_timestamp()` |
| `DECLARE @var TYPE; SET @var = ...` | Subqueries or `INSERT...SELECT` |
| `BEGIN TRANSACTION; ... COMMIT;` | Managed by C# `BeginTransactionAsync()` |
| `int IDENTITY(1,1)` | `INTEGER GENERATED ALWAYS AS IDENTITY` |
| Table/Column names (PascalCase) | lowercase per DMS schema mapping |

## Files Modified
1. `DataAccess/ProductRepository.cs` - SQL statements, ADO.NET types, column name references
2. `AdoCore.csproj` - Package reference (SqlClient → Npgsql)
3. `appsettings.json` - Connection strings (SQL Server → PostgreSQL format)

## Artifacts Generated
1. `extracted_statements.sql` - Complete catalog of all 7 original MS SQL statements
2. `converted_statements.sql` - Complete catalog of all 7 converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report (7 pairs, all ERROR status from tool)
4. `migration_report.md` - This report

## Statements Requiring Manual Review
All 7 statements require manual review because:
1. DMS statement conversion tool was unavailable (metadata model creation failed)
2. SQL Equivalency tool returned errors for all pairs ('uniqueID' error)
3. Manual conversion was applied using DMS schema mapping output as the authoritative source for schema object names

## Build Status
Final build: **SUCCESS** (0 errors, 10 warnings - all pre-existing nullable reference warnings)
