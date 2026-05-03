# Migration Report: SQL Server to PostgreSQL

## Summary
This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-05-03  
**Source Database:** Microsoft SQL Server 2019  
**Target Database:** PostgreSQL 13  
**Application Framework:** .NET 9.0 with ADO.NET  

---

## 1. SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 12 |
| **From ProductRepository.cs** | 7 |
| **From SQL Scripts** | 5 |
| **Successfully Converted by DMS** | 0 |
| **Manual Conversion Required** | 12 |
| **Validated as Equivalent** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 12 |

---

## 2. DMS Tool Status

**DMS Statement Conversion Tool:** FAILED for all statements  
**Error:** `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`  
**DMS Schema Mapping Tool:** SUCCESS - successfully provided schema mappings for all tables

### Schema Mappings from DMS:
| Source Table (SQL Server) | Target Table (PostgreSQL) | Target Schema |
|---------------------------|--------------------------|---------------|
| dbo.Products | products | productmanagement_dbo |
| dbo.ProductHistory | producthistory | productmanagement_dbo |
| dbo.ProductStats | productstats | productmanagement_dbo |
| dbo.Categories | categories | productmanagement_dbo |
| dbo.Suppliers | suppliers | productmanagement_dbo |

### Key Type Mappings from DMS:
| SQL Server Type | PostgreSQL Type |
|----------------|----------------|
| int IDENTITY(1,1) | INTEGER GENERATED ALWAYS AS IDENTITY |
| nvarchar(N) | VARCHAR(N) |
| varchar(N) | VARCHAR(N) |
| decimal(18,2) | NUMERIC(18,2) |
| datetime | TIMESTAMP WITHOUT TIME ZONE |
| bit | NUMERIC(1,0) |
| GETDATE() | clock_timestamp() |

---

## 3. SQL Equivalency Tool Status

**Tool Status:** ERROR for all validations  
**Error:** `'uniqueID'` (consistent internal tool error)  
**Note:** All 12 statement pairs were submitted to the tool, all returned ERROR due to tool-side issue.

---

## 4. Conversion Details by Statement

### ProductRepository.cs Statements (7)

| # | Method | Conversion Type | Key Changes |
|---|--------|----------------|-------------|
| 1 | GetAllProductsAsync | Manual (lowercase schema) | Table/column names lowercased, CTE renamed |
| 2 | GetProductByIdAsync | Manual (lowercase schema) | Table/column names lowercased, CTE renamed |
| 3 | InsertProductAsync | Manual (lowercase schema) | SCOPE_IDENTITY() → RETURNING, GETDATE() → NOW(), DECLARE → C# transaction with multiple commands |
| 4 | UpdateProductAsync | Manual (lowercase schema) | DECLARE → C# transaction, GETDATE() → NOW(), table/column names lowercased |
| 5 | DeleteProductAsync | Manual (lowercase schema) | DECLARE → C# transaction, GETDATE() → NOW(), CASE preserved |
| 6 | GetProductsByPriceRangeAsync | Manual (lowercase schema) | Table/column names lowercased, RANK/PERCENT_RANK preserved |
| 7 | GetLowStockProductsAsync | Manual (lowercase schema) | Table/column names lowercased, added CAST for integer division |

### SQL Script Statements (5)

| # | Procedure/Function | Conversion Type | Key Changes |
|---|-------------------|----------------|-------------|
| 8 | sp_GetAllProducts | Manual (lowercase schema) | CREATE OR ALTER PROCEDURE → CREATE OR REPLACE FUNCTION |
| 9 | sp_InsertProduct | Manual (lowercase schema) | SCOPE_IDENTITY() → RETURNING |
| 10 | sp_UpdateProduct | Manual (lowercase schema) | GETDATE() → NOW() |
| 11 | sp_DeleteProduct | Manual (lowercase schema) | Table/column names lowercased |
| 12 | sp_GetProductById | Manual (lowercase schema) | Table/column names lowercased |

---

## 5. Code Changes Summary

### Package Dependencies
| Change | Old | New |
|--------|-----|-----|
| NuGet Package | Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.7 |

### Using Directives
| Change | Old | New |
|--------|-----|-----|
| Import | `using Microsoft.Data.SqlClient;` | `using Npgsql;` |

### ADO.NET Class Replacements
| SQL Server Class | Npgsql Class |
|-----------------|-------------|
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |

### Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server | `Server=localhost` | `Host=localhost` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | (removed - not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | (removed - not applicable) |

---

## 6. SQL Script Conversions

### Scripts/01_InitialSetup.sql
- Converted table creation with PostgreSQL types
- Converted stored procedures to PostgreSQL functions (plpgsql)
- Converted SCOPE_IDENTITY() to RETURNING clause
- Converted GETDATE() to clock_timestamp()/NOW()
- Removed GO statements
- Converted IF NOT EXISTS checks to PostgreSQL syntax

### Database/Scripts/01_InitialSetup.sql
- Converted all 5 tables (Categories, Suppliers, Products, ProductHistory, ProductStats)
- Converted IDENTITY columns to GENERATED ALWAYS AS IDENTITY
- Converted nvarchar to VARCHAR, datetime to TIMESTAMP, bit to NUMERIC(1,0)
- Converted trigger from SQL Server syntax to PostgreSQL trigger function + trigger
- Converted SYSTEM_USER to current_user
- Converted all 5 stored procedures to PostgreSQL functions
- Preserved all indexes, foreign keys, and constraints
- Preserved all sample data inserts

---

## 7. Files Modified

| File | Changes |
|------|---------|
| sourceCode/DataAccess/ProductRepository.cs | All 7 SQL statements converted, ADO.NET classes replaced |
| sourceCode/AdoCore.csproj | Package reference changed to Npgsql 8.0.7 |
| sourceCode/appsettings.json | Connection strings converted to PostgreSQL format |
| sourceCode/Scripts/01_InitialSetup.sql | Fully converted to PostgreSQL syntax |
| sourceCode/Database/Scripts/01_InitialSetup.sql | Fully converted to PostgreSQL syntax |

## 8. Artifacts Generated

| Artifact | Description |
|----------|------------|
| sourceCode/extracted_statements.sql | Catalog of all 7 original MS SQL statements from ProductRepository.cs |
| sourceCode/converted_statements.sql | Catalog of all 7 converted PostgreSQL statements |
| sourceCode/sql_equivalency_validation_report.json | Comprehensive equivalency validation report for all 12 statement pairs |
| sourceCode/migration_report.md | This migration report |

---

## 9. Build Status

**Final Build:** ✅ SUCCESS  
- 0 Errors
- 10 Warnings (pre-existing nullable reference warnings only)
- No vulnerability warnings

---

## 10. Known Issues and Recommendations

1. **DMS Statement Conversion Tool Failure:** The DMS statement conversion tool consistently failed with "Metadata model creation failed" error. All conversions were done manually using DMS schema mapping as reference. Recommend re-running DMS conversion when the tool is available.

2. **SQL Equivalency Tool Failure:** The SQL Equivalency tool consistently returned ERROR with "'uniqueID'" for all statement pairs. Recommend re-validating equivalency when the tool is operational.

3. **Connection String Credentials:** The connection strings use placeholder credentials (`Username=postgres;Password=postgres`). These should be replaced with actual credentials using environment variables or a secure configuration provider before deployment.

4. **Transaction Handling:** The transactional statements (Insert, Update, Delete) were refactored from single SQL with DECLARE/SET to multiple Npgsql commands within C# managed transactions. This maintains atomicity while being compatible with Npgsql's parameterized query model.
