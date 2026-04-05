# DMS Conversion Log

## Migration Details
- **Source Database**: Microsoft SQL Server 2019 (ProductManagement)
- **Target Database**: PostgreSQL 13
- **DMS Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Schema Mapping**: `dbo` → `productmanagement_dbo`

## Schema Mapping Results (Successful)

DMS schema_mapping_tool was successfully called for all 3 tables:

| Source Table | Source Schema | Target Table | Target Schema |
|---|---|---|---|
| Products | dbo | products | productmanagement_dbo |
| ProductHistory | dbo | producthistory | productmanagement_dbo |
| ProductStats | dbo | productstats | productmanagement_dbo |

Column name mappings (all lowercase in target):
- ProductId → productid
- Name → name
- Description → description
- Price → price
- StockQuantity → stockquantity
- CreatedDate → createddate
- ModifiedDate → modifieddate
- HistoryId → historyid
- Action → action
- OldPrice → oldprice
- NewPrice → newprice
- OldStock → oldstock
- NewStock → newstock
- ActionDate → actiondate
- StatId → statid
- TotalProducts → totalproducts
- AveragePrice → averageprice
- LastUpdated → lastupdated

Type mappings from DMS:
- `int IDENTITY(1,1)` → `INTEGER GENERATED ALWAYS AS IDENTITY`
- `nvarchar(N)` → `VARCHAR(N)`
- `varchar(N)` → `VARCHAR(N)`
- `decimal(18,2)` → `NUMERIC(18,2)`
- `datetime` → `TIMESTAMP WITHOUT TIME ZONE`
- `bit` → `NUMERIC(1,0)`
- `GETDATE()` → `clock_timestamp()`

## Statement Conversion Attempts

### Statement 1: GetAllProductsAsync
- **DMS Tool Called**: Yes
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}`
- **Timestamp**: 2026-04-05T05:49:28 to 2026-04-05T05:52:15
- **Fallback**: Manual conversion with lowercase schema (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Conversions**:
  - CTE name `ProductStats` renamed to `productstats_cte` to avoid conflict with table name
  - All table/column names lowercased per DMS schema mapping
  - Table references prefixed with `productmanagement_dbo.`

### Statement 2: GetProductByIdAsync
- **DMS Tool Called**: Yes
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}`
- **Timestamp**: 2026-04-05T05:52:16 to 2026-04-05T05:54:51
- **Fallback**: Manual conversion with lowercase schema (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Conversions**:
  - CTE name `ProductHistory` renamed to `producthistory_cte` to avoid conflict with table name
  - LAG window functions preserved (compatible with PostgreSQL)
  - All table/column names lowercased per DMS schema mapping

### Statement 3: InsertProductAsync
- **DMS Tool Called**: Yes
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}`
- **Timestamp**: 2026-04-05T05:54:52 to 2026-04-05T05:57:27
- **Fallback**: Manual conversion with lowercase schema (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Conversions**:
  - `DECLARE @NewProductId INT` + `SCOPE_IDENTITY()` → `lastval()` (PostgreSQL sequence function)
  - `BEGIN TRANSACTION`/`COMMIT` removed (handled at application level)
  - `GETDATE()` → `clock_timestamp()`
  - All table/column names lowercased per DMS schema mapping

### Statement 4: UpdateProductAsync
- **DMS Tool Called**: Yes
- **DMS Status**: ERROR (Timeout)
- **DMS Error**: `Command execution timed out after 300 seconds`
- **Fallback**: Manual conversion with lowercase schema (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Conversions**:
  - `DECLARE @OldPrice`/`@OldStock` variables replaced with subquery approach
  - History INSERT reordered before UPDATE to capture old values via subquery
  - Stats UPDATE uses subquery for old price reference
  - `GETDATE()` → `clock_timestamp()`
  - All table/column names lowercased per DMS schema mapping

### Statement 5: DeleteProductAsync
- **DMS Tool Called**: Yes
- **DMS Status**: ERROR (Timeout)
- **DMS Error**: `Command execution timed out after 300 seconds`
- **Fallback**: Manual conversion with lowercase schema (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Conversions**:
  - `DECLARE @OldPrice`/`@OldStock` variables replaced with subquery approach
  - History INSERT reordered before DELETE to capture old values via subquery
  - Stats UPDATE uses subquery for old price reference
  - `GETDATE()` → `clock_timestamp()`
  - All table/column names lowercased per DMS schema mapping

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Tool Called**: Yes
- **DMS Status**: ERROR (Timeout)
- **DMS Error**: `Command execution timed out after 300 seconds`
- **Fallback**: Manual conversion with lowercase schema (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Conversions**:
  - RANK() and PERCENT_RANK() preserved (compatible with PostgreSQL)
  - BETWEEN preserved (compatible with PostgreSQL)
  - All table/column names lowercased per DMS schema mapping

### Statement 7: GetLowStockProductsAsync
- **DMS Tool Called**: Yes
- **DMS Status**: ERROR (Timeout)
- **DMS Error**: `Command execution timed out after 300 seconds`
- **Fallback**: Manual conversion with lowercase schema (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Conversions**:
  - AVG/MIN/MAX window functions preserved (compatible with PostgreSQL)
  - Added `::numeric` cast for integer division in ROUND to avoid integer division
  - All table/column names lowercased per DMS schema mapping

## Summary
- **Total Statements**: 7
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7 (all timeout/metadata model errors)
- **Manual Conversions**: 7 (all using DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Schema Mapping Used**: DMS schema_mapping_tool results (successful) applied to manual conversions
