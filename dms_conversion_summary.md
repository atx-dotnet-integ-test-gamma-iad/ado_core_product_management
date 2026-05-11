# SQL Server to PostgreSQL Migration - DMS Conversion Summary

## Migration Overview
- **Project**: AdoCore - Product Management System
- **Source Database**: Microsoft SQL Server (via Microsoft.Data.SqlClient 5.1.4)
- **Target Database**: PostgreSQL (via Npgsql 8.0.1)
- **Migration Tool**: AWS DMS MCP Statement Conversion Tool
- **DMS Status**: FAILED - All conversions failed with metadata model creation error

## DMS Tool Error Details
All 7 SQL statements were submitted to the DMS MCP tool for conversion. All failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

## Manual Conversion Applied
Since the DMS tool was unavailable, manual conversion was applied using the following rules
(as per DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA):

### Schema Object Name Mapping (Lowercase Convention)
| SQL Server Name | PostgreSQL Name |
|----------------|----------------|
| Products | products |
| ProductHistory | producthistory |
| ProductStats | productstats |
| ProductId | productid |
| Name | name |
| Description | description |
| Price | price |
| StockQuantity | stockquantity |
| CreatedDate | createddate |
| ModifiedDate | modifieddate |
| OldPrice | oldprice |
| NewPrice | newprice |
| OldStock | oldstock |
| NewStock | newstock |
| ActionDate | actiondate |
| TotalProducts | totalproducts |
| AveragePrice | averageprice |
| LastUpdated | lastupdated |
| StatId | statid |
| HistoryId | historyid |
| Action | action |

### SQL Syntax Conversions Applied
| SQL Server Syntax | PostgreSQL Equivalent |
|------------------|---------------------|
| SCOPE_IDENTITY() | INSERT ... RETURNING productid |
| GETDATE() | NOW() |
| DECLARE @var / SET @var | CTE (WITH clause) |
| BEGIN TRANSACTION / COMMIT | Writable CTE (single statement) |
| INT IDENTITY(1,1) | SERIAL |
| NVARCHAR(n) | VARCHAR(n) |
| DATETIME | TIMESTAMP |
| Trusted_Connection=True | Username/Password auth |
| Server= | Host= |

## Statement Conversion Summary

| # | Method | Source Location | SQL Type | Key Changes |
|---|--------|---------------|----------|-------------|
| 1 | GetAllProductsAsync | ProductRepository.cs | SELECT with CTE | Lowercase schema objects only |
| 2 | GetProductByIdAsync | ProductRepository.cs | SELECT with CTE/LAG | Lowercase schema objects only |
| 3 | InsertProductAsync | ProductRepository.cs | Transaction block | SCOPE_IDENTITY->RETURNING, GETDATE->NOW, writable CTE |
| 4 | UpdateProductAsync | ProductRepository.cs | Transaction block | DECLARE->CTE, GETDATE->NOW, writable CTE |
| 5 | DeleteProductAsync | ProductRepository.cs | Transaction block | DECLARE->CTE, GETDATE->NOW, writable CTE |
| 6 | GetProductsByPriceRangeAsync | ProductRepository.cs | SELECT with CTE/RANK | Lowercase schema objects only |
| 7 | GetLowStockProductsAsync | ProductRepository.cs | SELECT with CTE/AVG | Lowercase schema objects, added CAST for integer division |

## SQL Equivalency Validation Results
All 7 statement pairs were submitted to the SQL Equivalency tool for validation.
All returned ERROR status with error: `'uniqueID'`

This appears to be a systemic issue with the SQL Equivalency tool service, not related to the statement conversions themselves.

## Static Code Changes

### Package Reference Changes (AdoCore.csproj)
- Removed: `Microsoft.Data.SqlClient` Version 5.1.4
- Added: `Npgsql` Version 8.0.1

### ADO.NET Class Replacements (ProductRepository.cs)
- `using Microsoft.Data.SqlClient` → `using Npgsql`
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`

### Connection String Changes (appsettings.json)
- `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
  → `Host=localhost;Database=productmanagement;Username=postgres;Password=postgres`

### Column Name Reference Updates in MapProductFromReader
All reader column name references updated to lowercase to match PostgreSQL schema:
- `reader["ProductId"]` → `reader["productid"]`
- `reader["Name"]` → `reader["name"]`
- `reader["Description"]` → `reader["description"]`
- `reader["Price"]` → `reader["price"]`
- `reader["StockQuantity"]` → `reader["stockquantity"]`
- `reader["CreatedDate"]` → `reader["createddate"]`
- `reader["ModifiedDate"]` → `reader["modifieddate"]`

## Final Statistics
- Total SQL statements processed: 7
- Statements successfully converted by DMS: 0
- Statements manually converted (DMS failure): 7
- Statements validated as equivalent: 0
- Statements validated as non-equivalent: 0
- Statements with equivalency validation errors: 7
- Statements requiring manual review: 7 (all, due to tool failures)
