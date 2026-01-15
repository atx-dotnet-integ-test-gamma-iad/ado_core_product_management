# ADO.NET PostgreSQL Migration - Testing and Validation Guide

## Overview

This guide provides comprehensive instructions for testing and validating the migrated ADO.NET application that now uses PostgreSQL instead of Microsoft SQL Server.

## Migration Summary

### What Was Changed

1. **Database Provider**: Microsoft.Data.SqlClient → Npgsql 8.0.5
2. **ADO.NET Classes**: 
   - SqlConnection → NpgsqlConnection
   - SqlCommand → NpgsqlCommand
   - SqlDataReader → NpgsqlDataReader
   - SqlParameter → NpgsqlParameter

3. **SQL Syntax Conversions**:
   - All 7 SQL statements converted to PostgreSQL syntax
   - CTEs and window functions preserved (LAG, RANK, PERCENT_RANK, AVG/MIN/MAX OVER)
   - GETDATE() → CURRENT_TIMESTAMP
   - SCOPE_IDENTITY() → RETURNING clause
   - Transaction management moved from SQL to ADO.NET level

4. **Schema Changes**:
   - dbo schema → productmanagement_dbo schema
   - All identifiers converted to lowercase (PostgreSQL convention)

5. **Connection Strings**: Updated to PostgreSQL format

## Prerequisites for Testing

### 1. PostgreSQL Database Setup

Before testing, you MUST have a PostgreSQL database with the required schema and tables.

**Follow the setup guide**: `Database/PostgreSQL_Setup_Guide.md`

Quick setup commands:

```sql
-- Create schema
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;

-- Create tables (see full DDL in PostgreSQL_Setup_Guide.md)
-- products, producthistory, productstats
```

### 2. Update Connection String

Edit `appsettings.json` with your PostgreSQL credentials:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Pooling=true"
  },
  "Environment": "Development"
}
```

### 3. Verify Build

```bash
dotnet build
# Should complete with 0 errors (nullable warnings are OK)
```

## Testing Strategy

### Level 1: Unit Testing (Manual)

Since the application doesn't have automated unit tests, perform manual validation of each method.

#### Test 1: Database Connection

**Objective**: Verify application can connect to PostgreSQL

```bash
dotnet run
# Look for successful startup without connection errors
```

**Expected Result**: Application starts without database connection errors

#### Test 2: GetAllProductsAsync

**SQL Features Tested**: 
- CTE (WITH clause)
- Window functions (AVG OVER, COUNT OVER)
- CASE statements
- Complex JOIN with CTE

**Test Steps**:
1. Insert sample data if not present (see PostgreSQL_Setup_Guide.md)
2. Call GetAllProductsAsync
3. Verify results returned

**Expected Result**: 
- All products returned with computed columns (pricecategory, pricepercentageofaverage)
- No SQL errors
- Products sorted correctly (above average first, then by name)

#### Test 3: GetProductByIdAsync

**SQL Features Tested**:
- CTE with LAG window function
- LEFT OUTER JOIN
- Parameterized query (@ProductId)
- NULL handling

**Test Steps**:
1. Get product by valid ID
2. Get product by invalid ID
3. Verify computed columns (previousprice, pricechangepercentage)

**Expected Result**:
- Valid ID returns product with history data
- Invalid ID returns null
- Previous price/stock tracked correctly

#### Test 4: InsertProductAsync (Transaction Test)

**SQL Features Tested**:
- RETURNING clause (PostgreSQL replacement for SCOPE_IDENTITY())
- Multi-statement transaction (3 statements)
- CURRENT_TIMESTAMP
- Transaction atomicity

**Test Steps**:
1. Insert valid product
2. Verify new product ID returned
3. Check producthistory has INSERT entry
4. Check productstats updated (totalproducts, averageprice)
5. Test transaction rollback on error

**Expected Result**:
- Product inserted with correct ID
- History logged
- Stats updated
- Transaction rolls back on error

**Critical Validation**: This method was manually converted after DMS tool failure. Verify:
- RETURNING clause returns correct productid
- All 3 statements execute within transaction
- Transaction commits only if all succeed

#### Test 5: UpdateProductAsync (Transaction Test)

**SQL Features Tested**:
- Multi-statement transaction (4 statements)
- Variable handling (oldPrice, oldStock captured via SELECT first)
- CURRENT_TIMESTAMP
- Complex math in UPDATE

**Test Steps**:
1. Update existing product with new price and stock
2. Verify producthistory has UPDATE entry with old and new values
3. Verify productstats averageprice recalculated
4. Test transaction rollback on error

**Expected Result**:
- Product updated
- History logged with correct old/new values
- Stats recalculated correctly
- Transaction atomicity maintained

#### Test 6: DeleteProductAsync (Transaction Test)

**SQL Features Tested**:
- Multi-statement transaction (4 statements)
- CASCADE delete handling (if foreign keys configured)
- CASE statement in UPDATE
- Division by zero prevention

**Test Steps**:
1. Delete existing product
2. Verify producthistory has DELETE entry
3. Verify productstats updated (totalproducts decremented, averageprice recalculated)
4. Verify product actually deleted

**Expected Result**:
- Product deleted
- History logged
- Stats updated correctly
- Transaction atomicity maintained

#### Test 7: GetProductsByPriceRangeAsync

**SQL Features Tested**:
- CTE with RANK() and PERCENT_RANK() window functions
- BETWEEN clause with parameters
- Complex CASE for categorization

**Test Steps**:
1. Query with valid price range containing products
2. Query with price range containing no products
3. Verify pricesegment computed correctly (Budget/Mid-Range/Premium)

**Expected Result**:
- Products within range returned
- Ranked correctly by price
- Price segments assigned correctly

#### Test 8: GetLowStockProductsAsync

**SQL Features Tested**:
- CTE with multiple window functions (AVG, MIN, MAX OVER)
- WHERE clause filtering
- ORDER BY with NULLS FIRST (PostgreSQL explicit null ordering)

**Test Steps**:
1. Query with threshold that matches some products
2. Verify stockstatus computed correctly (Critical/Low/Adequate)
3. Verify stockpercentageofaverage calculated

**Expected Result**:
- Only products below threshold returned
- Stock status categorized correctly
- Sorted by stock quantity ascending

### Level 2: Integration Testing

#### Transaction Atomicity Test

**Objective**: Verify transaction rollback works correctly

```csharp
// Pseudo-test code
try
{
    await repository.InsertProductAsync(new Product 
    { 
        Name = "Test", 
        Price = -1, // This might cause constraint violation
        StockQuantity = 10 
    });
}
catch
{
    // Expected to catch exception
}

// Verify: No partial data in database
// - Product not inserted
// - ProductHistory not inserted
// - ProductStats not modified
```

#### Concurrent Operation Test

**Objective**: Verify connection pooling and concurrent queries work

```csharp
// Execute multiple queries concurrently
var tasks = new List<Task>
{
    repository.GetAllProductsAsync(),
    repository.GetProductByIdAsync(1),
    repository.GetLowStockProductsAsync(50)
};

await Task.WhenAll(tasks);
```

**Expected Result**: All queries complete successfully without connection errors

### Level 3: Performance Testing

#### Baseline Performance

Compare query execution times between SQL Server (if available) and PostgreSQL:

1. **GetAllProductsAsync**: CTE with window functions
2. **GetProductByIdAsync**: LAG window function
3. **GetProductsByPriceRangeAsync**: RANK and PERCENT_RANK

**Tools**:
- PostgreSQL: `EXPLAIN ANALYZE <query>`
- Application: Add stopwatch timing to methods

#### Expected Performance

Window functions and CTEs should perform similarly or better in PostgreSQL compared to SQL Server for these relatively simple queries.

### Level 4: Data Integrity Testing

#### Test Scenarios

1. **Data Type Preservation**:
   - DECIMAL(18,2) preserved for price
   - INTEGER for quantities and IDs
   - VARCHAR/TEXT for strings
   - TIMESTAMP for dates

2. **Null Handling**:
   - Description field accepts NULL
   - ModifiedDate accepts NULL
   - Computed columns with NULL handling (pricechangepercentage)

3. **Constraint Validation**:
   - NOT NULL constraints enforced
   - Foreign key constraints (producthistory → products)
   - DEFAULT values applied

## Known Limitations and Considerations

### 1. SQL Equivalency Validation

**Status**: All 7 SQL statements marked as ERROR in equivalency validation

**Reason**: SQL Equivalency tool cannot process:
- Complex CTEs with window functions
- Multi-statement transaction blocks
- Parameterized queries with complex logic

**Mitigation**: 
- All statements successfully converted by DMS tool (6 of 7)
- 1 statement manually converted following PostgreSQL best practices
- **Manual runtime testing is REQUIRED** to confirm semantic equivalency

### 2. Transaction Behavior Differences

**SQL Server**: Transactions can be managed at SQL statement level (BEGIN TRANSACTION/COMMIT in SQL)

**PostgreSQL**: Transactions managed at ADO.NET level (BeginTransactionAsync/CommitAsync)

**Impact**: Code now uses proper ADO.NET transaction management, which is actually better practice

**Validation**: Test rollback scenarios to ensure atomicity

### 3. Case Sensitivity

**SQL Server**: Case-insensitive by default for identifiers

**PostgreSQL**: Case-sensitive for unquoted identifiers (becomes lowercase)

**Impact**: All identifiers converted to lowercase (productid, name, price, etc.)

**Validation**: Verify column names in MapProductFromReader match PostgreSQL lowercase convention

### 4. NULL Ordering

**SQL Server**: NULL values ordered differently than PostgreSQL

**PostgreSQL**: Explicit `NULLS FIRST` or `NULLS LAST` added to ORDER BY clauses

**Impact**: Query results may have different ordering for NULL values

**Validation**: Test queries with NULL values in ordered columns

## Troubleshooting

### Common Issues

#### 1. "relation does not exist"

**Cause**: Schema or table not created, or incorrect case

**Fix**: 
```sql
-- Verify schema exists
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'productmanagement_dbo';

-- Verify tables exist
SELECT table_name FROM information_schema.tables WHERE table_schema = 'productmanagement_dbo';
```

#### 2. "column does not exist"

**Cause**: Column name case mismatch

**Fix**: Verify column names are lowercase in SQL queries (productid, not ProductId)

#### 3. Connection timeout

**Cause**: PostgreSQL not running or firewall blocking connection

**Fix**:
```bash
# Check PostgreSQL status
sudo systemctl status postgresql  # Linux
# Or check Services on Windows

# Test connection
psql -h localhost -U postgres -d ProductManagement
```

#### 4. Transaction deadlock

**Cause**: Concurrent operations on same data

**Fix**: Implement retry logic or optimize transaction scope

## Success Criteria

✅ **All exit criteria met when**:

1. Application compiles without errors ✓
2. Database connection established ✓
3. All 7 CRUD methods execute without SQL errors
4. Transaction atomicity verified (rollback works)
5. Data integrity maintained across operations
6. Window functions return correct results
7. CTE queries return expected data
8. Performance acceptable (no significant degradation)

## Testing Checklist

- [ ] PostgreSQL database created with schema and tables
- [ ] Sample data inserted for testing
- [ ] Connection string updated with correct credentials
- [ ] Application builds successfully (0 errors)
- [ ] Database connection established
- [ ] GetAllProductsAsync tested (CTE + window functions)
- [ ] GetProductByIdAsync tested (LAG window function)
- [ ] InsertProductAsync tested (RETURNING clause + transaction)
- [ ] UpdateProductAsync tested (multi-statement transaction)
- [ ] DeleteProductAsync tested (multi-statement transaction)
- [ ] GetProductsByPriceRangeAsync tested (RANK + PERCENT_RANK)
- [ ] GetLowStockProductsAsync tested (multiple window functions)
- [ ] Transaction rollback tested
- [ ] Concurrent operations tested
- [ ] Data integrity verified
- [ ] Performance baseline established

## Next Steps After Validation

1. **Create Automated Tests**: Build integration test suite
2. **Performance Optimization**: Add indexes, tune queries if needed
3. **Monitoring**: Set up logging and monitoring for production
4. **Documentation**: Update API documentation with PostgreSQL specifics
5. **Deployment**: Create deployment scripts and CI/CD pipeline

## Support and Resources

- **PostgreSQL Setup Guide**: `Database/PostgreSQL_Setup_Guide.md`
- **Migration Report**: `../migration_report.json`
- **SQL Equivalency Report**: `../sql_equivalency_validation_report.json`
- **Extracted SQL**: `../extracted_statements.sql`
- **Converted SQL**: `../converted_statements.sql`

## Contact

For migration issues or questions, refer to:
- Migration artifacts in parent directory
- PostgreSQL documentation: https://www.postgresql.org/docs/
- Npgsql documentation: https://www.npgsql.org/doc/
