# DMS Conversion Failure Summary

## Overview
All 7 SQL statements from ProductRepository.cs failed DMS statement conversion due to a persistent 
metadata model creation error. Manual conversion was applied using lowercase schema object names 
as per DMS schema mapping results.

## DMS Error Details
- **Tool**: dms-mcp___statement_conversion_tool
- **Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Attempts Per Statement**: Multiple (2-3 attempts each)
- **Total DMS Calls Made**: 10 (including retries with different parameters)

## Schema Mapping (from DMS schema_mapping_tool - SUCCESSFUL)
The DMS schema_mapping_tool worked correctly and provided the following mappings:

### Products Table
- Source: `[dbo].[Products]` → Target: `productmanagement_dbo.products`
- Columns: All lowercase (ProductId → productid, Name → name, etc.)
- IDENTITY → GENERATED ALWAYS AS IDENTITY
- NVARCHAR → VARCHAR
- DECIMAL → NUMERIC
- DATETIME → TIMESTAMP WITHOUT TIME ZONE
- GETDATE() → clock_timestamp()

### ProductHistory Table
- Source: `[dbo].[ProductHistory]` → Target: `productmanagement_dbo.producthistory`
- Columns: All lowercase

### ProductStats Table
- Source: `[dbo].[ProductStats]` → Target: `productmanagement_dbo.productstats`
- Columns: All lowercase

## Conversion Rules Applied
1. All table names → lowercase
2. All column names → lowercase
3. CTE names → lowercase
4. SCOPE_IDENTITY() → LASTVAL()
5. GETDATE() → clock_timestamp()
6. BEGIN TRANSACTION → BEGIN
7. DECLARE @var / SET @var → temp table approach (PostgreSQL doesn't support DECLARE in inline SQL)
8. ROUND, CASE, OVER() window functions → preserved (valid in PostgreSQL)

## Statements Converted

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, Window Functions
- **Conversion**: Table/column names lowercased, syntax preserved (compatible)

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG window function
- **Conversion**: Table/column names lowercased, LAG/OVER preserved

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY, UPDATE
- **Conversion**: SCOPE_IDENTITY() → LASTVAL(), GETDATE() → clock_timestamp(), DECLARE removed

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO vars, UPDATE, INSERT
- **Conversion**: DECLARE → temp table approach, GETDATE() → clock_timestamp()

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, DELETE, CASE in UPDATE
- **Conversion**: DECLARE → temp table approach, GETDATE() → clock_timestamp()

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK, PERCENT_RANK
- **Conversion**: Table/column names lowercased, window functions preserved

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX OVER()
- **Conversion**: Table/column names lowercased, added CAST for integer division

## SQL Equivalency Validation
All 7 statement pairs were submitted to sql-equivalency___validate_sql_equivalence tool.
All returned ERROR with "'uniqueID'" error.
