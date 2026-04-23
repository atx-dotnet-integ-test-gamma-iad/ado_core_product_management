# DMS Conversion Summary

## Overview
All 7 SQL statements from ProductRepository.cs were submitted to the DMS MCP tool for conversion. All 7 failed with the same error.

## DMS Configuration
- Migration Project: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- Database: `ProductManagement`
- Schema: `dbo`
- Region: `us-east-1`
- Server: `172.31.83.165`

## Error Details
**Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
**Status**: `error`
**Workflow Step Failed**: `create_metadata_model`

This error occurred consistently across all 7 statement submissions and multiple retry attempts with different polling configurations (default, 20 attempts/20s interval, 30 attempts/30s interval).

## Statement Conversion Status

| # | Method | Statement | DMS Status | Manual Conversion Applied |
|---|--------|-----------|------------|--------------------------|
| 1 | GetAllProductsAsync | CTE with AVG/COUNT OVER, INNER JOIN, CASE, ROUND | FAILED | Yes - lowercase schema |
| 2 | GetProductByIdAsync | CTE with LAG OVER, LEFT JOIN, CASE, ROUND | FAILED | Yes - lowercase schema |
| 3 | InsertProductAsync | Transaction with SCOPE_IDENTITY(), GETDATE(), multi-table | FAILED | Yes - RETURNING clause, NOW(), lowercase schema |
| 4 | UpdateProductAsync | Transaction with DECLARE/SET, GETDATE(), multi-table | FAILED | Yes - SELECT INTO, NOW(), lowercase schema |
| 5 | DeleteProductAsync | Transaction with DECLARE/SET, DELETE, CASE, GETDATE() | FAILED | Yes - SELECT INTO, NOW(), lowercase schema |
| 6 | GetProductsByPriceRangeAsync | CTE with RANK(), PERCENT_RANK(), BETWEEN, CASE | FAILED | Yes - lowercase schema |
| 7 | GetLowStockProductsAsync | CTE with AVG/MIN/MAX OVER, ROUND, CASE | FAILED | Yes - CAST for integer division, lowercase schema |

## Manual Conversion Rules Applied
Since DMS failed for all statements, manual conversion was applied with the following rules:
1. **Lowercase schema objects**: All table names, column names, aliases converted to lowercase
2. **SCOPE_IDENTITY()** → `RETURNING productid` clause on INSERT
3. **GETDATE()** → `NOW()`
4. **DECLARE @var / SET @var** → PostgreSQL `SELECT ... INTO` variable assignment
5. **BEGIN TRANSACTION / COMMIT** → Handled via ADO.NET transaction management (BeginTransactionAsync)
6. **Integer division fix**: Added `CAST(... AS DECIMAL)` where integer division could lose precision
7. **Window functions**: LAG, RANK, PERCENT_RANK, AVG/MIN/MAX OVER - syntax compatible, only schema names lowercased
8. **Parameter names**: Kept as `@ParamName` for Npgsql compatibility
