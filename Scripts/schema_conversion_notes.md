# PostgreSQL Schema Conversion Notes

## Migration Date: 2026-01-25

## Data Type Mappings

| SQL Server | PostgreSQL |
|------------|------------|
| INT IDENTITY(1,1) | SERIAL or INTEGER GENERATED ALWAYS AS IDENTITY |
| NVARCHAR(n) | VARCHAR(n) or TEXT |
| DECIMAL(18,2) | NUMERIC(18,2) |
| DATETIME | TIMESTAMP |
| GETDATE() | CURRENT_TIMESTAMP or NOW() |

## Syntax Transformations

### Table Creation
- Removed `GO` statements (SQL Server batch separator)
- Removed `[dbo].` schema qualifiers (using public schema)
- Changed `IF NOT EXISTS (SELECT...)` to `CREATE TABLE IF NOT EXISTS`
- Added `ON CONFLICT DO NOTHING` for idempotent INSERT statements

### Stored Procedures
- **Original:** SQL Server stored procedures (sp_GetAllProducts, sp_GetProductById, etc.)
- **Converted:** Removed - replaced with inline parameterized SQL in ProductRepository.cs
- **Rationale:** Application uses ADO.NET with inline SQL queries, making stored procedures unnecessary. This simplifies the migration and reduces database-side complexity.

### Identity Columns
- SQL Server `IDENTITY(1,1)` → PostgreSQL `SERIAL` (auto-incrementing integer)
- Alternative: `GENERATED ALWAYS AS IDENTITY` for SQL standard compliance

### Sample Data
- Changed `EXEC sp_InsertProduct` to direct `INSERT` statements
- Added `ON CONFLICT DO NOTHING` for safe re-execution

## Tables Created

1. **public.products** - Main product catalog table
2. **public.producthistory** - Audit trail for product changes
3. **public.productstats** - Aggregated statistics (single row, StatId=1)

## PostgreSQL-Specific Considerations

1. **Case Sensitivity:** PostgreSQL table/column names are lowercase by convention
2. **Schema:** Using `public` schema (PostgreSQL default)
3. **Transactions:** PostgreSQL uses `BEGIN` instead of `BEGIN TRANSACTION`
4. **Parameters:** Named parameters with `@` syntax supported by Npgsql driver
5. **Window Functions:** Fully compatible between SQL Server and PostgreSQL

## Testing Recommendations

1. Run `01_InitialSetup_PostgreSQL.sql` to create schema
2. Verify all tables exist: `\dt public.*`
3. Check sample data: `SELECT * FROM public.products;`
4. Verify ProductStats initialization: `SELECT * FROM public.productstats;`
5. Test application connectivity with new schema
