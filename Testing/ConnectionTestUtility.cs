using System;
using System.Threading.Tasks;
using Npgsql;
using Microsoft.Extensions.Configuration;

namespace AdoCore.Testing
{
    /// <summary>
    /// Utility class for validating PostgreSQL database connection
    /// This helps verify Exit Criterion 12: Application successfully connects to PostgreSQL database
    /// </summary>
    public class ConnectionTestUtility
    {
        private readonly IConfiguration _configuration;

        public ConnectionTestUtility(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        /// <summary>
        /// Tests database connection and reports detailed status
        /// </summary>
        public async Task<ConnectionTestResult> TestConnectionAsync()
        {
            var result = new ConnectionTestResult();
            
            try
            {
                Console.WriteLine("=== PostgreSQL Connection Test ===");
                Console.WriteLine();
                
                // Get connection string
                var environment = _configuration["Environment"];
                var connectionName = environment == "Production" ? "ProdConnection" : "DevConnection";
                var connectionString = _configuration.GetConnectionString(connectionName);
                
                Console.WriteLine($"Environment: {environment}");
                Console.WriteLine($"Connection Name: {connectionName}");
                Console.WriteLine($"Connection String: {MaskPassword(connectionString)}");
                Console.WriteLine();
                
                result.ConnectionString = connectionString;
                result.Environment = environment;
                
                // Test 1: Parse connection string
                Console.WriteLine("Test 1: Parsing connection string...");
                var builder = new NpgsqlConnectionStringBuilder(connectionString);
                Console.WriteLine($"  Host: {builder.Host}");
                Console.WriteLine($"  Port: {builder.Port}");
                Console.WriteLine($"  Database: {builder.Database}");
                Console.WriteLine($"  Username: {builder.Username}");
                Console.WriteLine($"  Pooling: {builder.Pooling}");
                Console.WriteLine("  ✓ Connection string parsed successfully");
                Console.WriteLine();
                
                result.Host = builder.Host;
                result.Port = builder.Port;
                result.Database = builder.Database;
                result.Username = builder.Username;
                
                // Test 2: Open connection
                Console.WriteLine("Test 2: Opening connection to PostgreSQL...");
                using var connection = new NpgsqlConnection(connectionString);
                
                var startTime = DateTime.UtcNow;
                await connection.OpenAsync();
                var connectionTime = DateTime.UtcNow - startTime;
                
                Console.WriteLine($"  ✓ Connection opened successfully in {connectionTime.TotalMilliseconds:F2}ms");
                Console.WriteLine($"  State: {connection.State}");
                Console.WriteLine($"  Server Version: {connection.ServerVersion}");
                Console.WriteLine($"  PostgreSQL Version: {connection.PostgreSqlVersion}");
                Console.WriteLine();
                
                result.ConnectionSuccessful = true;
                result.ConnectionTimeMs = connectionTime.TotalMilliseconds;
                result.ServerVersion = connection.ServerVersion;
                result.PostgreSqlVersion = connection.PostgreSqlVersion.ToString();
                
                // Test 3: Execute simple query
                Console.WriteLine("Test 3: Executing test query...");
                using var command = new NpgsqlCommand("SELECT version(), current_database(), current_user, NOW()", connection);
                using var reader = await command.ExecuteReaderAsync();
                
                if (await reader.ReadAsync())
                {
                    Console.WriteLine($"  PostgreSQL Version: {reader.GetString(0)}");
                    Console.WriteLine($"  Current Database: {reader.GetString(1)}");
                    Console.WriteLine($"  Current User: {reader.GetString(2)}");
                    Console.WriteLine($"  Server Time: {reader.GetDateTime(3)}");
                }
                Console.WriteLine("  ✓ Test query executed successfully");
                Console.WriteLine();
                
                result.QueryExecutionSuccessful = true;
                
                // Test 4: Check required tables exist
                Console.WriteLine("Test 4: Verifying database schema...");
                string[] requiredTables = { "products", "producthistory", "productstats", "categories", "suppliers" };
                
                foreach (var tableName in requiredTables)
                {
                    using var checkCommand = new NpgsqlCommand(
                        "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = @tableName)", 
                        connection);
                    checkCommand.Parameters.AddWithValue("@tableName", tableName);
                    
                    var exists = (bool)await checkCommand.ExecuteScalarAsync();
                    Console.WriteLine($"  Table '{tableName}': {(exists ? "✓ Found" : "✗ Missing")}");
                    
                    if (!exists)
                    {
                        result.MissingTables.Add(tableName);
                    }
                }
                
                if (result.MissingTables.Count == 0)
                {
                    Console.WriteLine("  ✓ All required tables found");
                    result.SchemaValid = true;
                }
                else
                {
                    Console.WriteLine($"  ✗ {result.MissingTables.Count} table(s) missing");
                    result.SchemaValid = false;
                }
                Console.WriteLine();
                
                // Test 5: Check sample data
                Console.WriteLine("Test 5: Checking sample data...");
                using var countCommand = new NpgsqlCommand("SELECT COUNT(*) FROM Products", connection);
                var productCount = Convert.ToInt32(await countCommand.ExecuteScalarAsync());
                Console.WriteLine($"  Products in database: {productCount}");
                
                result.ProductCount = productCount;
                
                if (productCount > 0)
                {
                    Console.WriteLine("  ✓ Sample data found");
                    result.SampleDataExists = true;
                }
                else
                {
                    Console.WriteLine("  ⚠ No sample data found (database may be empty)");
                    result.SampleDataExists = false;
                }
                Console.WriteLine();
                
                // Test 6: Test connection pooling
                Console.WriteLine("Test 6: Testing connection pooling...");
                if (builder.Pooling)
                {
                    // Open multiple connections to test pooling
                    for (int i = 0; i < 3; i++)
                    {
                        using var pooledConnection = new NpgsqlConnection(connectionString);
                        await pooledConnection.OpenAsync();
                        Console.WriteLine($"  Pooled connection {i + 1}: State={pooledConnection.State}");
                    }
                    Console.WriteLine("  ✓ Connection pooling working correctly");
                    result.ConnectionPoolingWorks = true;
                }
                else
                {
                    Console.WriteLine("  ⚠ Connection pooling is disabled");
                    result.ConnectionPoolingWorks = false;
                }
                Console.WriteLine();
                
                // Final status
                result.OverallSuccess = result.ConnectionSuccessful && 
                                       result.QueryExecutionSuccessful && 
                                       result.SchemaValid;
                
                Console.WriteLine("=== Connection Test Summary ===");
                Console.WriteLine($"Overall Status: {(result.OverallSuccess ? "✓ PASS" : "✗ FAIL")}");
                Console.WriteLine($"Connection: {(result.ConnectionSuccessful ? "✓ PASS" : "✗ FAIL")}");
                Console.WriteLine($"Query Execution: {(result.QueryExecutionSuccessful ? "✓ PASS" : "✗ FAIL")}");
                Console.WriteLine($"Schema Validation: {(result.SchemaValid ? "✓ PASS" : "✗ FAIL")}");
                Console.WriteLine($"Sample Data: {(result.SampleDataExists ? "✓ PASS" : "⚠ WARNING")}");
                Console.WriteLine($"Connection Pooling: {(result.ConnectionPoolingWorks ? "✓ PASS" : "⚠ WARNING")}");
                Console.WriteLine();
                
                if (result.OverallSuccess)
                {
                    Console.WriteLine("✓ All connection tests passed!");
                    Console.WriteLine("✓ Exit Criterion 12 (Database Connection) is satisfied.");
                }
                else
                {
                    Console.WriteLine("✗ Some connection tests failed.");
                    Console.WriteLine("✗ Exit Criterion 12 (Database Connection) is NOT satisfied.");
                    
                    if (result.MissingTables.Count > 0)
                    {
                        Console.WriteLine();
                        Console.WriteLine("Missing tables detected. Please run the schema initialization script:");
                        Console.WriteLine("  psql -U postgres -d ProductManagement -f Database/Scripts/01_PostgreSQL_InitialSetup.sql");
                    }
                }
                
            }
            catch (Exception ex)
            {
                result.OverallSuccess = false;
                result.ErrorMessage = ex.Message;
                result.ExceptionType = ex.GetType().Name;
                result.StackTrace = ex.StackTrace;
                
                Console.WriteLine();
                Console.WriteLine("✗ Connection test FAILED with exception:");
                Console.WriteLine($"  Type: {ex.GetType().Name}");
                Console.WriteLine($"  Message: {ex.Message}");
                Console.WriteLine();
                Console.WriteLine("Common solutions:");
                Console.WriteLine("  1. Ensure PostgreSQL is running: sudo systemctl status postgresql");
                Console.WriteLine("  2. Check connection string credentials in appsettings.json");
                Console.WriteLine("  3. Verify database 'ProductManagement' exists: psql -l");
                Console.WriteLine("  4. Check firewall allows connection to port 5432");
                Console.WriteLine("  5. Verify pg_hba.conf allows connection from your host");
            }
            
            Console.WriteLine();
            return result;
        }
        
        private string MaskPassword(string connectionString)
        {
            try
            {
                var builder = new NpgsqlConnectionStringBuilder(connectionString);
                if (!string.IsNullOrEmpty(builder.Password))
                {
                    builder.Password = "****";
                }
                return builder.ToString();
            }
            catch
            {
                return connectionString;
            }
        }
    }
    
    /// <summary>
    /// Results of connection testing
    /// </summary>
    public class ConnectionTestResult
    {
        public bool OverallSuccess { get; set; }
        public bool ConnectionSuccessful { get; set; }
        public bool QueryExecutionSuccessful { get; set; }
        public bool SchemaValid { get; set; }
        public bool SampleDataExists { get; set; }
        public bool ConnectionPoolingWorks { get; set; }
        
        public string ConnectionString { get; set; }
        public string Environment { get; set; }
        public string Host { get; set; }
        public int Port { get; set; }
        public string Database { get; set; }
        public string Username { get; set; }
        
        public double ConnectionTimeMs { get; set; }
        public string ServerVersion { get; set; }
        public string PostgreSqlVersion { get; set; }
        
        public int ProductCount { get; set; }
        public System.Collections.Generic.List<string> MissingTables { get; set; } = new System.Collections.Generic.List<string>();
        
        public string ErrorMessage { get; set; }
        public string ExceptionType { get; set; }
        public string StackTrace { get; set; }
        
        /// <summary>
        /// Export results to JSON format for documentation
        /// </summary>
        public string ToJson()
        {
            return System.Text.Json.JsonSerializer.Serialize(this, new System.Text.Json.JsonSerializerOptions 
            { 
                WriteIndented = true 
            });
        }
    }
}
