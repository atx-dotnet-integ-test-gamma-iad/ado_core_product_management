# SQL Statement Re-integration Mapping Document

## Purpose
This document maps each extracted SQL statement to its exact location in the source code for accurate re-integration after DMS conversion.

---

## Statement 1: GetAllProductsAsync
**Statement ID:** 1  
**Source File:** DataAccess/ProductRepository.cs  
**Method:** GetAllProductsAsync  
**Variable Name:** sql (const string)  
**Line Range:** ~42-67  
**Integration Type:** Direct string constant replacement  
**Notes:** Replace the entire const string sql = @"..." value with converted PostgreSQL statement

---

## Statement 2: GetProductByIdAsync
**Statement ID:** 2  
**Source File:** DataAccess/ProductRepository.cs  
**Method:** GetProductByIdAsync  
**Variable Name:** sql (const string)  
**Line Range:** ~77-104  
**Integration Type:** Direct string constant replacement  
**Notes:** Replace the entire const string sql = @"..." value with converted PostgreSQL statement. Ensure parameter @ProductId is handled correctly.

---

## Statement 3: InsertProductAsync
**Statement ID:** 3  
**Source File:** DataAccess/ProductRepository.cs  
**Method:** InsertProductAsync  
**Variable Name:** sql (const string)  
**Line Range:** ~114-136  
**Integration Type:** Direct string constant replacement with special handling  
**Special Considerations:**
- SCOPE_IDENTITY() must be converted to PostgreSQL RETURNING clause or CURRVAL()
- GETDATE() must be converted to NOW() or CURRENT_TIMESTAMP
- Transaction structure may need adjustment
- The method uses ExecuteScalarAsync to get the new ID - may need to adjust based on DMS conversion
**Notes:** This is a critical conversion - ensure the new product ID is correctly returned to the caller

---

## Statement 4: UpdateProductAsync
**Statement ID:** 4  
**Source File:** DataAccess/ProductRepository.cs  
**Method:** UpdateProductAsync  
**Variable Name:** sql (const string)  
**Line Range:** ~151-181  
**Integration Type:** Direct string constant replacement  
**Special Considerations:**
- DECLARE statements must be converted to PostgreSQL syntax
- GETDATE() must be converted to NOW() or CURRENT_TIMESTAMP
- Variable assignment (SELECT @OldPrice = ...) may need different syntax in PostgreSQL
**Notes:** Uses ExecuteNonQueryAsync - should work the same in PostgreSQL

---

## Statement 5: DeleteProductAsync
**Statement ID:** 5  
**Source File:** DataAccess/ProductRepository.cs  
**Method:** DeleteProductAsync  
**Variable Name:** sql (const string)  
**Line Range:** ~191-219  
**Integration Type:** Direct string constant replacement  
**Special Considerations:**
- DECLARE statements must be converted to PostgreSQL syntax
- GETDATE() must be converted to NOW() or CURRENT_TIMESTAMP
- Variable assignment may need different syntax
- CASE expression in UPDATE should be compatible but verify
**Notes:** Uses ExecuteNonQueryAsync - should work the same in PostgreSQL

---

## Statement 6: GetProductsByPriceRangeAsync
**Statement ID:** 6  
**Source File:** DataAccess/ProductRepository.cs  
**Method:** GetProductsByPriceRangeAsync  
**Variable Name:** sql (const string)  
**Line Range:** ~229-252  
**Integration Type:** Direct string constant replacement  
**Notes:** Replace the entire const string sql = @"..." value. RANK() and PERCENT_RANK() should work in PostgreSQL but verify syntax. Parameters @MinPrice and @MaxPrice need to be handled.

---

## Statement 7: GetLowStockProductsAsync
**Statement ID:** 7  
**Source File:** DataAccess/ProductRepository.cs  
**Method:** GetLowStockProductsAsync  
**Variable Name:** sql (const string)  
**Line Range:** ~262-285  
**Integration Type:** Direct string constant replacement  
**Notes:** Replace the entire const string sql = @"..." value. Multiple window functions (AVG, MIN, MAX OVER()) should work in PostgreSQL. Parameter @Threshold needs to be handled.

---

## Re-integration Procedure

### Step 1: Locate the SQL Statement
Use the line range and method name to find the exact location in the source file.

### Step 2: Verify Statement Context
Ensure you're replacing the correct SQL statement by verifying the variable name and surrounding code.

### Step 3: Replace SQL Text
Replace the entire SQL string content with the DMS-converted PostgreSQL statement.

### Step 4: Handle Schema Changes
If DMS converted schema object names (e.g., Products → public.products), use the new names in the code.

### Step 5: Verify Parameter Handling
Ensure parameter syntax is correct:
- SQL Server uses @ParamName
- PostgreSQL may use $1, $2, $3 (positional) or keep named parameters depending on driver
- Npgsql supports named parameters with : or @ prefix

### Step 6: Verify String Formatting
Maintain the @"..." verbatim string literal format or adjust if needed for PostgreSQL syntax.

### Step 7: Test Compilation
After each replacement, verify the code still compiles (may have type errors initially but syntax should be valid).

---

## Critical Considerations

### SCOPE_IDENTITY() Conversion (Statement 3)
The InsertProductAsync method currently uses:
```csharp
return Convert.ToInt32(await command.ExecuteScalarAsync());
```

After DMS conversion, if the statement uses RETURNING clause:
- Ensure ExecuteScalarAsync() can properly retrieve the returned value
- May need to adjust the SQL or C# code based on DMS output

### Transaction Handling
All transaction blocks (BEGIN TRANSACTION/COMMIT) must be converted to PostgreSQL syntax.
- SQL Server: BEGIN TRANSACTION; ... COMMIT;
- PostgreSQL: BEGIN; ... COMMIT; (or keep as-is if DMS handles it)

### Parameter Syntax
Npgsql driver supports named parameters, so @ParamName should work.
If DMS converts to positional parameters ($1, $2), will need to adjust AddWithValue calls.

### Variable Declarations
SQL Server: DECLARE @VarName TYPE;
PostgreSQL: DECLARE var_name TYPE; (lowercase, no @ prefix in stored procedures/functions)
For inline SQL, may need different approach.

---

## Verification Checklist
- [ ] All 7 SQL statements extracted and cataloged
- [ ] Mapping document created with line numbers and context
- [ ] Special considerations documented for each statement
- [ ] Re-integration procedure defined
- [ ] Critical conversion points identified (SCOPE_IDENTITY, GETDATE, transactions)
