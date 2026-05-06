# DMS Conversion Failure Summary
# Date: 2026-05-06
# All 7 SQL statements failed DMS conversion with the same error

## DMS Error Details
- Tool: dms-mcp___statement_conversion_tool
- Schema: dbo
- Region: us-east-1
- Migration Project: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- Error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
- Error occurred at the "create_metadata_model" workflow step

## Statements Affected (All 7)

### Statement 1: GetAllProductsAsync
- DMS Attempt Timestamp: 2026-05-06T09:43:34.739791
- Manual Conversion Applied: Lowercase schema object names
- Key Changes: Products -> products, ProductId -> productid, etc.

### Statement 2: GetProductByIdAsync  
- DMS Attempt Timestamp: 2026-05-06T09:43:49.647760
- Manual Conversion Applied: Lowercase schema object names
- Key Changes: Products -> products, LAG/OVER syntax preserved (PostgreSQL compatible)

### Statement 3: InsertProductAsync
- DMS Attempt Timestamp: 2026-05-06T09:44:05.409473
- Manual Conversion Applied: Lowercase schema + SCOPE_IDENTITY() -> RETURNING clause, GETDATE() -> NOW()
- Key Changes: DECLARE/SET block removed, INSERT with RETURNING replaces SCOPE_IDENTITY()

### Statement 4: UpdateProductAsync
- DMS Attempt Timestamp: 2026-05-06T09:44:19.993827
- Manual Conversion Applied: Lowercase schema + DECLARE -> multi-statement approach with app-level variables
- Key Changes: GETDATE() -> NOW(), Variables handled at application level

### Statement 5: DeleteProductAsync
- DMS Attempt Timestamp: 2026-05-06T09:44:33.167991
- Manual Conversion Applied: Lowercase schema + DECLARE -> multi-statement approach with app-level variables
- Key Changes: GETDATE() -> NOW(), CASE syntax preserved (PostgreSQL compatible)

### Statement 6: GetProductsByPriceRangeAsync
- DMS Attempt Timestamp: 2026-05-06T09:44:46.793507
- Manual Conversion Applied: Lowercase schema object names
- Key Changes: RANK/PERCENT_RANK syntax preserved (PostgreSQL compatible)

### Statement 7: GetLowStockProductsAsync
- DMS Attempt Timestamp: 2026-05-06T09:45:03.614667
- Manual Conversion Applied: Lowercase schema + added ::numeric cast for integer division
- Key Changes: StockQuantity/AvgStock division needs explicit numeric cast in PostgreSQL

## Conversion Approach
Per the transformation definition: Since DMS FAILED for all statements, manual conversion was applied with:
1. All schema object names converted to lowercase
2. GETDATE() replaced with NOW()
3. SCOPE_IDENTITY() replaced with RETURNING clause
4. DECLARE/SET variable patterns replaced with multi-statement approaches
5. Integer division cases received ::numeric cast
6. Window functions (LAG, AVG OVER, RANK, PERCENT_RANK) preserved as-is (PostgreSQL compatible)
7. CASE expressions preserved as-is (PostgreSQL compatible)
8. Transaction management delegated to application-level code (Npgsql transaction handling)
