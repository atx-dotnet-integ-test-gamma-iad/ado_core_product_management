# DMS Conversion Log

## Summary
- **DMS Migration Project ARN**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Source Database**: ProductManagement (SQL Server 2019)
- **Target Database**: PostgreSQL 13
- **Total Statements Attempted**: 7
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7
- **Manual Conversions Required**: 7

All 7 statements failed DMS conversion due to metadata model creation/conversion timeout errors. Manual conversion was applied using lowercase schema object naming conventions per the transformation definition fallback rules.

---

## Statement 1: GetAllProductsAsync

**DMS Input**: CTE with AVG/COUNT window functions, CASE expressions, ROUND, INNER JOIN, ORDER BY with CASE

**DMS Output**:
```json
{
  "status": "error",
  "error": "Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}",
  "error_timestamp": "2026-03-31T02:12:20.887566"
}
```

**Manual Conversion Applied**: Lowercase all schema object names (Products → products, ProductId → productid, etc.). SQL syntax (CTE, window functions, CASE, ROUND, INNER JOIN) is fully compatible with PostgreSQL.

**Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

---

## Statement 2: GetProductByIdAsync

**DMS Input**: CTE with LAG window function, ROUND, LEFT JOIN, parameterized WHERE

**DMS Output**:
```json
{
  "status": "error",
  "error": "Command execution timed out after 300 seconds"
}
```

**Manual Conversion Applied**: Lowercase all schema object names. SQL syntax (CTE, LAG window function, ROUND, LEFT JOIN) is fully compatible with PostgreSQL.

**Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

---

## Statement 3: InsertProductAsync

**DMS Input**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), INSERT into ProductHistory, UPDATE ProductStats, GETDATE()

**DMS Output**:
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}",
  "error_timestamp": "2026-03-31T02:24:04.366233"
}
```

**Manual Conversion Applied**:
- Lowercase all schema object names
- `SCOPE_IDENTITY()` → `RETURNING productid` + `lastval()`
- `GETDATE()` → `NOW()`
- `BEGIN TRANSACTION` / `COMMIT` → `BEGIN` / `COMMIT`
- Removed `DECLARE @NewProductId INT` and `SET @NewProductId = SCOPE_IDENTITY()` - used `RETURNING` clause instead
- Removed final `SELECT @NewProductId` - the `RETURNING` clause handles this

**Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

---

## Statement 4: UpdateProductAsync

**DMS Input**: Transaction block with DECLARE variables, SELECT INTO variables, UPDATE, INSERT, GETDATE()

**DMS Output**:
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}",
  "error_timestamp": "2026-03-31T02:26:50.794944"
}
```

**Manual Conversion Applied**:
- Lowercase all schema object names
- `BEGIN TRANSACTION` / `COMMIT` → `DO $$ ... END $$` anonymous block
- `DECLARE @OldPrice DECIMAL(18,2)` → `DECLARE v_oldprice NUMERIC(18,2)`
- `DECLARE @OldStock INT` → `DECLARE v_oldstock INT`
- `SELECT @OldPrice = Price, @OldStock = StockQuantity` → `SELECT price, stockquantity INTO v_oldprice, v_oldstock`
- `GETDATE()` → `NOW()`
- Variable references `@OldPrice` → `v_oldprice`, `@OldStock` → `v_oldstock`

**Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

---

## Statement 5: DeleteProductAsync

**DMS Input**: Transaction block with DECLARE, SELECT INTO, INSERT, DELETE, CASE expression, GETDATE()

**DMS Output**:
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}",
  "error_timestamp": "2026-03-31T02:29:37.596762"
}
```

**Manual Conversion Applied**:
- Lowercase all schema object names
- `BEGIN TRANSACTION` / `COMMIT` → `DO $$ ... END $$` anonymous block
- `DECLARE @OldPrice DECIMAL(18,2)` → `DECLARE v_oldprice NUMERIC(18,2)`
- `DECLARE @OldStock INT` → `DECLARE v_oldstock INT`
- `SELECT @OldPrice = Price, @OldStock = StockQuantity` → `SELECT price, stockquantity INTO v_oldprice, v_oldstock`
- `GETDATE()` → `NOW()`
- Variable references `@OldPrice` → `v_oldprice`, `@OldStock` → `v_oldstock`
- CASE expression syntax preserved (compatible with PostgreSQL)

**Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

---

## Statement 6: GetProductsByPriceRangeAsync

**DMS Input**: CTE with RANK() and PERCENT_RANK() window functions, BETWEEN, CASE

**DMS Output**:
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}",
  "error_timestamp": "2026-03-31T02:32:29.324319"
}
```

**Manual Conversion Applied**: Lowercase all schema object names. SQL syntax (CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE) is fully compatible with PostgreSQL.

**Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

---

## Statement 7: GetLowStockProductsAsync

**DMS Input**: CTE with AVG/MIN/MAX window functions, CASE, ROUND

**DMS Output**:
```json
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}",
  "error_timestamp": "2026-03-31T02:35:17.106681"
}
```

**Manual Conversion Applied**:
- Lowercase all schema object names
- Added `::NUMERIC` cast to `stockquantity` in ROUND division to prevent integer division truncation
- SQL syntax (CTE, AVG/MIN/MAX window functions, CASE) is fully compatible with PostgreSQL

**Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
