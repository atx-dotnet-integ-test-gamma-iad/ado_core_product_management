using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Xunit;
using AdoCore.DataAccess;
using AdoCore.Models;
using Microsoft.Extensions.Configuration;

namespace AdoCore.Tests
{
    /// <summary>
    /// Integration tests for ProductRepository with PostgreSQL database.
    /// NOTE: These tests require a live PostgreSQL database connection.
    /// 
    /// Database Setup Requirements:
    /// 1. PostgreSQL server running on localhost:5432
    /// 2. Database with ProductManagement schema
    /// 3. Required tables: Products, ProductHistory, ProductStats
    /// 4. Valid credentials configured in test configuration
    /// 
    /// To run these tests:
    /// - Ensure PostgreSQL is running and accessible
    /// - Run database setup scripts from /Database/setup_scripts.sql
    /// - Execute: dotnet test
    /// </summary>
    public class ProductRepositoryTests : IDisposable
    {
        private readonly ProductRepository _repository;
        private readonly IConfiguration _configuration;

        public ProductRepositoryTests()
        {
            // Configure test settings
            var configBuilder = new ConfigurationBuilder()
                .AddInMemoryCollection(new Dictionary<string, string>
                {
                    ["Environment"] = "Development",
                    ["ConnectionStrings:DevConnection"] = "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;",
                    ["ConnectionStrings:ProdConnection"] = "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;"
                });

            _configuration = configBuilder.Build();
            _repository = new ProductRepository(_configuration);
        }

        [Fact(Skip = "Requires live PostgreSQL database")]
        public async Task GetAllProductsAsync_ShouldReturnProducts()
        {
            // Arrange
            // Database should have test data loaded

            // Act
            var products = await _repository.GetAllProductsAsync();

            // Assert
            Assert.NotNull(products);
            Assert.IsType<List<Product>>(products);
        }

        [Fact(Skip = "Requires live PostgreSQL database")]
        public async Task GetProductByIdAsync_WithValidId_ShouldReturnProduct()
        {
            // Arrange
            int testProductId = 1; // Assumes test data exists with ID 1

            // Act
            var product = await _repository.GetProductByIdAsync(testProductId);

            // Assert
            Assert.NotNull(product);
            Assert.Equal(testProductId, product.ProductId);
        }

        [Fact(Skip = "Requires live PostgreSQL database")]
        public async Task GetProductByIdAsync_WithInvalidId_ShouldReturnNull()
        {
            // Arrange
            int invalidId = -9999;

            // Act
            var product = await _repository.GetProductByIdAsync(invalidId);

            // Assert
            Assert.Null(product);
        }

        [Fact(Skip = "Requires live PostgreSQL database")]
        public async Task InsertProductAsync_WithValidProduct_ShouldReturnNewId()
        {
            // Arrange
            var newProduct = new Product
            {
                Name = "Test Product",
                Price = 99.99m,
                StockQuantity = 100
            };

            // Act
            int newId = await _repository.InsertProductAsync(newProduct);

            // Assert
            Assert.True(newId > 0);

            // Cleanup: Delete the test product
            await _repository.DeleteProductAsync(newId);
        }

        [Fact(Skip = "Requires live PostgreSQL database")]
        public async Task UpdateProductAsync_WithValidProduct_ShouldReturnTrue()
        {
            // Arrange
            // First insert a product to update
            var product = new Product
            {
                Name = "Product to Update",
                Price = 50.00m,
                StockQuantity = 50
            };
            int productId = await _repository.InsertProductAsync(product);
            
            // Modify the product
            product.ProductId = productId;
            product.Name = "Updated Product";
            product.Price = 75.00m;

            // Act
            await _repository.UpdateProductAsync(product);

            // Verify the update
            var updatedProduct = await _repository.GetProductByIdAsync(productId);
            
            // Assert
            Assert.NotNull(updatedProduct);
            Assert.Equal("Updated Product", updatedProduct.Name);
            Assert.Equal(75.00m, updatedProduct.Price);

            // Cleanup
            await _repository.DeleteProductAsync(productId);
        }

        [Fact(Skip = "Requires live PostgreSQL database")]
        public async Task DeleteProductAsync_WithValidId_ShouldReturnTrue()
        {
            // Arrange
            var product = new Product
            {
                Name = "Product to Delete",
                Price = 25.00m,
                StockQuantity = 25
            };
            int productId = await _repository.InsertProductAsync(product);

            // Act
            await _repository.DeleteProductAsync(productId);

            // Verify deletion
            var deletedProduct = await _repository.GetProductByIdAsync(productId);
            
            // Assert
            Assert.Null(deletedProduct);
        }

        [Fact(Skip = "Requires live PostgreSQL database")]
        public async Task GetProductsByPriceRangeAsync_ShouldReturnFilteredProducts()
        {
            // Arrange
            decimal minPrice = 10.00m;
            decimal maxPrice = 100.00m;

            // Act
            var products = await _repository.GetProductsByPriceRangeAsync(minPrice, maxPrice);

            // Assert
            Assert.NotNull(products);
            Assert.All(products, p => 
            {
                Assert.True(p.Price >= minPrice);
                Assert.True(p.Price <= maxPrice);
            });
        }

        [Fact(Skip = "Requires live PostgreSQL database")]
        public async Task GetLowStockProductsAsync_ShouldReturnLowStockProducts()
        {
            // Arrange
            int threshold = 20;

            // Act
            var products = await _repository.GetLowStockProductsAsync(threshold);

            // Assert
            Assert.NotNull(products);
            Assert.All(products, p => Assert.True(p.StockQuantity <= threshold));
        }

        [Fact(Skip = "Requires live PostgreSQL database")]
        public async Task ExecuteInTransactionAsync_WithCommit_ShouldPersistChanges()
        {
            // Arrange
            var product1 = new Product { Name = "Transaction Test 1", Price = 10.00m, StockQuantity = 10 };
            var product2 = new Product { Name = "Transaction Test 2", Price = 20.00m, StockQuantity = 20 };
            
            List<int> insertedIds = new List<int>();

            // Act
            await _repository.ExecuteInTransactionAsync(async () =>
            {
                int id1 = await _repository.InsertProductAsync(product1);
                int id2 = await _repository.InsertProductAsync(product2);
                insertedIds.Add(id1);
                insertedIds.Add(id2);
            });

            // Assert
            foreach (var id in insertedIds)
            {
                var product = await _repository.GetProductByIdAsync(id);
                Assert.NotNull(product);
                
                // Cleanup
                await _repository.DeleteProductAsync(id);
            }
        }

        [Fact(Skip = "Requires live PostgreSQL database")]
        public async Task ExecuteInTransactionAsync_WithException_ShouldRollback()
        {
            // Arrange
            var product = new Product { Name = "Rollback Test", Price = 30.00m, StockQuantity = 30 };
            int insertedId = 0;

            // Act & Assert
            await Assert.ThrowsAsync<InvalidOperationException>(async () =>
            {
                await _repository.ExecuteInTransactionAsync(async () =>
                {
                    insertedId = await _repository.InsertProductAsync(product);
                    throw new InvalidOperationException("Force rollback");
                });
            });

            // Verify rollback - product should not exist
            if (insertedId > 0)
            {
                var rolledBackProduct = await _repository.GetProductByIdAsync(insertedId);
                Assert.Null(rolledBackProduct);
            }
        }

        public void Dispose()
        {
            _repository?.DisposeAsync().AsTask().Wait();
        }
    }
}
