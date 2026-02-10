# PostgreSQL Functional Testing Guide

## Overview

This guide provides step-by-step instructions for validating the migrated ADO.NET application against a live PostgreSQL database. These tests verify that all database operations function correctly after migration from SQL Server.

## Prerequisites

- PostgreSQL 12+ installed and running
- ProductManagement database created with schema (see README_PostgreSQL.md)
- Application built successfully (`dotnet build`)
- Connection string configured in appsettings.json

## Test Environment Setup

### 1. Verify PostgreSQL is Running

```bash
# Windows (PowerShell)
Get-Service -Name postgresql*

# Linux
sudo systemctl status postgresql

# Mac
brew services list | grep postgresql
```

### 2. Verify Database Connection

```bash
# Using psql
psql -U postgres -d ProductManagement -c "SELECT version();"

# Should return PostgreSQL version information
```

### 3. Verify Tables Exist

```bash
psql -U postgres -d ProductManagement -c "\dt"

# Expected output: Lists tables (products, categories, suppliers, product_history, product_stats)
```

## Functional Test Cases

### Test Suite 1: Database Connectivity

#### Test 1.1: Application Connects to PostgreSQL
```bash
# Run the application
dotnet run

# Expected Result: Application starts without connection errors
# Status: PASS if no exception, FAIL if connection error
```

#### Test 1.2: Connection String Validation
```bash
# Check connection string format in appsettings.json
cat appsettings.json

# Expected: PostgreSQL format with Host, Database, Username, Password, Port
# Status: PASS if correct format, FAIL if SQL Server format
```

---

### Test Suite 2: SELECT Operations

#### Test 2.1: GetAllProductsAsync - List All Products
```bash
# Execute
dotnet run -- list

# Expected Result:
# - Returns 18 sample products
# - Shows ProductId, Name, Description, Price, StockQuantity
# - No SQL errors
# - Data matches products table

# Validation Steps:
# 1. Count returned records (should be 18)
# 2. Verify column names are correct
# 3. Verify data types (decimal for price, int for quantity)
# 4. Check for NULL handling in Description

# Status: PASS / FAIL
```

**Database Verification:**
```sql
-- Run in psql to verify
SELECT COUNT(*) FROM products;  -- Should return 18
```

#### Test 2.2: GetProductByIdAsync - Get Single Product
```bash
# Execute
dotnet run -- get 1

# Expected Result:
# - Returns product with ID 1 (ProBook X1)
# - Shows: ProductId=1, Name="ProBook X1", Price=1299.99, Stock=15
# - No SQL errors

# Test Cases:
# a) Valid ID (1): Should return product
# b) Invalid ID (999): Should return "not found" or null
# c) Negative ID (-1): Should handle gracefully

# Status: PASS / FAIL
```

**Database Verification:**
```sql
SELECT product_id, name, price, stock_quantity 
FROM products 
WHERE product_id = 1;
```

#### Test 2.3: GetProductsByPriceRangeAsync - Price Range Query
```bash
# Execute
dotnet run -- price-range 100.00 500.00

# Expected Result:
# - Returns products priced between $100 and $500
# - Shows Price Rank and Percentage Rank columns (window functions)
# - Products ordered by price
# - No SQL errors

# Test Cases:
# a) Range 100-500: Should return ~11 products
# b) Range 0-50: Should return products under $50
# c) Range 3000-5000: Should return empty or no products

# Validation:
# - All returned products have price BETWEEN min and max
# - Window function columns populated correctly
# - Ranking is sequential

# Status: PASS / FAIL
```

**Database Verification:**
```sql
SELECT name, price 
FROM products 
WHERE price BETWEEN 100.00 AND 500.00
ORDER BY price;
```

#### Test 2.4: GetLowStockProductsAsync - Low Stock Query
```bash
# Execute
dotnet run -- low-stock 10

# Expected Result:
# - Returns products with stock_quantity <= 10
# - Shows product details with stock levels
# - CTE-based query executes correctly
# - No SQL errors

# Test Cases:
# a) Threshold 10: Should return products with stock <= 10
# b) Threshold 5: Should return fewer products
# c) Threshold 50: Should return more products

# Validation:
# - All returned products have stock_quantity <= threshold
# - Data is accurate

# Status: PASS / FAIL
```

**Database Verification:**
```sql
SELECT product_id, name, stock_quantity 
FROM products 
WHERE stock_quantity <= 10
ORDER BY stock_quantity;
```

---

### Test Suite 3: INSERT Operations

#### Test 3.1: InsertProductAsync - Create New Product
```bash
# Execute
dotnet run -- add "Test Product 001" 99.99 25 "Test product for validation"

# Expected Result:
# - Returns newly created ProductId
# - Product is inserted into database
# - RETURNING clause works correctly (PostgreSQL-specific)
# - CreatedDate is set automatically
# - No SQL errors

# Validation Steps:
# 1. Note the returned ProductId
# 2. Verify product exists in database
# 3. Check all fields are correct
# 4. Verify CreatedDate is populated
# 5. Check ProductHistory table for INSERT record

# Status: PASS / FAIL
```

**Database Verification:**
```sql
-- Verify product was created (replace with returned ID)
SELECT * FROM products WHERE name = 'Test Product 001';

-- Verify history record was created
SELECT * FROM product_history 
WHERE product_id = (SELECT product_id FROM products WHERE name = 'Test Product 001')
AND action = 'INSERT';
```

#### Test 3.2: Transaction Handling on Insert
```bash
# This tests the transaction rollback capability
# Test by causing an intentional error (e.g., NULL constraint violation)

# Expected Result:
# - Transaction should rollback on error
# - No partial data inserted
# - Proper error handling

# Status: PASS / FAIL
```

---

### Test Suite 4: UPDATE Operations

#### Test 4.1: UpdateProductAsync - Update Existing Product
```bash
# First, get current product details
dotnet run -- get 1

# Execute update
dotnet run -- update 1 "ProBook X1 Updated" 1399.99 20 "Updated description"

# Expected Result:
# - Product is updated in database
# - ModifiedDate is set automatically
# - CTE-based transaction executes correctly
# - Returns success indication
# - No SQL errors

# Validation Steps:
# 1. Verify all fields updated correctly
# 2. Check ModifiedDate is set
# 3. Verify ProductHistory table has UPDATE record
# 4. Confirm old and new values logged in history

# Status: PASS / FAIL
```

**Database Verification:**
```sql
-- Verify update
SELECT product_id, name, price, stock_quantity, modified_date 
FROM products 
WHERE product_id = 1;

-- Verify history record
SELECT * FROM product_history 
WHERE product_id = 1 
AND action = 'UPDATE'
ORDER BY action_date DESC 
LIMIT 1;
```

#### Test 4.2: Update Transaction Atomicity
```bash
# Test that UPDATE operations maintain atomicity
# All changes should commit or rollback together

# Expected Result:
# - Either all updates succeed or all rollback
# - No partial updates
# - ProductHistory only updated on successful commit

# Status: PASS / FAIL
```

**Database Verification:**
```sql
-- Check that history and products are consistent
SELECT 
    p.product_id, 
    p.name, 
    p.price,
    h.action,
    h.new_price
FROM products p
LEFT JOIN product_history h ON p.product_id = h.product_id
WHERE p.product_id = 1
ORDER BY h.action_date DESC;
```

---

### Test Suite 5: DELETE Operations

#### Test 5.1: DeleteProductAsync - Delete Product
```bash
# First, create a test product to delete
dotnet run -- add "Product To Delete" 19.99 5 "Temporary product"
# Note the returned ProductId (e.g., 19)

# Execute delete
dotnet run -- delete 19

# Expected Result:
# - Product is deleted from database
# - CTE-based transaction executes correctly
# - ProductHistory records DELETE action
# - No SQL errors
# - Foreign key constraints handled properly

# Validation Steps:
# 1. Verify product no longer exists in products table
# 2. Verify DELETE record in product_history
# 3. Confirm transaction completed successfully

# Status: PASS / FAIL
```

**Database Verification:**
```sql
-- Verify product deleted
SELECT * FROM products WHERE product_id = 19;
-- Should return no rows

-- Verify history record exists
SELECT * FROM product_history 
WHERE product_id = 19 
AND action = 'DELETE';
-- Should return one row
```

#### Test 5.2: Delete Transaction Atomicity
```bash
# Test that DELETE operations maintain atomicity

# Expected Result:
# - Product deleted completely or not at all
# - History record only created on successful delete
# - No orphaned records

# Status: PASS / FAIL
```

---

### Test Suite 6: Transaction Integrity

#### Test 6.1: Trigger Functionality
```sql
-- Run in psql to test trigger directly

-- Test INSERT trigger
INSERT INTO products (name, description, price, stock_quantity)
VALUES ('Trigger Test', 'Testing trigger', 50.00, 10)
RETURNING product_id;

-- Verify history record created
SELECT * FROM product_history WHERE action = 'INSERT' ORDER BY action_date DESC LIMIT 1;

-- Test UPDATE trigger
UPDATE products 
SET price = 55.00, stock_quantity = 8
WHERE name = 'Trigger Test';

-- Verify history record created
SELECT * FROM product_history WHERE action = 'UPDATE' ORDER BY action_date DESC LIMIT 1;

-- Test DELETE trigger
DELETE FROM products WHERE name = 'Trigger Test';

-- Verify history record created
SELECT * FROM product_history WHERE action = 'DELETE' ORDER BY action_date DESC LIMIT 1;
```

**Expected Result:**
- Each operation creates appropriate history record
- Old and new values captured correctly
- Trigger executes without errors

**Status: PASS / FAIL**

#### Test 6.2: RETURNING Clause Functionality
```sql
-- Run in psql to test RETURNING clause

INSERT INTO products (name, description, price, stock_quantity)
VALUES ('RETURNING Test', 'Testing RETURNING', 75.00, 15)
RETURNING product_id, name, price, created_date;

-- Expected Result:
-- - Returns the inserted values immediately
-- - ProductId is auto-generated (SERIAL)
-- - CreatedDate is auto-populated
```

**Status: PASS / FAIL**

---

### Test Suite 7: PostgreSQL-Specific Features

#### Test 7.1: Common Table Expressions (CTEs)
```bash
# CTE usage is in GetAllProductsAsync, GetProductByIdAsync, GetLowStockProductsAsync
# Test through normal operations

dotnet run -- list
dotnet run -- low-stock 10

# Expected Result:
# - Queries execute without errors
# - Results are accurate
# - CTE syntax is correct for PostgreSQL

# Status: PASS / FAIL
```

#### Test 7.2: Window Functions
```bash
# Window functions used in GetProductsByPriceRangeAsync

dotnet run -- price-range 100 500

# Expected Result:
# - ROW_NUMBER() and PERCENT_RANK() execute correctly
# - Ranking columns populated
# - Partition and order clauses work properly

# Status: PASS / FAIL
```

---

## Test Results Summary

### Template

| Test ID | Test Name | Status | Notes |
|---------|-----------|--------|-------|
| 1.1 | Database Connection | ☐ PASS ☐ FAIL | |
| 1.2 | Connection String | ☐ PASS ☐ FAIL | |
| 2.1 | Get All Products | ☐ PASS ☐ FAIL | |
| 2.2 | Get Product By ID | ☐ PASS ☐ FAIL | |
| 2.3 | Price Range Query | ☐ PASS ☐ FAIL | |
| 2.4 | Low Stock Query | ☐ PASS ☐ FAIL | |
| 3.1 | Insert Product | ☐ PASS ☐ FAIL | |
| 3.2 | Insert Transaction | ☐ PASS ☐ FAIL | |
| 4.1 | Update Product | ☐ PASS ☐ FAIL | |
| 4.2 | Update Transaction | ☐ PASS ☐ FAIL | |
| 5.1 | Delete Product | ☐ PASS ☐ FAIL | |
| 5.2 | Delete Transaction | ☐ PASS ☐ FAIL | |
| 6.1 | Trigger Functionality | ☐ PASS ☐ FAIL | |
| 6.2 | RETURNING Clause | ☐ PASS ☐ FAIL | |
| 7.1 | CTEs | ☐ PASS ☐ FAIL | |
| 7.2 | Window Functions | ☐ PASS ☐ FAIL | |

### Completion Criteria

**All Tests PASS** = Migration validation complete  
**Any Test FAIL** = Requires investigation and fix

---

## Troubleshooting Common Issues

### Issue: Connection Refused
**Cause**: PostgreSQL not running or wrong port  
**Solution**: 
```bash
# Check PostgreSQL status
sudo systemctl status postgresql
# Start if needed
sudo systemctl start postgresql
```

### Issue: Authentication Failed
**Cause**: Wrong username/password  
**Solution**: Update appsettings.json with correct credentials

### Issue: Relation Does Not Exist
**Cause**: Schema not created  
**Solution**: Run 01_InitialSetup_PostgreSQL.sql

### Issue: Syntax Error in SQL
**Cause**: SQL Server syntax not converted  
**Solution**: Review converted_statements.sql and verify conversion

### Issue: Transaction Rollback
**Cause**: Constraint violation or logic error  
**Solution**: Check PostgreSQL logs and application error messages

---

## Automated Testing (Future Enhancement)

Consider creating unit tests using:
- xUnit or NUnit
- Npgsql for database access
- Test fixtures for database setup/teardown
- Mock data for isolated testing

Example test structure:
```csharp
[Fact]
public async Task GetAllProductsAsync_ReturnsAllProducts()
{
    // Arrange
    var repository = new ProductRepository(configuration);
    
    // Act
    var products = await repository.GetAllProductsAsync();
    
    // Assert
    Assert.NotEmpty(products);
    Assert.Equal(18, products.Count());
}
```

---

## Reporting Results

After completing all tests, document:
1. Test execution date/time
2. PostgreSQL version
3. .NET version
4. Pass/Fail count
5. Any issues encountered
6. Recommendations for production deployment

**Report Template:**
```
PostgreSQL Functional Testing Report
=====================================
Date: [DATE]
Tester: [NAME]
Environment: [DEV/TEST/PROD]

PostgreSQL Version: [VERSION]
.NET Version: [VERSION]
Application Version: [VERSION]

Tests Executed: [TOTAL]
Tests Passed: [COUNT]
Tests Failed: [COUNT]

Failed Tests Details:
[LIST ANY FAILURES]

Recommendations:
[PRODUCTION READINESS ASSESSMENT]

Conclusion:
☐ READY FOR PRODUCTION
☐ REQUIRES FIXES
```
