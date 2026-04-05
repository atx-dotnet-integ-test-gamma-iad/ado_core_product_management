# DMS Conversion Failure Summary Log
# Date: 2026-04-05
# Migration Project: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

## DMS Tool Status
The DMS statement_conversion_tool failed consistently for ALL statements.
4 total attempts were made (including simple "SELECT SCOPE_IDENTITY()" and "SELECT ProductId, Name, Price FROM Products WHERE ProductId = @ProductId").
All failed with the same error: "Metadata model creation failed: {'error': 'Metadata model creation did not complete after N attempts'}"

## DMS Schema Mapping Tool Status
The DMS schema_mapping_tool SUCCEEDED for all 3 tables:
- Products -> products (schema: productmanagement_dbo)
- ProductHistory -> producthistory (schema: productmanagement_dbo)  
- ProductStats -> productstats (schema: productmanagement_dbo)

## Conversion Approach
All 7 statements were manually converted applying:
1. Lowercase schema object naming (tables, columns, aliases) per DMS schema mappings
2. SCOPE_IDENTITY() -> RETURNING clause + currval()
3. GETDATE() -> clock_timestamp() (matching DMS schema mapping defaults)
4. DECLARE @var / SELECT @var = col -> DO $$ DECLARE v_var; SELECT INTO v_var $$
5. BEGIN TRANSACTION/COMMIT -> DO $$ BEGIN/END $$ (implicit transaction in DO block)
6. Integer division in ROUND -> CAST to NUMERIC for proper decimal results

## Statement Conversion Details

### Statement 1: GetAllProductsAsync
- DMS Error: Metadata model creation failed (2 attempts: one with default, one with 30 max_poll)
- Manual Conversion: Lowercase names, renamed CTE alias from ProductStats to productstats_cte to avoid clash with table name
- Reason: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 2: GetProductByIdAsync
- DMS Error: Not individually attempted (same infrastructure failure)
- Manual Conversion: Lowercase names, renamed CTE alias from ProductHistory to producthistory_cte to avoid clash with table name
- Reason: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 3: InsertProductAsync
- DMS Error: Not individually attempted (same infrastructure failure)
- Manual Conversion: Lowercase, SCOPE_IDENTITY() -> RETURNING, GETDATE() -> clock_timestamp(), T-SQL transaction -> DO block
- Reason: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 4: UpdateProductAsync
- DMS Error: Not individually attempted (same infrastructure failure)
- Manual Conversion: Lowercase, DECLARE @var -> DECLARE v_var, SELECT @var=col -> SELECT INTO, GETDATE() -> clock_timestamp()
- Reason: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 5: DeleteProductAsync
- DMS Error: Not individually attempted (same infrastructure failure)
- Manual Conversion: Same as Statement 4, plus CASE expression in UPDATE preserved
- Reason: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 6: GetProductsByPriceRangeAsync
- DMS Error: Not individually attempted (same infrastructure failure)
- Manual Conversion: Lowercase names only (all SQL constructs PostgreSQL-compatible)
- Reason: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 7: GetLowStockProductsAsync
- DMS Error: Not individually attempted (same infrastructure failure)
- Manual Conversion: Lowercase names, CAST(stockquantity AS NUMERIC) for integer division in ROUND
- Reason: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
