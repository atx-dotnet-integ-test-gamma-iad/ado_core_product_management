# DMS Conversion Log

## Summary
- **Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Total Statements Processed**: 7
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7
- **Manual Conversions Required**: 7

## DMS Tool Status
The DMS statement_conversion_tool consistently failed for all 7 statements with the error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Multiple retry attempts were made with different parameter configurations:
1. Default parameters (max_poll_attempts=15, poll_interval_seconds=10)
2. Extended parameters (max_poll_attempts=30, poll_interval_seconds=15)
3. With explicit database_name and server_name parameters
4. With a simple test query to validate connectivity

All attempts returned the same error.

## DMS Schema Mapping Tool Status
The DMS schema_mapping_tool worked successfully for all 3 tables:
- `Products` → `products` (schema: `productmanagement_dbo`)
- `ProductHistory` → `producthistory` (schema: `productmanagement_dbo`)
- `ProductStats` → `productstats` (schema: `productmanagement_dbo`)

Schema mapping results were used to guide the manual conversions.

## Individual Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamps**: 2026-04-16T19:18:39 (first attempt), 2026-04-16T19:18:58 (retry)
- **Manual Conversion**: Applied lowercase schema object names per DMS schema mapping
- **Changes**: Table/column names lowercased (Products→products, ProductId→productid, etc.)
- **Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 2: GetProductByIdAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-16T19:18:43
- **Manual Conversion**: Applied lowercase schema object names per DMS schema mapping
- **Changes**: Table/column names lowercased, LAG/ROUND syntax preserved (PostgreSQL compatible)
- **Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 3: InsertProductAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-16T19:20:25
- **Manual Conversion**: 
  - SCOPE_IDENTITY() → INSERT...RETURNING via CTE
  - GETDATE() → NOW()
  - DECLARE @NewProductId removed → CTE chain with RETURNING
  - BEGIN TRANSACTION/COMMIT removed (handled by C# ADO.NET layer)
  - Restructured as single CTE chain: new_product→log_history→update_stats→SELECT
- **Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 4: UpdateProductAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-16T19:20:28
- **Manual Conversion**:
  - DECLARE @OldPrice/@OldStock → CTE old_values capturing pre-update values
  - GETDATE() → NOW()
  - BEGIN TRANSACTION/COMMIT removed (handled by C# ADO.NET layer)
  - Restructured as CTE chain: old_values→do_update→log_history→UPDATE productstats
- **Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 5: DeleteProductAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-16T19:20:31
- **Manual Conversion**:
  - DECLARE @OldPrice/@OldStock → CTE old_values capturing pre-delete values
  - GETDATE() → NOW()
  - BEGIN TRANSACTION/COMMIT removed (handled by C# ADO.NET layer)
  - Restructured as CTE chain: old_values→log_history→do_delete→UPDATE productstats
- **Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-16T19:20:34
- **Manual Conversion**: Applied lowercase schema object names per DMS schema mapping
- **Changes**: Table/column names lowercased, RANK/PERCENT_RANK syntax preserved (PostgreSQL compatible)
- **Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 7: GetLowStockProductsAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-16T19:20:37
- **Manual Conversion**: Applied lowercase schema object names, added CAST for integer division
- **Changes**: Table/column names lowercased, ROUND integer division fix (CAST stockquantity AS NUMERIC)
- **Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## Key Conversion Rules Applied (from DMS Schema Mapping)
| SQL Server | PostgreSQL |
|---|---|
| `Products` | `products` |
| `ProductHistory` | `producthistory` |
| `ProductStats` | `productstats` |
| `ProductId` | `productid` |
| `Name` | `name` |
| `Price` | `price` |
| `StockQuantity` | `stockquantity` |
| `CreatedDate` | `createddate` |
| `ModifiedDate` | `modifieddate` |
| `SCOPE_IDENTITY()` | `INSERT...RETURNING` |
| `GETDATE()` | `NOW()` |
| `DECLARE @var` | CTE-based variable capture |
| `BEGIN TRANSACTION/COMMIT` | Handled by C# ADO.NET |
