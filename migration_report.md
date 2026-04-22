# Migration Report: MS SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating ADO.NET data access components, modifying project dependencies, and updating connection strings.

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Statements Converted by DMS Tool | 0 |
| Statements Manually Converted (DMS Failure) | 7 |
| Statements Validated as Equivalent | 0 |
| Statements Validated as Non-Equivalent | 0 |
| Statements with Equivalency Errors | 7 |

## DMS Tool Usage

### Statement Conversion Tool
- **Status**: FAILED for all 7 statements
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Action Taken**: Manual conversion applied with lowercase schema object names per DMS schema mapping rules
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### Schema Mapping Tool
- **Status**: SUCCEEDED
- **Mappings Retrieved**:
  - `dbo.Products` → `productmanagement_dbo.products` (all columns lowercase)
  - `dbo.ProductHistory` → `productmanagement_dbo.producthistory` (all columns lowercase)
  - `dbo.ProductStats` → `productmanagement_dbo.productstats` (all columns lowercase)

## SQL Equivalency Validation

- **Tool Used**: sql-equivalency___validate_sql_equivalence
- **Status**: All 7 statement pairs returned ERROR due to tool infrastructure issue
- **Error**: `'uniqueID'` - internal tool error, not related to SQL content
- **Note**: All equivalency statuses in the report come exclusively from the SQL Equivalency tool output, not agent judgment

## Files Modified

### 1. sourceCode/DataAccess/ProductRepository.cs
**Changes:**
- Replaced `using Microsoft.Data.SqlClient;` → `using Npgsql;`
- Replaced `SqlConnection` → `NpgsqlConnection` (field declaration, method return type, constructor)
- Replaced `SqlCommand` → `NpgsqlCommand` (all 7 query methods + transaction commands)
- Replaced `SqlDataReader` → `NpgsqlDataReader` (MapProductFromReader method)
- Converted all 7 SQL statements to PostgreSQL syntax
- Updated MapProductFromReader column references to lowercase
- Restructured transactional methods (Insert, Update, Delete) to use C# managed transactions

### 2. sourceCode/AdoCore.csproj
**Changes:**
- Removed: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- Added: `<PackageReference Include="Npgsql" Version="8.0.0" />`
- All other package references unchanged

### 3. sourceCode/appsettings.json
**Changes:**
- DevConnection: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
  → `Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=postgres`
- ProdConnection: Same transformation applied
- Environment setting preserved as "Development"

## SQL Statement Conversions

### Statement 1: GetAllProductsAsync
- **Type**: CTE with window functions (AVG, COUNT OVER), ROUND, CASE, INNER JOIN
- **Key Changes**: Table/column names to lowercase, schema prefix `productmanagement_dbo`, CTE renamed to `productstats_cte` to avoid conflict with table name

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG window function, ROUND, CASE with NULL check, LEFT JOIN
- **Key Changes**: Table/column names to lowercase, schema prefix, CTE renamed to `producthistory_cte`

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE stats
- **Key Changes**: `SCOPE_IDENTITY()` → `RETURNING productid`, `GETDATE()` → `clock_timestamp()`, restructured to C# managed transaction with multiple commands

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE variables, SELECT INTO, UPDATE, INSERT history
- **Key Changes**: `DECLARE @var` → C# variables with reader, `GETDATE()` → `clock_timestamp()`, restructured to C# managed transaction

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE variables, SELECT INTO, INSERT history, DELETE, UPDATE stats with CASE
- **Key Changes**: Same as Statement 4, plus DELETE and CASE expression in UPDATE

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK/PERCENT_RANK window functions, BETWEEN, CASE
- **Key Changes**: Table/column names to lowercase, schema prefix

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Key Changes**: Table/column names to lowercase, schema prefix, added `CAST(stockquantity AS NUMERIC)` for integer division

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent |
|-----------------|-------------------|
| `Microsoft.Data.SqlClient` | `Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

## Connection String Migration

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=postgres` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | (removed - not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | (removed - not applicable) |

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | Original 7 MS SQL statements |
| converted_statements.sql | sourceCode/ | Converted 7 PostgreSQL statements |
| sql_equivalency_validation_report.json | sourceCode/ | Comprehensive equivalency validation report |
| migration_report.md | sourceCode/ | This report |

## Statements Requiring Manual Review

All 7 statements require manual review because:
1. DMS Statement Conversion Tool failed for all statements (infrastructure issue)
2. SQL Equivalency Tool returned ERROR for all statement pairs (infrastructure issue)
3. Manual conversion was applied based on DMS Schema Mapping Tool output

## Schema Mapping Details (from DMS Schema Mapping Tool)

### Products Table
```
Source: dbo.Products
Target: productmanagement_dbo.products

Column Mappings:
  ProductId → productid (INTEGER GENERATED ALWAYS AS IDENTITY)
  Name → name (VARCHAR(100))
  Description → description (VARCHAR(500))
  Price → price (NUMERIC(18,2))
  StockQuantity → stockquantity (INTEGER)
  CreatedDate → createddate (TIMESTAMP WITHOUT TIME ZONE)
  ModifiedDate → modifieddate (TIMESTAMP WITHOUT TIME ZONE)
```

### ProductHistory Table
```
Source: dbo.ProductHistory
Target: productmanagement_dbo.producthistory

Column Mappings:
  HistoryId → historyid (INTEGER GENERATED ALWAYS AS IDENTITY)
  ProductId → productid (INTEGER)
  Action → action (VARCHAR(10))
  OldPrice → oldprice (NUMERIC(18,2))
  NewPrice → newprice (NUMERIC(18,2))
  OldStock → oldstock (INTEGER)
  NewStock → newstock (INTEGER)
  ActionDate → actiondate (TIMESTAMP WITHOUT TIME ZONE)
```

### ProductStats Table
```
Source: dbo.ProductStats
Target: productmanagement_dbo.productstats

Column Mappings:
  StatId → statid (INTEGER)
  TotalProducts → totalproducts (INTEGER)
  AveragePrice → averageprice (NUMERIC(18,2))
  LastUpdated → lastupdated (TIMESTAMP WITHOUT TIME ZONE)
```
