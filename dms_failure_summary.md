# DMS Conversion Failure Summary
## Date: 2026-04-07
## Migration Project: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

### Summary
All 7 SQL statements were submitted to the DMS MCP tool (dms-mcp___statement_conversion_tool) for conversion.
All 7 attempts failed with the same error. Total DMS attempts: 8 (1 extra simple test query).

### DMS Error (Consistent Across All Attempts)
```
Status: error
Error: "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}"
```

### DMS Attempts Log

#### Attempt 1 - Statement 1 (GetAllProducts CTE)
- Timestamp: 2026-04-07T10:39:39
- Status: error (metadata model conversion timeout after 15 attempts)
- Retry with max_poll_attempts=30: Command execution timed out after 300 seconds

#### Attempt 2 - Simple test query (SELECT ... FROM Products)
- Timestamp: 2026-04-07T10:47:47
- Status: error (metadata model creation timeout after 25 attempts)

#### Attempt 3 - Simple test query (SELECT GETDATE())
- Timestamp: 2026-04-07T10:52:23
- Status: error (metadata model creation timeout after 15 attempts)

#### Attempt 4 - Statement 2 (GetProductById CTE with LAG)
- Timestamp: 2026-04-07T10:55:50
- Status: error (metadata model creation timeout after 15 attempts)

#### Attempt 5 - Statement 3 (InsertProduct Transaction Block)
- Timestamp: 2026-04-07T10:58:41
- Status: error (metadata model creation timeout after 15 attempts)

#### Attempt 6 - Statement 4 (UpdateProduct Transaction Block)
- Timestamp: 2026-04-07T11:01:28
- Status: error (metadata model creation timeout after 15 attempts)

#### Attempt 7 - Statement 5 (DeleteProduct Transaction Block)
- Timestamp: 2026-04-07T11:04:17
- Status: error (metadata model creation timeout after 15 attempts)

#### Attempt 8 - Statement 6 (GetProductsByPriceRange CTE)
- Timestamp: 2026-04-07T11:07:04
- Status: error (metadata model creation timeout after 15 attempts)

#### Attempt 9 - Statement 7 (GetLowStockProducts CTE)
- Timestamp: 2026-04-07T11:09:52
- Status: error (metadata model creation timeout after 15 attempts)

### Manual Conversion Applied
Since DMS was unavailable, manual conversion was applied per transformation definition rules:
- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- All schema object names converted to lowercase
- GETDATE() -> NOW()
- SCOPE_IDENTITY() -> RETURNING clause with lastval()
- BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT
- DECLARE @var patterns adapted for PostgreSQL compatibility
- Window functions (LAG, RANK, PERCENT_RANK, AVG, COUNT, MIN, MAX) preserved (compatible)
- CASE expressions preserved (compatible)
- ROUND function preserved (compatible)

### Statements Converted

| # | Method | Original Statement | Converted Statement |
|---|--------|-------------------|-------------------|
| 1 | GetAllProductsAsync | CTE with AVG/COUNT OVER() | Lowercased schema objects |
| 2 | GetProductByIdAsync | CTE with LAG OVER() | Lowercased schema objects |
| 3 | InsertProductAsync | Transaction with SCOPE_IDENTITY/GETDATE | RETURNING + NOW() |
| 4 | UpdateProductAsync | Transaction with DECLARE/GETDATE | BEGIN/COMMIT + NOW() |
| 5 | DeleteProductAsync | Transaction with DECLARE/GETDATE/CASE | BEGIN/COMMIT + NOW() |
| 6 | GetProductsByPriceRangeAsync | CTE with RANK/PERCENT_RANK | Lowercased schema objects |
| 7 | GetLowStockProductsAsync | CTE with AVG/MIN/MAX OVER() | Lowercased schema objects |
