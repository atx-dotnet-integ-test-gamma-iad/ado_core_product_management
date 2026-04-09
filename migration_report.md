# Migration Report: Microsoft SQL Server to PostgreSQL

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-04-09 |
| **Source Database** | Microsoft SQL Server 2019 (ProductManagement) |
| **Target Database** | PostgreSQL 13 (postgres) |
| **Target Schema** | productmanagement_dbo |
| **Source Framework** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Framework** | Npgsql 8.0.1 |

---

## SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS MCP Tool** | 0 |
| **Requiring Manual Intervention (DMS Failure)** | 7 |
| **Validated as Equivalent (SQL Equivalency Tool)** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **With Equivalency Validation Errors** | 7 |

---

## DMS Tool Status

The DMS MCP Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) was **unavailable** for statement conversion. All 5 retry attempts failed with the same error:

- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

The DMS Schema Mapping Tool (`dms-mcp___schema_mapping_tool`) was **successful** and provided target schema mappings that were used to guide manual conversion.

---

## SQL Equivalency Tool Status

The SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`) returned **ERROR** for all 7 statement pairs with error: `'uniqueID'`. All equivalency statuses are marked as ERROR per tool output (no agent judgment used).

---

## Detailed Statement Conversion Report

### Statement 1: GetAllProductsAsync
- **Source**: CTE with window functions (AVG OVER, COUNT OVER), CASE expressions, ROUND, INNER JOIN
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: 
  - All table/column names lowercased (Products→products, ProductId→productid, etc.)
  - CTE name changed from ProductStats to productstats_cte (avoid conflict with table name)
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)
- **Manual Review Required**: Yes

### Statement 2: GetProductByIdAsync
- **Source**: CTE with LAG window function, CASE, ROUND, LEFT JOIN, parameterized @ProductId
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - All table/column names lowercased
  - CTE name changed from ProductHistory to producthistory_cte (avoid conflict with table name)
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)
- **Manual Review Required**: Yes

### Statement 3: InsertProductAsync
- **Source**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), UPDATE, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - SCOPE_IDENTITY() → INSERT ... RETURNING productid (via writable CTE)
  - GETDATE() → NOW()
  - BEGIN TRANSACTION/COMMIT → Writable CTE approach for atomicity
  - DECLARE @NewProductId → CTE-based value passing
  - All table/column names lowercased
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)
- **Manual Review Required**: Yes

### Statement 4: UpdateProductAsync
- **Source**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - GETDATE() → NOW()
  - DECLARE + SELECT INTO variables → CTE-based old value capture
  - BEGIN TRANSACTION/COMMIT → Writable CTE approach
  - All table/column names lowercased
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)
- **Manual Review Required**: Yes

### Statement 5: DeleteProductAsync
- **Source**: Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - GETDATE() → NOW()
  - DECLARE + SELECT INTO variables → CTE-based old value capture
  - BEGIN TRANSACTION/COMMIT → Writable CTE approach
  - CASE expression preserved as-is (PostgreSQL compatible)
  - All table/column names lowercased
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)
- **Manual Review Required**: Yes

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: CTE with RANK() and PERCENT_RANK() window functions, BETWEEN, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - All table/column names lowercased
  - SQL syntax is largely compatible (RANK, PERCENT_RANK, BETWEEN supported in PostgreSQL)
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)
- **Manual Review Required**: Yes

### Statement 7: GetLowStockProductsAsync
- **Source**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - All table/column names lowercased
  - Added CAST(stockquantity AS NUMERIC) for integer division to ensure decimal result
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)
- **Manual Review Required**: Yes

---

## File Changes Summary

### Modified Files

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced using directive, ADO.NET classes, all 7 SQL statements, column name references in MapProductFromReader |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.1 |
| `appsettings.json` | Connection strings converted from SQL Server to PostgreSQL format |

### New Files Created

| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `dms_conversion_summary.md` | DMS failure documentation and conversion details |
| `migration_report.md` | This report |

### Unchanged Files (No SQL Server References)

| File | Status |
|------|--------|
| `Program.cs` | No changes needed - no SQL Server references |
| `Business/ProductService.cs` | No changes needed - business logic only |
| `CLI/CommandLineInterface.cs` | No changes needed - CLI logic only |
| `CLI/InteractiveMenu.cs` | No changes needed - menu logic only |
| `Models/Product.cs` | No changes needed - POCO model |
| `Database/Scripts/01_InitialSetup.sql` | **NOTE**: This SQL Server setup script was NOT modified. It contains SQL Server-specific DDL and would require separate migration for PostgreSQL database setup. |

---

## ADO.NET Class Replacements

| Original (SQL Server) | Replacement (PostgreSQL) |
|------------------------|--------------------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

---

## Connection String Changes

### DevConnection
- **Before**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After**: `Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=postgres`

### ProdConnection
- **Before**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After**: `Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=postgres`

### Parameters Removed (Not Applicable to PostgreSQL)
- `MultipleActiveResultSets=true`
- `TrustServerCertificate=True`
- `Trusted_Connection=True`

### Parameters Added
- `Port=5432`
- `Username=postgres`
- `Password=postgres`

---

## Schema Mapping (from DMS Schema Mapping Tool)

| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| `dbo.Products` | `productmanagement_dbo.products` |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` |

### Column Name Mappings (All Lowercase)
- `ProductId` → `productid`
- `Name` → `name`
- `Description` → `description`
- `Price` → `price`
- `StockQuantity` → `stockquantity`
- `CreatedDate` → `createddate`
- `ModifiedDate` → `modifieddate`
- `HistoryId` → `historyid`
- `Action` → `action`
- `OldPrice` → `oldprice`
- `NewPrice` → `newprice`
- `OldStock` → `oldstock`
- `NewStock` → `newstock`
- `ActionDate` → `actiondate`
- `StatId` → `statid`
- `TotalProducts` → `totalproducts`
- `AveragePrice` → `averageprice`
- `LastUpdated` → `lastupdated`

---

## SQL Function Conversions

| SQL Server Function | PostgreSQL Equivalent |
|---------------------|----------------------|
| `SCOPE_IDENTITY()` | `INSERT ... RETURNING productid` (via CTE) |
| `GETDATE()` | `NOW()` |
| `BEGIN TRANSACTION / COMMIT` | Writable CTE (for multi-table operations) |
| `DECLARE @var / SET @var` | CTE-based value passing |

---

## Build Status

**Final Build**: ✅ **SUCCESS** (0 Errors, 12 Warnings)

Warnings are pre-existing nullable reference warnings unrelated to the migration:
- CS8618: Non-nullable property/field warnings
- CS8600/CS8601/CS8603: Null reference warnings
- CS8625: Null literal conversion warning
- NU1903: Npgsql 8.0.1 known vulnerability warning (no patched 8.0.x available)

---

## Verification Checklist

- [x] All SQL Server specific packages replaced with PostgreSQL equivalents
- [x] All SqlConnection/SqlCommand/SqlDataReader references replaced with Npgsql equivalents
- [x] All 7 SQL statements processed through DMS MCP tool (all failed, documented)
- [x] All 7 SQL statements manually converted with lowercase schema mapping
- [x] All 7 SQL statement pairs validated through SQL Equivalency tool (all returned ERROR)
- [x] Comprehensive sql_equivalency_validation_report.json generated
- [x] Comprehensive extracted_statements.sql catalog generated
- [x] Comprehensive converted_statements.sql catalog generated
- [x] All connection strings updated to PostgreSQL format
- [x] Application compiles successfully
- [x] No remaining Microsoft.Data.SqlClient/System.Data.SqlClient references
- [x] Database/Scripts/01_InitialSetup.sql noted (requires separate migration)

---

## Recommendations for Manual Review

1. **All 7 SQL statements** should be manually reviewed since both the DMS conversion tool and SQL Equivalency tool experienced errors
2. **Transaction-based statements** (Insert, Update, Delete) were restructured from DECLARE/variable patterns to writable CTEs - verify correct behavior
3. **Database/Scripts/01_InitialSetup.sql** should be separately migrated for PostgreSQL database setup
4. **Connection string credentials** in appsettings.json should be updated with actual PostgreSQL credentials for the target environment
5. **Npgsql 8.0.1** has a known vulnerability (NU1903) - consider upgrading when a patched version becomes available
