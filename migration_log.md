# Migration Log: MS SQL Server to PostgreSQL

## DMS Tool Status
**Status**: FAILED (Systemic Error)
**Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
**Impact**: All 7 SQL statements failed DMS conversion. Manual conversion applied for all statements.

## DMS Conversion Attempts

### Statement 1: GetAllProductsAsync()
- **DMS Attempt Timestamp**: 2026-04-18T10:47:40
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Fallback**: Manual conversion with lowercase schema object names
- **Changes Applied**: All table names, column names, and CTE aliases converted to lowercase

### Statement 2: GetProductByIdAsync()
- **DMS Attempt Timestamp**: 2026-04-18T10:48:30
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Fallback**: Manual conversion with lowercase schema object names
- **Changes Applied**: All table names, column names, and CTE aliases converted to lowercase

### Statement 3: InsertProductAsync()
- **DMS Attempt Timestamp**: 2026-04-18T10:48:46
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Fallback**: Manual conversion with lowercase schema object names
- **Changes Applied**:
  - `SCOPE_IDENTITY()` → `RETURNING productid` with CTE + temp table pattern
  - `GETDATE()` → `NOW()`
  - `DECLARE @NewProductId INT` → removed, using temp table for productid
  - `BEGIN TRANSACTION` → `BEGIN`
  - All table/column names converted to lowercase

### Statement 4: UpdateProductAsync()
- **DMS Attempt Timestamp**: 2026-04-18T10:49:00
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Fallback**: Manual conversion with lowercase schema object names
- **Changes Applied**:
  - `DECLARE @OldPrice / @OldStock` → `CREATE TEMPORARY TABLE tmp_old_values AS SELECT ...`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Variable references → subquery from tmp_old_values
  - All table/column names converted to lowercase

### Statement 5: DeleteProductAsync()
- **DMS Attempt Timestamp**: 2026-04-18T10:49:15
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Fallback**: Manual conversion with lowercase schema object names
- **Changes Applied**:
  - `DECLARE @OldPrice / @OldStock` → `CREATE TEMPORARY TABLE tmp_old_values AS SELECT ...`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Variable references → subquery from tmp_old_values
  - All table/column names converted to lowercase

### Statement 6: GetProductsByPriceRangeAsync()
- **DMS Attempt Timestamp**: 2026-04-18T10:49:29
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Fallback**: Manual conversion with lowercase schema object names
- **Changes Applied**: All table names, column names, and CTE aliases converted to lowercase

### Statement 7: GetLowStockProductsAsync()
- **DMS Attempt Timestamp**: 2026-04-18T10:49:44
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Fallback**: Manual conversion with lowercase schema object names
- **Changes Applied**:
  - All table names, column names, and CTE aliases converted to lowercase
  - Added `::numeric` cast for integer division in `ROUND()` to prevent integer truncation

## SQL Equivalency Validation

All 7 statement pairs were submitted to the SQL Equivalency tool. All returned ERROR status with error `'uniqueID'`, indicating a systemic tool issue unrelated to the SQL conversions themselves.

| Statement | Equivalency Status | Tool Error |
|-----------|-------------------|------------|
| 1. GetAllProductsAsync | ERROR | 'uniqueID' |
| 2. GetProductByIdAsync | ERROR | 'uniqueID' |
| 3. InsertProductAsync | ERROR | 'uniqueID' |
| 4. UpdateProductAsync | ERROR | 'uniqueID' |
| 5. DeleteProductAsync | ERROR | 'uniqueID' |
| 6. GetProductsByPriceRangeAsync | ERROR | 'uniqueID' |
| 7. GetLowStockProductsAsync | ERROR | 'uniqueID' |

## Key Conversion Patterns Applied

| MS SQL Pattern | PostgreSQL Equivalent |
|---------------|----------------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` with CTE |
| `GETDATE()` | `NOW()` |
| `DECLARE @var TYPE` | `CREATE TEMPORARY TABLE` pattern |
| `BEGIN TRANSACTION` | `BEGIN` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `IDENTITY(1,1)` | `SERIAL` |
| `BIT` | `BOOLEAN` |
| `DATETIME` | `TIMESTAMP` |
| Integer division in ROUND | `::numeric` cast |
