# CRITICAL SQL STATEMENT RE-INTEGRATION REQUIRED

## Issue Summary
ProductRepository.cs contains SQL Server-specific syntax that is NOT PostgreSQL compatible. While converted_statements.sql shows the correct PostgreSQL conversions, the actual code was NOT properly updated.

## Files Affected
- **DataAccess/ProductRepository.cs** (Lines 128-244)

## Required Fixes

###  1. InsertProductAsync Method (Lines 128-161)
**Problem:** Uses SQL Server DECLARE, SCOPE_IDENTITY(), embedded BEGIN/COMMIT
**Solution:** Use PostgreSQL RETURNING clause with application-level transaction handling

**Replace lines 128-161 with:**
```csharp
public async Task<int> InsertProductAsync(Product product)
{
    var connection = await GetConnectionAsync();
    using var transaction = await connection.BeginTransactionAsync();

    try
    {
        // Insert the new product and get the ID using RETURNING clause
        const string insertSql = @"
            INSERT INTO Products (Name, Description, Price, StockQuantity)
            VALUES (@Name, @Description, @Price, @StockQuantity)
            RETURNING ProductId";

        int newProductId;
        using (var insertCommand = new NpgsqlCommand(insertSql, connection, transaction))
        {
            insertCommand.Parameters.AddWithValue("@Name", product.Name);
            insertCommand.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
            insertCommand.Parameters.AddWithValue("@Price", product.Price);
            insertCommand.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);

            newProductId = Convert.ToInt32(await insertCommand.ExecuteScalarAsync());
        }

        // Log the insertion
        const string historySql = @"
            INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
            VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP)";

        using (var historyCommand = new NpgsqlCommand(historySql, connection, transaction))
        {
            historyCommand.Parameters.AddWithValue("@ProductId", newProductId);
            historyCommand.Parameters.AddWithValue("@Price", product.Price);
            historyCommand.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);

            await historyCommand.ExecuteNonQueryAsync();
        }

        // Update product statistics
        const string statsSql = @"
            UPDATE ProductStats
            SET 
                TotalProducts = TotalProducts + 1,
                AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
                LastUpdated = CURRENT_TIMESTAMP
            WHERE StatId = 1";

        using (var statsCommand = new NpgsqlCommand(statsSql, connection, transaction))
        {
            statsCommand.Parameters.AddWithValue("@Price", product.Price);
            await statsCommand.ExecuteNonQueryAsync();
        }

        await transaction.CommitAsync();
        return newProductId;
    }
    catch
    {
        await transaction.RollbackAsync();
        throw;
    }
}
```

### 2. UpdateProductAsync Method (Lines 163-207)
**Problem:** Uses SQL Server DECLARE, embedded BEGIN/COMMIT, T-SQL variable assignment
**Solution:** Fetch old values in application code, use PostgreSQL transaction handling

**Replace lines 163-207 with:**
```csharp
public async Task UpdateProductAsync(Product product)
{
    var connection = await GetConnectionAsync();
    using var transaction = await connection.BeginTransactionAsync();

    try
    {
        // Get old values first
        decimal oldPrice = 0;
        int oldStock = 0;

        const string getOldValuesSql = @"
            SELECT Price, StockQuantity
            FROM Products
            WHERE ProductId = @ProductId";

        using (var getOldCommand = new NpgsqlCommand(getOldValuesSql, connection, transaction))
        {
            getOldCommand.Parameters.AddWithValue("@ProductId", product.ProductId);
            using var reader = await getOldCommand.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                oldPrice = reader.GetDecimal(0);
                oldStock = reader.GetInt32(1);
            }
        }

        // Update the product
        const string updateSql = @"
            UPDATE Products
            SET 
                Name = @Name,
                Description = @Description,
                Price = @Price,
                StockQuantity = @StockQuantity,
                ModifiedDate = CURRENT_TIMESTAMP
            WHERE ProductId = @ProductId";

        using (var updateCommand = new NpgsqlCommand(updateSql, connection, transaction))
        {
            updateCommand.Parameters.AddWithValue("@ProductId", product.ProductId);
            updateCommand.Parameters.AddWithValue("@Name", product.Name);
            updateCommand.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
            updateCommand.Parameters.AddWithValue("@Price", product.Price);
            updateCommand.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);

            await updateCommand.ExecuteNonQueryAsync();
        }

        // Log the changes
        const string historySql = @"
            INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
            VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP)";

        using (var historyCommand = new NpgsqlCommand(historySql, connection, transaction))
        {
            historyCommand.Parameters.AddWithValue("@ProductId", product.ProductId);
            historyCommand.Parameters.AddWithValue("@OldPrice", oldPrice);
            historyCommand.Parameters.AddWithValue("@Price", product.Price);
            historyCommand.Parameters.AddWithValue("@OldStock", oldStock);
            historyCommand.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);

            await historyCommand.ExecuteNonQueryAsync();
        }

        // Update product statistics
        const string statsSql = @"
            UPDATE ProductStats
            SET 
                AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
                LastUpdated = CURRENT_TIMESTAMP
            WHERE StatId = 1";

        using (var statsCommand = new NpgsqlCommand(statsSql, connection, transaction))
        {
            statsCommand.Parameters.AddWithValue("@OldPrice", oldPrice);
            statsCommand.Parameters.AddWithValue("@Price", product.Price);

            await statsCommand.ExecuteNonQueryAsync();
        }

        await transaction.CommitAsync();
    }
    catch
    {
        await transaction.RollbackAsync();
        throw;
    }
}
```

### 3. DeleteProductAsync Method (Lines 209-253)
**Problem:** Uses SQL Server DECLARE, embedded BEGIN/COMMIT, T-SQL variable assignment
**Solution:** Fetch old values in application code, use PostgreSQL transaction handling

**Replace lines 209-253 with:**
```csharp
public async Task DeleteProductAsync(int productId)
{
    var connection = await GetConnectionAsync();
    using var transaction = await connection.BeginTransactionAsync();

    try
    {
        // Get old values first
        decimal oldPrice = 0;
        int oldStock = 0;

        const string getOldValuesSql = @"
            SELECT Price, StockQuantity
            FROM Products
            WHERE ProductId = @ProductId";

        using (var getOldCommand = new NpgsqlCommand(getOldValuesSql, connection, transaction))
        {
            getOldCommand.Parameters.AddWithValue("@ProductId", productId);
            using var reader = await getOldCommand.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                oldPrice = reader.GetDecimal(0);
                oldStock = reader.GetInt32(1);
            }
        }

        // Log the deletion
        const string historySql = @"
            INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
            VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP)";

        using (var historyCommand = new NpgsqlCommand(historySql, connection, transaction))
        {
            historyCommand.Parameters.AddWithValue("@ProductId", productId);
            historyCommand.Parameters.AddWithValue("@OldPrice", oldPrice);
            historyCommand.Parameters.AddWithValue("@OldStock", oldStock);

            await historyCommand.ExecuteNonQueryAsync();
        }

        // Delete the product
        const string deleteSql = @"
            DELETE FROM Products 
            WHERE ProductId = @ProductId";

        using (var deleteCommand = new NpgsqlCommand(deleteSql, connection, transaction))
        {
            deleteCommand.Parameters.AddWithValue("@ProductId", productId);
            await deleteCommand.ExecuteNonQueryAsync();
        }

        // Update product statistics
        const string statsSql = @"
            UPDATE ProductStats
            SET 
                TotalProducts = TotalProducts - 1,
                AveragePrice = CASE 
                    WHEN TotalProducts > 1 
                    THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
                    ELSE 0
                END,
                LastUpdated = CURRENT_TIMESTAMP
            WHERE StatId = 1";

        using (var statsCommand = new NpgsqlCommand(statsSql, connection, transaction))
        {
            statsCommand.Parameters.AddWithValue("@OldPrice", oldPrice);
            await statsCommand.ExecuteNonQueryAsync();
        }

        await transaction.CommitAsync();
    }
    catch
    {
        await transaction.RollbackAsync();
        throw;
    }
}
```

## Impact Analysis

### Runtime Failures Without Fixes
If the code is deployed without these fixes, the following will occur:

1. **InsertProductAsync**: Will fail with PostgreSQL syntax error on DECLARE @NewProductId and SCOPE_IDENTITY()
2. **UpdateProductAsync**: Will fail with PostgreSQL syntax error on DECLARE @OldPrice, DECLARE @OldStock
3. **DeleteProductAsync**: Will fail with PostgreSQL syntax error on DECLARE @OldPrice, DECLARE @OldStock

### After Applying Fixes
- All transaction operations will use native PostgreSQL syntax
- Application-level transaction management via NpgsqlTransaction
- RETURNING clause for efficient ID retrieval
- Proper error handling and rollback capability
- Full compatibility with PostgreSQL database

## Verification Steps
After applying fixes:
1. Build the project: `dotnet build` (should complete successfully)
2. Run against PostgreSQL database with test data
3. Verify all CRUD operations complete without errors
4. Confirm transaction atomicity maintained

## Reference
- Original SQL Server statements: DataAccess/ProductRepository.cs.backup
- Converted PostgreSQL statements: converted_statements.sql
- Conversion log: dms_conversion_log.txt
