# DMS Conversion Failure Summary

## Overview
All 7 SQL statements failed DMS statement conversion across 2 rounds of attempts (14 total DMS calls).
All failures returned the same error. Manual conversion applied with lowercase schema object names per PostgreSQL conventions.

## DMS Error Details
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Workflow Step Failed**: create_metadata_model
- **Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Database**: ProductManagement
- **Schema**: dbo
- **Region**: us-east-1
- **Server**: 172.31.83.165

## DMS Attempt History

### Round 1 (Previous Attempt)
All 7 statements failed with identical error. Statement 1 was retried 3 times.

### Round 2 (Current Attempt - 2026-05-04T14:15-14:17)
All 7 statements retried and failed again with identical error:

| Statement | Timestamp | Status | Error |
|---|---|---|---|
| 1. GetAllProductsAsync | 2026-05-04T14:15:55 | FAILED | Metadata model creation failed |
| 2. GetProductByIdAsync | 2026-05-04T14:16:11 | FAILED | Metadata model creation failed |
| 3. InsertProductAsync | 2026-05-04T14:16:27 | FAILED | Metadata model creation failed |
| 4. UpdateProductAsync | 2026-05-04T14:16:41 | FAILED | Metadata model creation failed |
| 5. DeleteProductAsync | 2026-05-04T14:16:58 | FAILED | Metadata model creation failed |
| 6. GetProductsByPriceRangeAsync | 2026-05-04T14:17:12 | FAILED | Metadata model creation failed |
| 7. GetLowStockProductsAsync | 2026-05-04T14:17:27 | FAILED | Metadata model creation failed |

## Manual Conversion Applied
Since DMS failed for all statements, manual conversion was applied with method: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### Schema Mapping Applied
| Source (MS SQL) | Target (PostgreSQL) |
|---|---|
| Products | products |
| ProductHistory | producthistory |
| ProductStats | productstats |
| All column names | Lowercased (e.g., ProductId -> productid, Price -> price) |

## Statements and Manual Conversions

### Statement 1: GetAllProductsAsync
- **DMS Attempts**: 4 (Round 1: 3, Round 2: 1) - all failed
- **Manual Conversion**: Applied lowercase schema object names
- **Key Changes**: Table/column names lowercased, CTE alias lowercased

### Statement 2: GetProductByIdAsync
- **DMS Attempts**: 2 (Round 1: 1, Round 2: 1) - all failed
- **Manual Conversion**: Applied lowercase schema object names
- **Key Changes**: Table/column names lowercased, CTE alias lowercased

### Statement 3: InsertProductAsync
- **DMS Attempts**: 2 (Round 1: 1, Round 2: 1) - all failed
- **Manual Conversion**: SCOPE_IDENTITY() -> INSERT...RETURNING via CTE, GETDATE() -> NOW(), removed DECLARE/SET, lowercase names
- **Key Changes**: Major restructuring from transaction block to CTE-based INSERT...RETURNING pattern

### Statement 4: UpdateProductAsync
- **DMS Attempts**: 2 (Round 1: 1, Round 2: 1) - all failed
- **Manual Conversion**: DECLARE/SET -> CTE with old_values capture, GETDATE() -> NOW(), lowercase names
- **Key Changes**: Transaction with variables -> CTE pattern with old_values capture

### Statement 5: DeleteProductAsync
- **DMS Attempts**: 2 (Round 1: 1, Round 2: 1) - all failed
- **Manual Conversion**: DECLARE/SET -> CTE with old_values capture, GETDATE() -> NOW(), lowercase names
- **Key Changes**: Transaction with variables -> CTE pattern with old_values capture

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Attempts**: 2 (Round 1: 1, Round 2: 1) - all failed
- **Manual Conversion**: Applied lowercase schema object names
- **Key Changes**: Table/column names lowercased, CTE alias lowercased

### Statement 7: GetLowStockProductsAsync
- **DMS Attempts**: 2 (Round 1: 1, Round 2: 1) - all failed
- **Manual Conversion**: Applied lowercase schema object names, added ::numeric cast for integer division
- **Key Changes**: Table/column names lowercased, explicit numeric cast for ROUND division

## Conversion Summary
- **Total DMS Attempts**: 16 (across 2 rounds)
- **Successful DMS Conversions**: 0
- **Manual Conversions Applied**: 7
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
