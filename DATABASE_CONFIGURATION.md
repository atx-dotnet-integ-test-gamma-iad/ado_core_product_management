# Database Connection Configuration - Security Best Practices

## ⚠️ IMPORTANT: Hardcoded Credentials Removed

The connection strings in `appsettings.json` now contain placeholders instead of hardcoded credentials.

## Configuration Options

### Option 1: Environment-Specific Configuration Files (Recommended)

Create environment-specific configuration files that are NOT committed to source control:

1. **appsettings.Development.json** (for local development):
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=your_dev_username;Password=your_dev_password;Pooling=true"
  }
}
```

2. **appsettings.Production.json** (for production):
```json
{
  "ConnectionStrings": {
    "ProdConnection": "Host=prod-server;Port=5432;Database=ProductManagement;Username=your_prod_username;Password=your_prod_password;Pooling=true"
  }
}
```

3. Add these files to `.gitignore`:
```
appsettings.Development.json
appsettings.Production.json
```

### Option 2: Environment Variables

Set environment variables and read them in your application code:

**Environment Variables:**
```bash
# Linux/Mac
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=ProductManagement
export DB_USER=your_username
export DB_PASSWORD=your_password

# Windows
set DB_HOST=localhost
set DB_PORT=5432
set DB_NAME=ProductManagement
set DB_USER=your_username
set DB_PASSWORD=your_password
```

**Code to read environment variables (add to Program.cs or startup):**
```csharp
var connectionString = $"Host={Environment.GetEnvironmentVariable("DB_HOST")};Port={Environment.GetEnvironmentVariable("DB_PORT")};Database={Environment.GetEnvironmentVariable("DB_NAME")};Username={Environment.GetEnvironmentVariable("DB_USER")};Password={Environment.GetEnvironmentVariable("DB_PASSWORD")};Pooling=true";
```

### Option 3: Azure Key Vault / AWS Secrets Manager

For production environments, use a secure secrets management service:

**Azure Key Vault:**
```csharp
// Add package: Azure.Extensions.AspNetCore.Configuration.Secrets
builder.Configuration.AddAzureKeyVault(
    new Uri($"https://{keyVaultName}.vault.azure.net/"),
    new DefaultAzureCredential());
```

**AWS Secrets Manager:**
```csharp
// Add package: Amazon.Extensions.Configuration.SystemsManager
builder.Configuration.AddSystemsManager($"/myapp/{environmentName}");
```

### Option 4: User Secrets (for Development Only)

.NET provides a User Secrets feature for development:

```bash
# Initialize user secrets
dotnet user-secrets init

# Set secrets
dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=localhost;Port=5432;Database=ProductManagement;Username=dev_user;Password=dev_pass;Pooling=true"
```

## Current Configuration

Before running the application, you MUST:

1. Replace placeholders in `appsettings.json` OR
2. Create environment-specific configuration files OR
3. Set up environment variables OR
4. Configure user secrets OR
5. Integrate with a secrets management service

## Security Notes

- ✅ Never commit credentials to source control
- ✅ Use different credentials for each environment
- ✅ Rotate passwords regularly
- ✅ Use least privilege access (grant only necessary database permissions)
- ✅ Enable SSL/TLS for production database connections
- ✅ Monitor and audit database access

## Testing the Configuration

After configuring credentials, test the connection:

```bash
dotnet run
```

If connection fails, verify:
- PostgreSQL server is running
- Firewall allows connections on port 5432
- Database exists
- Username and password are correct
- User has necessary permissions
