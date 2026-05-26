# SQL Server to PostgreSQL Migration - DMS Conversion Summary

## DMS Tool Failure Documentation

All 7 SQL statements were submitted to the DMS MCP tool (dms-mcp___statement_conversion_tool) for conversion.
All 7 attempts failed with the same error.

### DMS Error Details
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Region**: us-east-1
- **Server**: 172.31.83.165
- **Database**: ProductManagement
- **Schema**: dbo

### Manual Conversion Applied
Since DMS failed for all statements, manual conversion was applied with the following rules:
- All schema object names converted to lowercase (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- SCOPE_IDENTITY() replaced with INSERT...RETURNING
- GETDATE() replaced with NOW()
- T-SQL DECLARE/SET variable patterns replaced with PostgreSQL writable CTEs
- BEGIN TRANSACTION/COMMIT blocks replaced with CTE-based atomic operations
- CAST(x AS DECIMAL) converted to CAST(x AS NUMERIC)

### SQL Equivalency Validation
All 7 statement pairs were submitted to the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence).
All 7 validations returned ERROR with: "'uniqueID'"

## Statements Processed

| # | Method | Source | DMS Status | Equivalency Status |
|---|--------|--------|------------|-------------------|
| 1 | GetAllProductsAsync | ProductRepository.cs | FAILED | ERROR |
| 2 | GetProductByIdAsync | ProductRepository.cs | FAILED | ERROR |
| 3 | InsertProductAsync | ProductRepository.cs | FAILED | ERROR |
| 4 | UpdateProductAsync | ProductRepository.cs | FAILED | ERROR |
| 5 | DeleteProductAsync | ProductRepository.cs | FAILED | ERROR |
| 6 | GetProductsByPriceRangeAsync | ProductRepository.cs | FAILED | ERROR |
| 7 | GetLowStockProductsAsync | ProductRepository.cs | FAILED | ERROR |

## Key Conversion Changes

### SQL Syntax Changes
| MS SQL Server | PostgreSQL |
|--------------|------------|
| SCOPE_IDENTITY() | INSERT...RETURNING |
| GETDATE() | NOW() |
| DECLARE @var / SET @var | Writable CTEs |
| BEGIN TRANSACTION/COMMIT | Writable CTEs (atomic) |
| CAST(x AS DECIMAL) | CAST(x AS NUMERIC) |

### Schema Object Name Changes (lowercase)
| MS SQL Server | PostgreSQL |
|--------------|------------|
| Products | products |
| ProductId | productid |
| ProductHistory | producthistory |
| ProductStats | productstats |
| StockQuantity | stockquantity |
| CreatedDate | createddate |
| ModifiedDate | modifieddate |
| AveragePrice | averageprice |
| TotalProducts | totalproducts |
| LastUpdated | lastupdated |

### Static Code Changes
| Component | MS SQL Server | PostgreSQL |
|-----------|--------------|------------|
| Package | Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.1 |
| Connection | SqlConnection | NpgsqlConnection |
| Command | SqlCommand | NpgsqlCommand |
| Reader | SqlDataReader | NpgsqlDataReader |
| Parameter | SqlParameter (AddWithValue) | NpgsqlParameter (AddWithValue) |
| Connection String | Server=localhost;Database=...;Trusted_Connection=True | Host=localhost;Database=...;Username=postgres;Password=postgres |
