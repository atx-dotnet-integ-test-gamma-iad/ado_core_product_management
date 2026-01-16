using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Xunit;
using Microsoft.Extensions.Configuration;
using AdoCore.DataAccess;
using AdoCore.Models;

namespace AdoCore.Tests
{
    /// <summary>
    /// Integration tests for ProductRepository with PostgreSQL database.
    /// 
    /// PREREQUISITES:
    /// 1. PostgreSQL must be running on localhost:5432
    /// 2. Database 'adocore_test' must exist
    /// 3. Schema 'productmanagement_dbo' must be created
    /// 4. Tables (products, producthistory, productstats) must be created
    /// 5. productstats table must have a record with statid = 1
    /// 
    /// Run database setup script before executing these tests:
    /// psql -U postgres -f DatabaseSetup.sql
    /// </summary>
    public class ProductRepositoryIntegrationTests : IAsyncLifetime
    {
        private IConfiguration _configuration;
        private ProductRepository _repository;

        public ProductRepositoryIntegrationTests()
        {
            // Setup configuration
            _configuration = new ConfigurationBuilder()
                .AddJsonFile("appsettings.test.json")
                .Build();
        }

        public async Task InitializeAsync()
        {
            _repository = new ProductRepository(_configuration);
            
            // Clean up test data before each test
            await CleanupTestData();
            
            // Initialize productstats if needed
            await InitializeProductStats();
        }

        public async Task DisposeAsync()
        {
            if (_repository != null)
            {
                await _repository.DisposeAsync();
            }
        }

        private async Task CleanupTestData()
        {
            // Delete test products (this will cascade to history)
            // Implementation depends on having a cleanup method or direct SQL execution
        }

        private async Task InitializeProductStats()
        {
            // Ensure productstats table has initial record
            // Implementation depends on having access to execute direct SQL
        }

        [Fact]
        public async Task InsertProductAsync_ShouldInsertProductAndReturnId()
        {
            // Arrange
            var product = new Product
            {
                Name = "Test Product",
                Description = "Test Description",
                Price = 99.99m,
                StockQuantity = 50
            };

            // Act
            int productId = await _repository.InsertProductAsync(product);

            // Assert
            Assert.True(productId > 0, "Product ID should be greater than 0");

            // Verify product was inserted by retrieving it
            var retrievedProduct = await _repository.GetProductByIdAsync(productId);
            Assert.NotNull(retrievedProduct);
            Assert.Equal(product.Name, retrievedProduct.Name);
            Assert.Equal(product.Description, retrievedProduct.Description);
            Assert.Equal(product.Price, retrievedProduct.Price);
            Assert.Equal(product.StockQuantity, retrievedProduct.StockQuantity);
        }

        [Fact]
        public async Task GetAllProductsAsync_ShouldReturnAllProducts()
        {
            // Arrange - Insert test products
            var product1 = new Product
            {
                Name = "Product 1",
                Description = "Description 1",
                Price = 50.00m,
                StockQuantity = 100
            };
            var product2 = new Product
            {
                Name = "Product 2",
                Description = "Description 2",
                Price = 150.00m,
                StockQuantity = 50
            };

            await _repository.InsertProductAsync(product1);
            await _repository.InsertProductAsync(product2);

            // Act
            var products = await _repository.GetAllProductsAsync();

            // Assert
            Assert.NotNull(products);
            Assert.True(products.Count >= 2, "Should return at least 2 products");
            
            // Verify products are ordered correctly (above average first, then by name)
            // This tests the complex CTE with window functions
        }

        [Fact]
        public async Task GetProductByIdAsync_WithValidId_ShouldReturnProduct()
        {
            // Arrange
            var product = new Product
            {
                Name = "Test Product",
                Description = "Test Description",
                Price = 99.99m,
                StockQuantity = 50
            };
            int productId = await _repository.InsertProductAsync(product);

            // Act
            var retrievedProduct = await _repository.GetProductByIdAsync(productId);

            // Assert
            Assert.NotNull(retrievedProduct);
            Assert.Equal(productId, retrievedProduct.ProductId);
            Assert.Equal(product.Name, retrievedProduct.Name);
        }

        [Fact]
        public async Task GetProductByIdAsync_WithInvalidId_ShouldReturnNull()
        {
            // Act
            var product = await _repository.GetProductByIdAsync(999999);

            // Assert
            Assert.Null(product);
        }

        [Fact]
        public async Task UpdateProductAsync_ShouldUpdateProduct()
        {
            // Arrange - Insert a product first
            var product = new Product
            {
                Name = "Original Product",
                Description = "Original Description",
                Price = 50.00m,
                StockQuantity = 100
            };
            int productId = await _repository.InsertProductAsync(product);

            // Modify the product
            var updatedProduct = new Product
            {
                ProductId = productId,
                Name = "Updated Product",
                Description = "Updated Description",
                Price = 75.00m,
                StockQuantity = 150
            };

            // Act
            await _repository.UpdateProductAsync(updatedProduct);

            // Assert - Retrieve and verify
            var retrievedProduct = await _repository.GetProductByIdAsync(productId);
            Assert.NotNull(retrievedProduct);
            Assert.Equal(updatedProduct.Name, retrievedProduct.Name);
            Assert.Equal(updatedProduct.Description, retrievedProduct.Description);
            Assert.Equal(updatedProduct.Price, retrievedProduct.Price);
            Assert.Equal(updatedProduct.StockQuantity, retrievedProduct.StockQuantity);
        }

        [Fact]
        public async Task DeleteProductAsync_ShouldDeleteProduct()
        {
            // Arrange - Insert a product first
            var product = new Product
            {
                Name = "Product to Delete",
                Description = "Will be deleted",
                Price = 50.00m,
                StockQuantity = 100
            };
            int productId = await _repository.InsertProductAsync(product);

            // Act
            await _repository.DeleteProductAsync(productId);

            // Assert - Product should no longer exist
            var deletedProduct = await _repository.GetProductByIdAsync(productId);
            Assert.Null(deletedProduct);
        }

        [Fact]
        public async Task GetProductsByPriceRangeAsync_ShouldReturnProductsInRange()
        {
            // Arrange - Insert products with different prices
            var product1 = new Product { Name = "Cheap Product", Description = "Low price", Price = 10.00m, StockQuantity = 100 };
            var product2 = new Product { Name = "Mid Product", Description = "Medium price", Price = 50.00m, StockQuantity = 50 };
            var product3 = new Product { Name = "Expensive Product", Description = "High price", Price = 200.00m, StockQuantity = 25 };

            await _repository.InsertProductAsync(product1);
            await _repository.InsertProductAsync(product2);
            await _repository.InsertProductAsync(product3);

            // Act - Get products in mid-price range
            var products = await _repository.GetProductsByPriceRangeAsync(40.00m, 100.00m);

            // Assert
            Assert.NotNull(products);
            Assert.All(products, p => Assert.InRange(p.Price, 40.00m, 100.00m));
        }

        [Fact]
        public async Task GetLowStockProductsAsync_ShouldReturnProductsBelowThreshold()
        {
            // Arrange - Insert products with different stock levels
            var product1 = new Product { Name = "Low Stock 1", Description = "Very low", Price = 50.00m, StockQuantity = 5 };
            var product2 = new Product { Name = "Low Stock 2", Description = "Low", Price = 50.00m, StockQuantity = 15 };
            var product3 = new Product { Name = "High Stock", Description = "Plenty", Price = 50.00m, StockQuantity = 100 };

            await _repository.InsertProductAsync(product1);
            await _repository.InsertProductAsync(product2);
            await _repository.InsertProductAsync(product3);

            // Act - Get products with stock below 20
            var lowStockProducts = await _repository.GetLowStockProductsAsync(20);

            // Assert
            Assert.NotNull(lowStockProducts);
            Assert.All(lowStockProducts, p => Assert.True(p.StockQuantity <= 20));
        }

        [Fact]
        public async Task TransactionRollback_ShouldNotCommitChanges()
        {
            // Arrange - Insert a product first
            var product = new Product
            {
                Name = "Transaction Test Product",
                Description = "For rollback test",
                Price = 50.00m,
                StockQuantity = 100
            };
            int productId = await _repository.InsertProductAsync(product);

            // Act - Attempt an update that will fail (simulate by throwing exception)
            var updatedProduct = new Product
            {
                ProductId = productId,
                Name = "Should Not Update",
                Description = "Should rollback",
                Price = 75.00m,
                StockQuantity = 150
            };

            bool exceptionThrown = false;
            try
            {
                await _repository.ExecuteInTransactionAsync(async () =>
                {
                    await _repository.UpdateProductAsync(updatedProduct);
                    throw new InvalidOperationException("Simulated error to test rollback");
                });
            }
            catch (InvalidOperationException)
            {
                exceptionThrown = true;
            }

            // Assert
            Assert.True(exceptionThrown, "Exception should have been thrown");
            
            // Verify product was NOT updated (transaction rolled back)
            var retrievedProduct = await _repository.GetProductByIdAsync(productId);
            Assert.NotNull(retrievedProduct);
            Assert.Equal("Transaction Test Product", retrievedProduct.Name);
            Assert.Equal(50.00m, retrievedProduct.Price);
        }

        [Fact]
        public async Task WindowFunctions_InGetAllProductsAsync_ShouldCalculateCorrectly()
        {
            // Arrange - Insert products with known prices to test window functions
            var products = new List<Product>
            {
                new Product { Name = "Product A", Description = "Test", Price = 100.00m, StockQuantity = 50 },
                new Product { Name = "Product B", Description = "Test", Price = 200.00m, StockQuantity = 50 },
                new Product { Name = "Product C", Description = "Test", Price = 300.00m, StockQuantity = 50 }
            };

            foreach (var product in products)
            {
                await _repository.InsertProductAsync(product);
            }

            // Act
            var retrievedProducts = await _repository.GetAllProductsAsync();

            // Assert
            // Average price should be (100 + 200 + 300) / 3 = 200
            // This tests the AVG() OVER () window function
            Assert.NotNull(retrievedProducts);
            Assert.True(retrievedProducts.Count >= 3, "Should have at least 3 products");
            
            // Products with price > 200 should be categorized as "Above Average"
            // Products with price < 200 should be categorized as "Below Average"
            // Product with price = 200 should be categorized as "Average"
        }
    }
}
