# SQL Statement Tracking Document
## Microsoft SQL Server to PostgreSQL Migration

**Project**: AdoCore - Product Management System  
**Source File**: sourceCode/DataAccess/ProductRepository.cs  
**Total Statements Extracted**: 7  
**Extraction Date**: Step 1 of Migration Plan  

---

## Statement Inventory

| ID | Method Name | Lines | Statement Type | Complexity | Parameters | SQL Server Features |
|----|-------------|-------|----------------|------------|------------|---------------------|
| 1 | GetAllProductsAsync | 40-68 | SELECT with CTE | High | None | Window Functions (AVG OVER, COUNT OVER), CTE |
| 2 | GetProductByIdAsync | 81-109 | SELECT with CTE | High | @ProductId | Window Function (LAG), CTE |
| 3 | InsertProductAsync | 120-147 | INSERT in Transaction | High | @Name, @Description, @Price, @StockQuantity | SCOPE_IDENTITY(), GETDATE(), BEGIN/COMMIT |
| 4 | UpdateProductAsync | 163-194 | UPDATE in Transaction | High | @ProductId, @Name, @Description, @Price, @StockQuantity | GETDATE(), BEGIN/COMMIT, DECLARE variables |
| 5 | DeleteProductAsync | 205-237 | DELETE in Transaction | High | @ProductId | GETDATE(), BEGIN/COMMIT, DECLARE variables |
| 6 | GetProductsByPriceRangeAsync | 248-272 | SELECT with CTE | High | @MinPrice, @MaxPrice | Window Functions (RANK, PERCENT_RANK), CTE |
| 7 | GetLowStockProductsAsync | 285-309 | SELECT with CTE | High | @Threshold | Window Functions (AVG, MIN, MAX OVER), CTE |

---

## Detailed Statement Analysis

### Statement 1: GetAllProductsAsync
- **Location**: ProductRepository.cs, lines 40-68
- **Purpose**: Retrieve all products with price category analysis
- **SQL Features**:
  - Common Table Expression (CTE) named `ProductStats`
  - Window functions: `AVG(Price) OVER()`, `COUNT(*) OVER()`
  - INNER JOIN between Products and CTE
  - Multiple CASE expressions for categorization
  - ROUND function for percentage calculation
  - Complex ORDER BY with CASE expression
- **Parameters**: None
- **Return Type**: List<Product>
- **Conversion Considerations**: 
  - PostgreSQL supports CTEs and window functions natively
  - ROUND function syntax should be compatible
  - CASE expressions are standard SQL

### Statement 2: GetProductByIdAsync
- **Location**: ProductRepository.cs, lines 81-109
- **Purpose**: Retrieve single product with historical price comparison
- **SQL Features**:
  - Common Table Expression (CTE) named `ProductHistory`
  - LAG window function: `LAG(Price) OVER (ORDER BY ModifiedDate)`
  - LEFT JOIN between Products and CTE
  - CASE expression for calculating percentage change
  - WHERE clause with parameter
- **Parameters**: @ProductId (int)
- **Return Type**: Product (single object)
- **Conversion Considerations**:
  - LAG function is supported in PostgreSQL
  - Parameter binding needs to use $ syntax in PostgreSQL

### Statement 3: InsertProductAsync
- **Location**: ProductRepository.cs, lines 120-147
- **Purpose**: Insert new product with history logging and statistics update
- **SQL Features**:
  - DECLARE variable statement
  - BEGIN TRANSACTION / COMMIT block
  - Multiple INSERT statements
  - SCOPE_IDENTITY() for retrieving last inserted ID
  - GETDATE() function (2 occurrences)
  - UPDATE statement with calculations
  - SELECT to return new ID
- **Parameters**: @Name, @Description, @Price, @StockQuantity
- **Return Type**: int (new product ID)
- **Conversion Considerations**:
  - **CRITICAL**: SCOPE_IDENTITY() must be converted to PostgreSQL equivalent (RETURNING clause or LASTVAL())
  - **CRITICAL**: GETDATE() must be converted to NOW() or CURRENT_TIMESTAMP
  - Transaction syntax differs in PostgreSQL (implicit in many cases)
  - Variable declarations use different syntax

### Statement 4: UpdateProductAsync
- **Location**: ProductRepository.cs, lines 163-194
- **Purpose**: Update product with history logging and statistics recalculation
- **SQL Features**:
  - BEGIN TRANSACTION / COMMIT block
  - DECLARE statements for variables
  - SELECT into variables to capture old values
  - UPDATE statement
  - INSERT for history logging
  - GETDATE() function (3 occurrences)
  - Complex UPDATE with calculations
- **Parameters**: @ProductId, @Name, @Description, @Price, @StockQuantity
- **Return Type**: void (Task)
- **Conversion Considerations**:
  - **CRITICAL**: GETDATE() must be converted to NOW() or CURRENT_TIMESTAMP
  - Variable declarations and assignments need PostgreSQL syntax
  - Transaction block syntax differences

### Statement 5: DeleteProductAsync
- **Location**: ProductRepository.cs, lines 205-237
- **Purpose**: Delete product with history logging and statistics update
- **SQL Features**:
  - BEGIN TRANSACTION / COMMIT block
  - DECLARE statements for variables
  - SELECT into variables
  - INSERT for history logging
  - DELETE statement
  - UPDATE with complex CASE expression
  - GETDATE() function (2 occurrences)
- **Parameters**: @ProductId
- **Return Type**: void (Task)
- **Conversion Considerations**:
  - **CRITICAL**: GETDATE() must be converted to NOW() or CURRENT_TIMESTAMP
  - Variable handling differences
  - Transaction block syntax

### Statement 6: GetProductsByPriceRangeAsync
- **Location**: ProductRepository.cs, lines 248-272
- **Purpose**: Retrieve products in price range with ranking
- **SQL Features**:
  - Common Table Expression (CTE) named `RankedProducts`
  - RANK() window function
  - PERCENT_RANK() window function
  - BETWEEN clause for range filtering
  - SELECT all columns with p.*
  - CASE expression for segmentation
- **Parameters**: @MinPrice, @MaxPrice
- **Return Type**: List<Product>
- **Conversion Considerations**:
  - RANK() and PERCENT_RANK() are supported in PostgreSQL
  - BETWEEN clause is standard SQL

### Statement 7: GetLowStockProductsAsync
- **Location**: ProductRepository.cs, lines 285-309
- **Purpose**: Find products with low stock levels with analytics
- **SQL Features**:
  - Common Table Expression (CTE) named `StockAnalysis`
  - Multiple window functions: AVG(), MIN(), MAX() with OVER()
  - SELECT all columns with p.*
  - CASE expression for status categorization
  - ROUND function
  - WHERE clause filtering
  - ORDER BY
- **Parameters**: @Threshold
- **Return Type**: List<Product>
- **Conversion Considerations**:
  - All window functions are supported in PostgreSQL
  - ROUND function syntax should be compatible

---

## SQL Server Specific Features Requiring Conversion

### High Priority Conversions
1. **SCOPE_IDENTITY()** (Statement 3) → PostgreSQL RETURNING clause or LASTVAL()
2. **GETDATE()** (Statements 3, 4, 5) → NOW() or CURRENT_TIMESTAMP
3. **BEGIN TRANSACTION / COMMIT** (Statements 3, 4, 5) → PostgreSQL transaction syntax
4. **DECLARE variable syntax** (Statements 3, 4, 5) → PostgreSQL variable syntax
5. **Variable assignment with SET** (Statement 3) → PostgreSQL assignment syntax

### Standard SQL Features (Should convert smoothly)
- Common Table Expressions (CTEs)
- Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX with OVER)
- CASE expressions
- JOIN operations
- WHERE, ORDER BY clauses
- ROUND function
- BETWEEN operator

---

## Conversion Readiness Assessment

| Statement ID | Readiness Level | Key Challenges |
|--------------|----------------|----------------|
| 1 | High | Standard SQL features, minimal conversion needed |
| 2 | High | LAG function and CTE are standard, parameter syntax only |
| 3 | Medium | SCOPE_IDENTITY() and GETDATE() need conversion, transaction syntax |
| 4 | Medium | GETDATE() and variable syntax need conversion |
| 5 | Medium | GETDATE() and variable syntax need conversion |
| 6 | High | Standard SQL features, ranking functions supported |
| 7 | High | Standard SQL features, window functions supported |

---

## Next Steps
1. ✅ **COMPLETED**: Extract all SQL statements
2. ⏭️ **NEXT**: Process each statement through DMS MCP tool
3. ⏭️ **PENDING**: Validate equivalency using SQL Equivalency tool
4. ⏭️ **PENDING**: Re-integrate converted statements into ProductRepository.cs
5. ⏭️ **PENDING**: Update package dependencies and ADO.NET classes
6. ⏭️ **PENDING**: Update connection strings
7. ⏭️ **PENDING**: Final verification and reporting

---

## Notes
- All statements have been extracted with complete SQL text
- Each statement is documented with full context (file, line numbers, method)
- Statement complexity ranges from High for all statements due to advanced SQL features
- The codebase uses consistent patterns for transaction management and parameterization
- Schema object names (Products, ProductHistory, ProductStats) will need case conversion verification based on DMS tool output
