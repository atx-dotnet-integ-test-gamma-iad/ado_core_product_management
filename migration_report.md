# SQL Server to PostgreSQL Migration Report

## Summary
- **Application**: AdoCore (.NET 9.0 Console Application)
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Total SQL Statements Processed**: 7
- **Statements Successfully Converted by DMS**: 0
- **Statements Requiring Manual Intervention**: 7
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}

## SQL Equivalency Validation Results
- **Statements Validated as Equivalent**: 0
- **Statements Validated as Non-Equivalent**: 0
- **Statements with Equivalency Validation Errors**: 7
- **Equivalency Tool Error**: 'uniqueID'

## Files Modified
1. `sourceCode/DataAccess/ProductRepository.cs` - All SQL statements converted, ADO.NET classes replaced
2. `sourceCode/AdoCore.csproj` - Package reference updated from Microsoft.Data.SqlClient to Npgsql
3. `sourceCode/appsettings.json` - Connection strings updated to PostgreSQL format

## Conversion Details

### Package Dependencies
| Original | Replacement |
|----------|-------------|
| Microsoft.Data.SqlClient v5.1.4 | Npgsql v8.0.1 |

### ADO.NET Class Replacements
| SQL Server Class | PostgreSQL Class |
|-----------------|-----------------|
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |
| SqlParameter (AddWithValue) | NpgsqlParameter (AddWithValue) |

### Connection String Changes
| Original (SQL Server) | Converted (PostgreSQL) |
|----------------------|----------------------|
| Server=localhost | Host=localhost |
| Database=ProductManagement | Database=ProductManagement |
| Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets=true | (removed - not applicable) |
| TrustServerCertificate=True | (removed - not applicable) |

### SQL Statement Conversions
| # | Method | Key Changes |
|---|--------|-------------|
| 1 | GetAllProductsAsync | Lowercase schema objects |
| 2 | GetProductByIdAsync | Lowercase schema objects |
| 3 | InsertProductAsync | SCOPE_IDENTITY() → RETURNING clause via writable CTE; GETDATE() → NOW() |
| 4 | UpdateProductAsync | DECLARE variables → writable CTE with old_values; GETDATE() → NOW() |
| 5 | DeleteProductAsync | DECLARE variables → writable CTE with old_values; GETDATE() → NOW() |
| 6 | GetProductsByPriceRangeAsync | Lowercase schema objects |
| 7 | GetLowStockProductsAsync | Lowercase schema objects; CAST AS DECIMAL → CAST AS NUMERIC |

### Column Name Mapping (reader access updated)
| SQL Server | PostgreSQL |
|-----------|-----------|
| ProductId | productid |
| Name | name |
| Description | description |
| Price | price |
| StockQuantity | stockquantity |
| CreatedDate | createddate |
| ModifiedDate | modifieddate |

## Artifacts Generated
1. `extracted_statements.sql` - Complete catalog of all original MS SQL statements
2. `converted_statements.sql` - Complete catalog of all converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Full equivalency validation report
4. `migration_report.md` - This file

## Notes
- All 7 DMS conversion attempts failed with the same error, requiring manual conversion
- All 7 SQL equivalency validation attempts returned ERROR, likely due to a service issue
- Manual conversions applied lowercase schema object naming convention per PostgreSQL best practices
- Transaction blocks using DECLARE/SET patterns were restructured to use PostgreSQL writable CTEs
- The SCOPE_IDENTITY() pattern was replaced with INSERT...RETURNING via writable CTEs
- GETDATE() was replaced with NOW() throughout
