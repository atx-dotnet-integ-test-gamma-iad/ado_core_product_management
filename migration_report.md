# Migration Report: MS SQL Server to PostgreSQL

## Project: AdoCore - Product Management Application
## Date: 2026-04-08
## Migration Type: .NET ADO Application - SQL Server to PostgreSQL

---

## Executive Summary

This report documents the complete migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating database driver dependencies, replacing ADO.NET classes, and updating connection string configurations.

---

## SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS MCP Tool** | 0 |
| **Requiring Manual Intervention (DMS Failure)** | 7 |
| **Validated as Equivalent (SQL Equivalency Tool)** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |

---

## DMS Tool Status

**Tool**: dms-mcp___statement_conversion_tool  
**Migration Project ARN**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4  
**Database**: ProductManagement  
**Schema**: dbo  
**Server**: 172.31.83.165  

**Status**: FAILED for all 7 statements  
**Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

All 7 SQL statements were passed through the DMS MCP tool as required. All returned the same infrastructure error. Manual conversion was applied with lowercase schema object names per the fallback rule (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

---

## SQL Equivalency Tool Status

**Tool**: sql-equivalency___validate_sql_equivalence  

**Status**: ERROR for all 7 statement pairs  
**Error**: `'uniqueID'` - consistent infrastructure error across all pairs

All 7 SQL statement pairs were validated through the SQL Equivalency tool as required. All returned ERROR status. Even a minimal test query ("SELECT ProductId, Name FROM Products" vs "SELECT productid, name FROM products") returned the same error, confirming a tool infrastructure issue.

Per the transformation definition: "If sql-equivalency___validate_sql_equivalence returns an error, mark the equivalency status as ERROR" - all 7 pairs are correctly marked as ERROR.

---

## Detailed Statement Conversion Log

### Statement 1: GetAllProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetAllProductsAsync()
- **Type**: CTE with AVG/COUNT window functions, INNER JOIN, CASE, ROUND, ORDER BY CASE
- **DMS Status**: FAILED - Metadata model creation failed
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (from sql-equivalency tool, error: 'uniqueID')
- **Key Changes**: All schema objects lowercased (Products→products, ProductId→productid, etc.), column aliases with AS "ColumnName" for reader compatibility

### Statement 2: GetProductByIdAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetProductByIdAsync(int productId)
- **Type**: CTE with LAG window functions, LEFT JOIN, CASE with NULL handling, ROUND
- **DMS Status**: FAILED - Metadata model creation failed
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (from sql-equivalency tool, error: 'uniqueID')
- **Key Changes**: All schema objects lowercased, LAG functions preserved (PostgreSQL compatible)

### Statement 3: InsertProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: InsertProductAsync(Product product)
- **Type**: Transaction block with DECLARE, BEGIN TRANSACTION/COMMIT, INSERT, SCOPE_IDENTITY(), GETDATE()
- **DMS Status**: FAILED - Metadata model creation failed
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (from sql-equivalency tool, error: 'uniqueID')
- **Key Changes**: SCOPE_IDENTITY() → INSERT...RETURNING via writable CTE, GETDATE() → NOW(), BEGIN TRANSACTION/COMMIT → writable CTE pattern, all schema objects lowercased

### Statement 4: UpdateProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: UpdateProductAsync(Product product)
- **Type**: Transaction block with DECLARE, SELECT into variables, UPDATE, INSERT, GETDATE()
- **DMS Status**: FAILED - Metadata model creation failed
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (from sql-equivalency tool, error: 'uniqueID')
- **Key Changes**: DECLARE variables → writable CTE with old_values, GETDATE() → NOW(), all schema objects lowercased

### Statement 5: DeleteProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: DeleteProductAsync(int productId)
- **Type**: Transaction block with DECLARE, SELECT into variables, DELETE, INSERT, UPDATE with CASE, GETDATE()
- **DMS Status**: FAILED - Metadata model creation failed
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (from sql-equivalency tool, error: 'uniqueID')
- **Key Changes**: DECLARE variables → writable CTE with old_values, GETDATE() → NOW(), CASE preserved (PostgreSQL compatible), all schema objects lowercased

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
- **Type**: CTE with RANK/PERCENT_RANK window functions, BETWEEN, CASE
- **DMS Status**: FAILED - Metadata model creation failed
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (from sql-equivalency tool, error: 'uniqueID')
- **Key Changes**: All schema objects lowercased, RANK/PERCENT_RANK/BETWEEN preserved (PostgreSQL compatible)

### Statement 7: GetLowStockProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetLowStockProductsAsync(int threshold)
- **Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **DMS Status**: FAILED - Metadata model creation failed
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (from sql-equivalency tool, error: 'uniqueID')
- **Key Changes**: All schema objects lowercased, added ::numeric cast for integer division, window functions preserved

---

## File Changes Summary

### 1. DataAccess/ProductRepository.cs
- **SQL Statements**: All 7 SQL strings replaced with PostgreSQL equivalents
- **Import**: `using Microsoft.Data.SqlClient;` → `using Npgsql;`
- **Types**: SqlConnection → NpgsqlConnection, SqlCommand → NpgsqlCommand, SqlDataReader → NpgsqlDataReader
- **Connection**: new SqlConnection() → new NpgsqlConnection()

### 2. AdoCore.csproj
- **Removed**: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added**: `<PackageReference Include="Npgsql" Version="8.0.6" />`

### 3. appsettings.json
- **DevConnection**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres`
- **ProdConnection**: Same transformation applied

---

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | All 7 original MS SQL statements |
| converted_statements.sql | sourceCode/ | All 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | sourceCode/ | Comprehensive equivalency validation report |
| migration_report.md | sourceCode/ | This final migration report |

---

## Build Verification

**Final Build Status**: ✅ SUCCESS  
**Errors**: 0  
**Warnings**: 10 (pre-existing nullable reference warnings, not introduced by migration)  
**Build Command**: `dotnet build AdoCore.csproj`

---

## Key Conversion Patterns Applied

| MS SQL Server | PostgreSQL | Notes |
|--------------|-----------|-------|
| SCOPE_IDENTITY() | INSERT...RETURNING | Via writable CTE |
| GETDATE() | NOW() | Current timestamp |
| BEGIN TRANSACTION/COMMIT | Writable CTE pattern | Application-level transaction via C# |
| DECLARE @var / SET @var | CTE subquery pattern | old_values CTE |
| NVARCHAR | VARCHAR | PostgreSQL type |
| DECIMAL | NUMERIC | PostgreSQL type |
| DATETIME | TIMESTAMP | PostgreSQL type |
| INT IDENTITY(1,1) | SERIAL | Auto-increment |
| BIT | BOOLEAN | Boolean type |
| Schema objects (PascalCase) | Schema objects (lowercase) | PostgreSQL convention |

---

## Notes and Recommendations

1. **DMS Tool**: The DMS MCP tool experienced consistent infrastructure failures ("Unknown metadata model creation status: RECEIVED"). All conversions were done manually with lowercase schema mapping. It is recommended to re-validate once DMS is operational.

2. **SQL Equivalency**: The SQL Equivalency tool experienced consistent infrastructure failures ("'uniqueID'" error). All equivalency statuses are marked as ERROR. Manual review of SQL logic confirms the conversions preserve the same functionality, but formal tool validation should be performed when the tool is operational.

3. **Transaction Handling**: The original MS SQL used inline BEGIN TRANSACTION/COMMIT within SQL strings. The PostgreSQL version uses writable CTEs for atomic multi-table operations, which is the idiomatic PostgreSQL approach for parameterized queries via ADO.NET.

4. **Integer Division**: PostgreSQL performs integer division differently than SQL Server. The `::numeric` cast was added where needed (e.g., `StockQuantity / AvgStock` → `stockquantity::numeric / avgstock`).

5. **Column Name Case Sensitivity**: PostgreSQL column names are case-sensitive when quoted. Double-quoted column aliases (e.g., `AS "ProductId"`) were used in SELECT statements to match the C# reader["ColumnName"] references.
