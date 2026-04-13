# DMS Conversion Failure Summary

## Overview
All 7 SQL statements were submitted to the DMS MCP tool (dms-mcp___statement_conversion_tool) for conversion.
All 7 failed with the same error, requiring manual conversion with lowercase schema object names.

## DMS Error Details
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Region**: us-east-1
- **Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Schema**: dbo
- **Database**: ProductManagement

## Statements and Manual Conversions

### Statement 1: GetAllProductsAsync
- **DMS Attempt Timestamp**: 2026-04-13T05:54:55.979029
- **DMS Status**: error
- **Manual Conversion**: Applied lowercase schema names. SQL syntax compatible (CTE, AVG OVER, COUNT OVER, ROUND, CASE, INNER JOIN all supported in PostgreSQL).

### Statement 2: GetProductByIdAsync  
- **DMS Attempt Timestamp**: 2026-04-13T05:55:49.848124
- **DMS Status**: error
- **Manual Conversion**: Applied lowercase schema names. LAG window function, ROUND, LEFT JOIN all supported in PostgreSQL.

### Statement 3: InsertProductAsync
- **DMS Attempt Timestamp**: 2026-04-13T05:56:06.999660
- **DMS Status**: error
- **Manual Conversion**: 
  - SCOPE_IDENTITY() → INSERT...RETURNING productid (PostgreSQL pattern)
  - GETDATE() → NOW()
  - DECLARE @var → PostgreSQL variable syntax not needed (handled via app-level transaction)
  - BEGIN TRANSACTION/COMMIT → Handled by Npgsql transaction API

### Statement 4: UpdateProductAsync
- **DMS Attempt Timestamp**: 2026-04-13T05:56:21.260979
- **DMS Status**: error
- **Manual Conversion**:
  - GETDATE() → NOW()
  - DECLARE @var / SELECT INTO @var → Separate queries with app-level variables
  - BEGIN TRANSACTION/COMMIT → Handled by Npgsql transaction API

### Statement 5: DeleteProductAsync
- **DMS Attempt Timestamp**: 2026-04-13T05:56:36.356431
- **DMS Status**: error
- **Manual Conversion**:
  - GETDATE() → NOW()
  - DECLARE @var / SELECT INTO @var → Separate queries with app-level variables
  - BEGIN TRANSACTION/COMMIT → Handled by Npgsql transaction API

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Attempt Timestamp**: 2026-04-13T05:56:51.179472
- **DMS Status**: error
- **Manual Conversion**: Applied lowercase schema names. RANK(), PERCENT_RANK(), BETWEEN all supported in PostgreSQL.

### Statement 7: GetLowStockProductsAsync
- **DMS Attempt Timestamp**: 2026-04-13T05:57:06.469496
- **DMS Status**: error
- **Manual Conversion**: Applied lowercase schema names. AVG/MIN/MAX OVER(), ROUND, CAST supported in PostgreSQL. Added CAST for integer division in ROUND.
