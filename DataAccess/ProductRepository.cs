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
                WITH productstats
                AS (SELECT
                    productid, AVG(Price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
                    FROM public.products)
                SELECT
                    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
                    CASE
                        WHEN p.Price > ps.avgprice THEN 'Above Average'
                        WHEN p.Price < ps.avgprice THEN 'Below Average'
                        ELSE 'Average'
                    END AS pricecategory, ROUND((p.Price / ps.avgprice), 2) AS pricepercentageofaverage
                    FROM public.products AS p
                    INNER JOIN productstats AS ps
                        ON p.ProductId = ps.productid
                    ORDER BY
                    CASE
                        WHEN p.Price > ps.avgprice THEN 1
                        ELSE 2
                    END NULLS FIRST, p.Name NULLS FIRST";

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
                WITH producthistory
                AS (SELECT
                    productid, lag(Price) OVER (ORDER BY ModifiedDate) AS previousprice, lag(StockQuantity) OVER (ORDER BY ModifiedDate) AS previousstock
                    FROM public.products
                    WHERE productid = @ProductId)
                SELECT
                    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, ph.previousprice, ph.previousstock,
                    CASE
                        WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.Price - ph.previousprice) / ph.previousprice), 2)
                        ELSE NULL
                    END AS pricechangepercentage
                    FROM public.products AS p
                    LEFT OUTER JOIN producthistory AS ph
                        ON p.ProductId = ph.productid
                    WHERE p.ProductId = @ProductId";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue("@ProductId", productId);

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

            const string sql = @"
                INSERT INTO public.products (name, description, price, stockquantity)
                VALUES (@Name, @Description, @Price, @StockQuantity)
                RETURNING productid";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue("@Name", product.Name);
            command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);

            return Convert.ToInt32(await command.ExecuteScalarAsync());
        }

        public async Task UpdateProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();

            const string sql = @"
                UPDATE public.products
                SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = NOW()
                WHERE productid = @ProductId";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue("@ProductId", product.ProductId);
            command.Parameters.AddWithValue("@Name", product.Name);
            command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);

            await command.ExecuteNonQueryAsync();
        }

        public async Task DeleteProductAsync(int productId)
        {
            var connection = await GetConnectionAsync();

            const string sql = @"
                DELETE FROM public.products
                WHERE productid = @ProductId";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue("@ProductId", productId);

            await command.ExecuteNonQueryAsync();
        }

        public async Task<List<Product>> GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
        {
            var products = new List<Product>();
            var connection = await GetConnectionAsync();

            const string sql = @"
                WITH rankedproducts
                AS (SELECT
                    p.*, RANK() OVER (ORDER BY p.Price) AS pricerank, percent_rank() OVER (ORDER BY p.Price) AS pricepercentile
                    FROM public.products AS p
                    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice)
                SELECT
                    rp.*,
                    CASE
                        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
                        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
                        ELSE 'Premium'
                    END AS pricesegment
                    FROM rankedproducts AS rp
                    ORDER BY rp.pricerank NULLS FIRST";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue("@MinPrice", minPrice);
            command.Parameters.AddWithValue("@MaxPrice", maxPrice);

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
                WITH stockanalysis
                AS (SELECT p.*,
                        AVG(StockQuantity) OVER () AS avgstock,
                        MIN(StockQuantity) OVER () AS minstock,
                        MAX(StockQuantity) OVER () AS maxstock
                    FROM public.products AS p)
                SELECT sa.*,
                        CASE
                            WHEN sa.StockQuantity <= @Threshold THEN 'Critical'
                            WHEN sa.StockQuantity <= avgstock * 0.5 THEN 'Low'
                            ELSE 'Adequate'
                        END AS stockstatus,
                        round((sa.StockQuantity / avgstock) * 100, 2) AS stockpercentageofaverage
                    FROM stockanalysis AS sa
                    WHERE sa.StockQuantity <= @Threshold
                    ORDER BY sa.StockQuantity";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue("@Threshold", threshold);

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
                ProductId = Convert.ToInt32(reader["ProductId"]),
                Name = reader["Name"].ToString(),
                Description = reader["Description"] == DBNull.Value ? null : reader["Description"].ToString(),
                Price = Convert.ToDecimal(reader["Price"]),
                StockQuantity = Convert.ToInt32(reader["StockQuantity"]),
                CreatedDate = Convert.ToDateTime(reader["CreatedDate"]),
                ModifiedDate = reader["ModifiedDate"] == DBNull.Value ? null : (DateTime?)Convert.ToDateTime(reader["ModifiedDate"])
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
