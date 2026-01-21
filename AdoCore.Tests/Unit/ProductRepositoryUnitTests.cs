using System;
using Xunit;
using Moq;
using Microsoft.Extensions.Configuration;
using AdoCore.DataAccess;
using AdoCore.Models;

namespace AdoCore.Tests.Unit
{
    /// <summary>
    /// Unit tests for ProductRepository focusing on configuration and basic validation.
    /// These tests do not require a database connection.
    /// </summary>
    public class ProductRepositoryUnitTests
    {
        [Fact]
        public void Constructor_ShouldInitializeWithDevConnection_WhenEnvironmentIsDevelopment()
        {
            // Arrange
            var mockConfig = new Mock<IConfiguration>();
            var mockConnectionStrings = new Mock<IConfigurationSection>();
            
            mockConfig.Setup(c => c["Environment"]).Returns("Development");
            mockConfig.Setup(c => c.GetSection("ConnectionStrings")).Returns(mockConnectionStrings.Object);
            mockConnectionStrings.Setup(cs => cs["DevConnection"])
                .Returns("Host=localhost;Port=5432;Database=AdoCoreDb;Username=postgres;Password=postgres;");

            // Act
            var repository = new ProductRepository(mockConfig.Object);

            // Assert
            Assert.NotNull(repository);
        }

        [Fact]
        public void Constructor_ShouldInitializeWithProdConnection_WhenEnvironmentIsProduction()
        {
            // Arrange
            var mockConfig = new Mock<IConfiguration>();
            var mockConnectionStrings = new Mock<IConfigurationSection>();
            
            mockConfig.Setup(c => c["Environment"]).Returns("Production");
            mockConfig.Setup(c => c.GetSection("ConnectionStrings")).Returns(mockConnectionStrings.Object);
            mockConnectionStrings.Setup(cs => cs["ProdConnection"])
                .Returns("Host=prod-server;Port=5432;Database=AdoCoreDb_Prod;Username=postgres_prod;Password=secret;");

            // Act
            var repository = new ProductRepository(mockConfig.Object);

            // Assert
            Assert.NotNull(repository);
        }

        [Fact]
        public void Product_Model_ShouldHaveCorrectProperties()
        {
            // Arrange & Act
            var product = new Product
            {
                ProductId = 1,
                Name = "Test Product",
                Description = "Test Description",
                Price = 99.99m,
                StockQuantity = 100,
                CreatedDate = DateTime.Now,
                ModifiedDate = DateTime.Now
            };

            // Assert
            Assert.Equal(1, product.ProductId);
            Assert.Equal("Test Product", product.Name);
            Assert.Equal("Test Description", product.Description);
            Assert.Equal(99.99m, product.Price);
            Assert.Equal(100, product.StockQuantity);
            Assert.NotEqual(default, product.CreatedDate);
            Assert.NotNull(product.ModifiedDate);
        }

        [Fact]
        public void Product_Model_ShouldAllowNullDescription()
        {
            // Arrange & Act
            var product = new Product
            {
                ProductId = 1,
                Name = "Test Product",
                Description = null,
                Price = 99.99m,
                StockQuantity = 100,
                CreatedDate = DateTime.Now
            };

            // Assert
            Assert.Null(product.Description);
        }

        [Fact]
        public void Product_Model_ShouldAllowNullModifiedDate()
        {
            // Arrange & Act
            var product = new Product
            {
                ProductId = 1,
                Name = "Test Product",
                Description = "Test",
                Price = 99.99m,
                StockQuantity = 100,
                CreatedDate = DateTime.Now,
                ModifiedDate = null
            };

            // Assert
            Assert.Null(product.ModifiedDate);
        }
    }
}
