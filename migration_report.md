# SQL Server to PostgreSQL Migration Report

## Migration Summary
- **Application**: AdoCore (.NET 9.0 Console Application)
- **Source Database**: SQL Server 2019 (ProductManagement)
- **Target Database**: PostgreSQL 13
- **Migration Method**: Manual conversion with lowercase schema (DMS tool unavailable)

## DMS Tool Status
- **Status**: FAILED for all 7 statements
- **Error**: "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}"
- **Fallback**: Manual conversion applying lowercase schema object names per transformation rules

## SQL Equivalency Tool Status
- **Status**: ERROR for all 7 statement pairs
- **Error**: "'uniqueID'" - tool returned internal error
- **Note**: Errors are from the tool itself, not from conversion quality

## Statement Processing Summary
| # | Method | Source | Statement Type | DMS Status | Equivalency Status |
|---|--------|--------|---------------|------------|-------------------|
| 1 | GetAllProductsAsync | ProductRepository.cs | SELECT with CTE + Window Functions | FAILED | ERROR |
| 2 | GetProductByIdAsync | ProductRepository.cs | SELECT with CTE + LAG | FAILED | ERROR |
| 3 | InsertProductAsync | ProductRepository.cs | Transaction (INSERT + SCOPE_IDENTITY) | FAILED | ERROR |
| 4 | UpdateProductAsync | ProductRepository.cs | Transaction (SELECT + UPDATE + INSERT) | FAILED | ERROR |
| 5 | DeleteProductAsync | ProductRepository.cs | Transaction (SELECT + INSERT + DELETE + UPDATE) | FAILED | ERROR |
| 6 | GetProductsByPriceRangeAsync | ProductRepository.cs | SELECT with CTE + RANK/PERCENT_RANK | FAILED | ERROR |
| 7 | GetLowStockProductsAsync | ProductRepository.cs | SELECT with CTE + AVG/MIN/MAX | FAILED | ERROR |

## Conversion Details

### SQL Server → PostgreSQL Mappings Applied:
1. **Schema Objects**: All converted to lowercase (PostgreSQL convention)
2. **SCOPE_IDENTITY()** → `RETURNING productid` clause
3. **GETDATE()** → `NOW()`
4. **DECLARE @var / SET @var** → Application-level variables (C# code)
5. **BEGIN TRANSACTION / COMMIT** → Application-level transaction management via `NpgsqlTransaction`
6. **Integer division** → Added `::numeric` cast for proper decimal division
7. **IDENTITY(1,1)** → `SERIAL` type
8. **NVARCHAR** → `VARCHAR`
9. **DATETIME** → `TIMESTAMP`
10. **BIT** → `BOOLEAN`
11. **Triggers** → PostgreSQL trigger function + trigger syntax
12. **Stored Procedures** → PostgreSQL functions (`CREATE OR REPLACE FUNCTION`)

### Package Changes:
- **Removed**: `Microsoft.Data.SqlClient` v5.1.4
- **Added**: `Npgsql` v8.0.3

### ADO.NET Type Replacements:
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`
- `using Microsoft.Data.SqlClient` → `using Npgsql`

### Connection String Changes:
- `Server=localhost` → `Host=localhost`
- `Database=ProductManagement` → `Database=productmanagement`
- `Trusted_Connection=True` → `Username=postgres;Password=postgres`
- Removed: `MultipleActiveResultSets=true` (not applicable to PostgreSQL)
- Removed: `TrustServerCertificate=True`

## Files Modified:
1. `sourceCode/DataAccess/ProductRepository.cs` - Complete rewrite for Npgsql
2. `sourceCode/AdoCore.csproj` - Package reference change
3. `sourceCode/appsettings.json` - Connection string update
4. `sourceCode/Database/Scripts/01_InitialSetup.sql` - Full PostgreSQL rewrite
5. `sourceCode/Scripts/01_InitialSetup.sql` - Full PostgreSQL rewrite

## Files Created:
1. `sourceCode/extracted_statements.sql` - Original SQL Server statements catalog
2. `sourceCode/converted_statements.sql` - Converted PostgreSQL statements catalog
3. `sourceCode/sql_equivalency_validation_report.json` - Equivalency validation report

## Statistics:
- Total SQL statements processed: 7
- Statements successfully converted by DMS: 0
- Statements manually converted (DMS failure): 7
- Statements validated as equivalent: 0
- Statements validated as non-equivalent: 0
- Statements with equivalency validation errors: 7
