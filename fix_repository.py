#!/usr/bin/env python3
import re

with open('DataAccess/ProductRepository.cs', 'r') as f:
    content = f.read()

# Fix InsertProductAsync - remove T-SQL syntax and use PostgreSQL RETURNING
insert_pattern = r'public async Task<int> InsertProductAsync\(Product product\)\s*\{[^}]*?return Convert\.ToInt32\(await command\.ExecuteScalarAsync\(\)\);[^}]*?\}'

insert_replacement = '''public async Task<int> InsertProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                // Insert the new product and return the generated ID
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
                    VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW())";
                
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
                        LastUpdated = NOW()
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
        }'''

content = re.sub(insert_pattern, insert_replacement, content, flags=re.DOTALL)

# Fix UpdateProductAsync
update_pattern = r'public async Task UpdateProductAsync\(Product product\)\s*\{[^}]*?await command\.ExecuteNonQueryAsync\(\);[^}]*?\}'

update_replacement = '''public async Task UpdateProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                // Get old values for history
                decimal oldPrice;
                int oldStock;
                
                const string selectSql = @"
                    SELECT Price, StockQuantity
                    FROM Products
                    WHERE ProductId = @ProductId";
                
                using (var selectCommand = new NpgsqlCommand(selectSql, connection, transaction))
                {
                    selectCommand.Parameters.AddWithValue("@ProductId", product.ProductId);
                    
                    using var reader = await selectCommand.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        oldPrice = reader.GetDecimal(0);
                        oldStock = reader.GetInt32(1);
                    }
                    else
                    {
                        throw new InvalidOperationException($"Product with ID {product.ProductId} not found.");
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
                        ModifiedDate = NOW()
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
                    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW())";
                
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
                        LastUpdated = NOW()
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
        }'''

content = re.sub(update_pattern, update_replacement, content, flags=re.DOTALL)

# Fix DeleteProductAsync
delete_pattern = r'public async Task DeleteProductAsync\(int productId\)\s*\{[^}]*?await command\.ExecuteNonQueryAsync\(\);[^}]*?\}'

delete_replacement = '''public async Task DeleteProductAsync(int productId)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                // Store product info for history
                decimal oldPrice;
                int oldStock;
                
                const string selectSql = @"
                    SELECT Price, StockQuantity
                    FROM Products
                    WHERE ProductId = @ProductId";
                
                using (var selectCommand = new NpgsqlCommand(selectSql, connection, transaction))
                {
                    selectCommand.Parameters.AddWithValue("@ProductId", productId);
                    
                    using var reader = await selectCommand.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        oldPrice = reader.GetDecimal(0);
                        oldStock = reader.GetInt32(1);
                    }
                    else
                    {
                        throw new InvalidOperationException($"Product with ID {productId} not found.");
                    }
                }
                
                // Log the deletion
                const string historySql = @"
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW())";
                
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
                        LastUpdated = NOW()
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
        }'''

content = re.sub(delete_pattern, delete_replacement, content, flags=re.DOTALL)

with open('DataAccess/ProductRepository.cs', 'w') as f:
    f.write(content)

print("Successfully fixed ProductRepository.cs")
print("- Fixed InsertProductAsync: Removed T-SQL DECLARE/@NewProductId, BEGIN TRANSACTION/COMMIT, SCOPE_IDENTITY(), replaced with RETURNING clause")
print("- Fixed UpdateProductAsync: Removed T-SQL DECLARE/@OldPrice/@OldStock, BEGIN TRANSACTION/COMMIT, replaced with separate SELECT")
print("- Fixed DeleteProductAsync: Removed T-SQL DECLARE/@OldPrice/@OldStock, BEGIN TRANSACTION/COMMIT, replaced with separate SELECT")
