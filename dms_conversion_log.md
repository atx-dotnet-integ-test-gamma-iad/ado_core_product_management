# DMS Conversion Log

## Migration Project
- **DMS ARN**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Source Database**: ProductManagement (SQL Server 2019)
- **Target Database**: postgres (PostgreSQL 13)
- **Source Server**: 172.31.83.165
- **Region**: us-east-1

## Schema Mapping Results (Successful)
The DMS schema_mapping_tool successfully returned schema mappings:

### Products Table
- Source: `[dbo].[Products]` → Target: `productmanagement_dbo.products`
- All column names lowercased (ProductId→productid, Name→name, etc.)
- `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`
- `datetime` → `TIMESTAMP WITHOUT TIME ZONE`
- `GETDATE()` → `clock_timestamp()`

### ProductHistory Table
- Source: `[dbo].[ProductHistory]` → Target: `productmanagement_dbo.producthistory`
- All column names lowercased (HistoryId→historyid, ProductId→productid, etc.)
- `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`

### ProductStats Table
- Source: `[dbo].[ProductStats]` → Target: `productmanagement_dbo.productstats`
- All column names lowercased (StatId→statid, TotalProducts→totalproducts, etc.)

## Statement Conversion Attempts

### Statement 1: GetAllProductsAsync
- **DMS Status**: FAILED
- **Error**: Metadata model conversion failed: Metadata model conversion did not complete after 15 attempts
- **DMS Timestamp**: 2026-04-01T05:32:57.862645
- **Metadata Model**: sql-conversion-1775021579
- **Manual Conversion**: Applied lowercase schema object names per DMS schema mapping
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 2: GetProductByIdAsync
- **DMS Status**: FAILED
- **Error**: Metadata model creation failed: Metadata model creation did not complete after 25 attempts
- **DMS Timestamp**: 2026-04-01T05:41:00.747640 (tested with simpler query from same table)
- **Manual Conversion**: Applied lowercase schema object names per DMS schema mapping
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 3: InsertProductAsync
- **DMS Status**: FAILED
- **Error**: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
- **DMS Timestamp**: 2026-04-01T05:45:29.709525 (tested with simple query)
- **Manual Conversion**: Restructured for PostgreSQL - SCOPE_IDENTITY() replaced with RETURNING clause, GETDATE() replaced with clock_timestamp(), transaction restructured into separate statements with RETURNING
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 4: UpdateProductAsync
- **DMS Status**: FAILED
- **Error**: DMS consistently failing - metadata model creation/conversion timeout
- **Manual Conversion**: DECLARE variables restructured, GETDATE() replaced with clock_timestamp(), all identifiers lowercased
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 5: DeleteProductAsync
- **DMS Status**: FAILED
- **Error**: DMS consistently failing - metadata model creation/conversion timeout
- **Manual Conversion**: DECLARE variables restructured, GETDATE() replaced with clock_timestamp(), all identifiers lowercased
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Status**: FAILED
- **Error**: DMS consistently failing - metadata model creation/conversion timeout
- **Manual Conversion**: All identifiers lowercased per schema mapping, SQL syntax compatible
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 7: GetLowStockProductsAsync
- **DMS Status**: FAILED
- **Error**: DMS consistently failing - metadata model creation/conversion timeout
- **Manual Conversion**: All identifiers lowercased, added ::NUMERIC cast for integer division
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## Summary
- **Total Statements**: 7
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7
- **Manual Conversions Required**: 7
- **DMS Failure Reason**: The DMS statement_conversion_tool consistently failed with metadata model creation/conversion timeout errors for all statements, including simple SELECT queries.
- **Schema Mapping**: Successfully obtained from DMS schema_mapping_tool and applied to all manual conversions.
