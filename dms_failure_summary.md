# DMS Conversion Failure Summary

## Overview
All 7 SQL statements failed DMS statement_conversion_tool conversion.
All 7 statements were manually converted using lowercase schema object names per transformation definition rules.
Schema mapping was obtained successfully from DMS schema_mapping_tool.

## DMS Error (Consistent Across All 7 Statements)
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

## Schema Mapping (from DMS schema_mapping_tool - SUCCESS)
| Source (MS SQL)     | Target (PostgreSQL)            |
|---------------------|-------------------------------|
| dbo.Products        | productmanagement_dbo.products |
| dbo.ProductHistory  | productmanagement_dbo.producthistory |
| dbo.ProductStats    | productmanagement_dbo.productstats |
| ProductId           | productid                      |
| Name                | name                           |
| Description         | description                    |
| Price               | price                          |
| StockQuantity       | stockquantity                  |
| CreatedDate         | createddate                    |
| ModifiedDate        | modifieddate                   |
| GETDATE()           | clock_timestamp()              |
| IDENTITY(1,1)       | GENERATED ALWAYS AS IDENTITY   |
| DATETIME            | TIMESTAMP WITHOUT TIME ZONE    |
| DECIMAL(18,2)       | NUMERIC(18,2)                  |
| NVARCHAR            | VARCHAR                        |

## Statements Processed

### Statement 1: GetAllProductsAsync
- DMS Attempt: FAILED
- Manual Conversion: Applied lowercase schema (tables, columns, aliases)
- Key Changes: All identifiers lowercased

### Statement 2: GetProductByIdAsync
- DMS Attempt: FAILED
- Manual Conversion: Applied lowercase schema (tables, columns, aliases)
- Key Changes: All identifiers lowercased

### Statement 3: InsertProductAsync
- DMS Attempt: FAILED
- Manual Conversion: SCOPE_IDENTITY() -> RETURNING clause with CTE approach, GETDATE() -> clock_timestamp()
- Key Changes: Complete restructure from DECLARE/SET/BEGIN TRANSACTION to CTE with RETURNING

### Statement 4: UpdateProductAsync
- DMS Attempt: FAILED
- Manual Conversion: DECLARE variables -> CTE with old_values, GETDATE() -> clock_timestamp()
- Key Changes: Complete restructure from DECLARE/SET to CTE-based approach

### Statement 5: DeleteProductAsync
- DMS Attempt: FAILED
- Manual Conversion: DECLARE variables -> CTE with old_values, GETDATE() -> clock_timestamp()
- Key Changes: Complete restructure from DECLARE/SET to CTE-based approach

### Statement 6: GetProductsByPriceRangeAsync
- DMS Attempt: FAILED
- Manual Conversion: Applied lowercase schema (tables, columns, aliases)
- Key Changes: All identifiers lowercased

### Statement 7: GetLowStockProductsAsync
- DMS Attempt: FAILED
- Manual Conversion: Applied lowercase schema, added ::NUMERIC cast for integer division
- Key Changes: All identifiers lowercased, explicit numeric cast for ROUND operation

## SQL Equivalency Validation
All 7 statement pairs were submitted to the SQL Equivalency tool.
All 7 returned ERROR with: `{'error': "'uniqueID'"}`
Per transformation definition, all marked as ERROR status.
