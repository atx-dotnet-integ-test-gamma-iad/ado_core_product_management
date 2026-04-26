# DMS Conversion Failure Summary Log
# All 7 statements failed DMS conversion with the same error
# Manual conversion applied with lowercase schema object names

## DMS Error (consistent across all 7 statements):
- Status: error
- Error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
- Migration Project: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- Region: us-east-1
- Schema: dbo
- Database: ProductManagement

## Statement 1 (GetAllProductsAsync):
- DMS attempted: Yes (2 attempts)
- DMS result: FAILED
- Manual conversion: Applied lowercase schema objects
- Key changes: ProductStats->productstats, Products->products, ProductId->productid, etc.

## Statement 2 (GetProductByIdAsync):
- DMS attempted: Yes
- DMS result: FAILED
- Manual conversion: Applied lowercase schema objects
- Key changes: Products->products, ProductId->productid, Price->price, etc.

## Statement 3 (InsertProductAsync):
- DMS attempted: Yes
- DMS result: FAILED
- Manual conversion: Applied lowercase schema objects + SQL Server to PostgreSQL syntax
- Key changes: SCOPE_IDENTITY() -> RETURNING clause, GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN, lowercase objects

## Statement 4 (UpdateProductAsync):
- DMS attempted: Yes
- DMS result: FAILED
- Manual conversion: Applied lowercase schema objects + SQL Server to PostgreSQL syntax
- Key changes: GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN, DECLARE @var handling, lowercase objects

## Statement 5 (DeleteProductAsync):
- DMS attempted: Yes
- DMS result: FAILED
- Manual conversion: Applied lowercase schema objects + SQL Server to PostgreSQL syntax
- Key changes: GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN, DECLARE @var handling, lowercase objects

## Statement 6 (GetProductsByPriceRangeAsync):
- DMS attempted: Yes
- DMS result: FAILED
- Manual conversion: Applied lowercase schema objects
- Key changes: Products->products, Price->price, PriceRank->pricerank, etc.

## Statement 7 (GetLowStockProductsAsync):
- DMS attempted: Yes
- DMS result: FAILED
- Manual conversion: Applied lowercase schema objects + CAST for integer division
- Key changes: Products->products, StockQuantity->stockquantity, CAST for ROUND division, etc.
