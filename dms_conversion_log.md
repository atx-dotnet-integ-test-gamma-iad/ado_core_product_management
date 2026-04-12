# DMS Conversion Log

## Summary
- **Total Statements Processed**: 7
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7
- **Manual Conversions Required**: 7
- **Conversion Method for All**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## DMS Tool Configuration
- **Migration Project ARN**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Database Name**: ProductManagement
- **Schema Name**: dbo
- **Region**: us-east-1
- **Server Name** (auto-detected): 172.31.83.165

## Common DMS Error
All 7 statements failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```
The DMS metadata model creation consistently returned status "RECEIVED" instead of completing. Multiple retry attempts with increased poll intervals (up to 30 attempts with 15-second intervals) did not resolve the issue.

---

## Statement 1: GetAllProductsAsync

### DMS Attempt
- **Timestamp**: 2026-04-12T17:49:07
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}

### Retry Attempt
- **Timestamp**: 2026-04-12T17:49:25 (with max_poll_attempts=30, poll_interval_seconds=15)
- **Status**: error
- **Error**: Same as above

### Manual Conversion Applied
- Lowercased all schema object names (Products -> products, ProductId -> productid, etc.)
- CTE name ProductStats -> productstats
- SQL logic preserved (AVG/COUNT window functions, CASE/WHEN, ROUND, INNER JOIN, ORDER BY)

---

## Statement 2: GetProductByIdAsync

### DMS Attempt
- **Timestamp**: 2026-04-12T17:49:59
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}

### Manual Conversion Applied
- Lowercased all schema object names
- CTE name ProductHistory -> producthistory_cte (to avoid conflict with table name producthistory)
- SQL logic preserved (LAG window function, ROUND, LEFT JOIN, CASE/WHEN)
- Parameter @ProductId preserved (Npgsql supports @-prefixed parameters)

---

## Statement 3: InsertProductAsync

### DMS Attempt
- **Timestamp**: 2026-04-12T17:50:15
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}

### Manual Conversion Applied
- **Key Changes**:
  - SCOPE_IDENTITY() replaced with INSERT...RETURNING productid pattern
  - GETDATE() replaced with NOW()
  - T-SQL DECLARE/@variable pattern restructured for C# ADO.NET usage
  - Transaction management moved to C# code (BeginTransactionAsync/CommitAsync)
  - Lowercased all schema object names
- The original single SQL block with DECLARE/BEGIN TRANSACTION/COMMIT is restructured into separate SQL statements executed within a C# managed transaction

---

## Statement 4: UpdateProductAsync

### DMS Attempt
- **Timestamp**: 2026-04-12T17:50:32
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}

### Manual Conversion Applied
- **Key Changes**:
  - GETDATE() replaced with NOW()
  - T-SQL DECLARE/@variable pattern restructured - old values fetched via separate SELECT
  - Transaction management moved to C# code
  - Lowercased all schema object names

---

## Statement 5: DeleteProductAsync

### DMS Attempt
- **Timestamp**: 2026-04-12T17:50:47
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}

### Manual Conversion Applied
- **Key Changes**:
  - GETDATE() replaced with NOW()
  - T-SQL DECLARE/@variable pattern restructured - old values fetched via separate SELECT
  - Transaction management moved to C# code
  - CASE/WHEN logic preserved
  - Lowercased all schema object names

---

## Statement 6: GetProductsByPriceRangeAsync

### DMS Attempt
- **Timestamp**: 2026-04-12T17:51:03
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}

### Manual Conversion Applied
- Lowercased all schema object names
- CTE name RankedProducts -> rankedproducts
- SQL logic preserved (RANK, PERCENT_RANK window functions, BETWEEN, CASE/WHEN)
- Parameters @MinPrice, @MaxPrice preserved

---

## Statement 7: GetLowStockProductsAsync

### DMS Attempt
- **Timestamp**: 2026-04-12T17:51:24
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}

### Manual Conversion Applied
- Lowercased all schema object names
- CTE name StockAnalysis -> stockanalysis
- Added CAST(stockquantity AS DECIMAL) for integer division precision in PostgreSQL
- SQL logic preserved (AVG/MIN/MAX window functions, CASE/WHEN, ROUND)
- Parameter @Threshold preserved

---

## SQL Equivalency Validation Summary
All 7 statement pairs were submitted to the SQL Equivalency MCP tool (sql-equivalency___validate_sql_equivalence).
All 7 returned ERROR status with error: "'uniqueID'"
Per transformation definition requirements, all are marked as ERROR in the equivalency report.
