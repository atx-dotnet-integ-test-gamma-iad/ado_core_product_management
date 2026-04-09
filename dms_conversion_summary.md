# DMS Conversion Summary Report
# Generated: 2026-04-09
# Migration: SQL Server to PostgreSQL
# Source File: DataAccess/ProductRepository.cs

## DMS Tool Status
- DMS Statement Conversion Tool: FAILED (all 7 attempts)
- DMS Schema Mapping Tool: SUCCESS (used to obtain schema mappings)
- Error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"

## Schema Mappings (from DMS schema_mapping_tool - SUCCESSFUL)

### Products Table
- Source: [dbo].[Products] -> Target: productmanagement_dbo.products
- ProductId -> productid (INTEGER GENERATED ALWAYS AS IDENTITY)
- Name -> name (VARCHAR(100))
- Description -> description (VARCHAR(500))
- Price -> price (NUMERIC(18,2))
- StockQuantity -> stockquantity (INTEGER)
- CreatedDate -> createddate (TIMESTAMP WITHOUT TIME ZONE, DEFAULT clock_timestamp())
- ModifiedDate -> modifieddate (TIMESTAMP WITHOUT TIME ZONE)

### ProductHistory Table
- Source: [dbo].[ProductHistory] -> Target: productmanagement_dbo.producthistory
- HistoryId -> historyid (INTEGER GENERATED ALWAYS AS IDENTITY)
- ProductId -> productid (INTEGER)
- Action -> action (VARCHAR(10))
- OldPrice -> oldprice (NUMERIC(18,2))
- NewPrice -> newprice (NUMERIC(18,2))
- OldStock -> oldstock (INTEGER)
- NewStock -> newstock (INTEGER)
- ActionDate -> actiondate (TIMESTAMP WITHOUT TIME ZONE, DEFAULT clock_timestamp())

### ProductStats Table
- Source: [dbo].[ProductStats] -> Target: productmanagement_dbo.productstats
- StatId -> statid (INTEGER, DEFAULT 1)
- TotalProducts -> totalproducts (INTEGER, DEFAULT 0)
- AveragePrice -> averageprice (NUMERIC(18,2), DEFAULT 0)
- LastUpdated -> lastupdated (TIMESTAMP WITHOUT TIME ZONE, DEFAULT clock_timestamp())

## Statement Conversion Details

### Statement 1: GetAllProductsAsync
- DMS Attempt: FAILED - "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
- Manual Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- Changes: All identifiers lowercased, CTE renamed from ProductStats to productstats_cte to avoid conflict with actual table

### Statement 2: GetProductByIdAsync
- DMS Attempt: FAILED - "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
- Manual Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- Changes: All identifiers lowercased, CTE renamed from ProductHistory to producthistory_cte to avoid conflict with actual table

### Statement 3: InsertProductAsync
- DMS Attempt: FAILED - "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
- Manual Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- Changes: SCOPE_IDENTITY() replaced with RETURNING clause, GETDATE() -> clock_timestamp(), DECLARE removed, transaction restructured for Npgsql multi-command execution

### Statement 4: UpdateProductAsync
- DMS Attempt: FAILED - "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
- Manual Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- Changes: DECLARE removed (variables handled in C# code), GETDATE() -> clock_timestamp(), all identifiers lowercased

### Statement 5: DeleteProductAsync
- DMS Attempt: FAILED - "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
- Manual Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- Changes: DECLARE removed (variables handled in C# code), GETDATE() -> clock_timestamp(), all identifiers lowercased

### Statement 6: GetProductsByPriceRangeAsync
- DMS Attempt: FAILED - "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
- Manual Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- Changes: All identifiers lowercased

### Statement 7: GetLowStockProductsAsync
- DMS Attempt: FAILED - "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
- Manual Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- Changes: All identifiers lowercased, added ::NUMERIC cast for integer division in ROUND function

## SQL Equivalency Validation
- Tool: sql-equivalency___validate_sql_equivalence
- All 7 statement pairs returned ERROR with: "'uniqueID'"
- This appears to be a tool infrastructure issue, not related to statement quality
- All statements marked as ERROR per the transformation definition requirements
