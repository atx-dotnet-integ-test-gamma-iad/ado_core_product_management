# SQL Server to PostgreSQL Migration Report

## Migration Summary
- **Source Database:** SQL Server 2019
- **Target Database:** PostgreSQL 13
- **Application:** AdoCore (.NET 9.0 Console Application)
- **DMS Project ARN:** arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

## DMS Tool Status
**Status: FAILED** - All 7 SQL statements were submitted to the DMS MCP tool but consistently failed with the error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

All statements were manually converted applying lowercase schema object naming convention for PostgreSQL compatibility per the transformation instructions.

## SQL Equivalency Tool Status
**Status: FAILED** - All 7 statement pairs were submitted to the SQL Equivalency MCP tool but consistently returned:
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

All equivalency results are marked as ERROR per the transformation instructions.

## SQL Statements Processed

| # | Method | Source Location | Statement Type | DMS Status | Equivalency Status |
|---|--------|----------------|----------------|------------|-------------------|
| 1 | GetAllProductsAsync | DataAccess/ProductRepository.cs | SELECT with CTE + Window Functions | FAILED | ERROR |
| 2 | GetProductByIdAsync | DataAccess/ProductRepository.cs | SELECT with CTE + LAG Window Function | FAILED | ERROR |
| 3 | InsertProductAsync | DataAccess/ProductRepository.cs | Transaction (INSERT + SCOPE_IDENTITY + UPDATE) | FAILED | ERROR |
| 4 | UpdateProductAsync | DataAccess/ProductRepository.cs | Transaction (SELECT INTO vars + UPDATE + INSERT + UPDATE) | FAILED | ERROR |
| 5 | DeleteProductAsync | DataAccess/ProductRepository.cs | Transaction (SELECT INTO vars + INSERT + DELETE + UPDATE) | FAILED | ERROR |
| 6 | GetProductsByPriceRangeAsync | DataAccess/ProductRepository.cs | SELECT with CTE + RANK/PERCENT_RANK | FAILED | ERROR |
| 7 | GetLowStockProductsAsync | DataAccess/ProductRepository.cs | SELECT with CTE + AVG/MIN/MAX OVER | FAILED | ERROR |

## Key Conversions Applied

### SQL Syntax Changes
| MS SQL Server | PostgreSQL |
|---------------|-----------|
| `SCOPE_IDENTITY()` | `RETURNING productid` clause |
| `GETDATE()` | `NOW()` |
| `DECLARE @var TYPE` | Application-level variables or `DO $$ DECLARE ... BEGIN ... END $$` |
| `BEGIN TRANSACTION / COMMIT` | `NpgsqlTransaction` in application code |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `NVARCHAR(MAX)` | `TEXT` |
| `BIT` | `BOOLEAN` |
| `IDENTITY(1,1)` | `SERIAL` |
| `DATETIME` | `TIMESTAMP` |
| `SYSTEM_USER` | `current_user` |
| `SET NOCOUNT ON` | Not needed in PostgreSQL |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| Integer division (implicit) | `::numeric` cast for decimal results |

### Schema Object Name Changes
All schema object names converted to lowercase for PostgreSQL:
- `Products` → `products`
- `ProductId` → `productid`
- `ProductHistory` → `producthistory`
- `ProductStats` → `productstats`
- `Categories` → `categories`
- `Suppliers` → `suppliers`
- All column names converted to lowercase

### Package/Library Changes
| Original | Replacement |
|----------|-------------|
| `Microsoft.Data.SqlClient` 5.1.4 | `Npgsql` 8.0.1 |

### Class/Type Mapping
| SQL Server (ADO.NET) | PostgreSQL (Npgsql) |
|---------------------|---------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |

### Connection String Changes
| Original (SQL Server) | Converted (PostgreSQL) |
|----------------------|----------------------|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=ProductManagement` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | Removed (not applicable) |
| `TrustServerCertificate=True` | Removed (not applicable) |

### Stored Procedure Conversions
SQL Server stored procedures converted to PostgreSQL functions:
- `sp_GetAllProducts` → `sp_getallproducts()` (RETURNS TABLE)
- `sp_GetProductById` → `sp_getproductbyid(INT)` (RETURNS TABLE)
- `sp_InsertProduct` → `sp_insertproduct(...)` (RETURNS INT)
- `sp_UpdateProduct` → `sp_updateproduct(...)` (RETURNS VOID)
- `sp_DeleteProduct` → `sp_deleteproduct(INT)` (RETURNS VOID)

### Trigger Conversion
- SQL Server `AFTER INSERT, UPDATE, DELETE` trigger → PostgreSQL trigger function with `TG_OP` check
- `inserted`/`deleted` pseudo-tables → `NEW`/`OLD` record references

## Files Modified
1. `sourceCode/DataAccess/ProductRepository.cs` - Main database access code
2. `sourceCode/AdoCore.csproj` - Package references
3. `sourceCode/appsettings.json` - Connection strings
4. `sourceCode/Database/Scripts/01_InitialSetup.sql` - Database setup script
5. `sourceCode/Scripts/01_InitialSetup.sql` - Simple database setup script

## Files Created
1. `sourceCode/extracted_statements.sql` - Catalog of all original SQL statements
2. `sourceCode/converted_statements.sql` - Catalog of all converted PostgreSQL statements
3. `sourceCode/sql_equivalency_validation_report.json` - Comprehensive equivalency validation report
4. `sourceCode/migration_report.md` - This migration report

## Statistics
- **Total SQL statements processed:** 7
- **Statements successfully converted by DMS:** 0
- **Statements requiring manual conversion:** 7
- **Statements validated as equivalent:** 0
- **Statements validated as non-equivalent:** 0
- **Statements with equivalency validation errors:** 7
