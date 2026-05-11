# DMS Conversion Summary Log
## SQL Server to PostgreSQL Migration - AdoCore Application

### DMS Tool Status
- **Status**: FAILED for ALL statements
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **All 7 statements** were submitted to the DMS tool and all failed with the same error.
- **Fallback**: Manual conversion applied with lowercase schema mapping per transformation instructions.

---

### Statement 1: GetAllProductsAsync - SELECT with CTE and Window Functions
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion Applied**: Yes
- **Changes**: All schema objects converted to lowercase (Products→products, ProductId→productid, etc.)
- **SQL Features**: CTE, AVG() OVER(), COUNT() OVER(), CASE, ROUND, INNER JOIN - all supported in PostgreSQL

### Statement 2: GetProductByIdAsync - SELECT with CTE and LAG Window Function
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion Applied**: Yes
- **Changes**: All schema objects converted to lowercase, LAG() window function preserved (supported in PostgreSQL)
- **SQL Features**: CTE, LAG() OVER(), CASE, ROUND, LEFT JOIN - all supported in PostgreSQL

### Statement 3: InsertProductAsync - Transaction with INSERT, SCOPE_IDENTITY, UPDATE
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion Applied**: Yes
- **Changes**:
  - SCOPE_IDENTITY() replaced with PostgreSQL RETURNING clause in a writable CTE
  - GETDATE() replaced with NOW()
  - BEGIN TRANSACTION/COMMIT replaced with atomic CTE (single statement, auto-transactional)
  - All schema objects converted to lowercase

### Statement 4: UpdateProductAsync - Transaction with DECLARE, SELECT INTO, UPDATE, INSERT
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion Applied**: Yes
- **Changes**:
  - T-SQL DECLARE @var / SELECT @var = col converted to PL/pgSQL DO block with SELECT INTO
  - GETDATE() replaced with NOW()
  - BEGIN TRANSACTION/COMMIT replaced with DO $$ block (auto-transactional in PostgreSQL)
  - All schema objects converted to lowercase

### Statement 5: DeleteProductAsync - Transaction with DECLARE, SELECT INTO, INSERT, DELETE, UPDATE
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion Applied**: Yes
- **Changes**:
  - T-SQL DECLARE @var / SELECT @var = col converted to PL/pgSQL DO block with SELECT INTO
  - GETDATE() replaced with NOW()
  - BEGIN TRANSACTION/COMMIT replaced with DO $$ block (auto-transactional in PostgreSQL)
  - All schema objects converted to lowercase

### Statement 6: GetProductsByPriceRangeAsync - SELECT with CTE, RANK, PERCENT_RANK
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion Applied**: Yes
- **Changes**: All schema objects converted to lowercase
- **SQL Features**: CTE, RANK() OVER(), PERCENT_RANK() OVER(), BETWEEN, CASE - all supported in PostgreSQL

### Statement 7: GetLowStockProductsAsync - SELECT with CTE, AVG/MIN/MAX Window Functions
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion Applied**: Yes
- **Changes**:
  - All schema objects converted to lowercase
  - Added ::numeric cast for integer division in ROUND() to avoid integer truncation
- **SQL Features**: CTE, AVG/MIN/MAX() OVER(), CASE - all supported in PostgreSQL

---

### SQL Equivalency Validation Status
- **Tool**: sql-equivalency___validate_sql_equivalence
- **Result**: ERROR for all 7 statement pairs
- **Error**: `'uniqueID'`
- **Note**: The equivalency tool returned errors for all validations (independent of DMS failures). Per instructions, all pairs are marked as ERROR status. No agent judgment was used to determine equivalency.

---

### Migration Summary
| Metric | Count |
|--------|-------|
| Total SQL Statements | 7 |
| DMS Successful Conversions | 0 |
| DMS Failed Conversions | 7 |
| Manual Conversions Applied | 7 |
| Equivalency: EQUIVALENT | 0 |
| Equivalency: NOT_EQUIVALENT | 0 |
| Equivalency: ERROR | 7 |
