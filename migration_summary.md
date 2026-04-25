# Migration Summary: MS SQL Server to PostgreSQL

## Overview
Migration of AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-04-25  
**Source Database:** Microsoft SQL Server 2019  
**Target Database:** PostgreSQL 13  
**Application Framework:** .NET 9.0 with ADO.NET  

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| DMS Tool Conversion Successes | 0 |
| DMS Tool Conversion Failures | 7 |
| Manual Conversions (with lowercase schema) | 7 |
| Equivalency Validated as EQUIVALENT | 0 |
| Equivalency Validated as NOT_EQUIVALENT | 0 |
| Equivalency Validated as ERROR | 7 |

### DMS Tool Status
The DMS MCP Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) consistently failed for all 7 statements with the error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

The DMS Schema Mapping Tool (`dms-mcp___schema_mapping_tool`) was successful and provided the target schema mappings used for manual conversion.

### SQL Equivalency Tool Status
The SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`) returned ERROR for all 7 statement pairs with:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```
This appears to be a consistent tool infrastructure issue unrelated to the SQL statements.

---

## Schema Mapping (from DMS Schema Mapping Tool)

| Source Table (SQL Server) | Target Table (PostgreSQL) | Target Schema |
|---------------------------|---------------------------|---------------|
| dbo.Products | products | productmanagement_dbo |
| dbo.ProductHistory | producthistory | productmanagement_dbo |
| dbo.ProductStats | productstats | productmanagement_dbo |

### Column Mappings

**Products → products**
| Source Column | Target Column | Source Type | Target Type |
|---------------|---------------|-------------|-------------|
| ProductId | productid | int IDENTITY(1,1) | INTEGER GENERATED ALWAYS AS IDENTITY |
| Name | name | nvarchar(100) | VARCHAR(100) |
| Description | description | nvarchar(500) | VARCHAR(500) |
| Price | price | decimal(18,2) | NUMERIC(18,2) |
| StockQuantity | stockquantity | int | INTEGER |
| CreatedDate | createddate | datetime DEFAULT GETDATE() | TIMESTAMP DEFAULT clock_timestamp() |
| ModifiedDate | modifieddate | datetime | TIMESTAMP |

**ProductHistory → producthistory**
| Source Column | Target Column | Source Type | Target Type |
|---------------|---------------|-------------|-------------|
| HistoryId | historyid | int IDENTITY(1,1) | INTEGER GENERATED ALWAYS AS IDENTITY |
| ProductId | productid | int | INTEGER |
| Action | action | varchar(10) | VARCHAR(10) |
| OldPrice | oldprice | decimal(18,2) | NUMERIC(18,2) |
| NewPrice | newprice | decimal(18,2) | NUMERIC(18,2) |
| OldStock | oldstock | int | INTEGER |
| NewStock | newstock | int | INTEGER |
| ActionDate | actiondate | datetime DEFAULT GETDATE() | TIMESTAMP DEFAULT clock_timestamp() |

**ProductStats → productstats**
| Source Column | Target Column | Source Type | Target Type |
|---------------|---------------|-------------|-------------|
| StatId | statid | int DEFAULT 1 | INTEGER DEFAULT 1 |
| TotalProducts | totalproducts | int DEFAULT 0 | INTEGER DEFAULT 0 |
| AveragePrice | averageprice | decimal(18,2) DEFAULT 0 | NUMERIC(18,2) DEFAULT 0 |
| LastUpdated | lastupdated | datetime DEFAULT GETDATE() | TIMESTAMP DEFAULT clock_timestamp() |

---

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Type:** CTE with AVG/COUNT window functions, CASE, ROUND, INNER JOIN
- **Key Changes:** Table/column names lowercased per DMS schema mapping
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 2: GetProductByIdAsync
- **Type:** CTE with LAG window function, ROUND, LEFT JOIN, parameterized WHERE
- **Key Changes:** Table/column names lowercased per DMS schema mapping
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 3: InsertProductAsync
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY(), history logging, stats update
- **Key Changes:**
  - SCOPE_IDENTITY() → INSERT...RETURNING productid
  - GETDATE() → NOW()
  - Single T-SQL batch → Multiple C# commands within transaction
  - DECLARE @var → C# variables
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, UPDATE
- **Key Changes:**
  - DECLARE @var / SELECT INTO @var → Separate SELECT query into C# variables
  - GETDATE() → NOW()
  - Single T-SQL batch → Multiple C# commands within transaction
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE
- **Key Changes:**
  - DECLARE @var / SELECT INTO @var → Separate SELECT query into C# variables
  - GETDATE() → NOW()
  - Single T-SQL batch → Multiple C# commands within transaction
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** CTE with RANK(), PERCENT_RANK(), CASE, BETWEEN
- **Key Changes:** Table/column names lowercased per DMS schema mapping
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 7: GetLowStockProductsAsync
- **Type:** CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Key Changes:**
  - Table/column names lowercased per DMS schema mapping
  - Added ::numeric cast for integer division to prevent truncation
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

---

## Files Modified

| File | Changes |
|------|---------|
| DataAccess/ProductRepository.cs | All SQL statements converted to PostgreSQL; SqlClient → Npgsql classes; Transaction blocks restructured |
| AdoCore.csproj | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| appsettings.json | Connection strings updated from SQL Server to PostgreSQL format |

## Files Created

| File | Description |
|------|-------------|
| extracted_statements.sql | Catalog of all 7 original MS SQL statements |
| converted_statements.sql | Catalog of all 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | Comprehensive equivalency validation report |
| migration_summary.md | This file |

---

## Package Dependency Changes

| Before | After | Reason |
|--------|-------|--------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 | PostgreSQL ADO.NET driver replacement |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | Server=localhost | Host=localhost |
| Database | Database=ProductManagement | Database=ProductManagement |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MARS | MultipleActiveResultSets=true | (removed - not applicable) |
| Certificate | TrustServerCertificate=True | (removed - not applicable) |

---

## ADO.NET Class Replacements

| SQL Server (Microsoft.Data.SqlClient) | PostgreSQL (Npgsql) |
|---------------------------------------|---------------------|
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |
| SqlParameter | NpgsqlParameter (via AddWithValue) |
| using Microsoft.Data.SqlClient | using Npgsql |

---

## Manual Interventions Required

All 7 SQL statements required manual conversion due to DMS tool failure. The following manual interventions were applied:

1. **Schema Object Names:** Converted to lowercase per DMS schema mapping (e.g., `Products` → `products`, `ProductId` → `productid`)
2. **SCOPE_IDENTITY():** Replaced with PostgreSQL `RETURNING` clause
3. **GETDATE():** Replaced with PostgreSQL `NOW()`
4. **T-SQL Batch Syntax:** DECLARE/SET variables replaced with separate C# commands within transactions
5. **Integer Division:** Added `::numeric` cast where integer division could cause truncation
6. **Transaction Management:** Moved from inline T-SQL BEGIN TRANSACTION/COMMIT to C# `BeginTransactionAsync()`/`CommitAsync()`/`RollbackAsync()`

---

## Build Status
- **Final Build:** SUCCESS (0 errors, 10 warnings)
- **Warnings:** All pre-existing nullable reference warnings, no new warnings introduced
- **Npgsql Version:** 8.0.6 (upgraded from 8.0.1 to resolve known vulnerability GHSA-x9vc-6hfv-hg8c)
