# SQL Server to PostgreSQL Migration Report

## Summary
- **Total SQL Statements Processed**: 7
- **Statements Successfully Converted by DMS**: 0
- **Statements Requiring Manual Conversion (DMS Failure)**: 7
- **Statements Validated as Equivalent**: 0
- **Statements Validated as Non-Equivalent**: 0
- **Statements with Equivalency Validation Errors**: 7

## DMS Tool Failure
All 7 statements failed DMS conversion with error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Manual conversion was applied with lowercase schema object names per the transformation definition (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

## SQL Equivalency Tool Error
All 7 statement pairs failed equivalency validation with error:
```
{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}
```

This is a service-side error unrelated to the SQL statements themselves.

## Key Conversion Changes

### SQL Syntax Changes
| SQL Server | PostgreSQL |
|------------|-----------|
| SCOPE_IDENTITY() | INSERT...RETURNING |
| GETDATE() | NOW() |
| DECLARE @Variable | CTE (WITH clause) |
| BEGIN TRANSACTION/COMMIT | Writable CTEs (atomic) |
| DECIMAL(18,2) | NUMERIC(18,2) |
| NVARCHAR | VARCHAR |
| IDENTITY(1,1) | SERIAL |

### Schema Object Changes
All table names, column names, and aliases converted to lowercase:
- Products → products
- ProductHistory → producthistory
- ProductStats → productstats
- ProductId → productid
- StockQuantity → stockquantity
- CreatedDate → createddate
- ModifiedDate → modifieddate
- etc.

### Package/Dependency Changes
| Original | Replacement |
|----------|------------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.1 |

### Class Replacements
| SQL Server Class | PostgreSQL Class |
|-----------------|----------------|
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |
| SqlParameter | NpgsqlParameter |

### Connection String Changes
| Original | Converted |
|----------|-----------|
| Server=localhost | Host=localhost |
| Database=ProductManagement | Database=productmanagement |
| Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets=true | (removed - not applicable) |
| TrustServerCertificate=True | (removed - not applicable) |

## Files Modified
1. `DataAccess/ProductRepository.cs` - All SQL statements converted, ADO.NET classes replaced
2. `AdoCore.csproj` - Package reference updated
3. `appsettings.json` - Connection strings updated

## Files Created
1. `extracted_statements.sql` - Original MS SQL statements catalog
2. `converted_statements.sql` - Converted PostgreSQL statements catalog
3. `sql_equivalency_validation_report.json` - Equivalency validation report
4. `migration_report.md` - This report

## Statements Requiring Manual Review
All 7 statements require manual review due to:
1. DMS tool failure (service unavailable)
2. SQL Equivalency tool failure (service error)

The manual conversions follow standard SQL Server to PostgreSQL patterns and should be functionally equivalent.
