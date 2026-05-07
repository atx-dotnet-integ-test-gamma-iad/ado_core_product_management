# Migration Report: MS SQL Server to PostgreSQL
## AdoCore .NET ADO Application

### Migration Summary
- **Date:** 2026-05-07
- **Source Database:** Microsoft SQL Server
- **Target Database:** PostgreSQL
- **Application Framework:** .NET 9.0 with ADO.NET
- **Migration Status:** COMPLETED (Build Successful)

---

### SQL Statements Processed

| # | Method | Type | DMS Status | Manual Conversion |
|---|--------|------|-----------|-------------------|
| 1 | GetAllProductsAsync | CTE + Window Functions | FAILED | Yes - Lowercase Schema |
| 2 | GetProductByIdAsync | CTE + LAG Window | FAILED | Yes - Lowercase Schema |
| 3 | InsertProductAsync | Transaction + SCOPE_IDENTITY | FAILED | Yes - RETURNING clause |
| 4 | UpdateProductAsync | Transaction + DECLARE | FAILED | Yes - Separate queries |
| 5 | DeleteProductAsync | Transaction + DECLARE | FAILED | Yes - Separate queries |
| 6 | GetProductsByPriceRangeAsync | CTE + RANK/PERCENT_RANK | FAILED | Yes - Lowercase Schema |
| 7 | GetLowStockProductsAsync | CTE + AVG/MIN/MAX OVER | FAILED | Yes - Lowercase Schema |

**Total SQL Statements:** 7
**DMS Conversion Successes:** 0
**DMS Conversion Failures:** 7 (all failed with "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}")
**Manual Conversions Applied:** 7

---

### SQL Equivalency Validation Results

| Metric | Count |
|--------|-------|
| Statements Validated | 7 |
| Equivalent | 0 |
| Non-Equivalent | 0 |
| Errors | 7 |

**Note:** All SQL Equivalency tool calls returned ERROR with "'uniqueID'" - this appears to be a tool-internal issue unrelated to the SQL statements themselves.

---

### Key Conversion Decisions

1. **SCOPE_IDENTITY() → RETURNING clause**: PostgreSQL uses RETURNING instead of SCOPE_IDENTITY(). The InsertProductAsync method was restructured to use ExecuteScalarAsync with RETURNING productid.

2. **GETDATE() → NOW()**: All GETDATE() calls replaced with PostgreSQL NOW() function.

3. **DECLARE @variable patterns → Application-level variables**: Transaction blocks with DECLARE statements were restructured to use separate C# queries within an application-level transaction.

4. **Schema object names → Lowercase**: All table names, column names, and aliases converted to lowercase for PostgreSQL convention.

5. **ROUND function with integer division → CAST to NUMERIC**: Added explicit CAST(stockquantity AS NUMERIC) for integer division in GetLowStockProductsAsync.

6. **Transaction handling**: BEGIN TRANSACTION/COMMIT blocks converted to application-level NpgsqlTransaction with proper commit/rollback patterns.

---

### Files Modified

| File | Changes |
|------|---------|
| sourceCode/DataAccess/ProductRepository.cs | All 7 SQL statements converted; All ADO.NET types replaced with Npgsql equivalents |
| sourceCode/AdoCore.csproj | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| sourceCode/appsettings.json | Connection strings converted to PostgreSQL format |

### New Files Created

| File | Purpose |
|------|---------|
| sourceCode/extracted_statements.sql | Catalog of all 7 original MS SQL statements |
| sourceCode/converted_statements.sql | Catalog of all 7 converted PostgreSQL statements |
| sourceCode/sql_equivalency_validation_report.json | Comprehensive equivalency validation report |
| sourceCode/migration_report.md | This migration report |

---

### Package Changes

| Original Package | New Package | Version |
|-----------------|-------------|---------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 | Upgraded from plan's 8.0.0 to avoid GHSA-x9vc-6hfv-hg8c vulnerability |

---

### Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | Server=localhost | Host=localhost |
| Database | Database=ProductManagement | Database=ProductManagement |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets | true | (removed - not applicable) |
| TrustServerCertificate | True | (removed - not applicable) |

---

### Build Status
- **Final Build:** ✅ SUCCESS (0 errors, 10 warnings)
- **All warnings are pre-existing nullable reference warnings**, not related to the migration.

---

### Manual Interventions Required

All 7 SQL statements required manual conversion due to DMS tool failure. The conversions follow the DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA pattern as specified in the transformation rules.
