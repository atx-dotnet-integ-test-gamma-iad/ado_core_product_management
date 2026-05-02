# Migration Report: MS SQL Server to PostgreSQL
## AdoCore Application - .NET ADO Migration

### Summary
- **Application**: AdoCore (.NET 9.0 Console Application)
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Migration Date**: 2026-05-02
- **Total SQL Statements Processed**: 7
- **Total Files Modified**: 3 (ProductRepository.cs, AdoCore.csproj, appsettings.json)

---

### 1. SQL Statement Conversion Results

| # | Method | DMS Status | Manual Conversion | Equivalency Status |
|---|--------|-----------|-------------------|-------------------|
| 1 | GetAllProductsAsync | FAILED | YES (lowercase schema) | ERROR |
| 2 | GetProductByIdAsync | FAILED | YES (lowercase schema) | ERROR |
| 3 | InsertProductAsync | FAILED | YES (restructured with CTE/RETURNING) | ERROR |
| 4 | UpdateProductAsync | FAILED | YES (restructured with CTE) | ERROR |
| 5 | DeleteProductAsync | FAILED | YES (restructured with CTE) | ERROR |
| 6 | GetProductsByPriceRangeAsync | FAILED | YES (lowercase schema) | ERROR |
| 7 | GetLowStockProductsAsync | FAILED | YES (lowercase schema + CAST) | ERROR |

**DMS Tool Error (all 7 statements)**: 
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**SQL Equivalency Tool Error (all 7 statements)**:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

### 2. Key Syntax Transformations Applied

| SQL Server Syntax | PostgreSQL Equivalent | Statements Affected |
|-------------------|----------------------|-------------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` (CTE chain) | Statement 3 |
| `GETDATE()` | `NOW()` | Statements 3, 4, 5 |
| `DECLARE @var TYPE; SET @var = ...` | CTE with `old_values AS (SELECT ...)` | Statements 3, 4, 5 |
| `BEGIN TRANSACTION; ... COMMIT;` | Single CTE statement (atomic) | Statements 3, 4, 5 |
| Table/Column names (PascalCase) | lowercase | All 7 statements |
| `ROUND(int / numeric, 2)` | `ROUND(CAST(int AS NUMERIC) / numeric, 2)` | Statement 7 |

### 3. Schema Object Name Mapping

| SQL Server Name | PostgreSQL Name |
|----------------|----------------|
| `Products` | `products` |
| `ProductHistory` | `producthistory` |
| `ProductStats` | `productstats` |
| `ProductId` | `productid` |
| `Name` | `name` |
| `Description` | `description` |
| `Price` | `price` |
| `StockQuantity` | `stockquantity` |
| `CreatedDate` | `createddate` |
| `ModifiedDate` | `modifieddate` |
| `StatId` | `statid` |
| `TotalProducts` | `totalproducts` |
| `AveragePrice` | `averageprice` |
| `LastUpdated` | `lastupdated` |
| `OldPrice` | `oldprice` |
| `NewPrice` | `newprice` |
| `OldStock` | `oldstock` |
| `NewStock` | `newstock` |
| `ActionDate` | `actiondate` |
| `Action` | `action` |
| `HistoryId` | `historyid` |

### 4. Package Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.6 |

### 5. ADO.NET Class Replacements

| SQL Server Class | Npgsql Class | Occurrences |
|-----------------|--------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

### 6. Connection String Changes

**Before (SQL Server)**:
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

**After (PostgreSQL)**:
```
Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres
```

**Parameter Mapping**:
- `Server=` → `Host=`
- `Database=` → `Database=` (preserved)
- `Trusted_Connection=True` → Removed (replaced with Username/Password)
- `MultipleActiveResultSets=true` → Removed (not applicable to PostgreSQL)
- `TrustServerCertificate=True` → Removed (not applicable to PostgreSQL)

### 7. Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements, imports, ADO.NET classes, column name references |
| `AdoCore.csproj` | Package reference swap |
| `appsettings.json` | Connection string format |

### 8. Artifacts Generated

| Artifact | Description |
|----------|-------------|
| `extracted_statements.sql` | Original 7 MS SQL statements catalog |
| `converted_statements.sql` | Converted 7 PostgreSQL statements catalog |
| `sql_equivalency_validation_report.json` | Equivalency validation results for all 7 pairs |
| `migration_report.md` | This report |

### 9. Build Status

- **Final Build**: SUCCESS (0 errors, warnings are pre-existing nullable reference warnings)
- **Npgsql Version**: 8.0.6 (upgraded from initial 8.0.0 to address GHSA-x9vc-6hfv-hg8c vulnerability)

### 10. Manual Review Recommendations

1. **SQL Equivalency**: All 7 statement pairs returned ERROR from the SQL Equivalency tool. Manual review of converted SQL statements is recommended.
2. **Transaction Semantics**: Statements 3, 4, 5 were restructured from T-SQL transaction blocks to PostgreSQL CTE chains. Verify that the CTE-based approach provides equivalent transactional behavior.
3. **Integer Division**: Statement 7 (GetLowStockProductsAsync) required explicit CAST to NUMERIC for integer division in PostgreSQL.
4. **Database Schema**: Ensure the PostgreSQL database schema uses lowercase table/column names to match the converted SQL statements.
5. **Connection Credentials**: The connection string uses placeholder credentials (postgres/postgres). Update with appropriate production credentials.

### 11. Database Script Notes

The SQL Server setup scripts (`Scripts/01_InitialSetup.sql` and `Database/Scripts/01_InitialSetup.sql`) contain T-SQL specific syntax:
- `IF NOT EXISTS (SELECT * FROM sys.databases ...)`
- `GO` batch separators
- `CREATE OR ALTER PROCEDURE`
- `IDENTITY(1,1)` columns
- Triggers (`CREATE TRIGGER`)
- `EXEC sp_InsertProduct`

These scripts are NOT part of the application code migration but should be separately converted for PostgreSQL database setup using:
- `CREATE TABLE IF NOT EXISTS` 
- `SERIAL` or `GENERATED ALWAYS AS IDENTITY` for auto-increment
- PostgreSQL function syntax instead of stored procedures
- PostgreSQL trigger syntax
