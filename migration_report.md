# AdoCore Migration Report: MS SQL Server → PostgreSQL

## Migration Summary

| Metric | Value |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS** | 0 |
| **Requiring Manual Intervention** | 7 |
| **Validated as Equivalent** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |

### DMS Conversion Status
The DMS statement_conversion_tool was attempted for all 7 SQL statements but consistently failed with "Metadata model creation/conversion did not complete after N attempts" timeout errors. The DMS schema_mapping_tool was successful and provided the target PostgreSQL schema mappings used for manual conversion.

### SQL Equivalency Validation Status
The sql-equivalency___validate_sql_equivalence tool was called for all 7 statement pairs but consistently returned ERROR with `'uniqueID'` error (service-side issue). All equivalency statuses are marked as ERROR per the tool output, not agent judgment.

---

## Files Modified

### 1. `AdoCore.csproj` - Package Reference Update
- **Removed:** `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added:** `<PackageReference Include="Npgsql" Version="8.0.6" />`
- All other package references preserved unchanged

### 2. `DataAccess/ProductRepository.cs` - SQL Statements & ADO.NET Classes
#### SQL Statement Conversions (7 statements):

| # | Method | Key Changes |
|---|--------|-------------|
| 1 | `GetAllProductsAsync` | Table/column names lowercased per DMS schema mapping |
| 2 | `GetProductByIdAsync` | Table/column names lowercased, LAG window function preserved |
| 3 | `InsertProductAsync` | `SCOPE_IDENTITY()` → `lastval()`, `GETDATE()` → `clock_timestamp()`, removed `DECLARE`/`BEGIN TRANSACTION` |
| 4 | `UpdateProductAsync` | `DECLARE @var` → CTE approach, `GETDATE()` → `clock_timestamp()` |
| 5 | `DeleteProductAsync` | `DECLARE @var` → CTE approach, `GETDATE()` → `clock_timestamp()`, CASE preserved |
| 6 | `GetProductsByPriceRangeAsync` | Table/column names lowercased, RANK/PERCENT_RANK preserved |
| 7 | `GetLowStockProductsAsync` | Table/column names lowercased, added `CAST(stockquantity AS NUMERIC)` for division |

#### ADO.NET Class Replacements:
| Original | Replacement | Occurrences |
|----------|-------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 (field, method return, constructor) |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

### 3. `appsettings.json` - Connection Strings Updated
| SQL Server Parameter | PostgreSQL Parameter |
|---------------------|---------------------|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=ProductManagement` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | *(removed)* |
| `TrustServerCertificate=True` | *(removed)* |
| *(not present)* | `Port=5432` |

---

## Files Created (Artifacts)

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL statements with source method, file location, and complete SQL text |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements with conversion notes |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency report with all 7 statement pairs, conversion methods, and equivalency tool results |
| `migration_report.md` | This migration report |

---

## Files NOT Modified (No SQL Server-specific code)

| File | Reason |
|------|--------|
| `Program.cs` | No database-specific code |
| `Models/Product.cs` | Pure model class |
| `Business/ProductService.cs` | Business logic only |
| `CLI/CommandLineInterface.cs` | UI layer only |
| `CLI/InteractiveMenu.cs` | UI layer only |
| `Scripts/01_InitialSetup.sql` | DDL script (handled separately by DMS schema migration) |
| `Database/Scripts/01_InitialSetup.sql` | DDL script (handled separately by DMS schema migration) |

---

## Schema Mapping (from DMS schema_mapping_tool)

| Source (SQL Server) | Target (PostgreSQL) |
|--------------------|--------------------|
| `[dbo].[Products]` | `productmanagement_dbo.products` |
| `[dbo].[ProductHistory]` | `productmanagement_dbo.producthistory` |
| `[dbo].[ProductStats]` | `productmanagement_dbo.productstats` |

### Column Mapping (Products table)
| SQL Server | PostgreSQL |
|-----------|-----------|
| `ProductId` (int IDENTITY) | `productid` (INTEGER GENERATED ALWAYS AS IDENTITY) |
| `Name` (nvarchar(100)) | `name` (VARCHAR(100)) |
| `Description` (nvarchar(500)) | `description` (VARCHAR(500)) |
| `Price` (decimal(18,2)) | `price` (NUMERIC(18,2)) |
| `StockQuantity` (int) | `stockquantity` (INTEGER) |
| `CreatedDate` (datetime) | `createddate` (TIMESTAMP WITHOUT TIME ZONE) |
| `ModifiedDate` (datetime) | `modifieddate` (TIMESTAMP WITHOUT TIME ZONE) |

### Function Mapping
| SQL Server | PostgreSQL |
|-----------|-----------|
| `GETDATE()` | `clock_timestamp()` |
| `SCOPE_IDENTITY()` | `lastval()` |
| `DECLARE @var TYPE` | CTE approach / DO $$ block |
| `BEGIN TRANSACTION` / `COMMIT` | ADO.NET transaction handling |

---

## Build Verification

**Final Build Status:** ✅ SUCCESS
- **Errors:** 0
- **Warnings:** 10 (all pre-existing nullable reference type warnings, not related to migration)
- **Build Command:** `dotnet build sourceCode/AdoCore.sln`

---

## Detailed Statement Conversion Log

### Statement 1: GetAllProductsAsync
- **DMS Attempt:** Failed - "Metadata model creation did not complete after 15 attempts"
- **Manual Conversion:** Applied lowercase schema object names
- **Equivalency Check:** ERROR ('uniqueID' service error)

### Statement 2: GetProductByIdAsync
- **DMS Attempt:** Failed - "Metadata model creation did not complete after 15 attempts"
- **Manual Conversion:** Applied lowercase schema object names
- **Equivalency Check:** ERROR ('uniqueID' service error)

### Statement 3: InsertProductAsync
- **DMS Attempt:** Failed - "Metadata model creation/conversion timed out"
- **Manual Conversion:** Restructured from DECLARE/@var/BEGIN TRANSACTION to sequential PostgreSQL statements with lastval()
- **Equivalency Check:** ERROR ('uniqueID' service error)

### Statement 4: UpdateProductAsync
- **DMS Attempt:** Failed - "Metadata model creation/conversion timed out"
- **Manual Conversion:** Replaced DECLARE/@var with CTE for old values, GETDATE() → clock_timestamp()
- **Equivalency Check:** ERROR ('uniqueID' service error)

### Statement 5: DeleteProductAsync
- **DMS Attempt:** Failed - "Metadata model creation/conversion timed out"
- **Manual Conversion:** Replaced DECLARE/@var with CTE for old values, GETDATE() → clock_timestamp()
- **Equivalency Check:** ERROR ('uniqueID' service error)

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Attempt:** Failed - "Metadata model creation/conversion timed out"
- **Manual Conversion:** Applied lowercase schema object names
- **Equivalency Check:** ERROR ('uniqueID' service error)

### Statement 7: GetLowStockProductsAsync
- **DMS Attempt:** Failed - "Metadata model creation/conversion timed out"
- **Manual Conversion:** Applied lowercase schema object names, added CAST for integer division
- **Equivalency Check:** ERROR ('uniqueID' service error)
