# Migration Report: MS SQL Server to PostgreSQL
## AdoCore .NET Application

### Summary
| Metric | Count |
|--------|-------|
| Total SQL statements processed | 16 |
| Statements successfully converted by DMS | 0 |
| Statements requiring manual intervention | 16 |
| Statements validated as equivalent | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 16 |

### DMS Tool Status
The AWS DMS MCP tool was **unavailable** for all conversion attempts. Every statement was attempted through the DMS tool and all returned the same error:
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Migration Project**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

### SQL Equivalency Tool Status
The SQL Equivalency tool returned **ERROR** status for all 16 statement pairs:
- **Error**: `'uniqueID'`
- This appears to be an internal tool error affecting all validations

### Manual Conversion Approach
All statements were manually converted using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` approach:
- All schema object names (tables, columns, views, functions) converted to lowercase
- SQL Server-specific functions replaced with PostgreSQL equivalents
- Stored procedures converted to PostgreSQL functions

### Key Conversions Applied

#### SQL Functions
| MS SQL Server | PostgreSQL |
|---|---|
| `GETDATE()` | `NOW()` |
| `SCOPE_IDENTITY()` | `RETURNING` clause |
| `SYSTEM_USER` | `CURRENT_USER` |

#### Data Types
| MS SQL Server | PostgreSQL |
|---|---|
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `BIT` | `BOOLEAN` |
| `DATETIME` | `TIMESTAMP` |
| `INT IDENTITY(1,1)` | `SERIAL` |

#### Syntax
| MS SQL Server | PostgreSQL |
|---|---|
| `[dbo].[TableName]` | `tablename` (lowercase, no brackets) |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `SET NOCOUNT ON` | Removed (not needed) |
| `GO` | Removed (not needed) |
| `IF NOT EXISTS (SELECT * FROM sys.objects...)` | `DROP IF EXISTS` / `CREATE IF NOT EXISTS` |
| `BEGIN TRANSACTION / COMMIT` | App-level transaction or `DO $$ ... END $$` |
| Trigger with `inserted`/`deleted` tables | Trigger function with `NEW`/`OLD` records |
| `IsDiscontinued = 1` (BIT) | `isdiscontinued = TRUE` (BOOLEAN) |

#### ADO.NET (.NET Code)
| MS SQL Server | PostgreSQL |
|---|---|
| `Microsoft.Data.SqlClient` | `Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |
| `Server=localhost` | `Host=localhost` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |

### Files Modified
1. **sourceCode/DataAccess/ProductRepository.cs** - All SQL statements and ADO.NET types replaced
2. **sourceCode/AdoCore.csproj** - Package reference changed from Microsoft.Data.SqlClient 5.1.4 to Npgsql 8.0.1
3. **sourceCode/appsettings.json** - Connection strings updated to PostgreSQL format
4. **sourceCode/Scripts/01_InitialSetup.sql** - Converted to PostgreSQL syntax
5. **sourceCode/Database/Scripts/01_InitialSetup.sql** - Converted to PostgreSQL syntax

### Files Unchanged
- sourceCode/Models/Product.cs (no database code)
- sourceCode/Business/ProductService.cs (no database code)
- sourceCode/CLI/CommandLineInterface.cs (no database code)
- sourceCode/CLI/InteractiveMenu.cs (no database code)
- sourceCode/Program.cs (no database-specific code)

### Artifacts Generated
1. **extracted_statements.sql** - All 7 original MS SQL statements from ProductRepository.cs
2. **converted_statements.sql** - All 7 converted PostgreSQL statements
3. **sql_equivalency_validation_report.json** - Complete equivalency report for all 16 statement pairs
4. **dms_failure_summary.md** - DMS tool failure documentation
5. **migration_report.md** - This report

### Detailed Statement Listing

#### ProductRepository.cs Statements (7)
| # | Method | Type | Manual Review Needed |
|---|--------|------|---------------------|
| 1 | GetAllProductsAsync | CTE with AVG/COUNT OVER | Yes - Equivalency ERROR |
| 2 | GetProductByIdAsync | CTE with LAG window function | Yes - Equivalency ERROR |
| 3 | InsertProductAsync | INSERT with RETURNING (was SCOPE_IDENTITY) | Yes - Equivalency ERROR |
| 4 | UpdateProductAsync | App-level transaction (was SQL transaction) | Yes - Equivalency ERROR |
| 5 | DeleteProductAsync | App-level transaction (was SQL transaction) | Yes - Equivalency ERROR |
| 6 | GetProductsByPriceRangeAsync | CTE with RANK/PERCENT_RANK | Yes - Equivalency ERROR |
| 7 | GetLowStockProductsAsync | CTE with AVG/MIN/MAX | Yes - Equivalency ERROR |

#### SQL Script Statements (9)
| # | Source File | Type | Manual Review Needed |
|---|-----------|------|---------------------|
| 8 | Scripts/01_InitialSetup.sql | CREATE TABLE Products | Yes - Equivalency ERROR |
| 9 | Scripts & Database/Scripts | sp_GetAllProducts -> function | Yes - Equivalency ERROR |
| 10 | Scripts & Database/Scripts | sp_GetProductById -> function | Yes - Equivalency ERROR |
| 11 | Scripts & Database/Scripts | sp_InsertProduct -> function | Yes - Equivalency ERROR |
| 12 | Scripts & Database/Scripts | sp_UpdateProduct -> function | Yes - Equivalency ERROR |
| 13 | Scripts & Database/Scripts | sp_DeleteProduct -> function | Yes - Equivalency ERROR |
| 14 | Database/Scripts | UPDATE ProductStats statistics | Yes - Equivalency ERROR |
| 15 | Database/Scripts | INSERT Categories sample data | Yes - Equivalency ERROR |
| 16 | Database/Scripts | Trigger trg_Products_History | Yes - Equivalency ERROR |

### Recommendations
1. **Manual review required for all 16 statements** due to DMS and SQL Equivalency tool errors
2. **Test thoroughly** against a PostgreSQL 13+ database before production deployment
3. **Verify trigger behavior** - PostgreSQL trigger syntax differs significantly from SQL Server
4. **Test transaction handling** - The app-level transaction approach (UpdateProductAsync, DeleteProductAsync) should be functionally equivalent but needs integration testing
5. **Verify ROUND behavior** with decimal division - added `::numeric` cast in GetLowStockProductsAsync for PostgreSQL compatibility
