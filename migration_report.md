# Migration Report: MS SQL Server to PostgreSQL
## AdoCore .NET Application

### Migration Date: 2026-04-15

---

## Executive Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration covered SQL statement conversion, package dependency updates, ADO.NET class replacements, connection string updates, and SQL script conversions.

---

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total SQL Statements Extracted | 44 |
| Statements from ProductRepository.cs | 7 |
| Statements from Scripts/01_InitialSetup.sql | 8 (S1-S8) |
| Statements from Database/Scripts/01_InitialSetup.sql | 29 (D1-D29) |
| DMS Tool Conversion Successes | 0 |
| DMS Tool Conversion Failures | 44 |
| Manual Conversions (with lowercase schema) | 44 |
| Equivalency Tool: EQUIVALENT | 0 |
| Equivalency Tool: NOT_EQUIVALENT | 0 |
| Equivalency Tool: ERROR | 44 |
| Files Modified | 5 |
| Build Status | SUCCESS |

---

## DMS Tool Status

### Statement Conversion Tool (dms-mcp___statement_conversion_tool)
- **Status**: FAILED for all 44 statements
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Attempts**: Multiple attempts with varying parameters (poll intervals from 10s-20s, max attempts from 15-45)
- **Root Cause**: The DMS metadata model creation process was stuck in RECEIVED status and never progressed

### Schema Mapping Tool (dms-mcp___schema_mapping_tool)
- **Status**: SUCCESSFUL
- **Tables Mapped**: Products, ProductHistory, ProductStats, Categories, Suppliers
- **Target Schema**: productmanagement_dbo
- **Key Mappings Used**: All identifiers converted to lowercase as per DMS schema mapping

---

## SQL Equivalency Tool Status

- **Tool**: sql-equivalency___validate_sql_equivalence
- **Status**: All 44 statement pairs returned ERROR with `'uniqueID'`
- **Note**: The equivalency tool returned an internal error for all validations, independent of DMS status
- **Per instructions**: All statuses marked as ERROR (not using agent judgment)

---

## Conversion Details

### SQL Server → PostgreSQL Transformations Applied

| SQL Server Construct | PostgreSQL Equivalent |
|---------------------|----------------------|
| IDENTITY(1,1) | GENERATED ALWAYS AS IDENTITY |
| GETDATE() | NOW() |
| SCOPE_IDENTITY() | RETURNING productid |
| NVARCHAR(n) | VARCHAR(n) |
| BIT | BOOLEAN |
| DATETIME | TIMESTAMP |
| DECLARE @var / SET @var | C# variable management or DO blocks |
| BEGIN TRANSACTION / COMMIT | C# transaction management (BeginTransactionAsync) |
| CREATE OR ALTER PROCEDURE | CREATE OR REPLACE FUNCTION |
| CREATE TRIGGER ... AS BEGIN | CREATE FUNCTION + CREATE TRIGGER |
| SYSTEM_USER | current_user |
| GO | Removed (not applicable in PostgreSQL) |
| IF NOT EXISTS (sys.objects) | DROP IF EXISTS / CREATE IF NOT EXISTS |
| IF EXISTS (sys.objects) DROP | DROP ... IF EXISTS |
| [dbo].[TableName] | tablename (lowercase, no schema prefix) |
| [ColumnName] | columnname (lowercase, no brackets) |
| StockQuantity / AvgStock | stockquantity::numeric / avgstock (explicit numeric cast) |
| DEFAULT 1 (for BIT) | DEFAULT TRUE |
| DEFAULT 0 (for BIT) | DEFAULT FALSE |
| EXEC sp_name | PERFORM sp_name() |
| SELECT TOP 1 | SELECT ... LIMIT 1 |

### Package Dependencies Updated

| Original | Replacement | Version |
|----------|-------------|---------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 | 8.0.6 |

### ADO.NET Class Replacements

| SQL Server Class | Npgsql Class | Occurrences |
|-----------------|--------------|-------------|
| SqlConnection | NpgsqlConnection | 3 |
| SqlCommand | NpgsqlCommand | 15 |
| SqlDataReader | NpgsqlDataReader | 1 |
| SqlTransaction | NpgsqlTransaction | 15 |

### Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server= | localhost | Host=localhost |
| Port | (default 1433) | Port=5432 |
| Database= | ProductManagement | Database=ProductManagement |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets | true | Removed (N/A) |
| TrustServerCertificate | True | Removed |

---

## Complete SQL Statement Catalog

### ProductRepository.cs (7 statements)

| ID | Statement | Type | Equivalency Status |
|----|-----------|------|-------------------|
| 1 | GetAllProductsAsync | SELECT with CTE, Window Functions | ERROR |
| 2 | GetProductByIdAsync | SELECT with CTE, LAG | ERROR |
| 3 | InsertProductAsync | Transaction block with INSERT, SCOPE_IDENTITY | ERROR |
| 4 | UpdateProductAsync | Transaction block with UPDATE | ERROR |
| 5 | DeleteProductAsync | Transaction block with DELETE | ERROR |
| 6 | GetProductsByPriceRangeAsync | SELECT with CTE, RANK | ERROR |
| 7 | GetLowStockProductsAsync | SELECT with CTE, AVG/MIN/MAX | ERROR |

### Scripts/01_InitialSetup.sql (8 statements)

| ID | Statement | Type | Equivalency Status |
|----|-----------|------|-------------------|
| S1 | Create Database | DDL - CREATE DATABASE | ERROR |
| S2 | Create Products Table | DDL - CREATE TABLE | ERROR |
| S3 | sp_GetAllProducts | DDL - CREATE PROCEDURE | ERROR |
| S4 | sp_GetProductById | DDL - CREATE PROCEDURE | ERROR |
| S5 | sp_InsertProduct | DDL - CREATE PROCEDURE | ERROR |
| S6 | sp_UpdateProduct | DDL - CREATE PROCEDURE | ERROR |
| S7 | sp_DeleteProduct | DDL - CREATE PROCEDURE | ERROR |
| S8 | Insert Sample Data | DML - EXEC stored procs | ERROR |

### Database/Scripts/01_InitialSetup.sql (29 statements)

| ID | Statement | Type | Equivalency Status |
|----|-----------|------|-------------------|
| D1 | Create Database | DDL - CREATE DATABASE | ERROR |
| D2 | Drop Trigger | DDL - DROP TRIGGER | ERROR |
| D3 | Drop ProductHistory Table | DDL - DROP TABLE | ERROR |
| D4 | Drop Products Table | DDL - DROP TABLE | ERROR |
| D5 | Drop Categories Table | DDL - DROP TABLE | ERROR |
| D6 | Drop Suppliers Table | DDL - DROP TABLE | ERROR |
| D7 | Drop ProductStats Table | DDL - DROP TABLE | ERROR |
| D8 | Create Categories Table | DDL - CREATE TABLE | ERROR |
| D9 | Add FK Categories | DDL - ALTER TABLE | ERROR |
| D10 | Create Suppliers Table | DDL - CREATE TABLE | ERROR |
| D11 | Create Products Table | DDL - CREATE TABLE | ERROR |
| D12 | Create ProductHistory Table | DDL - CREATE TABLE | ERROR |
| D13 | Create ProductStats Table | DDL - CREATE TABLE | ERROR |
| D14 | Create Index CategoryId | DDL - CREATE INDEX | ERROR |
| D15 | Create Index SupplierId | DDL - CREATE INDEX | ERROR |
| D16 | Create Unique Index SKU | DDL - CREATE UNIQUE INDEX | ERROR |
| D17 | Create Index ProductHistoryProductId | DDL - CREATE INDEX | ERROR |
| D18 | Create Index ProductHistoryActionDate | DDL - CREATE INDEX | ERROR |
| D19 | Insert Sample Categories | DML - INSERT | ERROR |
| D20 | Insert Sample Suppliers | DML - INSERT | ERROR |
| D21 | Insert Sample Products | DML - INSERT | ERROR |
| D22 | Insert Initial Stats | DML - INSERT | ERROR |
| D23 | Update Initial Statistics | DML - UPDATE | ERROR |
| D24 | Create Trigger | DDL - CREATE TRIGGER | ERROR |
| D25 | sp_GetAllProducts | DDL - CREATE PROCEDURE | ERROR |
| D26 | sp_GetProductById | DDL - CREATE PROCEDURE | ERROR |
| D27 | sp_InsertProduct | DDL - CREATE PROCEDURE | ERROR |
| D28 | sp_UpdateProduct | DDL - CREATE PROCEDURE | ERROR |
| D29 | sp_DeleteProduct | DDL - CREATE PROCEDURE | ERROR |

---

## Files Modified

1. **DataAccess/ProductRepository.cs** - SQL statements converted, ADO.NET classes replaced
2. **AdoCore.csproj** - Package reference updated
3. **appsettings.json** - Connection strings updated
4. **Scripts/01_InitialSetup.sql** - Converted to PostgreSQL syntax
5. **Database/Scripts/01_InitialSetup.sql** - Converted to PostgreSQL syntax

## Artifacts Generated

1. **extracted_statements.sql** - Complete catalog of all 44 original SQL statements
2. **converted_statements.sql** - Complete catalog of all 44 PostgreSQL-converted statements
3. **sql_equivalency_validation_report.json** - Comprehensive equivalency report (44 statements)
4. **dms_failure_summary.md** - Detailed DMS failure documentation
5. **migration_report.md** - This report

---

## Issues and Manual Interventions

### 1. DMS Tool Unavailability
- **Issue**: DMS statement conversion tool failed for all 44 statements
- **Resolution**: Manual conversion applied using DMS schema_mapping_tool output for accurate schema mapping
- **Impact**: All conversions required manual intervention

### 2. SQL Equivalency Tool Errors
- **Issue**: All 44 equivalency validations returned ERROR with internal error "'uniqueID'"
- **Resolution**: Marked all as ERROR per instructions; manual review recommended
- **Impact**: No automated equivalency validation could be performed

### 3. Transaction Block Restructuring (Statements 3, 4, 5)
- **Issue**: SQL Server DECLARE/@variable/SCOPE_IDENTITY() pattern cannot be directly translated to PostgreSQL within single SQL strings
- **Resolution**: Restructured to use separate C# commands within ADO.NET managed transactions
- **Impact**: Code structure changed from single SQL string to multiple commands; functionality preserved

### 4. Integer Division (Statement 7)
- **Issue**: PostgreSQL performs integer division by default, losing decimal precision
- **Resolution**: Added `::numeric` cast for proper decimal results in ROUND calculations
- **Impact**: Minor syntax addition to maintain calculation accuracy

### 5. Stored Procedure to Function Conversion
- **Issue**: PostgreSQL does not have the same stored procedure model as SQL Server
- **Resolution**: Converted all CREATE OR ALTER PROCEDURE statements to CREATE OR REPLACE FUNCTION with appropriate RETURNS TABLE or RETURNS type definitions
- **Impact**: Functional equivalent achieved through plpgsql functions

### 6. Trigger Conversion
- **Issue**: SQL Server trigger model (inserted/deleted pseudo-tables) differs from PostgreSQL (NEW/OLD records with TG_OP)
- **Resolution**: Created trigger function + trigger definition following PostgreSQL FOR EACH ROW pattern
- **Impact**: Trigger fires per-row instead of per-statement; functionally equivalent for this use case

---

## Recommendations for Manual Review

1. **Verify all 44 SQL statements** execute correctly against the target PostgreSQL database
2. **Test transaction atomicity** for Insert, Update, and Delete operations
3. **Validate window functions** (LAG, RANK, PERCENT_RANK, AVG OVER()) work identically
4. **Test the trigger** (trg_products_history) fires correctly on INSERT, UPDATE, DELETE
5. **Verify stored functions** (sp_getallproducts, sp_getproductbyid, etc.) return expected results
6. **Run integration tests** with the PostgreSQL database
7. **Review connection string** credentials for production deployment (currently using placeholder values)
8. **Re-run SQL equivalency validation** when the tool's 'uniqueID' error is resolved

---

## Build Verification

```
Build succeeded.
    0 Warning(s) (nullable reference warnings - pre-existing)
    0 Error(s)
```

The application compiles successfully with all PostgreSQL-related changes applied.
