# DMS Failures Summary

## Overview
- **Total Statements Processed**: 15
- **DMS Successful Conversions**: 15
- **DMS Failed Conversions**: 0

## Notes

### Statement 3 - INSERT with SCOPE_IDENTITY
- **Status**: DMS succeeded but partial conversion
- **Issue**: DMS converted `SCOPE_IDENTITY()` to `SCOPE_IDENTITY` (removed parentheses) but did not convert it to PostgreSQL's `RETURNING` clause
- **DMS Output**: `INSERT INTO productmanagement_dbo.products (...) VALUES (...); SELECT SCOPE_IDENTITY;`
- **Resolution**: During re-integration, the `SELECT SCOPE_IDENTITY;` portion will be replaced with PostgreSQL `RETURNING productid` clause. This is documented since DMS technically succeeded but the output requires adaptation for PostgreSQL.
- **Category**: DMS_TOOL (DMS succeeded, adaptation needed for re-integration)

## Key Schema Mappings by DMS
- `dbo.Products` → `productmanagement_dbo.products`
- `dbo.ProductHistory` → `productmanagement_dbo.producthistory`
- `dbo.ProductStats` → `productmanagement_dbo.productstats`
- `GETDATE()` → `clock_timestamp()`
- All column names → lowercase
- Added `NULLS FIRST` to ORDER BY clauses where applicable
- `SCOPE_IDENTITY()` → `SCOPE_IDENTITY` (partial - needs RETURNING clause adaptation)
