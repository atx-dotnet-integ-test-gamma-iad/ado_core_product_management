using System;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Npgsql;
using Microsoft.Extensions.Configuration;
using AdoCore.Models;

namespace AdoCore.DataAccess
{
    public class ProductRepository : IAsyncDisposable
    {
        private readonly string _connectionString;
        private NpgsqlConnection _connection;
        private readonly IConfiguration _configuration;

        public ProductRepository(IConfiguration configuration)
        {
            _configuration = configuration;
            var environment = _configuration["Environment"];
            var connectionName = environment == "Production" ? "ProdConnection" : "DevConnection";
            _connectionString = _configuration.GetConnectionString(connectionName);
        }

        private async Task<NpgsqlConnection> GetConnectionAsync()
        {
            if (_connection == null)
            {
                _connection = new NpgsqlConnection(_connectionString);
            }
            if (_connection.State != ConnectionState.Open)
            {
                await _connection.OpenAsync();
            }
            return _connection;
        }

        public async Task<List<Product>> GetAllProductsAsync()
        {
            var products = new List<Product>();
            var connection = await GetConnectionAsync();

            const string sql = @"
                WITH productstats AS (
                    SELECT 
                        productid,
                        AVG(price) OVER() as avgprice,
                        COUNT(*) OVER() as totalproducts
                    FROM products
                )
                SELECT 
                    p.productid,
                    p.name,
                    p.description,
                    p.price,
                    p.stockquantity,
                    p.createddate,
                    p.modifieddate,
                    CASE 
                        WHEN p.price > ps.avgprice THEN 'Above Average'
                        WHEN p.price < ps.avgprice THEN 'Below Average'
                        ELSE 'Average'
                    END as pricecategory,
                    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
                FROM products p
                INNER JOIN productstats ps ON p.productid = ps.productid
                ORDER BY 
                    CASE 
                        WHEN p.price > ps.avgprice THEN 1
                        ELSE 2
                    END,
                    p.name";

            using var command = new NpgsqlCommand(sql, connection);
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                products.Add(MapProductFromReader(reader));
            }

            return products;
        }

        public async Task<Product> GetProductByIdAsync(int productId)
        {
            var connection = await GetConnectionAsync();

            const string sql = @"
                WITH producthistory AS (
                    SELECT 
                        productid,
                        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
                        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
                    FROM products
                    WHERE productid = $1
                )
                SELECT 
                    p.productid,
                    p.name,
                    p.description,
                    p.price,
                    p.stockquantity,
                    p.createddate,
                    p.modifieddate,
                    ph.previousprice,
                    ph.previousstock,
                    CASE 
                        WHEN ph.previousprice IS NOT NULL THEN 
                            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
                        ELSE NULL
                    END as pricechangepercentage
                FROM products p
                LEFT JOIN producthistory ph ON p.productid = ph.productid
                WHERE p.productid = $1";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue(productId);

            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                return MapProductFromReader(reader);
            }

            return null;
        }

        public async Task<int> InsertProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();
            
            // PostgreSQL approach: Use RETURNING clause to get the new product ID
            const string insertProductSql = @"
                INSERT INTO products (name, description, price, stockquantity)
                VALUES ($1, $2, $3, $4)
                RETURNING productid";
            
            const string insertHistorySql = @"
                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES ($1, 'INSERT', NULL, $2, NULL, $3, CURRENT_TIMESTAMP)";
            
            const string updateStatsSql = @"
                UPDATE productstats
                SET 
                    totalproducts = totalproducts + 1,
                    averageprice = (averageprice * totalproducts + $1) / (totalproducts + 1),
                    lastupdated = CURRENT_TIMESTAMP
                WHERE statid = 1";

            using var transaction = await connection.BeginTransactionAsync();
            try
            {
                // Insert the new product and get the ID
                int newProductId;
                using (var command = new NpgsqlCommand(insertProductSql, connection, transaction))
                {
                    command.Parameters.AddWithValue(product.Name);
                    command.Parameters.AddWithValue((object)product.Description ?? DBNull.Value);
                    command.Parameters.AddWithValue(product.Price);
                    command.Parameters.AddWithValue(product.StockQuantity);
                    newProductId = Convert.ToInt32(await command.ExecuteScalarAsync());
                }
                
                // Log the insertion
                using (var command = new NpgsqlCommand(insertHistorySql, connection, transaction))
                {
                    command.Parameters.AddWithValue(newProductId);
                    command.Parameters.AddWithValue(product.Price);
                    command.Parameters.AddWithValue(product.StockQuantity);
                    await command.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
                using (var command = new NpgsqlCommand(updateStatsSql, connection, transaction))
                {
                    command.Parameters.AddWithValue(product.Price);
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
        }

        public async Task UpdateProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();
            
            const string getOldValuesSql = @"
                SELECT price, stockquantity 
                FROM products 
                WHERE productid = $1";
            
            const string updateProductSql = @"
                UPDATE products
                SET 
                    name = $2,
                    description = $3,
                    price = $4,
                    stockquantity = $5,
                    modifieddate = CURRENT_TIMESTAMP
                WHERE productid = $1";
            
            const string insertHistorySql = @"
                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES ($1, 'UPDATE', $2, $3, $4, $5, CURRENT_TIMESTAMP)";
            
            const string updateStatsSql = @"
                UPDATE productstats
                SET 
                    averageprice = (averageprice * totalproducts - $1 + $2) / totalproducts,
                    lastupdated = CURRENT_TIMESTAMP
                WHERE statid = 1";

            using var transaction = await connection.BeginTransactionAsync();
            try
            {
                // Get old values for history
                decimal oldPrice;
                int oldStock;
                using (var command = new NpgsqlCommand(getOldValuesSql, connection, transaction))
                {
                    command.Parameters.AddWithValue(product.ProductId);
                    using var reader = await command.ExecuteReaderAsync();
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
                using (var command = new NpgsqlCommand(updateProductSql, connection, transaction))
                {
                    command.Parameters.AddWithValue(product.ProductId);
                    command.Parameters.AddWithValue(product.Name);
                    command.Parameters.AddWithValue((object)product.Description ?? DBNull.Value);
                    command.Parameters.AddWithValue(product.Price);
                    command.Parameters.AddWithValue(product.StockQuantity);
                    await command.ExecuteNonQueryAsync();
                }
                
                // Log the changes
                using (var command = new NpgsqlCommand(insertHistorySql, connection, transaction))
                {
                    command.Parameters.AddWithValue(product.ProductId);
                    command.Parameters.AddWithValue(oldPrice);
                    command.Parameters.AddWithValue(product.Price);
                    command.Parameters.AddWithValue(oldStock);
                    command.Parameters.AddWithValue(product.StockQuantity);
                    await command.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
                using (var command = new NpgsqlCommand(updateStatsSql, connection, transaction))
                {
                    command.Parameters.AddWithValue(oldPrice);
                    command.Parameters.AddWithValue(product.Price);
                    await command.ExecuteNonQueryAsync();
                }
                
                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        public async Task DeleteProductAsync(int productId)
        {
            var connection = await GetConnectionAsync();
            
            const string getOldValuesSql = @"
                SELECT price, stockquantity 
                FROM products 
                WHERE productid = $1";
            
            const string insertHistorySql = @"
                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES ($1, 'DELETE', $2, NULL, $3, NULL, CURRENT_TIMESTAMP)";
            
            const string deleteProductSql = @"
                DELETE FROM products 
                WHERE productid = $1";
            
            const string updateStatsSql = @"
                UPDATE productstats
                SET 
                    totalproducts = totalproducts - 1,
                    averageprice = CASE 
                        WHEN totalproducts > 1 
                        THEN (averageprice * totalproducts - $1) / (totalproducts - 1)
                        ELSE 0
                    END,
                    lastupdated = CURRENT_TIMESTAMP
                WHERE statid = 1";

            using var transaction = await connection.BeginTransactionAsync();
            try
            {
                // Get old values for history
                decimal oldPrice;
                int oldStock;
                using (var command = new NpgsqlCommand(getOldValuesSql, connection, transaction))
                {
                    command.Parameters.AddWithValue(productId);
                    using var reader = await command.ExecuteReaderAsync();
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
                using (var command = new NpgsqlCommand(insertHistorySql, connection, transaction))
                {
                    command.Parameters.AddWithValue(productId);
                    command.Parameters.AddWithValue(oldPrice);
                    command.Parameters.AddWithValue(oldStock);
                    await command.ExecuteNonQueryAsync();
                }
                
                // Delete the product
                using (var command = new NpgsqlCommand(deleteProductSql, connection, transaction))
                {
                    command.Parameters.AddWithValue(productId);
                    await command.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
                using (var command = new NpgsqlCommand(updateStatsSql, connection, transaction))
                {
                    command.Parameters.AddWithValue(oldPrice);
                    await command.ExecuteNonQueryAsync();
                }
                
                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        public async Task<List<Product>> GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
        {
            var products = new List<Product>();
            var connection = await GetConnectionAsync();

            const string sql = @"
                WITH rankedproducts AS (
                    SELECT 
                        p.*,
                        RANK() OVER (ORDER BY p.price) as pricerank,
                        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
                    FROM products p
                    WHERE p.price BETWEEN $1 AND $2
                )
                SELECT 
                    rp.*,
                    CASE 
                        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
                        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
                        ELSE 'Premium'
                    END as pricesegment
                FROM rankedproducts rp
                ORDER BY rp.pricerank";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue(minPrice);
            command.Parameters.AddWithValue(maxPrice);

            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                products.Add(MapProductFromReader(reader));
            }

            return products;
        }

        public async Task<List<Product>> GetLowStockProductsAsync(int threshold)
        {
            var products = new List<Product>();
            var connection = await GetConnectionAsync();

            const string sql = @"
                WITH stockanalysis AS (
                    SELECT 
                        p.*,
                        AVG(stockquantity) OVER() as avgstock,
                        MIN(stockquantity) OVER() as minstock,
                        MAX(stockquantity) OVER() as maxstock
                    FROM products p
                )
                SELECT 
                    sa.*,
                    CASE 
                        WHEN stockquantity <= $1 THEN 'Critical'
                        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
                        ELSE 'Adequate'
                    END as stockstatus,
                    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
                FROM stockanalysis sa
                WHERE stockquantity <= $1
                ORDER BY stockquantity";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue(threshold);

            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                products.Add(MapProductFromReader(reader));
            }

            return products;
        }

        public async Task ExecuteInTransactionAsync(Func<Task> action)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();
            try
            {
                await action();
                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        private static Product MapProductFromReader(NpgsqlDataReader reader)
        {
            return new Product
            {
                ProductId = Convert.ToInt32(reader["productid"]),
                Name = reader["name"].ToString(),
                Description = reader["description"] == DBNull.Value ? null : reader["description"].ToString(),
                Price = Convert.ToDecimal(reader["price"]),
                StockQuantity = Convert.ToInt32(reader["stockquantity"]),
                CreatedDate = Convert.ToDateTime(reader["createddate"]),
                ModifiedDate = reader["modifieddate"] == DBNull.Value ? null : (DateTime?)Convert.ToDateTime(reader["modifieddate"])
            };
        }

        public async ValueTask DisposeAsync()
        {
            if (_connection != null)
            {
                if (_connection.State == ConnectionState.Open)
                {
                    await _connection.CloseAsync();
                }
                await _connection.DisposeAsync();
                _connection = null;
            }
        }
    }
}
