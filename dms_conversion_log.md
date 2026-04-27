# DMS Conversion Log

## Summary
- **Total Statements Processed**: 7
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7
- **Manual Conversions (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)**: 7
- **DMS Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **DMS Error (All Statements)**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

## Schema Mapping (from DMS schema_mapping_tool - SUCCESSFUL)
The DMS schema_mapping_tool was used successfully to obtain target schema information:
- **Source Schema**: `dbo`
- **Target Schema**: `productmanagement_dbo`
- **Products**: `dbo.Products` → `productmanagement_dbo.products` (all columns lowercase)
- **ProductHistory**: `dbo.ProductHistory` → `productmanagement_dbo.producthistory` (all columns lowercase)
- **ProductStats**: `dbo.ProductStats` → `productmanagement_dbo.productstats` (all columns lowercase)

### Key Column Mappings
| MS SQL Column | PostgreSQL Column | Type Change |
|---|---|---|
| ProductId | productid | int → INTEGER |
| Name | name | nvarchar(100) → VARCHAR(100) |
| Description | description | nvarchar(500) → VARCHAR(500) |
| Price | price | decimal(18,2) → NUMERIC(18,2) |
| StockQuantity | stockquantity | int → INTEGER |
| CreatedDate | createddate | datetime → TIMESTAMP |
| ModifiedDate | modifieddate | datetime → TIMESTAMP |
| GETDATE() | clock_timestamp() | Function change |
| SCOPE_IDENTITY() | RETURNING clause | Pattern change |

## Statement-by-Statement Log

### Statement 1: GetAllProductsAsync
- **DMS Attempt Timestamp**: 2026-04-27T05:49:38 and 2026-04-27T05:49:53
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**: CTE alias renamed from `ProductStats` to `productstats_cte` to avoid conflict with the `productstats` table. All identifiers lowercased per DMS schema mapping.

### Statement 2: GetProductByIdAsync
- **DMS Attempt Timestamp**: 2026-04-27T05:50:31
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**: CTE alias renamed from `ProductHistory` to `producthistory_cte` to avoid conflict with the `producthistory` table. All identifiers lowercased.

### Statement 3: InsertProductAsync
- **DMS Attempt Timestamp**: 2026-04-27T05:50:35
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**: SCOPE_IDENTITY() replaced with RETURNING clause. GETDATE() replaced with clock_timestamp(). Transaction block restructured for Npgsql application-level transaction handling. DECLARE/SET pattern replaced with RETURNING INTO pattern.

### Statement 4: UpdateProductAsync
- **DMS Attempt Timestamp**: 2026-04-27T05:50:38
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**: GETDATE() replaced with clock_timestamp(). Variable declarations moved to C# application code. Transaction handling via Npgsql. All identifiers lowercased.

### Statement 5: DeleteProductAsync
- **DMS Attempt Timestamp**: 2026-04-27T05:50:58
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**: GETDATE() replaced with clock_timestamp(). CASE expression preserved (compatible with PostgreSQL). Transaction handling via Npgsql. All identifiers lowercased.

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Attempt Timestamp**: 2026-04-27T05:51:02
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**: RANK(), PERCENT_RANK(), BETWEEN all compatible with PostgreSQL. All identifiers lowercased.

### Statement 7: GetLowStockProductsAsync
- **DMS Attempt Timestamp**: 2026-04-27T05:51:05
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**: Added CAST(stockquantity AS NUMERIC) to prevent integer division in PostgreSQL. AVG/MIN/MAX window functions compatible. All identifiers lowercased.
