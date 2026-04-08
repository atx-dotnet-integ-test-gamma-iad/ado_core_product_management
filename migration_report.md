# Migration Report: SQL Server to PostgreSQL

## Overview

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-04-08 |
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Application Framework** | .NET 9.0 (ADO.NET) |
| **Source Package** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Package** | Npgsql 8.0.1 |
| **Build Status** | ✅ Success |

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Statements Successfully Converted by DMS Tool** | 0 |
| **Statements Requiring Manual Intervention (DMS Failure)** | 7 |
| **Statements Validated as Equivalent** | 0 |
| **Statements Validated as Non-Equivalent** | 0 |
| **Statements with Equivalency Validation Errors** | 7 |

### DMS Tool Status

The DMS MCP statement conversion tool (`dms-mcp___statement_conversion_tool`) was attempted for ALL 7 SQL statements but consistently failed with:
- **Error**: "Metadata model creation/conversion did not complete after maximum poll attempts"
- **Retry Attempts**: Multiple attempts with increased `max_poll_attempts` (15, 25, 30) and `poll_interval_seconds` (10, 12, 15)
- **Final Status**: Command execution timed out after 300 seconds

The DMS Schema Mapping Tool (`dms-mcp___schema_mapping_tool`) worked successfully and was used to obtain accurate schema mappings for manual conversion.

### SQL Equivalency Tool Status

The SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`) was invoked for ALL 7 statement pairs but returned ERROR for all with:
- **Error**: `'uniqueID'`
- **Status**: All 7 pairs marked as ERROR per transformation definition requirements

### Manual Conversion Approach

Per the transformation definition, when DMS fails, manual conversion was applied with:
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Schema Mapping Source**: DMS Schema Mapping Tool (verified mappings)
- **Key Transformations**:
  - All table names lowercased (Products → products, ProductHistory → producthistory, ProductStats → productstats)
  - All column names lowercased (ProductId → productid, StockQuantity → stockquantity, etc.)
  - `SCOPE_IDENTITY()` → `RETURNING productid` clause
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → C# managed `NpgsqlTransaction`
  - `DECLARE @var` / `SELECT @var = column` → C# variables with separate SELECT queries
  - CTE names renamed to avoid collision with table names (productstats_cte, producthistory_cte)
  - Integer division in `ROUND()` → Added `CAST(... AS NUMERIC)` for PostgreSQL

---

## Statement-by-Statement Details

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND
- **Conversion**: Lowercase schema objects, CTE renamed to `productstats_cte`
- **DMS Result**: Failed (timeout)
- **Equivalency Result**: ERROR ('uniqueID')

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG Window Function, LEFT JOIN, CASE, ROUND, Parameterized (@ProductId)
- **Conversion**: Lowercase schema objects, CTE renamed to `producthistory_cte`
- **DMS Result**: Failed (timeout)
- **Equivalency Result**: ERROR ('uniqueID')

### Statement 3: InsertProductAsync
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
- **Conversion**: Refactored to multi-statement with RETURNING clause, NOW(), C# transaction
- **DMS Result**: Failed (timeout)
- **Equivalency Result**: ERROR ('uniqueID')

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **Conversion**: Refactored to multi-statement with C# variables and transaction, NOW()
- **DMS Result**: Failed (timeout)
- **Equivalency Result**: ERROR ('uniqueID')

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, CASE, GETDATE()
- **Conversion**: Refactored to multi-statement with C# variables and transaction, NOW()
- **DMS Result**: Failed (timeout)
- **Equivalency Result**: ERROR ('uniqueID')

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Conversion**: Lowercase schema objects, window functions compatible
- **DMS Result**: Failed (timeout)
- **Equivalency Result**: ERROR ('uniqueID')

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
- **Conversion**: Lowercase schema objects, CAST for integer division in ROUND
- **DMS Result**: Failed (timeout)
- **Equivalency Result**: ERROR ('uniqueID')

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL, class references updated (NpgsqlConnection, NpgsqlCommand, NpgsqlDataReader, NpgsqlTransaction), using directive updated, reader column names lowercased, transaction handling refactored |
| `AdoCore.csproj` | Package reference changed from Microsoft.Data.SqlClient 5.1.4 to Npgsql 8.0.1 |
| `appsettings.json` | Connection strings updated from SQL Server format to PostgreSQL Npgsql format |

## Artifact Files Generated

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | JSON report with equivalency validation results for all 7 statement pairs |
| `migration_report.md` | This comprehensive migration report |

## Schema Mapping (from DMS Schema Mapping Tool)

### Products → products
| SQL Server Column | PostgreSQL Column | Type Mapping |
|-------------------|-------------------|-------------|
| ProductId | productid | int IDENTITY → INTEGER GENERATED ALWAYS AS IDENTITY |
| Name | name | nvarchar(100) → VARCHAR(100) |
| Description | description | nvarchar(500) → VARCHAR(500) |
| Price | price | decimal(18,2) → NUMERIC(18,2) |
| StockQuantity | stockquantity | int → INTEGER |
| CreatedDate | createddate | datetime → TIMESTAMP WITHOUT TIME ZONE |
| ModifiedDate | modifieddate | datetime → TIMESTAMP WITHOUT TIME ZONE |

### ProductHistory → producthistory
| SQL Server Column | PostgreSQL Column | Type Mapping |
|-------------------|-------------------|-------------|
| HistoryId | historyid | int IDENTITY → INTEGER GENERATED ALWAYS AS IDENTITY |
| ProductId | productid | int → INTEGER |
| Action | action | varchar(10) → VARCHAR(10) |
| OldPrice | oldprice | decimal(18,2) → NUMERIC(18,2) |
| NewPrice | newprice | decimal(18,2) → NUMERIC(18,2) |
| OldStock | oldstock | int → INTEGER |
| NewStock | newstock | int → INTEGER |
| ActionDate | actiondate | datetime → TIMESTAMP WITHOUT TIME ZONE |

### ProductStats → productstats
| SQL Server Column | PostgreSQL Column | Type Mapping |
|-------------------|-------------------|-------------|
| StatId | statid | int → INTEGER |
| TotalProducts | totalproducts | int → INTEGER |
| AveragePrice | averageprice | decimal(18,2) → NUMERIC(18,2) |
| LastUpdated | lastupdated | datetime → TIMESTAMP WITHOUT TIME ZONE |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| SSL | `TrustServerCertificate=True` | Removed (not applicable) |

## Files NOT Modified (No SQL Server Dependencies)

- `Business/ProductService.cs` - No SQL Server imports or references
- `CLI/CommandLineInterface.cs` - No SQL Server imports or references
- `CLI/InteractiveMenu.cs` - No SQL Server imports or references
- `Models/Product.cs` - No SQL Server imports or references
- `Program.cs` - No SQL Server imports or references
