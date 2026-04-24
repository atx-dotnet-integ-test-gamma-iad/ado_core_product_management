# Migration Log - MS SQL Server to PostgreSQL

## Project: AdoCore - Product Management Application
## Date: 2026-04-24
## Source Database: SQL Server (ProductManagement)
## Target Database: PostgreSQL

---

## 1. SQL Statement Processing

### Statement 1: GetAllProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetAllProductsAsync()
- **Line**: ~42 (const string sql)
- **Type**: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **DMS Tool Result**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-24T01:35:52
- **Manual Conversion Applied**: Yes (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Changes**:
  - All table/column/alias names converted to lowercase
  - Products → products, ProductId → productid, AvgPrice → avgprice, etc.
  - SQL logic and structure preserved (CTE, window functions, CASE, ROUND are PostgreSQL-compatible)

### Statement 2: GetProductByIdAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetProductByIdAsync(int productId)
- **Line**: ~86 (const string sql)
- **Type**: SELECT with CTE, LAG Window Function, LEFT JOIN, CASE, ROUND
- **Parameters**: @ProductId
- **DMS Tool Result**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-24T01:36:07
- **Manual Conversion Applied**: Yes (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Changes**:
  - All table/column/alias names converted to lowercase
  - LAG window function syntax preserved (PostgreSQL-compatible)

### Statement 3: InsertProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: InsertProductAsync(Product product)
- **Line**: ~130 (const string sql)
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), INSERT history, UPDATE stats
- **Parameters**: @Name, @Description, @Price, @StockQuantity
- **DMS Tool Result**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-24T01:36:22
- **Manual Conversion Applied**: Yes (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Changes**:
  - SCOPE_IDENTITY() → INSERT...RETURNING productid (PostgreSQL idiom)
  - GETDATE() → NOW()
  - T-SQL DECLARE @var / SET @var → Restructured to separate SQL statements with C# variable handling
  - BEGIN TRANSACTION/COMMIT → C# BeginTransactionAsync/CommitAsync
  - All table/column names converted to lowercase
  - Single monolithic T-SQL batch split into 3 separate parameterized queries within a C# transaction

### Statement 4: UpdateProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: UpdateProductAsync(Product product)
- **Line**: ~191 (const string sqlGetOld)
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT history, UPDATE stats
- **Parameters**: @ProductId, @Name, @Description, @Price, @StockQuantity
- **DMS Tool Result**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-24T01:36:37
- **Manual Conversion Applied**: Yes (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Changes**:
  - GETDATE() → NOW()
  - T-SQL DECLARE @OldPrice / @OldStock → C# variables (decimal oldPrice, int oldStock)
  - SELECT @OldPrice = Price → Separate SELECT query with C# reader
  - BEGIN TRANSACTION/COMMIT → C# BeginTransactionAsync/CommitAsync
  - All table/column names converted to lowercase
  - Single T-SQL batch split into 4 separate parameterized queries within a C# transaction

### Statement 5: DeleteProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: DeleteProductAsync(int productId)
- **Line**: ~275 (const string sqlGetOld)
- **Type**: Transaction block with DECLARE, SELECT INTO variables, INSERT history, DELETE, UPDATE stats with CASE
- **Parameters**: @ProductId
- **DMS Tool Result**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-24T01:36:53
- **Manual Conversion Applied**: Yes (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Changes**:
  - GETDATE() → NOW()
  - T-SQL DECLARE variables → C# variables
  - BEGIN TRANSACTION/COMMIT → C# BeginTransactionAsync/CommitAsync
  - All table/column names converted to lowercase
  - CASE expression in UPDATE preserved (PostgreSQL-compatible)
  - Single T-SQL batch split into 4 separate parameterized queries within a C# transaction

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
- **Line**: ~351 (const string sql)
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK() Window Functions, BETWEEN, CASE
- **Parameters**: @MinPrice, @MaxPrice
- **DMS Tool Result**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-24T01:37:08
- **Manual Conversion Applied**: Yes (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Changes**:
  - All table/column/alias names converted to lowercase
  - RANK() and PERCENT_RANK() syntax preserved (PostgreSQL-compatible)

### Statement 7: GetLowStockProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetLowStockProductsAsync(int threshold)
- **Line**: ~388 (const string sql)
- **Type**: SELECT with CTE, AVG/MIN/MAX OVER Window Functions, CASE, ROUND
- **Parameters**: @Threshold
- **DMS Tool Result**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-24T01:37:24
- **Manual Conversion Applied**: Yes (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Changes**:
  - All table/column/alias names converted to lowercase
  - Added CAST(stockquantity AS DECIMAL) for proper decimal division (prevents integer truncation)
  - AVG/MIN/MAX OVER window functions preserved (PostgreSQL-compatible)

---

## 2. Class/Package Replacements

### Package References (AdoCore.csproj)
- **Removed**: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added**: `<PackageReference Include="Npgsql" Version="8.0.1" />`
- **Preserved**: Microsoft.Extensions.Configuration (8.0.0), Microsoft.Extensions.Configuration.Json (8.0.0), Microsoft.Extensions.DependencyInjection (8.0.0)

### Using Directives (ProductRepository.cs)
- **Replaced**: `using Microsoft.Data.SqlClient;` → `using Npgsql;`

### ADO.NET Class Replacements (ProductRepository.cs)
| Original | Replacement | Occurrences |
|----------|------------|-------------|
| SqlConnection | NpgsqlConnection | 3 |
| SqlCommand | NpgsqlCommand | 15 |
| SqlDataReader | NpgsqlDataReader | 1 |
| SqlTransaction | NpgsqlTransaction | 11 |

---

## 3. Connection String Changes (appsettings.json)

### DevConnection
- **Before**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After**: `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`

### ProdConnection
- **Before**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After**: `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`

### Parameter Mapping
| SQL Server Parameter | PostgreSQL Equivalent | Action |
|---------------------|----------------------|--------|
| Server= | Host= | Renamed |
| Database= | Database= | Preserved |
| Trusted_Connection=True | N/A | Removed |
| MultipleActiveResultSets=true | N/A | Removed |
| TrustServerCertificate=True | N/A | Removed |
| N/A | Username=postgres | Added |
| N/A | Password=postgres | Added |

---

## 4. Column Name Reader Access Updates (ProductRepository.cs - MapProductFromReader)

Updated column name references from PascalCase to lowercase to match PostgreSQL naming:
- reader["ProductId"] → reader["productid"]
- reader["Name"] → reader["name"]
- reader["Description"] → reader["description"]
- reader["Price"] → reader["price"]
- reader["StockQuantity"] → reader["stockquantity"]
- reader["CreatedDate"] → reader["createddate"]
- reader["ModifiedDate"] → reader["modifieddate"]
