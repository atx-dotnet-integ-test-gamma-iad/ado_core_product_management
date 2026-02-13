#!/usr/bin/env python3
import re

# Read the file
with open('DataAccess/ProductRepository.cs', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: InsertProductAsync - find by unique pattern
insert_pattern = r'(        public async Task<int> InsertProductAsync\(Product product\)\s*\{\s*var connection = await GetConnectionAsync\(\);)\s*const string sql = @"[^"]*DECLARE @NewProductId INT;[^"]*";[^}]*return Convert\.ToInt32\(await command\.ExecuteScalarAsync\(\)\);\s*\}'

insert_replacement = r'''\1
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                int newProductId;
                
                // Insert the new product and get the ID using RETURNING clause
                const string insertProductSql = @"
                    INSERT INTO Products (Name, Description, Price, StockQuantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING ProductId";

                using (var command = new NpgsqlCommand(insertProductSql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@Name", product.Name);
                    command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                    command.Parameters.AddWithValue("@Price", product.Price);
                    command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    newProductId = Convert.ToInt32(await command.ExecuteScalarAsync());
                }
                
                // Log the insertion
                const string insertHistorySql = @"
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP)";

                using (var command = new NpgsqlCommand(insertHistorySql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@ProductId", newProductId);
                    command.Parameters.AddWithValue("@Price", product.Price);
                    command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    await command.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
                const string updateStatsSql = @"
                    UPDATE ProductStats
                    SET 
                        TotalProducts = TotalProducts + 1,
                        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
                        LastUpdated = CURRENT_TIMESTAMP
                    WHERE StatId = 1";

                using (var command = new NpgsqlCommand(updateStatsSql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@Price", product.Price);
                    
                    await command.ExecuteNonQueryAsync();
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

# Fix 2: UpdateProductAsync - find by unique pattern  
update_pattern = r'(        public async Task UpdateProductAsync\(Product product\)\s*\{\s*var connection = await GetConnectionAsync\(\);)\s*const string sql = @"[^"]*BEGIN TRANSACTION;[^"]*DECLARE @OldPrice DECIMAL[^"]*";[^}]*await command\.ExecuteNonQueryAsync\(\);\s*\}'

update_replacement = r'''\1
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                decimal oldPrice;
                int oldStock;
                
                // Store old values for history
                const string selectOldValuesSql = @"
                    SELECT Price, StockQuantity
                    FROM Products
                    WHERE ProductId = @ProductId";

                using (var command = new NpgsqlCommand(selectOldValuesSql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@ProductId", product.ProductId);
                    
                    using var reader = await command.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        oldPrice = reader.GetDecimal(0);
                        oldStock = reader.GetInt32(1);
                    }
                    else
                    {
                        throw new InvalidOperationException($"Product with ID {product.ProductId} not found");
                    }
                }
                
                // Update the product
                const string updateProductSql = @"
                    UPDATE Products
                    SET 
                        Name = @Name,
                        Description = @Description,
                        Price = @Price,
                        StockQuantity = @StockQuantity,
                        ModifiedDate = CURRENT_TIMESTAMP
                    WHERE ProductId = @ProductId";

                using (var command = new NpgsqlCommand(updateProductSql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@ProductId", product.ProductId);
                    command.Parameters.AddWithValue("@Name", product.Name);
                    command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                    command.Parameters.AddWithValue("@Price", product.Price);
                    command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    await command.ExecuteNonQueryAsync();
                }
                
                // Log the changes
                const string insertHistorySql = @"
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP)";

                using (var command = new NpgsqlCommand(insertHistorySql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@ProductId", product.ProductId);
                    command.Parameters.AddWithValue("@OldPrice", oldPrice);
                    command.Parameters.AddWithValue("@Price", product.Price);
                    command.Parameters.AddWithValue("@OldStock", oldStock);
                    command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    await command.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
                const string updateStatsSql = @"
                    UPDATE ProductStats
                    SET 
                        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
                        LastUpdated = CURRENT_TIMESTAMP
                    WHERE StatId = 1";

                using (var command = new NpgsqlCommand(updateStatsSql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@OldPrice", oldPrice);
                    command.Parameters.AddWithValue("@Price", product.Price);
                    
                    await command.ExecuteNonQueryAsync();
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

# Fix 3: DeleteProductAsync - find by unique pattern
delete_pattern = r'(        public async Task DeleteProductAsync\(int productId\)\s*\{\s*var connection = await GetConnectionAsync\(\);)\s*const string sql = @"[^"]*BEGIN TRANSACTION;[^"]*DECLARE @OldPrice DECIMAL[^"]*DELETE FROM Products[^"]*";[^}]*await command\.ExecuteNonQueryAsync\(\);\s*\}'

delete_replacement = r'''\1
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                decimal oldPrice;
                int oldStock;
                
                // Store product info for history
                const string selectOldValuesSql = @"
                    SELECT Price, StockQuantity
                    FROM Products
                    WHERE ProductId = @ProductId";

                using (var command = new NpgsqlCommand(selectOldValuesSql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@ProductId", productId);
                    
                    using var reader = await command.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        oldPrice = reader.GetDecimal(0);
                        oldStock = reader.GetInt32(1);
                    }
                    else
                    {
                        throw new InvalidOperationException($"Product with ID {productId} not found");
                    }
                }
                
                // Log the deletion
                const string insertHistorySql = @"
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP)";

                using (var command = new NpgsqlCommand(insertHistorySql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@ProductId", productId);
                    command.Parameters.AddWithValue("@OldPrice", oldPrice);
                    command.Parameters.AddWithValue("@OldStock", oldStock);
                    
                    await command.ExecuteNonQueryAsync();
                }
                
                // Delete the product
                const string deleteProductSql = @"
                    DELETE FROM Products 
                    WHERE ProductId = @ProductId";

                using (var command = new NpgsqlCommand(deleteProductSql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@ProductId", productId);
                    
                    await command.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
                const string updateStatsSql = @"
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

                using (var command = new NpgsqlCommand(updateStatsSql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@OldPrice", oldPrice);
                    
                    await command.ExecuteNonQueryAsync();
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

# Save back
with open('DataAccess/ProductRepository.cs', 'w', encoding='utf-8') as f:
    f.write(content)

print("All transaction methods updated successfully")
print("- InsertProductAsync: T-SQL replaced with C# transaction + RETURNING clause")
print("- UpdateProductAsync: T-SQL replaced with C# transaction + separate queries")
print("- DeleteProductAsync: T-SQL replaced with C# transaction + separate queries")
