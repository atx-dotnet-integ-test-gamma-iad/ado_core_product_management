#!/usr/bin/env python3
"""
Script to fix transaction statements in ProductRepository.cs
Replaces SQL Server syntax with PostgreSQL syntax for transaction methods
"""

import re

def fix_insert_method(content):
    """Fix InsertProductAsync method"""
    old_pattern = r'public async Task<int> InsertProductAsync\(Product product\)\s*\{[^}]*?var connection = await GetConnectionAsync\(\);[^}]*?const string sql = @"[^"]*?";[^}]*?using var command = new NpgsqlCommand\(sql, connection\);[^}]*?command\.Parameters\.AddWithValue\("@Name", product\.Name\);[^}]*?command\.Parameters\.AddWithValue\("@Description", \(object\)product\.Description \?\? DBNull\.Value\);[^}]*?command\.Parameters\.AddWithValue\("@Price", product\.Price\);[^}]*?command\.Parameters\.AddWithValue\("@StockQuantity", product\.StockQuantity\);[^}]*?return Convert\.ToInt32\(await command\.ExecuteScalarAsync\(\)\);[^}]*?\}'
    
    new_method = '''public async Task<int> InsertProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                // Insert the new product and get the ID using RETURNING clause
                const string insertSql = @"
                    INSERT INTO products (name, description, price, stockquantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING productid";

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
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
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
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                        lastupdated = CURRENT_TIMESTAMP
                    WHERE statid = 1";
                
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
    
    return re.sub(old_pattern, new_method, content, flags=re.DOTALL)

def fix_update_method(content):
    """Fix UpdateProductAsync method"""
    old_pattern = r'public async Task UpdateProductAsync\(Product product\)\s*\{[^}]*?var connection = await GetConnectionAsync\(\);[^}]*?const string sql = @"[^"]*?";[^}]*?using var command = new NpgsqlCommand\(sql, connection\);[^}]*?command\.Parameters\.AddWithValue\("@ProductId", product\.ProductId\);[^}]*?command\.Parameters\.AddWithValue\("@Name", product\.Name\);[^}]*?command\.Parameters\.AddWithValue\("@Description", \(object\)product\.Description \?\? DBNull\.Value\);[^}]*?command\.Parameters\.AddWithValue\("@Price", product\.Price\);[^}]*?command\.Parameters\.AddWithValue\("@StockQuantity", product\.StockQuantity\);[^}]*?await command\.ExecuteNonQueryAsync\(\);[^}]*?\}'
    
    new_method = '''public async Task UpdateProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                // Store old values for history
                const string selectSql = @"
                    SELECT price, stockquantity
                    FROM products
                    WHERE productid = @ProductId";
                
                decimal oldPrice;
                int oldStock;
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
                        throw new InvalidOperationException($"Product with ID {product.ProductId} not found");
                    }
                }
                
                // Update the product
                const string updateSql = @"
                    UPDATE products
                    SET 
                        name = @Name,
                        description = @Description,
                        price = @Price,
                        stockquantity = @StockQuantity,
                        modifieddate = CURRENT_TIMESTAMP
                    WHERE productid = @ProductId";
                
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
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'UPDATE', @OldPrice, @NewPrice, @OldStock, @NewStock, CURRENT_TIMESTAMP)";
                
                using (var historyCommand = new NpgsqlCommand(historySql, connection, transaction))
                {
                    historyCommand.Parameters.AddWithValue("@ProductId", product.ProductId);
                    historyCommand.Parameters.AddWithValue("@OldPrice", oldPrice);
                    historyCommand.Parameters.AddWithValue("@NewPrice", product.Price);
                    historyCommand.Parameters.AddWithValue("@OldStock", oldStock);
                    historyCommand.Parameters.AddWithValue("@NewStock", product.StockQuantity);
                    await historyCommand.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
                const string statsSql = @"
                    UPDATE productstats
                    SET 
                        averageprice = (averageprice * totalproducts - @OldPrice + @NewPrice) / totalproducts,
                        lastupdated = CURRENT_TIMESTAMP
                    WHERE statid = 1";
                
                using (var statsCommand = new NpgsqlCommand(statsSql, connection, transaction))
                {
                    statsCommand.Parameters.AddWithValue("@OldPrice", oldPrice);
                    statsCommand.Parameters.AddWithValue("@NewPrice", product.Price);
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
    
    return re.sub(old_pattern, new_method, content, flags=re.DOTALL)

def fix_delete_method(content):
    """Fix DeleteProductAsync method"""
    old_pattern = r'public async Task DeleteProductAsync\(int productId\)\s*\{[^}]*?var connection = await GetConnectionAsync\(\);[^}]*?const string sql = @"[^"]*?";[^}]*?using var command = new NpgsqlCommand\(sql, connection\);[^}]*?command\.Parameters\.AddWithValue\("@ProductId", productId\);[^}]*?await command\.ExecuteNonQueryAsync\(\);[^}]*?\}'
    
    new_method = '''public async Task DeleteProductAsync(int productId)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                // Store product info for history
                const string selectSql = @"
                    SELECT price, stockquantity
                    FROM products
                    WHERE productid = @ProductId";
                
                decimal oldPrice;
                int oldStock;
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
                        throw new InvalidOperationException($"Product with ID {productId} not found");
                    }
                }
                
                // Log the deletion
                const string historySql = @"
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
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
                    DELETE FROM products 
                    WHERE productid = @ProductId";
                
                using (var deleteCommand = new NpgsqlCommand(deleteSql, connection, transaction))
                {
                    deleteCommand.Parameters.AddWithValue("@ProductId", productId);
                    await deleteCommand.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
                const string statsSql = @"
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts - 1,
                        averageprice = CASE 
                            WHEN totalproducts > 1 
                            THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
                            ELSE 0
                        END,
                        lastupdated = CURRENT_TIMESTAMP
                    WHERE statid = 1";
                
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
    
    return re.sub(old_pattern, new_method, content, flags=re.DOTALL)

def main():
    file_path = 'ProductRepository.cs'
    
    # Read the file
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    print("Original file read successfully")
    print(f"File size: {len(content)} bytes")
    
    # Apply fixes
    content = fix_insert_method(content)
    print("InsertProductAsync method fixed")
    
    content = fix_update_method(content)
    print("UpdateProductAsync method fixed")
    
    content = fix_delete_method(content)
    print("DeleteProductAsync method fixed")
    
    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"File written successfully")
    print(f"New file size: {len(content)} bytes")

if __name__ == '__main__':
    main()
