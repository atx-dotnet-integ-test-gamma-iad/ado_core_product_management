using System;
using System.Threading.Tasks;
using AdoCore.Business;
using AdoCore.CLI;
using AdoCore.DataAccess;
using AdoCore.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace AdoCore
{
    class Program
    {
        static async Task<int> Main(string[] args)
        {
            var configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: false)
                .Build();

            var services = new ServiceCollection();
            ConfigureServices(services, configuration);
            var serviceProvider = services.BuildServiceProvider();

            // Check for validation test mode
            if (args.Length > 0 && args[0].ToLower() == "--validate")
            {
                Console.WriteLine("Running PostgreSQL Migration Validation Tests...\n");
                int exitCode = await ValidationTests.RunValidationTestsAsync();
                return exitCode;
            }
            else if (args.Length > 0)
            {
                var cli = serviceProvider.GetRequiredService<CommandLineInterface>();
                await cli.ProcessCommandAsync(args);
            }
            else
            {
                var menu = serviceProvider.GetRequiredService<InteractiveMenu>();
                await menu.RunAsync();
            }

            return 0;
        }

        private static void ConfigureServices(IServiceCollection services, IConfiguration configuration)
        {
            services.AddSingleton(configuration);
            services.AddScoped<ProductRepository>();
            services.AddScoped<ProductService>();
            services.AddScoped<CommandLineInterface>();
            services.AddScoped<InteractiveMenu>();
        }
    }
}
