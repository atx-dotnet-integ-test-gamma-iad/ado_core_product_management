# DMS Conversion Log

## Summary
- **Total Statements**: 7
- **DMS Successfully Converted**: 0
- **DMS Failed (Manual Conversion Applied)**: 7
- **DMS Failure Reason**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Schema Mapping Source**: DMS schema_mapping_tool (successful) provided target schema mappings

## Schema Mappings Retrieved via DMS schema_mapping_tool

| Source Table | Source Schema | Target Table | Target Schema |
|---|---|---|---|
| Products | dbo | products | productmanagement_dbo |
| ProductHistory | dbo | producthistory | productmanagement_dbo |
| ProductStats | dbo | productstats | productmanagement_dbo |

### Column Mappings (Products)
| Source Column | Target Column |
|---|---|
| ProductId | productid |
| Name | name |
| Description | description |
| Price | price |
| StockQuantity | stockquantity |
| CategoryId | categoryid |
| SupplierId | supplierid |
| SKU | sku |
| Weight | weight |
| Dimensions | dimensions |
| IsDiscontinued | isdiscontinued |
| ReorderLevel | reorderlevel |
| CreatedDate | createddate |
| ModifiedDate | modifieddate |

### Column Mappings (ProductHistory)
| Source Column | Target Column |
|---|---|
| HistoryId | historyid |
| ProductId | productid |
| Action | action |
| OldPrice | oldprice |
| NewPrice | newprice |
| OldStock | oldstock |
| NewStock | newstock |
| ActionDate | actiondate |
| ModifiedBy | modifiedby |

### Column Mappings (ProductStats)
| Source Column | Target Column |
|---|---|
| StatId | statid |
| TotalProducts | totalproducts |
| AveragePrice | averageprice |
| TotalStockValue | totalstockvalue |
| LowStockCount | lowstockcount |
| DiscontinuedCount | discontinuedcount |
| LastUpdated | lastupdated |

---

## Statement 1: GetAllProductsAsync

**DMS Tool Call**: dms-mcp___statement_conversion_tool with schema_name='dbo', max_poll_attempts=30, poll_interval_seconds=15
**DMS Status**: error
**DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
**DMS Timestamp**: 2026-04-26T14:25:44.376106
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Conversion Notes**: 
- CTE and window functions (AVG() OVER, COUNT() OVER) are ANSI SQL compatible with PostgreSQL
- Table name `Products` → `productmanagement_dbo.products`
- All column names converted to lowercase per DMS schema mapping
- ROUND() function is compatible with PostgreSQL
- CASE expressions are ANSI SQL compatible

---

## Statement 2: GetProductByIdAsync

**DMS Tool Call**: dms-mcp___statement_conversion_tool with schema_name='dbo', max_poll_attempts=30, poll_interval_seconds=15
**DMS Status**: error
**DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
**DMS Timestamp**: 2026-04-26T14:26:35.802275
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Conversion Notes**:
- CTE with LAG() window function is ANSI SQL compatible with PostgreSQL
- Table name `Products` → `productmanagement_dbo.products`
- All column names converted to lowercase per DMS schema mapping
- Parameter @ProductId retained (Npgsql supports @ parameter syntax)

---

## Statement 3: InsertProductAsync

**DMS Tool Call**: dms-mcp___statement_conversion_tool with schema_name='dbo', max_poll_attempts=30, poll_interval_seconds=15
**DMS Status**: error
**DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
**DMS Timestamp**: 2026-04-26T14:26:50.200778
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Conversion Notes**:
- SCOPE_IDENTITY() → RETURNING productid clause on INSERT
- GETDATE() → clock_timestamp()
- DECLARE @NewProductId / SET pattern → C# code captures returned value from RETURNING clause
- BEGIN TRANSACTION/COMMIT → Handled via NpgsqlTransaction in C# code
- Table names: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
- All column names converted to lowercase per DMS schema mapping
- Single monolithic SQL block split into separate statements executed within a C# transaction

---

## Statement 4: UpdateProductAsync

**DMS Tool Call**: dms-mcp___statement_conversion_tool with schema_name='dbo', max_poll_attempts=30, poll_interval_seconds=15
**DMS Status**: error
**DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
**DMS Timestamp**: 2026-04-26T14:27:03.610283
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Conversion Notes**:
- DECLARE @OldPrice / @OldStock + SELECT INTO variables → Separate SELECT query, results captured in C# code
- GETDATE() → clock_timestamp()
- BEGIN TRANSACTION/COMMIT → Handled via NpgsqlTransaction in C# code
- Table names converted per DMS schema mapping
- All column names converted to lowercase per DMS schema mapping

---

## Statement 5: DeleteProductAsync

**DMS Tool Call**: dms-mcp___statement_conversion_tool with schema_name='dbo', max_poll_attempts=30, poll_interval_seconds=15
**DMS Status**: error
**DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
**DMS Timestamp**: 2026-04-26T14:27:16.871787
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Conversion Notes**:
- DECLARE @OldPrice / @OldStock + SELECT INTO variables → Separate SELECT query, results captured in C# code
- GETDATE() → clock_timestamp()
- BEGIN TRANSACTION/COMMIT → Handled via NpgsqlTransaction in C# code
- CASE expression in UPDATE is ANSI SQL compatible
- Table names converted per DMS schema mapping
- All column names converted to lowercase per DMS schema mapping

---

## Statement 6: GetProductsByPriceRangeAsync

**DMS Tool Call**: dms-mcp___statement_conversion_tool with schema_name='dbo', max_poll_attempts=30, poll_interval_seconds=15
**DMS Status**: error
**DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
**DMS Timestamp**: 2026-04-26T14:27:30.438200
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Conversion Notes**:
- CTE with RANK() and PERCENT_RANK() window functions are ANSI SQL compatible with PostgreSQL
- BETWEEN clause is ANSI SQL compatible
- Table name `Products` → `productmanagement_dbo.products`
- All column names converted to lowercase per DMS schema mapping

---

## Statement 7: GetLowStockProductsAsync

**DMS Tool Call**: dms-mcp___statement_conversion_tool with schema_name='dbo', max_poll_attempts=30, poll_interval_seconds=15
**DMS Status**: error
**DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
**DMS Timestamp**: 2026-04-26T14:27:45.361095
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Conversion Notes**:
- CTE with AVG(), MIN(), MAX() window functions are ANSI SQL compatible with PostgreSQL
- Added explicit ::numeric cast for integer division (StockQuantity / AvgStock) to ensure decimal results in PostgreSQL
- Table name `Products` → `productmanagement_dbo.products`
- All column names converted to lowercase per DMS schema mapping
