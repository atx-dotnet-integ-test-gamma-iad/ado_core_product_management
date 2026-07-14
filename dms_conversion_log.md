# DMS Conversion Summary Log

## Overview
- Total SQL Statements: 7
- DMS Successfully Converted: 0
- DMS Failed (Manual Conversion Required): 7
- DMS Error: "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}"

## Manual Conversion Rules Applied
Since DMS failed for all statements, manual conversion was performed with:
- All schema object names (tables, columns, aliases) converted to lowercase
- SCOPE_IDENTITY() → lastval()
- GETDATE() → NOW()
- BEGIN TRANSACTION → BEGIN
- DECLARE @var / SET @var → Replaced with subqueries where applicable
- Integer division cast to numeric where needed (::numeric)
- Conversion method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## Statement-by-Statement Log

### Statement 1: GetAllProductsAsync (SELECT with CTE)
- Source: ProductRepository.cs, GetAllProductsAsync method
- DMS Input: CTE with window functions (AVG, COUNT OVER())
- DMS Output: ERROR - Metadata model creation failed
- Manual Conversion: Lowercase schema objects, syntax compatible as-is with PostgreSQL

### Statement 2: GetProductByIdAsync (SELECT with CTE + LAG)
- Source: ProductRepository.cs, GetProductByIdAsync method
- DMS Input: CTE with LAG window function
- DMS Output: ERROR - Metadata model creation failed
- Manual Conversion: Lowercase schema objects, syntax compatible as-is with PostgreSQL

### Statement 3: InsertProductAsync (Transaction with INSERT)
- Source: ProductRepository.cs, InsertProductAsync method
- DMS Input: DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(), GETDATE()
- DMS Output: ERROR - Metadata model creation failed
- Manual Conversion: SCOPE_IDENTITY() → lastval(), GETDATE() → NOW(), BEGIN TRANSACTION → BEGIN, removed DECLARE/SET variables

### Statement 4: UpdateProductAsync (Transaction with UPDATE)
- Source: ProductRepository.cs, UpdateProductAsync method
- DMS Input: BEGIN TRANSACTION, DECLARE, SELECT INTO vars, UPDATE, INSERT, GETDATE()
- DMS Output: ERROR - Metadata model creation failed
- Manual Conversion: Removed DECLARE/variable assignment, used subqueries for old values, GETDATE() → NOW(), BEGIN TRANSACTION → BEGIN

### Statement 5: DeleteProductAsync (Transaction with DELETE)
- Source: ProductRepository.cs, DeleteProductAsync method
- DMS Input: BEGIN TRANSACTION, DECLARE, SELECT INTO vars, INSERT, DELETE, GETDATE()
- DMS Output: ERROR - Metadata model creation failed
- Manual Conversion: Removed DECLARE/variable assignment, used subqueries for old values, GETDATE() → NOW(), BEGIN TRANSACTION → BEGIN

### Statement 6: GetProductsByPriceRangeAsync (SELECT with CTE + RANK)
- Source: ProductRepository.cs, GetProductsByPriceRangeAsync method
- DMS Input: CTE with RANK() and PERCENT_RANK() window functions
- DMS Output: ERROR - Metadata model creation failed
- Manual Conversion: Lowercase schema objects, syntax compatible as-is with PostgreSQL

### Statement 7: GetLowStockProductsAsync (SELECT with CTE + aggregates)
- Source: ProductRepository.cs, GetLowStockProductsAsync method
- DMS Input: CTE with AVG, MIN, MAX window functions
- DMS Output: ERROR - Metadata model creation failed
- Manual Conversion: Lowercase schema objects, added ::numeric cast for integer division in ROUND

## SQL Equivalency Validation
- Tool Used: sql-equivalency___validate_sql_equivalence
- All 7 statement pairs returned ERROR status with error: "'uniqueID'"
- Status recorded as ERROR per transformation instructions
