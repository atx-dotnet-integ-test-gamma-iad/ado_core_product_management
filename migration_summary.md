# SQL Server to PostgreSQL Migration Summary

## Migration Overview
- **Source**: Microsoft SQL Server 2019
- **Target**: PostgreSQL 13
- **Application**: AdoCore (.NET 9.0 Console Application)
- **Migration Tool**: AWS DMS (attempted) + Manual Conversion

## DMS Tool Status
**All 7 SQL statement conversions FAILED through the DMS MCP tool.**

Error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

DMS ARN: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

## SQL Equivalency Tool Status
**All 7 SQL statement pair validations returned ERROR from the SQL Equivalency tool.**

Error: `'uniqueID'`

This appears to be a systemic tool issue, not related to individual statement quality.

## Conversion Method Applied
Since DMS failed, all statements were manually converted using the rule: **DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA**

### Schema Mapping Rules Applied:
1. All table names → lowercase (Products → products, ProductHistory → producthistory, ProductStats → productstats)
2. All column names → lowercase (ProductId → productid, StockQuantity → stockquantity, etc.)
3. All aliases → lowercase
4. CTE names → lowercase

### SQL Server → PostgreSQL Syntax Conversions:
| SQL Server | PostgreSQL | Notes |
|---|---|---|
| `SCOPE_IDENTITY()` | `RETURNING productid` | Used RETURNING clause on INSERT |
| `GETDATE()` | `NOW()` | Standard PostgreSQL current timestamp |
| `IDENTITY(1,1)` | `SERIAL` | PostgreSQL auto-increment |
| `NVARCHAR(n)` | `VARCHAR(n)` | PostgreSQL uses VARCHAR |
| `DATETIME` | `TIMESTAMP` | PostgreSQL timestamp type |
| `BIT` | `BOOLEAN` | PostgreSQL boolean type |
| `DECLARE @var / SET @var` | Application-level variables | Restructured transactions |
| `BEGIN TRANSACTION / COMMIT` (in SQL batch) | Application-level transaction | Using NpgsqlTransaction |
| `SYSTEM_USER` | `CURRENT_USER` | PostgreSQL current user |
| `SET NOCOUNT ON` | (removed) | Not applicable in PostgreSQL |
| `GO` batch separator | (removed) | Not applicable in PostgreSQL |
| `IF NOT EXISTS (SELECT * FROM sys.objects...)` | `DROP ... IF EXISTS` / `CREATE ... IF NOT EXISTS` | PostgreSQL DDL syntax |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` | PostgreSQL uses functions |
| `CREATE TRIGGER ... AFTER INSERT, UPDATE, DELETE` | `CREATE TRIGGER ... AFTER INSERT OR UPDATE OR DELETE` + trigger function | PostgreSQL trigger pattern |
| Integer division `(int / int)` | `(int::numeric / int)` | PostgreSQL needs explicit cast for decimal division |

## Statements Processed

| # | Method | Source Location | Type | DMS Status | Equivalency Status |
|---|---|---|---|---|---|
| 1 | GetAllProductsAsync | ProductRepository.cs | SELECT with CTE + Window Functions | FAILED | ERROR |
| 2 | GetProductByIdAsync | ProductRepository.cs | SELECT with CTE + LAG | FAILED | ERROR |
| 3 | InsertProductAsync | ProductRepository.cs | Transaction: INSERT + SCOPE_IDENTITY + INSERT + UPDATE | FAILED | ERROR |
| 4 | UpdateProductAsync | ProductRepository.cs | Transaction: SELECT + UPDATE + INSERT + UPDATE | FAILED | ERROR |
| 5 | DeleteProductAsync | ProductRepository.cs | Transaction: SELECT + INSERT + DELETE + UPDATE | FAILED | ERROR |
| 6 | GetProductsByPriceRangeAsync | ProductRepository.cs | SELECT with CTE + RANK + PERCENT_RANK | FAILED | ERROR |
| 7 | GetLowStockProductsAsync | ProductRepository.cs | SELECT with CTE + AVG/MIN/MAX Window Functions | FAILED | ERROR |

## Static Code Changes

### Package References (AdoCore.csproj)
- **Removed**: `Microsoft.Data.SqlClient 5.1.4`
- **Added**: `Npgsql 8.0.1`

### Class Replacements (ProductRepository.cs)
- `using Microsoft.Data.SqlClient` → `using Npgsql`
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`

### Connection String (appsettings.json)
- **Before**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After**: `Host=localhost;Database=productmanagement;Username=postgres;Password=postgres;`

### Transaction Handling
- Transactional SQL batches (statements 3, 4, 5) were restructured from single-batch SQL Server scripts with DECLARE/SET variables to multiple commands within application-level NpgsqlTransaction
- This maintains the same atomicity guarantees

## Final Statistics
- Total SQL statements processed: 7
- Statements converted by DMS: 0 (all failed)
- Statements manually converted: 7
- Statements validated as equivalent: 0
- Statements validated as non-equivalent: 0
- Statements with equivalency errors: 7 (tool systemic error)
