# Transaction Code Comparison - Before and After

## InsertProductAsync

### BEFORE (Invalid PostgreSQL) ❌
```csharp
public async Task<int> InsertProductAsync(Product product)
{
    var connection = await GetConnectionAsync();

    const string sql = @"
        DECLARE @NewProductId INT;
        
        BEGIN TRANSACTION;
            -- Insert the new product
            INSERT INTO Products (Name, Description, Price, StockQuantity)
            VALUES (@Name, @Description, @Price, @StockQuantity);
            
            SET @NewProductId = LASTVAL();  -- ❌ INVALID: Not a valid function call
            
            -- Log the insertion
            INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
            VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
            
            -- Update product statistics
            UPDATE ProductStats
            SET 
                TotalProducts = TotalProducts + 1,
                AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
                LastUpdated = CURRENT_TIMESTAMP
            WHERE StatId = 1;
        COMMIT;
        
        SELECT @NewProductId;";  -- ❌ INVALID: Variable doesn't exist in this context

    using var command = new NpgsqlCommand(sql, connection);
    command.Parameters.AddWithValue("@Name", product.Name);
    command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
    command.Parameters.AddWithValue("@Price", product.Price);
    command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);

    return Convert.ToInt32(await command.ExecuteScalarAsync());
}
```

**Issues**:
- ❌ `DECLARE @NewProductId INT` - Not supported in client-side PostgreSQL SQL
- ❌ `SET @NewProductId = LASTVAL()` - LASTVAL() doesn't work this way
- ❌ `BEGIN TRANSACTION; ... COMMIT;` - Cannot be in SQL string with Npgsql
- ❌ `SELECT @NewProductId` - Variable doesn't exist

### AFTER (Valid PostgreSQL) ✅
```csharp
public async Task<int> InsertProductAsync(Product product)
{
    var connection = await GetConnectionAsync();
    using var transaction = await connection.BeginTransactionAsync();  // ✅ ADO.NET transaction
    
    try
    {
        // Insert the new product
        const string insertSql = @"
            INSERT INTO Products (Name, Description, Price, StockQuantity)
            VALUES (@Name, @Description, @Price, @StockQuantity)
            RETURNING ProductId";  // ✅ PostgreSQL RETURNING clause

        int newProductId;  // ✅ C# variable instead of SQL variable
        using (var command = new NpgsqlCommand(insertSql, connection, transaction))
        {
            command.Parameters.AddWithValue("@Name", product.Name);
            command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
            
            newProductId = Convert.ToInt32(await command.ExecuteScalarAsync());  // ✅ Get ID from RETURNING
        }
        
        // Log the insertion
        const string historySql = @"
            INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
            VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP)";
            
        using (var command = new NpgsqlCommand(historySql, connection, transaction))
        {
            command.Parameters.AddWithValue("@ProductId", newProductId);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
            await command.ExecuteNonQueryAsync();
        }
        
        // Update product statistics
        const string statsSql = @"
            UPDATE ProductStats
            SET 
                TotalProducts = TotalProducts + 1,
                AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
                LastUpdated = CURRENT_TIMESTAMP
            WHERE StatId = 1";
            
        using (var command = new NpgsqlCommand(statsSql, connection, transaction))
        {
            command.Parameters.AddWithValue("@Price", product.Price);
            await command.ExecuteNonQueryAsync();
        }
        
        await transaction.CommitAsync();  // ✅ Commit via ADO.NET
        return newProductId;
    }
    catch
    {
        await transaction.RollbackAsync();  // ✅ Rollback on error
        throw;
    }
}
```

**Benefits**:
- ✅ Valid PostgreSQL syntax throughout
- ✅ Proper transaction management via ADO.NET
- ✅ Type-safe C# variables
- ✅ Clear error handling with rollback
- ✅ Separate SQL commands for better maintainability

---

## UpdateProductAsync

### BEFORE (Invalid PostgreSQL) ❌
```csharp
public async Task UpdateProductAsync(Product product)
{
    var connection = await GetConnectionAsync();

    const string sql = @"
        BEGIN TRANSACTION;
            -- Store old values for history
            DECLARE @OldPrice DECIMAL(18,2);  -- ❌ INVALID in client SQL
            DECLARE @OldStock INT;            -- ❌ INVALID in client SQL
            
            SELECT @OldPrice = Price, @OldStock = StockQuantity  -- ❌ INVALID syntax
            FROM Products
            WHERE ProductId = @ProductId;
            
            -- Update the product
            UPDATE Products
            SET 
                Name = @Name,
                Description = @Description,
                Price = @Price,
                StockQuantity = @StockQuantity,
                ModifiedDate = CURRENT_TIMESTAMP
            WHERE ProductId = @ProductId;
            
            -- Log the changes
            INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
            VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);
            
            -- Update product statistics
            UPDATE ProductStats
            SET 
                AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
                LastUpdated = CURRENT_TIMESTAMP
            WHERE StatId = 1;
        COMMIT;";

    using var command = new NpgsqlCommand(sql, connection);
    command.Parameters.AddWithValue("@ProductId", product.ProductId);
    command.Parameters.AddWithValue("@Name", product.Name);
    command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
    command.Parameters.AddWithValue("@Price", product.Price);
    command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);

    await command.ExecuteNonQueryAsync();
}
```

**Issues**:
- ❌ `DECLARE @OldPrice` and `DECLARE @OldStock` - Not supported in client-side PostgreSQL SQL
- ❌ `SELECT @Var = Column` - Not valid PostgreSQL syntax
- ❌ `BEGIN TRANSACTION; ... COMMIT;` - Cannot be in SQL string with Npgsql

### AFTER (Valid PostgreSQL) ✅
```csharp
public async Task UpdateProductAsync(Product product)
{
    var connection = await GetConnectionAsync();
    using var transaction = await connection.BeginTransactionAsync();  // ✅ ADO.NET transaction
    
    try
    {
        // Store old values for history
        decimal oldPrice;  // ✅ C# variable
        int oldStock;      // ✅ C# variable
        
        const string selectSql = @"
            SELECT Price, StockQuantity
            FROM Products
            WHERE ProductId = @ProductId";  // ✅ Standard PostgreSQL SELECT
            
        using (var command = new NpgsqlCommand(selectSql, connection, transaction))
        {
            command.Parameters.AddWithValue("@ProductId", product.ProductId);
            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                oldPrice = reader.GetDecimal(0);  // ✅ Read into C# variable
                oldStock = reader.GetInt32(1);    // ✅ Read into C# variable
            }
            else
            {
                throw new InvalidOperationException($"Product with ID {product.ProductId} not found");
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
            
        using (var command = new NpgsqlCommand(updateSql, connection, transaction))
        {
            command.Parameters.AddWithValue("@ProductId", product.ProductId);
            command.Parameters.AddWithValue("@Name", product.Name);
            command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
            await command.ExecuteNonQueryAsync();
        }
        
        // Log the changes
        const string historySql = @"
            INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
            VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP)";
            
        using (var command = new NpgsqlCommand(historySql, connection, transaction))
        {
            command.Parameters.AddWithValue("@ProductId", product.ProductId);
            command.Parameters.AddWithValue("@OldPrice", oldPrice);  // ✅ Use C# variable
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@OldStock", oldStock);  // ✅ Use C# variable
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
            await command.ExecuteNonQueryAsync();
        }
        
        // Update product statistics
        const string statsSql = @"
            UPDATE ProductStats
            SET 
                AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
                LastUpdated = CURRENT_TIMESTAMP
            WHERE StatId = 1";
            
        using (var command = new NpgsqlCommand(statsSql, connection, transaction))
        {
            command.Parameters.AddWithValue("@OldPrice", oldPrice);  // ✅ Use C# variable
            command.Parameters.AddWithValue("@Price", product.Price);
            await command.ExecuteNonQueryAsync();
        }
        
        await transaction.CommitAsync();  // ✅ Commit via ADO.NET
    }
    catch
    {
        await transaction.RollbackAsync();  // ✅ Rollback on error
        throw;
    }
}
```

**Benefits**:
- ✅ Valid PostgreSQL syntax throughout
- ✅ Type-safe C# variables for old values
- ✅ Proper error handling for missing records
- ✅ Clear separation of concerns
- ✅ Proper transaction management

---

## DeleteProductAsync

**Same pattern as UpdateProductAsync** - refactored from SQL Server DECLARE syntax to C# variables with ADO.NET transaction management.

---

## Key Takeaways

### What Was Wrong
1. **SQL Server syntax in PostgreSQL**: DECLARE, SET, BEGIN TRANSACTION in SQL strings don't work with PostgreSQL client-side execution
2. **Variable scope issues**: SQL variables declared in one command aren't accessible in subsequent commands
3. **LASTVAL() misuse**: Not a scalar function, can't be used with SET

### Why ADO.NET Transactions Are Better
1. **Database-agnostic**: Works with any ADO.NET provider
2. **Type-safe**: Variables are C# typed, not SQL typed
3. **Better error handling**: Native C# exceptions and try-catch
4. **Clearer code**: Separation between SQL and transaction logic
5. **Maintainable**: Easier to debug and modify

### Runtime Behavior
- **BEFORE**: Would throw PostgreSQL syntax errors at runtime
- **AFTER**: Executes successfully with proper ACID guarantees

---

## Testing Verification

To verify the fixes work correctly:

```csharp
// Test InsertProductAsync
var product = new Product 
{ 
    Name = "Test", 
    Price = 10.00m, 
    StockQuantity = 5 
};
int id = await repo.InsertProductAsync(product);
// Should return valid ID and commit all three operations atomically

// Test UpdateProductAsync
product.ProductId = id;
product.Price = 15.00m;
await repo.UpdateProductAsync(product);
// Should update product, log history, update stats atomically

// Test DeleteProductAsync
await repo.DeleteProductAsync(id);
// Should delete product, log history, update stats atomically
```

All operations maintain ACID properties:
- ✅ **Atomicity**: All operations commit or rollback together
- ✅ **Consistency**: Database constraints enforced
- ✅ **Isolation**: No partial visibility of changes
- ✅ **Durability**: Changes persist after commit
