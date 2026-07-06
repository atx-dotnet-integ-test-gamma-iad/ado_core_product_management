# SQL Server to PostgreSQL Migration Report

## Migration Summary
- **Source Database**: SQL Server (ProductManagement)
- **Target Database**: PostgreSQL (productmanagement)
- **Application**: AdoCore (.NET 9.0 Console Application)
- **Migration Method**: Manual conversion (DMS tool unavailable)

## DMS Tool Status
- **Status**: FAILED for all 7 statements
- **Error**: "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}"
- **Fallback**: Manual conversion with lowercase schema mapping (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)

## SQL Equivalency Tool Status
- **Status**: ERROR for all 7 statement pairs
- **Error**: "'uniqueID'" (tool-side error)
- **Note**: Equivalency could not be determined programmatically; all pairs marked as ERROR per transformation instructions

## Statements Processed

| # | Method | Type | Key Conversions |
|---|--------|------|-----------------|
| 1 | GetAllProductsAsync | SELECT with CTE + Window Functions | Lowercase schema objects |
| 2 | GetProductByIdAsync | SELECT with CTE + LAG | Lowercase schema objects |
| 3 | InsertProductAsync | Transaction + INSERT + SCOPE_IDENTITY | Writeable CTE with RETURNING, GETDATE→NOW() |
| 4 | UpdateProductAsync | Transaction + UPDATE | Writeable CTE for variable replacement, GETDATE→NOW() |
| 5 | DeleteProductAsync | Transaction + DELETE | Writeable CTE for variable replacement, GETDATE→NOW() |
| 6 | GetProductsByPriceRangeAsync | SELECT with CTE + RANK/PERCENT_RANK | Lowercase schema objects |
| 7 | GetLowStockProductsAsync | SELECT with CTE + AVG/MIN/MAX | Lowercase schema objects, ::numeric cast |

## T-SQL to PostgreSQL Conversion Rules Applied

| T-SQL Feature | PostgreSQL Equivalent |
|---------------|---------------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` (via writeable CTE) |
| `GETDATE()` | `NOW()` |
| `DECLARE @var TYPE; SET @var = ...` | Writeable CTE with subquery |
| `BEGIN TRANSACTION / COMMIT` | Single-statement CTE (implicit transaction) |
| `IDENTITY(1,1)` | `SERIAL` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `DATETIME` | `TIMESTAMP` |
| `INT IDENTITY` | `SERIAL` |
| Mixed-case schema objects | Lowercase schema objects |

## Static Code Changes

| File | Change |
|------|--------|
| `AdoCore.csproj` | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.3` |
| `DataAccess/ProductRepository.cs` | `using Microsoft.Data.SqlClient` → `using Npgsql` |
| `DataAccess/ProductRepository.cs` | `SqlConnection` → `NpgsqlConnection` |
| `DataAccess/ProductRepository.cs` | `SqlCommand` → `NpgsqlCommand` |
| `DataAccess/ProductRepository.cs` | `SqlDataReader` → `NpgsqlDataReader` |
| `appsettings.json` | SQL Server connection string → PostgreSQL connection string |
| `Scripts/01_InitialSetup.sql` | T-SQL DDL → PostgreSQL DDL |
| `Database/Scripts/01_InitialSetup.sql` | T-SQL DDL → PostgreSQL DDL |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Auth | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| Options | `MultipleActiveResultSets=true;TrustServerCertificate=True` | (removed - not applicable) |

## Final Statistics
- Total SQL statements processed: 7
- DMS successful conversions: 0
- DMS failed conversions: 7
- Manual conversions: 7
- Equivalency validated (EQUIVALENT): 0
- Equivalency validated (NOT_EQUIVALENT): 0
- Equivalency validation errors: 7
