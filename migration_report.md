# Migration Report: MS SQL Server to PostgreSQL
## ADO.NET Application Migration (AdoCore)

### Report Date
2026-04-22

### Migration Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS MCP Tool | 0 |
| Requiring Manual Intervention (DMS Failure) | 7 |
| Validated as Equivalent (SQL Equivalency Tool) | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Validation Errors | 7 |

---

### DMS Tool Status

**DMS Statement Conversion Tool (`dms-mcp___statement_conversion_tool`)**:
- Status: **FAILED** for all 7 statements
- Error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- The tool was invoked 4 times with different parameters, all failing with the same error
- Migration Project ARN: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

**DMS Schema Mapping Tool (`dms-mcp___schema_mapping_tool`)**:
- Status: **SUCCEEDED** for all 3 tables
- Provided accurate target schema mappings used for manual conversion
- Target schema: `productmanagement_dbo`
- Confirmed all identifiers converted to lowercase

**SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`)**:
- Status: **ERROR** for all 7 statement pairs
- Error: `'uniqueID'` (tool-level error, not statement-specific)
- All 7 pairs individually submitted to the tool
- Per transformation rules, all marked as ERROR (no agent judgment used)

---

### Schema Mapping (from DMS Schema Mapping Tool)

| Source Table | Target Table | Target Schema |
|-------------|-------------|---------------|
| `[dbo].[Products]` | `products` | `productmanagement_dbo` |
| `[dbo].[ProductHistory]` | `producthistory` | `productmanagement_dbo` |
| `[dbo].[ProductStats]` | `productstats` | `productmanagement_dbo` |

---

### Statement Conversion Details

#### Statement 1: GetAllProductsAsync
- **Method**: `GetAllProductsAsync()`
- **Type**: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: CTE renamed to `productstats_cte` to avoid conflict with table name, all identifiers lowercase
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)

#### Statement 2: GetProductByIdAsync
- **Method**: `GetProductByIdAsync(int productId)`
- **Type**: SELECT with CTE, LAG Window Function, Parameterized (@ProductId), CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: CTE renamed to `producthistory_cte`, all identifiers lowercase, LAG preserved
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)

#### Statement 3: InsertProductAsync
- **Method**: `InsertProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, SCOPE_IDENTITY(), INSERT, UPDATE, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: SCOPE_IDENTITY() → INSERT ... RETURNING via writable CTEs, GETDATE() → NOW(), transaction restructured as atomic CTE chain
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)

#### Statement 4: UpdateProductAsync
- **Method**: `UpdateProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, SELECT into variables, UPDATE, INSERT, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: DECLARE/SET → writable CTEs with old_values capture, GETDATE() → NOW()
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)

#### Statement 5: DeleteProductAsync
- **Method**: `DeleteProductAsync(int productId)`
- **Type**: Transaction block with DECLARE, SELECT into variables, INSERT, DELETE, UPDATE with CASE, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: DECLARE/SET → writable CTEs, DELETE RETURNING, CASE expression preserved, GETDATE() → NOW()
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)

#### Statement 6: GetProductsByPriceRangeAsync
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK() Window Functions, BETWEEN, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: All identifiers lowercase, window functions preserved (native PG support)
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)

#### Statement 7: GetLowStockProductsAsync
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: All identifiers lowercase, added CAST for integer division, window functions preserved
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)

---

### Statements Requiring Manual Review

All 7 statements require manual review due to:
1. **DMS tool failure** - statements were manually converted using schema mapping information from DMS
2. **SQL Equivalency tool error** - all validations returned ERROR, preventing automated equivalency verification

**Recommended Manual Review Actions:**
- Verify each SQL statement against a live PostgreSQL database
- Ensure writable CTEs (statements 3, 4, 5) execute correctly with proper transaction isolation
- Verify parameter binding works correctly with Npgsql for all `@ParamName` parameters
- Test ROUND function behavior with NUMERIC types in PostgreSQL

---

### Code Changes Summary

#### Files Modified
1. **DataAccess/ProductRepository.cs**
   - 7 SQL statements converted to PostgreSQL syntax
   - `using Microsoft.Data.SqlClient` → `using Npgsql`
   - `SqlConnection` → `NpgsqlConnection`
   - `SqlCommand` → `NpgsqlCommand`
   - `SqlDataReader` → `NpgsqlDataReader`
   - All method signatures preserved (public API unchanged)

2. **AdoCore.csproj**
   - Removed: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
   - Added: `<PackageReference Include="Npgsql" Version="8.0.6" />`

3. **appsettings.json**
   - Connection strings updated from SQL Server format to PostgreSQL format
   - `Server=` → `Host=`
   - Removed SQL Server-specific parameters (Trusted_Connection, MultipleActiveResultSets, TrustServerCertificate)
   - Added PostgreSQL authentication (Username, Password)

#### Files Created
1. **extracted_statements.sql** - Complete catalog of all 7 original MS SQL statements
2. **converted_statements.sql** - Complete catalog of all 7 converted PostgreSQL statements
3. **sql_equivalency_validation_report.json** - Comprehensive equivalency validation report
4. **dms_conversion_summary.md** - Detailed DMS failure documentation
5. **migration_report.md** - This report

---

### Build Verification

| Build Attempt | Result | Errors | Warnings |
|--------------|--------|--------|----------|
| Step 3 (SQL re-integration) | Success | 0 | 10 |
| Step 4 (Npgsql replacement) | Success | 0 | 10 |
| Step 5 (Connection strings) | Success | 0 | 10 |
| Final verification (Step 6) | Success | 0 | 10 |

All warnings are pre-existing nullable reference warnings and are not related to the migration.

---

### Transformation Criteria Verification

| Criteria | Status |
|----------|--------|
| All SqlClient packages replaced with Npgsql | ✅ Verified |
| All SqlConnection/SqlCommand/SqlDataReader replaced | ✅ Verified |
| All SQL statements processed through DMS tool | ✅ Attempted (all failed) |
| Manual conversion applied for DMS failures | ✅ Applied with lowercase schema |
| SQL equivalency validation attempted for all pairs | ✅ All 7 pairs submitted |
| Connection strings updated to PostgreSQL format | ✅ Verified |
| Application compiles successfully | ✅ Verified (0 errors) |
| Complete statement catalog maintained | ✅ extracted_statements.sql + converted_statements.sql |
| Equivalency report generated | ✅ sql_equivalency_validation_report.json |
| DMS failures documented | ✅ dms_conversion_summary.md |
