# SQL Server to PostgreSQL Migration Report

## Migration Overview
- **Date**: 2026-04-02
- **Source Database**: Microsoft SQL Server (ProductManagement)
- **Target Database**: PostgreSQL (ProductManagement)
- **Application**: AdoCore (.NET 9.0 ADO.NET Application)
- **Migration Type**: ADO.NET SQL Server to PostgreSQL

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention (DMS failure) | 7 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| With equivalency validation errors | 7 |

---

## DMS Conversion Results

### DMS Tool Configuration
- **Migration Project ARN**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Database Name**: ProductManagement
- **Schema Name**: dbo
- **Region**: us-east-1
- **Server Name**: 172.31.83.165

### DMS Conversion Status
All 7 SQL statements were passed through the DMS MCP tool. All failed with the same error:
- **Error**: Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
- **Failed Step**: create_metadata_model

### Manual Conversion Applied
Since DMS failed for all statements, manual conversion was performed with:
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- All schema object names (tables, columns, aliases) converted to lowercase
- SQL Server-specific functions replaced with PostgreSQL equivalents

---

## SQL Equivalency Validation Results

All 7 statement pairs were validated using the SQL Equivalency MCP tool (sql-equivalency___validate_sql_equivalence).
All returned ERROR status with error "'uniqueID'".

| # | Statement | Equivalency Status | Tool Error |
|---|-----------|-------------------|------------|
| 1 | GetAllProductsAsync | ERROR | 'uniqueID' |
| 2 | GetProductByIdAsync | ERROR | 'uniqueID' |
| 3 | InsertProductAsync | ERROR | 'uniqueID' |
| 4 | UpdateProductAsync | ERROR | 'uniqueID' |
| 5 | DeleteProductAsync | ERROR | 'uniqueID' |
| 6 | GetProductsByPriceRangeAsync | ERROR | 'uniqueID' |
| 7 | GetLowStockProductsAsync | ERROR | 'uniqueID' |

**Note**: Equivalency statuses are strictly from the SQL Equivalency tool. No agent judgment was used.

---

## Detailed SQL Statement Conversions

### Statement 1: GetAllProductsAsync
- **Type**: CTE with AVG() OVER(), COUNT(*) OVER(), CASE, ROUND
- **Key Changes**: Lowercase schema objects, ROUND with ::numeric cast
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG() window function, LEFT JOIN, CASE, ROUND
- **Key Changes**: Lowercase schema objects, ROUND with ::numeric cast
- **Parameters**: @ProductId (preserved for Npgsql)
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Key Changes**:
  - SCOPE_IDENTITY() → lastval()
  - GETDATE() → NOW()
  - Removed DECLARE @NewProductId INT (not needed with lastval())
- **Parameters**: @Name, @Description, @Price, @StockQuantity
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT
- **Key Changes**:
  - Removed DECLARE @OldPrice/@OldStock
  - Replaced variable assignment with subqueries
  - GETDATE() → NOW()
  - Reordered: INSERT history + UPDATE stats before UPDATE product (to capture old values)
- **Parameters**: @ProductId, @Name, @Description, @Price, @StockQuantity
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE
- **Key Changes**:
  - Removed DECLARE @OldPrice/@OldStock
  - Used SELECT...FROM subquery for INSERT into history
  - GETDATE() → NOW()
  - Reordered: INSERT history + UPDATE stats before DELETE (to capture old values)
- **Parameters**: @ProductId
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Key Changes**: Lowercase schema objects only (functions compatible)
- **Parameters**: @MinPrice, @MaxPrice
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX OVER(), CASE, ROUND
- **Key Changes**: Lowercase schema objects, ROUND with ::numeric cast
- **Parameters**: @Threshold
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

---

## Files Modified

| File | Changes |
|------|---------|
| DataAccess/ProductRepository.cs | All 7 SQL statements converted to PostgreSQL; SqlConnection → NpgsqlConnection; SqlCommand → NpgsqlCommand; SqlDataReader → NpgsqlDataReader; using Microsoft.Data.SqlClient → using Npgsql |
| AdoCore.csproj | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| appsettings.json | Connection strings updated from SQL Server to PostgreSQL format |

---

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | Server=localhost | Host=localhost |
| Database | Database=ProductManagement | Database=ProductManagement |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets | true | (removed - not applicable) |
| TrustServerCertificate | True | (removed - not applicable) |

---

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | Project root | All 7 original MS SQL statements |
| converted_statements.sql | Project root | All 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | Project root | Comprehensive equivalency validation report |
| dms_failure_summary.md | Project root | DMS failure documentation |
| migration_report.md | Project root | This report |

---

## Build Status
- **Final Build**: ✅ SUCCESS (0 Errors, 10 Warnings)
- **Warnings**: Pre-existing nullable reference warnings (CS8618, CS8601, CS8600, CS8603, CS8625)
- **Vulnerable Dependencies**: None (Npgsql 8.0.6 has no known vulnerabilities)
