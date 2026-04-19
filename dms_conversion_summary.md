# DMS Conversion Summary Report
## Date: 2026-04-19
## Project: Microsoft SQL Server to PostgreSQL Migration for AdoCore

### DMS Tool Status: UNAVAILABLE
All 7 SQL statements from ProductRepository.cs were passed through the DMS MCP tool (dms-mcp___statement_conversion_tool) with the following parameters:
- migration_project_identifier: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- database_name: ProductManagement
- schema_name: dbo
- region: us-east-1

**All calls returned the same error:**
```
Status: error
Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

### Manual Conversion Applied
Per the transformation definition, since DMS failed, manual conversion was applied with:
- All schema object names converted to lowercase
- SCOPE_IDENTITY() → INSERT...RETURNING / lastval()
- GETDATE() → NOW()
- BEGIN TRANSACTION / COMMIT → Managed via C# NpgsqlTransaction
- DECLARE @variable / SET @variable → Restructured to use C# variables or separate SQL statements
- All table names: Products→products, ProductHistory→producthistory, ProductStats→productstats
- All column names lowercased: ProductId→productid, Name→name, etc.

### Statement-by-Statement Details

| # | Method | DMS Status | DMS Error | Manual Conversion |
|---|--------|-----------|-----------|-------------------|
| 1 | GetAllProductsAsync | FAILED | Metadata model creation failed: RECEIVED | Lowercase schema, syntax compatible |
| 2 | GetProductByIdAsync | FAILED | Metadata model creation failed: RECEIVED | Lowercase schema, syntax compatible |
| 3 | InsertProductAsync | FAILED | Metadata model creation failed: RECEIVED | SCOPE_IDENTITY()→RETURNING, GETDATE()→NOW(), restructured transaction |
| 4 | UpdateProductAsync | FAILED | Metadata model creation failed: RECEIVED | GETDATE()→NOW(), DECLARE removed, restructured transaction |
| 5 | DeleteProductAsync | FAILED | Metadata model creation failed: RECEIVED | GETDATE()→NOW(), DECLARE removed, restructured transaction |
| 6 | GetProductsByPriceRangeAsync | FAILED | Metadata model creation failed: RECEIVED | Lowercase schema, syntax compatible |
| 7 | GetLowStockProductsAsync | FAILED | Metadata model creation failed: RECEIVED | Lowercase schema, CAST for integer division |
