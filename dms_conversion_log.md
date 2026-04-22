# DMS Conversion Log

## Summary
- **DMS Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Source**: Microsoft SQL Server 2019, Database: ProductManagement
- **Target**: PostgreSQL 13
- **Total Statements**: 7
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7
- **Manual Conversions (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)**: 7

## DMS Tool Status
The DMS Statement Conversion Tool (dms-mcp___statement_conversion_tool) consistently failed for all statements with the following error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

This error occurred on every attempt, including:
- Multiple attempts with default parameters
- Increased poll attempts (30) and poll intervals (15s, 20s)
- Explicit server_name parameter
- Simple test queries

**Note**: The DMS Schema Mapping Tool (dms-mcp___schema_mapping_tool) worked correctly and provided the target schema/table/column mappings used for manual conversion.

## Schema Mapping (from DMS schema_mapping_tool)
| Source Schema | Target Schema |
|---|---|
| `dbo` | `productmanagement_dbo` |

| Source Table | Target Table |
|---|---|
| `[dbo].[Products]` | `productmanagement_dbo.products` |
| `[dbo].[ProductHistory]` | `productmanagement_dbo.producthistory` |
| `[dbo].[ProductStats]` | `productmanagement_dbo.productstats` |

### Column Mappings (Products)
| Source Column | Target Column | Source Type | Target Type |
|---|---|---|---|
| ProductId | productid | int IDENTITY(1,1) | INTEGER GENERATED ALWAYS AS IDENTITY |
| Name | name | nvarchar(100) | VARCHAR(100) |
| Description | description | nvarchar(500) | VARCHAR(500) |
| Price | price | decimal(18,2) | NUMERIC(18,2) |
| StockQuantity | stockquantity | int | INTEGER |
| CategoryId | categoryid | int | INTEGER |
| SupplierId | supplierid | int | INTEGER |
| SKU | sku | nvarchar(50) | VARCHAR(50) |
| Weight | weight | decimal(10,2) | NUMERIC(10,2) |
| Dimensions | dimensions | nvarchar(50) | VARCHAR(50) |
| IsDiscontinued | isdiscontinued | bit | NUMERIC(1,0) |
| ReorderLevel | reorderlevel | int | INTEGER |
| CreatedDate | createddate | datetime | TIMESTAMP WITHOUT TIME ZONE |
| ModifiedDate | modifieddate | datetime | TIMESTAMP WITHOUT TIME ZONE |

### Column Mappings (ProductHistory)
| Source Column | Target Column | Source Type | Target Type |
|---|---|---|---|
| HistoryId | historyid | int IDENTITY(1,1) | INTEGER GENERATED ALWAYS AS IDENTITY |
| ProductId | productid | int | INTEGER |
| Action | action | varchar(10) | VARCHAR(10) |
| OldPrice | oldprice | decimal(18,2) | NUMERIC(18,2) |
| NewPrice | newprice | decimal(18,2) | NUMERIC(18,2) |
| OldStock | oldstock | int | INTEGER |
| NewStock | newstock | int | INTEGER |
| ActionDate | actiondate | datetime | TIMESTAMP WITHOUT TIME ZONE |
| ModifiedBy | modifiedby | nvarchar(100) | VARCHAR(100) |

### Column Mappings (ProductStats)
| Source Column | Target Column | Source Type | Target Type |
|---|---|---|---|
| StatId | statid | int | INTEGER |
| TotalProducts | totalproducts | int | INTEGER |
| AveragePrice | averageprice | decimal(18,2) | NUMERIC(18,2) |
| TotalStockValue | totalstockvalue | decimal(18,2) | NUMERIC(18,2) |
| LowStockCount | lowstockcount | int | INTEGER |
| DiscontinuedCount | discontinuedcount | int | INTEGER |
| LastUpdated | lastupdated | datetime | TIMESTAMP WITHOUT TIME ZONE |

## Conversion Rules Applied (Manual)
- `GETDATE()` → `clock_timestamp()` (based on DMS schema mapping target defaults)
- `SCOPE_IDENTITY()` → `lastval()`
- `BEGIN TRANSACTION` → `BEGIN`
- `DECLARE @var TYPE; SET @var = expr` → Replaced with subqueries
- All schema object names (tables, columns, aliases) → lowercase
- Schema prefix: `dbo.` → `productmanagement_dbo.`

---

## Detailed Statement Log

### Statement 1: GetAllProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetAllProductsAsync()
- **DMS Attempt**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-22T06:39:53
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: CTE alias renamed from `ProductStats` to `productstats_cte` (to avoid conflict with table name), all identifiers lowercased, schema prefixed

### Statement 2: GetProductByIdAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetProductByIdAsync(int productId)
- **DMS Attempt**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-22T06:39:56
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: CTE alias renamed from `ProductHistory` to `producthistory_cte` (to avoid conflict with table name), all identifiers lowercased, schema prefixed, LAG window functions preserved

### Statement 3: InsertProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: InsertProductAsync(Product product)
- **DMS Attempt**: FAILED (same error as above)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: `DECLARE @NewProductId` / `SCOPE_IDENTITY()` → `lastval()`, `BEGIN TRANSACTION` → `BEGIN`, `GETDATE()` → `clock_timestamp()`, all identifiers lowercased, schema prefixed

### Statement 4: UpdateProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: UpdateProductAsync(Product product)
- **DMS Attempt**: FAILED (same error as above)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: `DECLARE @OldPrice/@OldStock` replaced with subqueries (history logged BEFORE update to capture old values), `GETDATE()` → `clock_timestamp()`, all identifiers lowercased, schema prefixed

### Statement 5: DeleteProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: DeleteProductAsync(int productId)
- **DMS Attempt**: FAILED (same error as above)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: `DECLARE @OldPrice/@OldStock` replaced with subqueries (stats updated and history logged BEFORE deletion to capture old values), `GETDATE()` → `clock_timestamp()`, all identifiers lowercased, schema prefixed

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
- **DMS Attempt**: FAILED (same error as above)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: All identifiers lowercased, schema prefixed, RANK()/PERCENT_RANK() window functions preserved (PostgreSQL compatible)

### Statement 7: GetLowStockProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetLowStockProductsAsync(int threshold)
- **DMS Attempt**: FAILED (same error as above)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: All identifiers lowercased, schema prefixed, added CAST(stockquantity AS NUMERIC) for integer division fix in ROUND, AVG/MIN/MAX window functions preserved
