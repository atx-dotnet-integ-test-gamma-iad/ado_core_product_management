# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-05-02 |
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Source Framework** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Framework** | Npgsql 8.0.6 |
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS** | 0 |
| **Manual Conversion (DMS Failure)** | 7 |
| **Validated as Equivalent** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |

## DMS Tool Results

All 7 SQL statements were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`) as required. Every statement failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**DMS Configuration Used:**
- Migration Project ARN: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- Database Name: `ProductManagement`
- Schema Name: `dbo`
- Region: `us-east-1`

Since DMS failed for all statements, manual conversion was applied using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` approach as specified in the transformation definition.

## SQL Equivalency Results

All 7 statement pairs were validated through the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All returned `ERROR` status with error `'uniqueID'`.

**Note:** Per the transformation definition, no agent judgment was used for equivalency determination. All statuses come exclusively from the SQL Equivalency tool output.

## Detailed Statement Conversion Report

### Statement 1: GetAllProductsAsync
- **Source File:** `DataAccess/ProductRepository.cs`
- **Method:** `GetAllProductsAsync()`
- **SQL Features:** CTE, AVG/COUNT window functions, CASE, ROUND, INNER JOIN
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Status:** Failed
- **Equivalency Status:** ERROR
- **Key Changes:**
  - All schema object names lowercased (Products → products, ProductId → productid, etc.)
  - CTE alias: ProductStats → productstats
  - Column aliases lowercased

### Statement 2: GetProductByIdAsync
- **Source File:** `DataAccess/ProductRepository.cs`
- **Method:** `GetProductByIdAsync(int productId)`
- **SQL Features:** CTE, LAG window function, CASE, ROUND, LEFT JOIN, parameterized
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Status:** Failed
- **Equivalency Status:** ERROR
- **Key Changes:**
  - All schema object names lowercased
  - CTE alias: ProductHistory → producthistory
  - Parameter syntax preserved (@ProductId works with Npgsql)

### Statement 3: InsertProductAsync
- **Source File:** `DataAccess/ProductRepository.cs`
- **Method:** `InsertProductAsync(Product product)`
- **SQL Features:** DECLARE, BEGIN TRANSACTION/COMMIT, SCOPE_IDENTITY(), GETDATE(), INSERT, UPDATE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Status:** Failed
- **Equivalency Status:** ERROR
- **Key Changes:**
  - `SCOPE_IDENTITY()` → `INSERT...RETURNING productid`
  - `GETDATE()` → `NOW()`
  - `DECLARE @var / SET @var` → Removed, restructured into separate C# commands
  - `BEGIN TRANSACTION / COMMIT` → C# managed transaction (BeginTransactionAsync/CommitAsync)
  - Split single SQL batch into 3 separate NpgsqlCommand executions within C# transaction
  - All schema object names lowercased

### Statement 4: UpdateProductAsync
- **Source File:** `DataAccess/ProductRepository.cs`
- **Method:** `UpdateProductAsync(Product product)`
- **SQL Features:** BEGIN TRANSACTION, DECLARE, variable assignment via SELECT, GETDATE(), INSERT, UPDATE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Status:** Failed
- **Equivalency Status:** ERROR
- **Key Changes:**
  - `GETDATE()` → `NOW()`
  - `DECLARE @OldPrice / @OldStock` → Fetched via separate SELECT command, stored in C# variables
  - `BEGIN TRANSACTION / COMMIT` → C# managed transaction
  - Split into 4 separate NpgsqlCommand executions (fetch, update, history insert, stats update)
  - All schema object names lowercased

### Statement 5: DeleteProductAsync
- **Source File:** `DataAccess/ProductRepository.cs`
- **Method:** `DeleteProductAsync(int productId)`
- **SQL Features:** BEGIN TRANSACTION, DECLARE, CASE expression, GETDATE(), INSERT, DELETE, UPDATE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Status:** Failed
- **Equivalency Status:** ERROR
- **Key Changes:**
  - `GETDATE()` → `NOW()`
  - `DECLARE @OldPrice / @OldStock` → Fetched via separate SELECT, stored in C# variables
  - CASE expression preserved (compatible between SQL Server and PostgreSQL)
  - `BEGIN TRANSACTION / COMMIT` → C# managed transaction
  - Split into 4 separate NpgsqlCommand executions (fetch, history insert, delete, stats update)
  - All schema object names lowercased

### Statement 6: GetProductsByPriceRangeAsync
- **Source File:** `DataAccess/ProductRepository.cs`
- **Method:** `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **SQL Features:** CTE, RANK/PERCENT_RANK window functions, CASE, BETWEEN, parameterized
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Status:** Failed
- **Equivalency Status:** ERROR
- **Key Changes:**
  - All schema object names lowercased
  - CTE alias: RankedProducts → rankedproducts
  - Window functions (RANK, PERCENT_RANK) preserved (compatible)

### Statement 7: GetLowStockProductsAsync
- **Source File:** `DataAccess/ProductRepository.cs`
- **Method:** `GetLowStockProductsAsync(int threshold)`
- **SQL Features:** CTE, AVG/MIN/MAX window functions, CASE, ROUND, parameterized
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Status:** Failed
- **Equivalency Status:** ERROR
- **Key Changes:**
  - All schema object names lowercased
  - CTE alias: StockAnalysis → stockanalysis
  - Added `::numeric` cast for integer division in ROUND function (PostgreSQL requires explicit numeric type for ROUND with decimals)

## Schema Name Changes

Since DMS failed and manual conversion was applied, all schema object names were converted to lowercase per the PostgreSQL convention:

| SQL Server Name | PostgreSQL Name |
|----------------|-----------------|
| Products | products |
| ProductId | productid |
| ProductHistory | producthistory |
| ProductStats | productstats |
| StockQuantity | stockquantity |
| CreatedDate | createddate |
| ModifiedDate | modifieddate |
| AvgPrice | avgprice |
| TotalProducts | totalproducts |
| AveragePrice | averageprice |
| LastUpdated | lastupdated |
| StatId | statid |
| ActionDate | actiondate |
| OldPrice | oldprice |
| NewPrice | newprice |
| OldStock | oldstock |
| NewStock | newstock |

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent |
|-----------------|-------------------|
| `Microsoft.Data.SqlClient` (namespace) | `Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` (AddWithValue used) |

## Configuration Changes

### Package Dependencies (AdoCore.csproj)
- **Removed:** `Microsoft.Data.SqlClient` version 5.1.4
- **Added:** `Npgsql` version 8.0.6

### Connection Strings (appsettings.json)
- **Before:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After:** `Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres`

### SQL Setup Scripts
- **Database/Scripts/01_InitialSetup.sql:** Full conversion with all tables, indexes, triggers, and functions
- **Scripts/01_InitialSetup.sql:** Simplified version with products table and basic functions

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| Extracted Statements | `extracted_statements.sql` | All 7 original MS SQL statements |
| Converted Statements | `converted_statements.sql` | All 7 converted PostgreSQL statements |
| Equivalency Report | `sql_equivalency_validation_report.json` | Complete validation report with all 7 pairs |
| Migration Report | `migration_report.md` | This document |

## Build Status

**Final Build:** ✅ SUCCESS (0 errors, warnings are pre-existing nullable reference type warnings)

## Files Modified

1. `DataAccess/ProductRepository.cs` - SQL statements, ADO.NET classes, transaction handling
2. `AdoCore.csproj` - Package reference (SqlClient → Npgsql)
3. `appsettings.json` - Connection strings (SQL Server → PostgreSQL format)
4. `Database/Scripts/01_InitialSetup.sql` - Full PostgreSQL DDL with functions/triggers
5. `Scripts/01_InitialSetup.sql` - Simplified PostgreSQL DDL with functions
