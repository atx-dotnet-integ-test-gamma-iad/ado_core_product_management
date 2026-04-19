# MS SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS MCP Tool** | 0 |
| **Manual Conversion After DMS Failure** | 7 |
| **Validated as Equivalent (SQL Equivalency Tool)** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |

## DMS Tool Status

All 7 SQL statements were submitted to the DMS MCP Statement Conversion Tool (`dms-mcp___statement_conversion_tool`). All attempts failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**DMS Configuration Used:**
- Migration Project: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- Database: `ProductManagement`
- Schema: `dbo`
- Region: `us-east-1`
- Server: `172.31.83.165`

## SQL Equivalency Tool Status

All 7 statement pairs were submitted to the SQL Equivalency validation tool (`sql-equivalency___validate_sql_equivalence`). All returned ERROR status:

```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be a backend service issue unrelated to the quality of the conversions.

## Schema Mapping (from DMS Schema Mapping Tool)

The DMS Schema Mapping Tool (`dms-mcp___schema_mapping_tool`) was successfully used to retrieve target schema mappings:

| Source Table (SQL Server) | Target Table (PostgreSQL) | Target Schema |
|---------------------------|---------------------------|---------------|
| `dbo.Products` | `products` | `productmanagement_dbo` |
| `dbo.ProductHistory` | `producthistory` | `productmanagement_dbo` |
| `dbo.ProductStats` | `productstats` | `productmanagement_dbo` |

### Column Mappings (Products)
| SQL Server | PostgreSQL |
|-----------|------------|
| `ProductId` (int IDENTITY) | `productid` (INTEGER GENERATED ALWAYS AS IDENTITY) |
| `Name` (nvarchar) | `name` (VARCHAR) |
| `Description` (nvarchar) | `description` (VARCHAR) |
| `Price` (decimal) | `price` (NUMERIC) |
| `StockQuantity` (int) | `stockquantity` (INTEGER) |
| `CreatedDate` (datetime) | `createddate` (TIMESTAMP WITHOUT TIME ZONE) |
| `ModifiedDate` (datetime) | `modifieddate` (TIMESTAMP WITHOUT TIME ZONE) |

### Column Mappings (ProductHistory)
| SQL Server | PostgreSQL |
|-----------|------------|
| `HistoryId` (int IDENTITY) | `historyid` (INTEGER GENERATED ALWAYS AS IDENTITY) |
| `ProductId` (int) | `productid` (INTEGER) |
| `Action` (varchar) | `action` (VARCHAR) |
| `OldPrice` (decimal) | `oldprice` (NUMERIC) |
| `NewPrice` (decimal) | `newprice` (NUMERIC) |
| `OldStock` (int) | `oldstock` (INTEGER) |
| `NewStock` (int) | `newstock` (INTEGER) |
| `ActionDate` (datetime) | `actiondate` (TIMESTAMP WITHOUT TIME ZONE) |

### Column Mappings (ProductStats)
| SQL Server | PostgreSQL |
|-----------|------------|
| `StatId` (int) | `statid` (INTEGER) |
| `TotalProducts` (int) | `totalproducts` (INTEGER) |
| `AveragePrice` (decimal) | `averageprice` (NUMERIC) |
| `LastUpdated` (datetime) | `lastupdated` (TIMESTAMP WITHOUT TIME ZONE) |

## Detailed Statement Conversion Listing

### Statement 1: GetAllProductsAsync
- **Source File:** `DataAccess/ProductRepository.cs`
- **Method:** `GetAllProductsAsync()`
- **Type:** SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool backend issue)
- **Key Changes:**
  - CTE renamed from `ProductStats` to `productstats_cte` (avoid conflict with table name)
  - All table/column names lowercased per DMS schema mapping
  - Window functions (AVG OVER, COUNT OVER) are PostgreSQL-compatible
  - ROUND function preserved (compatible)
  - CASE expression preserved (compatible)

### Statement 2: GetProductByIdAsync
- **Source File:** `DataAccess/ProductRepository.cs`
- **Method:** `GetProductByIdAsync(int productId)`
- **Type:** SELECT with CTE, LAG Window Function, CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool backend issue)
- **Key Changes:**
  - CTE renamed from `ProductHistory` to `producthistory_cte` (avoid conflict with table name)
  - All table/column names lowercased
  - LAG window function preserved (compatible)
  - Parameter @ProductId preserved for Npgsql compatibility

### Statement 3: InsertProductAsync
- **Source File:** `DataAccess/ProductRepository.cs`
- **Method:** `InsertProductAsync(Product product)`
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool backend issue)
- **Key Changes:**
  - `DECLARE @NewProductId INT` removed
  - `SCOPE_IDENTITY()` → `LASTVAL()`
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION` → `BEGIN;`
  - `SELECT @NewProductId` → `SELECT LASTVAL()`
  - All table/column names lowercased

### Statement 4: UpdateProductAsync
- **Source File:** `DataAccess/ProductRepository.cs`
- **Method:** `UpdateProductAsync(Product product)`
- **Type:** Transaction block with DECLARE variables, GETDATE(), UPDATE/INSERT
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool backend issue)
- **Key Changes:**
  - `DECLARE @OldPrice`/`@OldStock` removed (PostgreSQL doesn't support T-SQL DECLARE)
  - Old values captured via `INSERT...SELECT` subquery pattern
  - Stats update uses subquery to get old price before UPDATE
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION` → `BEGIN;`
  - All table/column names lowercased

### Statement 5: DeleteProductAsync
- **Source File:** `DataAccess/ProductRepository.cs`
- **Method:** `DeleteProductAsync(int productId)`
- **Type:** Transaction block with DECLARE variables, GETDATE(), DELETE, CASE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool backend issue)
- **Key Changes:**
  - `DECLARE @OldPrice`/`@OldStock` removed
  - Old values captured via `INSERT...SELECT` before DELETE
  - Stats update uses subquery from producthistory for old price
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION` → `BEGIN;`
  - CASE expression preserved (compatible)
  - All table/column names lowercased

### Statement 6: GetProductsByPriceRangeAsync
- **Source File:** `DataAccess/ProductRepository.cs`
- **Method:** `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type:** SELECT with CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool backend issue)
- **Key Changes:**
  - CTE renamed from `RankedProducts` to `rankedproducts`
  - RANK() and PERCENT_RANK() preserved (compatible)
  - BETWEEN clause preserved (compatible)
  - All table/column names lowercased

### Statement 7: GetLowStockProductsAsync
- **Source File:** `DataAccess/ProductRepository.cs`
- **Method:** `GetLowStockProductsAsync(int threshold)`
- **Type:** SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool backend issue)
- **Key Changes:**
  - CTE renamed from `StockAnalysis` to `stockanalysis`
  - AVG/MIN/MAX window functions preserved (compatible)
  - Added `CAST(stockquantity AS NUMERIC)` for integer division in ROUND
  - CASE expression preserved (compatible)
  - All table/column names lowercased

## Static Code Changes Summary

### Package Reference Update (AdoCore.csproj)
| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.6 |

### Import Update (ProductRepository.cs)
| Before | After |
|--------|-------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |

### ADO.NET Class Replacements (ProductRepository.cs)
| SQL Server Class | PostgreSQL Class | Occurrences |
|------------------|------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

### Connection String Update (appsettings.json)
| Parameter | Before (SQL Server) | After (PostgreSQL) |
|-----------|--------------------|--------------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | (removed - not applicable) |
| TLS | `TrustServerCertificate=True` | (removed - not applicable) |

## Files Modified

1. `sourceCode/DataAccess/ProductRepository.cs` - SQL statements, imports, ADO.NET classes
2. `sourceCode/AdoCore.csproj` - Package reference
3. `sourceCode/appsettings.json` - Connection strings

## Build Verification

```
dotnet build sourceCode/AdoCore.sln
Result: Build succeeded.
Errors: 0
Warnings: 10 (pre-existing nullable reference warnings)
```

## Transformation Artifacts

| Artifact | Location | Contents |
|----------|----------|----------|
| Extracted SQL Statements | `extracted_statements.sql` | 7 original MS SQL statements |
| Converted SQL Statements | `converted_statements.sql` | 7 converted PostgreSQL statements |
| SQL Equivalency Report | `sql_equivalency_validation_report.json` | 7 statement pairs with tool-determined status |
| Migration Report | `migration_report.md` | This document |
| DMS Conversion Log | `dms_conversion_log.md` | Detailed DMS interaction log |
