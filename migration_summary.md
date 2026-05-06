# Migration Summary: MS SQL Server to PostgreSQL

## Overview
This document summarizes the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-05-06  
**Source Database:** Microsoft SQL Server 2019  
**Target Database:** PostgreSQL 13  
**Application Framework:** .NET 9.0, ADO.NET  

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL, ADO.NET classes replaced with Npgsql equivalents |
| `AdoCore.csproj` | Package reference changed from Microsoft.Data.SqlClient 5.1.4 to Npgsql 8.0.6 |
| `appsettings.json` | Connection strings updated from SQL Server format to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax |

## Files Created (Migration Artifacts)

| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all original MS SQL statements |
| `converted_statements.sql` | Catalog of all converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `migration_summary.md` | This document |

---

## Package Changes

| Original Package | Version | Replacement Package | Version |
|-----------------|---------|--------------------|---------| 
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.6 |

**Note:** Npgsql 8.0.6 was used instead of 8.0.0 to address known high severity vulnerability GHSA-x9vc-6hfv-hg8c.

---

## Connection String Changes

### Before (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL)
```
Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres
```

### Parameter Mapping
| SQL Server Parameter | PostgreSQL Parameter |
|---------------------|---------------------|
| Server=localhost | Host=localhost |
| (default port 1433) | Port=5432 |
| Database=ProductManagement | Database=ProductManagement |
| Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets=true | (removed - not applicable) |
| TrustServerCertificate=True | (removed - not applicable) |

---

## SQL Statements Converted

### Summary
- **Total Statements Processed:** 7
- **Successfully Converted by DMS:** 0
- **Manually Converted (DMS Failure):** 7
- **Validated as Equivalent:** 0
- **Validated as Non-Equivalent:** 0
- **Equivalency Validation Errors:** 7

### DMS Tool Status
The DMS MCP tool was unavailable during this migration. All 7 statements were passed through the tool and all returned the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Per the transformation definition, manual conversion was applied with lowercase schema object names for PostgreSQL compatibility.

### SQL Equivalency Tool Status
The SQL Equivalency MCP tool was also experiencing issues. All 7 statement pair validations returned ERROR:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

Per the transformation definition, all pairs are marked with ERROR status in the report.

### Statement Details

| # | Method | Key Changes |
|---|--------|-------------|
| 1 | GetAllProductsAsync | Lowercase schema objects in CTE with AVG/COUNT window functions |
| 2 | GetProductByIdAsync | Lowercase schema objects in CTE with LAG window function |
| 3 | InsertProductAsync | SCOPE_IDENTITY() → RETURNING, GETDATE() → NOW(), transaction decomposed |
| 4 | UpdateProductAsync | DECLARE/variable assignment → separate queries, GETDATE() → NOW() |
| 5 | DeleteProductAsync | Same as Update pattern, GETDATE() → NOW() |
| 6 | GetProductsByPriceRangeAsync | Lowercase schema objects, RANK/PERCENT_RANK unchanged (compatible) |
| 7 | GetLowStockProductsAsync | Lowercase schema objects, added CAST for integer division |

---

## Code Changes Summary

### ADO.NET Class Replacements
| SQL Server Class | PostgreSQL (Npgsql) Class |
|-----------------|--------------------------|
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |
| SqlTransaction | NpgsqlTransaction |

### SQL Syntax Changes
| MS SQL Server | PostgreSQL |
|---------------|-----------|
| SCOPE_IDENTITY() | RETURNING clause |
| GETDATE() | NOW() |
| DECLARE @var / SET @var | Application-level variables |
| BEGIN TRANSACTION / COMMIT | Application-managed BeginTransactionAsync/CommitAsync |
| IDENTITY(1,1) | SERIAL |
| NVARCHAR(n) | VARCHAR(n) |
| DATETIME | TIMESTAMP |
| BIT | BOOLEAN |
| GETDATE() default | NOW() default |

### Transaction Management
The original code used SQL-embedded transactions (BEGIN TRANSACTION/COMMIT inside SQL strings). The migrated code uses application-level transaction management via Npgsql's `BeginTransactionAsync()`, `CommitAsync()`, and `RollbackAsync()` methods. This provides:
- Better error handling with try/catch/rollback patterns
- Individual statement execution within the transaction
- PostgreSQL compatibility (no T-SQL variable declarations)

---

## Database Script Changes

### Scripts/01_InitialSetup.sql
- CREATE TABLE with IDENTITY → SERIAL
- Stored procedures → PostgreSQL functions (PL/pgSQL)
- IF NOT EXISTS checks → CREATE TABLE IF NOT EXISTS / DO blocks
- GETDATE() → NOW()

### Database/Scripts/01_InitialSetup.sql (Full schema)
- All tables converted with lowercase names
- IDENTITY → SERIAL
- BIT → BOOLEAN
- NVARCHAR → VARCHAR
- DATETIME → TIMESTAMP
- Trigger converted from T-SQL to PL/pgSQL trigger function
- Stored procedures converted to PL/pgSQL functions
- GO statements removed
- IF EXISTS/IF NOT EXISTS patterns converted to PostgreSQL equivalents

---

## Manual Interventions

All 7 SQL statements required manual intervention due to DMS tool failure. The conversion approach followed these rules per the transformation definition:
1. All schema object names (tables, columns, views) converted to lowercase
2. SQL logic and structure preserved
3. SQL Server-specific functions replaced with PostgreSQL equivalents
4. Transaction management moved to application level

**Reason:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

---

## Build Status
- **Final Build Result:** SUCCESS
- **Errors:** 0
- **Warnings:** 10 (pre-existing nullable reference warnings, not related to migration)

---

## Risk Assessment
- **Low Risk:** SQL syntax conversion for SELECT/INSERT/UPDATE/DELETE operations - these are standard SQL with minor dialect differences
- **Medium Risk:** Transaction block decomposition (Statements 3-5) - changed from single SQL batch to multiple statements in application-managed transaction. Functionally equivalent but different execution pattern.
- **Note:** All equivalency validations returned ERROR due to tool issues, so manual review of converted statements is recommended.
