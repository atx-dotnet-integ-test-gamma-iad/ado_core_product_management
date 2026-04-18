# Migration Report: Microsoft SQL Server to PostgreSQL

## Overview
- **Application**: AdoCore (.NET 9.0 ADO.NET Application)
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Migration Date**: 2026-04-17
- **Migration Tool**: AWS DMS MCP Statement Conversion Tool (attempted) + Manual Conversion

---

## 1. SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Manually converted after DMS failure | 7 |
| Validated as EQUIVALENT | 0 |
| Validated as NOT_EQUIVALENT | 0 |
| Equivalency validation ERRORS | 7 |

### DMS Tool Status
- **DMS Statement Conversion Tool**: FAILED for all 7 statements
  - Error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
  - All 7 statements were attempted through DMS before manual conversion
- **DMS Schema Mapping Tool**: SUCCESSFUL
  - Successfully retrieved schema mappings for all 3 tables (Products, ProductHistory, ProductStats)
  - Schema mappings used to guide manual conversion (lowercase naming, type mappings)

### SQL Equivalency Tool Status
- **Equivalency Validation**: All 7 statement pairs returned ERROR
  - Error: `'uniqueID'`
  - Per transformation definition: all marked as ERROR status (not agent-judged)

---

## 2. SQL Statements Detail

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**: All identifiers lowercased per DMS schema mapping

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG Window Function, LEFT JOIN, CASE, ROUND
- **Parameters**: @ProductId
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**: All identifiers lowercased per DMS schema mapping

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), INSERT, UPDATE, GETDATE()
- **Parameters**: @Name, @Description, @Price, @StockQuantity
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `RETURNING productid` clause
  - `GETDATE()` → `clock_timestamp()`
  - Single SQL batch → 3 separate SQL commands with C# transaction management
  - `DECLARE @NewProductId` → C# `int newProductId` variable
  - All identifiers lowercased

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO vars, UPDATE, INSERT, UPDATE, GETDATE()
- **Parameters**: @ProductId, @Name, @Description, @Price, @StockQuantity
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**:
  - `DECLARE @OldPrice / @OldStock` → C# `decimal oldPrice / int oldStock` variables
  - `SELECT @OldPrice = Price` → `SELECT price, stockquantity` with C# reader
  - `GETDATE()` → `clock_timestamp()`
  - Single SQL batch → 4 separate SQL commands with C# transaction management
  - All identifiers lowercased

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO vars, INSERT, DELETE, UPDATE with CASE, GETDATE()
- **Parameters**: @ProductId
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**:
  - Same variable handling as UpdateProductAsync
  - `GETDATE()` → `clock_timestamp()`
  - Single SQL batch → 4 separate SQL commands with C# transaction management
  - All identifiers lowercased

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK(), CASE, BETWEEN
- **Parameters**: @MinPrice, @MaxPrice
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**: All identifiers lowercased per DMS schema mapping

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
- **Parameters**: @Threshold
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**:
  - All identifiers lowercased
  - Added `::numeric` cast for integer division in ROUND function

---

## 3. File Changes Summary

### Modified Files
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL; All SqlClient classes replaced with Npgsql equivalents; Transaction handling restructured for statements 3-5; Column name references in MapProductFromReader lowercased |
| `AdoCore.csproj` | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6` |
| `appsettings.json` | Connection strings updated from SQL Server format to PostgreSQL format |

### New Artifact Files
| File | Description |
|------|-------------|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency report for all 7 statement pairs |
| `dms_conversion_log.txt` | Detailed log of all DMS conversion attempts and results |
| `migration_report.md` | This report |

### Unchanged Files
- `Models/Product.cs` - No SQL Server specific code
- `Business/ProductService.cs` - No SQL Server specific code
- `CLI/InteractiveMenu.cs` - No SQL Server specific code
- `Program.cs` - No SQL Server specific code

---

## 4. Static Code Transformations

### Package References
- **Removed**: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added**: `<PackageReference Include="Npgsql" Version="8.0.6" />`

### Using Directives
- **Removed**: `using Microsoft.Data.SqlClient;`
- **Added**: `using Npgsql;`

### ADO.NET Class Replacements
| Original (SQL Server) | Replacement (PostgreSQL) |
|-----------------------|-------------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlTransaction` | `NpgsqlTransaction` |

### Connection String Transformation
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server name | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| Certificate | `TrustServerCertificate=True` | Removed |

---

## 5. Schema Mapping (from DMS Schema Mapping Tool)

| SQL Server Object | PostgreSQL Object |
|-------------------|-------------------|
| `[dbo].[Products]` | `products` |
| `[dbo].[ProductHistory]` | `producthistory` |
| `[dbo].[ProductStats]` | `productstats` |
| `ProductId` | `productid` |
| `Name` | `name` |
| `Description` | `description` |
| `Price` | `price` |
| `StockQuantity` | `stockquantity` |
| `CreatedDate` | `createddate` |
| `ModifiedDate` | `modifieddate` |
| `GETDATE()` | `clock_timestamp()` |
| `SCOPE_IDENTITY()` | `RETURNING productid` |
| `int IDENTITY(1,1)` | `INTEGER GENERATED ALWAYS AS IDENTITY` |
| `decimal(18,2)` | `NUMERIC(18,2)` |
| `datetime` | `TIMESTAMP WITHOUT TIME ZONE` |
| `nvarchar(N)` | `VARCHAR(N)` |

---

## 6. Build Status
- **Final Build**: ✅ SUCCESS (0 errors)
- **Warnings**: Pre-existing nullable reference warnings (CS8601, CS8618, CS8600, CS8603, CS8625) - not introduced by migration

---

## 7. Items Requiring Manual Review
All 7 SQL statement conversions require manual review because:
1. DMS Statement Conversion Tool failed for all statements (metadata model creation error)
2. SQL Equivalency Tool returned ERROR for all statement pairs ('uniqueID' error)
3. Manual conversions were applied using DMS Schema Mapping output as guidance
4. Transaction-based statements (Insert, Update, Delete) were significantly restructured from single SQL batches to multiple C# commands

**Recommended post-migration testing:**
- Execute each converted SQL statement against a PostgreSQL instance
- Verify transaction atomicity for Insert/Update/Delete operations
- Test edge cases (NULL descriptions, zero stock, division by zero in stats)
- Validate window function results match SQL Server output
