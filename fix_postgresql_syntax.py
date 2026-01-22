#!/usr/bin/env python3
"""
Fix SQL Server-specific syntax in ProductRepository.cs to be PostgreSQL compatible.
This script replaces DECLARE statements, SCOPE_IDENTITY(), and variable assignments
with PostgreSQL-compatible alternatives using RETURNING clauses and CTEs.
"""

import re

def fix_product_repository():
    file_path = "/QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs"
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Fix InsertProductAsync method
    insert_old = r'''        public async Task<int> InsertProductAsync\(Product product\)
        \{
            var connection = await GetConnectionAsync\(\);

            const string sql = @"
                DECLARE @NewProductId INT;
                
                BEGIN;
                    -- Insert the new product
                    INSERT INTO Products \(Name, Description, Price, StockQuantity\)
                    VALUES \(@Name, @Description, @Price, @StockQuantity\);
                    
                    SET @NewProductId = SCOPE_IDENTITY\(\);
                    
                    -- Log the insertion
                    INSERT INTO ProductHistory \(ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate\)
                    VALUES \(@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW\(\)\);
                    
                    -- Update product statistics
                    UPDATE ProductStats
                    SET 
                        TotalProducts = TotalProducts \+ 1,
                        AveragePrice = \(AveragePrice \* TotalProducts \+ @Price\) / \(TotalProducts \+ 1\),
                        LastUpdated = NOW\(\)
                    WHERE StatId = 1;
                COMMIT;
                
                SELECT @NewProductId;";

            using var command = new NpgsqlCommand\(sql, connection\);
            command\.Parameters\.AddWithValue\("@Name", product\.Name\);
            command\.Parameters\.AddWithValue\("@Description", \(object\)product\.Description \?\? DBNull\.Value\);
            command\.Parameters\.AddWithValue\("@Price", product\.Price\);
            command\.Parameters\.AddWithValue\("@StockQuantity", product\.StockQuantity\);

            return Convert\.ToInt32\(await command\.ExecuteScalarAsync\(\)\);
        \}'''
    
    insert_new = '''        public async Task<int> InsertProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                // Step 1: Insert the new product and get the ID using RETURNING
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
                
                // Step 2: Log the insertion
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
                
                // Step 3: Update product statistics
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
    
    content = re.sub(insert_old, insert_new, content, flags=re.DOTALL)
    
    # Fix UpdateProductAsync method
    update_old = r'''        public async Task UpdateProductAsync\(Product product\)
        \{
            var connection = await GetConnectionAsync\(\);

            const string sql = @"
                BEGIN;
                    -- Store old values for history
                    DECLARE @OldPrice DECIMAL\(18,2\);
                    DECLARE @OldStock INT;
                    
                    SELECT @OldPrice = Price, @OldStock = StockQuantity
                    FROM Products
                    WHERE ProductId = @ProductId;
                    
                    -- Update the product
                    UPDATE Products
                    SET 
                        Name = @Name,
                        Description = @Description,
                        Price = @Price,
                        StockQuantity = @StockQuantity,
                        ModifiedDate = NOW\(\)
                    WHERE ProductId = @ProductId;
                    
                    -- Log the changes
                    INSERT INTO ProductHistory \(ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate\)
                    VALUES \(@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW\(\)\);
                    
                    -- Update product statistics
                    UPDATE ProductStats
                    SET 
                        AveragePrice = \(AveragePrice \* TotalProducts - @OldPrice \+ @Price\) / TotalProducts,
                        LastUpdated = NOW\(\)
                    WHERE StatId = 1;
                COMMIT;";

            using var command = new NpgsqlCommand\(sql, connection\);
            command\.Parameters\.AddWithValue\("@ProductId", product\.ProductId\);
            command\.Parameters\.AddWithValue\("@Name", product\.Name\);
            command\.Parameters\.AddWithValue\("@Description", \(object\)product\.Description \?\? DBNull\.Value\);
            command\.Parameters\.AddWithValue\("@Price", product\.Price\);
            command\.Parameters\.AddWithValue\("@StockQuantity", product\.StockQuantity\);

            await command\.ExecuteNonQueryAsync\(\);
        \}'''
    
    update_new = '''        public async Task UpdateProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                // Step 1: Get old values using CTE and update product
                const string updateSql = @"
                    WITH old_values AS (
                        SELECT Price as OldPrice, StockQuantity as OldStock
                        FROM Products
                        WHERE ProductId = @ProductId
                    )
                    UPDATE Products
                    SET 
                        Name = @Name,
                        Description = @Description,
                        Price = @Price,
                        StockQuantity = @StockQuantity,
                        ModifiedDate = NOW()
                    WHERE ProductId = @ProductId
                    RETURNING (SELECT OldPrice FROM old_values) as OldPrice, (SELECT OldStock FROM old_values) as OldStock";
                
                decimal oldPrice;
                int oldStock;
                using (var updateCommand = new NpgsqlCommand(updateSql, connection, transaction))
                {
                    updateCommand.Parameters.AddWithValue("@ProductId", product.ProductId);
                    updateCommand.Parameters.AddWithValue("@Name", product.Name);
                    updateCommand.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                    updateCommand.Parameters.AddWithValue("@Price", product.Price);
                    updateCommand.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    using var reader = await updateCommand.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        oldPrice = reader.GetDecimal(0);
                        oldStock = reader.GetInt32(1);
                    }
                    else
                    {
                        throw new InvalidOperationException("Product not found");
                    }
                }
                
                // Step 2: Log the changes
                const string historySql = @"
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@ProductId, 'UPDATE', @OldPrice, @NewPrice, @OldStock, @NewStock, NOW())";
                
                using (var historyCommand = new NpgsqlCommand(historySql, connection, transaction))
                {
                    historyCommand.Parameters.AddWithValue("@ProductId", product.ProductId);
                    historyCommand.Parameters.AddWithValue("@OldPrice", oldPrice);
                    historyCommand.Parameters.AddWithValue("@NewPrice", product.Price);
                    historyCommand.Parameters.AddWithValue("@OldStock", oldStock);
                    historyCommand.Parameters.AddWithValue("@NewStock", product.StockQuantity);
                    
                    await historyCommand.ExecuteNonQueryAsync();
                }
                
                // Step 3: Update product statistics
                const string statsSql = @"
                    UPDATE ProductStats
                    SET 
                        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @NewPrice) / TotalProducts,
                        LastUpdated = NOW()
                    WHERE StatId = 1";
                
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
    
    content = re.sub(update_old, update_new, content, flags=re.DOTALL)
    
    # Fix DeleteProductAsync method
    delete_old = r'''        public async Task DeleteProductAsync\(int productId\)
        \{
            var connection = await GetConnectionAsync\(\);

            const string sql = @"
                BEGIN;
                    -- Store product info for history
                    DECLARE @OldPrice DECIMAL\(18,2\);
                    DECLARE @OldStock INT;
                    
                    SELECT @OldPrice = Price, @OldStock = StockQuantity
                    FROM Products
                    WHERE ProductId = @ProductId;
                    
                    -- Log the deletion
                    INSERT INTO ProductHistory \(ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate\)
                    VALUES \(@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW\(\)\);
                    
                    -- Delete the product
                    DELETE FROM Products 
                    WHERE ProductId = @ProductId;
                    
                    -- Update product statistics
                    UPDATE ProductStats
                    SET 
                        TotalProducts = TotalProducts - 1,
                        AveragePrice = CASE 
                            WHEN TotalProducts > 1 
                            THEN \(AveragePrice \* TotalProducts - @OldPrice\) / \(TotalProducts - 1\)
                            ELSE 0
                        END,
                        LastUpdated = NOW\(\)
                    WHERE StatId = 1;
                COMMIT;";

            using var command = new NpgsqlCommand\(sql, connection\);
            command\.Parameters\.AddWithValue\("@ProductId", productId\);

            await command\.ExecuteNonQueryAsync\(\);
        \}'''
    
    delete_new = '''        public async Task DeleteProductAsync(int productId)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                // Step 1: Get product info and delete it
                const string deleteSql = @"
                    DELETE FROM Products 
                    WHERE ProductId = @ProductId
                    RETURNING Price as OldPrice, StockQuantity as OldStock";
                
                decimal oldPrice;
                int oldStock;
                using (var deleteCommand = new NpgsqlCommand(deleteSql, connection, transaction))
                {
                    deleteCommand.Parameters.AddWithValue("@ProductId", productId);
                    
                    using var reader = await deleteCommand.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        oldPrice = reader.GetDecimal(0);
                        oldStock = reader.GetInt32(1);
                    }
                    else
                    {
                        throw new InvalidOperationException("Product not found");
                    }
                }
                
                // Step 2: Log the deletion
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
                
                // Step 3: Update product statistics
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
    
    content = re.sub(delete_old, delete_new, content, flags=re.DOTALL)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("Successfully fixed ProductRepository.cs with PostgreSQL-compatible SQL")

if __name__ == "__main__":
    fix_product_repository()
