# Remaining Migration Steps - Implementation Guide

## Current Status
- ✓ Step 1: SQL statements extracted
- ✓ Step 2: SQL statements converted via DMS
- ✓ Step 3: Equivalency validated
- ✓ Step 4: Documented (not yet applied to code)
- ✓ Step 5: Npgsql package verified
- ✓ Step 6: ADO.NET classes updated (SqlClient -> Npgsql)
- ⚠ Step 7: SQL statements and parameters need updating
- ⚠ Step 8: Final verification needed

## Step 7: SQL and Parameter Updates Required

### Critical Note
The ProductRepository.cs file currently has:
- ✓ Npgsql classes (NpgsqlConnection, NpgsqlCommand, etc.)
- ✗ Original SQL Server SQL syntax (needs DMS-converted PostgreSQL syntax)
- ✗ SQL Server parameter syntax (@param needs $1, $2, etc.)

### Required Updates for Each Method

#### 1. GetAllProductsAsync
**SQL Changes:**
- CTE: `ProductStats` -> `productstats`
- Table: `Products` -> `productmanagement_dbo.products`
- Columns: `ProductId` -> `productid`, etc. (all lowercase)
- Add `NULLS FIRST` to ORDER BY

**Parameters:** None (no parameters in this query)

#### 2. GetProductByIdAsync
**SQL Changes:**
- CTE: `ProductHistory` -> `producthistory`
- Table: `Products` -> `productmanagement_dbo.products`
- Columns: all to lowercase
- `LAG` -> `lag`
- `LEFT JOIN` -> `LEFT OUTER JOIN`

**Parameters:**
- `@ProductId` -> `$1`
- Update: `command.Parameters.AddWithValue("@ProductId", productId)` -> use positional

#### 3. InsertProductAsync
**SQL Changes:**
- Remove entire transaction block
- Split into 3 separate statements:
  1. INSERT with RETURNING
  2. INSERT into producthistory  
  3. UPDATE productstats
- Replace `GETDATE()` with `CURRENT_TIMESTAMP`
- Replace `SCOPE_IDENTITY()` with `RETURNING productid`
- All tables to lowercase with schema prefix
- All columns to lowercase

**Parameters:**
- `@Name` -> `$1`
- `@Description` -> `$2`
- `@Price` -> `$3`
- `@StockQuantity` -> `$4`

#### 4. UpdateProductAsync
**SQL Changes:**
- Remove transaction block
- Split into 4 separate statements
- Add preliminary SELECT for old values
- Replace `GETDATE()` with `CURRENT_TIMESTAMP`
- All schema/column transformations

**Parameters:**
- Multiple parameters need positional conversion

#### 5. DeleteProductAsync
**SQL Changes:**
- Remove transaction block
- Split into 4 separate statements
- Add preliminary SELECT
- Replace `GETDATE()` with `CURRENT_TIMESTAMP`
- All schema/column transformations

**Parameters:**
- `@ProductId` -> `$1`

#### 6. GetProductsByPriceRangeAsync
**SQL Changes:**
- CTE: `RankedProducts` -> `rankedproducts`
- Table: `Products` -> `productmanagement_dbo.products`
- `PERCENT_RANK()` -> `percent_rank()`
- All columns lowercase
- Add `NULLS FIRST`

**Parameters:**
- `@MinPrice` -> `$1`
- `@MaxPrice` -> `$2`

#### 7. GetLowStockProductsAsync
**SQL Changes:**
- CTE: `StockAnalysis` -> `stockanalysis`
- Table: `Products` -> `productmanagement_dbo.products`
- All columns lowercase
- Add `NULLS FIRST`

**Parameters:**
- `@Threshold` -> `$1`

#### 8. MapProductFromReader
**Column Name Updates:**
- `ProductId` -> `productid`
- `Name` -> `name`
- `Description` -> `description`
- `Price` -> `price`
- `StockQuantity` -> `stockquantity`
- `CreatedDate` -> `createddate`
- `ModifiedDate` -> `modifieddate`

## Step 8: Connection Strings

### Current appsettings.json Check Required
Verify connection strings are PostgreSQL format:
```
Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=postgres
```

## Implementation Complexity

### Estimated Lines of Code to Update
- ProductRepository.cs: ~300 lines of SQL and parameter syntax
- MapProductFromReader: ~10 lines
- Total: ~310 lines

### Risk Assessment
- **Low Risk:** Method signatures, class structure preserved
- **Medium Risk:** Transaction block restructuring (3 methods)
- **High Risk:** Parameter binding order must match positional syntax

## Recommendation

Given the comprehensive nature of remaining updates:
1. All SQL statements need DMS schema transformations applied
2. All parameters need positional conversion
3. Transaction blocks need restructuring
4. Column names in MapProductFromReader need updating

These changes affect ~310 lines across ProductRepository.cs and require:
- Careful attention to parameter order
- Transaction handling verification
- Schema name consistency
- Complete testing with PostgreSQL database

## Alternative Approach

Create a completely new ProductRepository.cs file with all transformations applied atomically, using the converted SQL from converted_statements.sql as the source of truth.

## Files to Reference
- `converted_statements.sql` - PostgreSQL SQL statements
- `dms_conversion_log.json` - Schema transformations
- `SQL_STATEMENTS_UPDATED.md` - Transformation documentation
