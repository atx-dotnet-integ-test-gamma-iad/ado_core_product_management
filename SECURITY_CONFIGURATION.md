# Security Configuration Guide

## Overview
This document provides guidance on securing database credentials and connection strings for the AdoCore application after migration from SQL Server to PostgreSQL.

## Security Improvements Implemented

### 1. Environment Variable Support
The application now supports environment variables for configuration overrides, allowing secure credential management without hardcoding sensitive information in configuration files.

**Changes Made:**
- Added `Microsoft.Extensions.Configuration.EnvironmentVariables` package to `AdoCore.csproj`
- Updated `Program.cs` to include `.AddEnvironmentVariables()` in the configuration builder
- Modified `appsettings.json` to use placeholder values instead of hardcoded credentials

### 2. Configuration Priority
The configuration system now follows this priority order (later sources override earlier ones):
1. `appsettings.json` (base configuration)
2. Environment variables (runtime overrides)

## How to Configure Credentials Securely

### Option 1: Using Environment Variables (Recommended for Production)

Set the following environment variables before running the application:

**Linux/macOS:**
```bash
export ConnectionStrings__DevConnection="Host=localhost;Port=5432;Database=ProductManagement;Username=your_username;Password=your_password;Pooling=true"
export ConnectionStrings__ProdConnection="Host=your_host;Port=5432;Database=ProductManagement;Username=your_username;Password=your_password;Pooling=true"
```

**Windows (Command Prompt):**
```cmd
set ConnectionStrings__DevConnection=Host=localhost;Port=5432;Database=ProductManagement;Username=your_username;Password=your_password;Pooling=true
set ConnectionStrings__ProdConnection=Host=your_host;Port=5432;Database=ProductManagement;Username=your_username;Password=your_password;Pooling=true
```

**Windows (PowerShell):**
```powershell
$env:ConnectionStrings__DevConnection="Host=localhost;Port=5432;Database=ProductManagement;Username=your_username;Password=your_password;Pooling=true"
$env:ConnectionStrings__ProdConnection="Host=your_host;Port=5432;Database=ProductManagement;Username=your_username;Password=your_password;Pooling=true"
```

**Note:** Use double underscores (`__`) to represent nested configuration keys (e.g., `ConnectionStrings__DevConnection`).

### Option 2: Using Docker Secrets (Recommended for Docker Deployments)

When deploying with Docker, use Docker secrets or environment variables:

```yaml
# docker-compose.yml example
version: '3.8'
services:
  adocore:
    image: adocore:latest
    environment:
      - ConnectionStrings__DevConnection=Host=postgres;Port=5432;Database=ProductManagement;Username=appuser;Password=${DB_PASSWORD};Pooling=true
    secrets:
      - db_password

secrets:
  db_password:
    external: true
```

### Option 3: Using Azure Key Vault (Recommended for Azure Deployments)

For Azure deployments, integrate Azure Key Vault by adding:

```xml
<PackageReference Include="Azure.Extensions.AspNetCore.Configuration.Secrets" Version="1.3.0" />
```

And updating `Program.cs`:
```csharp
var keyVaultEndpoint = new Uri(Environment.GetEnvironmentVariable("VaultUri"));
configuration.AddAzureKeyVault(keyVaultEndpoint, new DefaultAzureCredential());
```

### Option 4: Using AWS Secrets Manager (Recommended for AWS Deployments)

For AWS deployments, integrate AWS Secrets Manager by adding:

```xml
<PackageReference Include="AWSSDK.SecretsManager" Version="3.7.0" />
```

## Best Practices

### 1. Never Commit Credentials to Version Control
- Ensure `appsettings.json` uses placeholder values only
- Add `appsettings.Development.json` to `.gitignore` if used for local development
- Use environment-specific configuration files with placeholders

### 2. Rotate Credentials Regularly
- Implement a credential rotation policy (e.g., every 90 days)
- Update environment variables or secret stores accordingly
- Test connectivity after rotation

### 3. Use Least Privilege Principle
- Create dedicated PostgreSQL users for the application with minimal required permissions
- Avoid using `postgres` superuser account in application connection strings
- Grant only necessary permissions (SELECT, INSERT, UPDATE, DELETE on specific tables)

**Example PostgreSQL User Setup:**
```sql
-- Create dedicated application user
CREATE USER adocore_app WITH PASSWORD 'strong_password_here';

-- Grant schema usage
GRANT USAGE ON SCHEMA productmanagement_dbo TO adocore_app;

-- Grant table-level permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON productmanagement_dbo.products TO adocore_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON productmanagement_dbo.producthistory TO adocore_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON productmanagement_dbo.productstats TO adocore_app;

-- Grant sequence permissions (for auto-increment columns)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA productmanagement_dbo TO adocore_app;
```

### 4. Use SSL/TLS for Database Connections
Update connection strings to enforce SSL:
```
Host=your_host;Port=5432;Database=ProductManagement;Username=your_username;Password=your_password;SSL Mode=Require;Trust Server Certificate=false;Pooling=true
```

### 5. Separate Development and Production Credentials
- Use different credentials for development and production environments
- Configure the `Environment` setting appropriately (Development/Production)
- Never use production credentials in development environments

## Local Development Configuration

For local development only, you may create an `appsettings.Development.json` file (ensure it's in `.gitignore`):

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=local_dev_user;Password=local_dev_password;Pooling=true"
  },
  "Environment": "Development"
}
```

## Security Checklist

- [ ] Removed hardcoded credentials from `appsettings.json`
- [ ] Configured environment variables for runtime credential injection
- [ ] Added `appsettings.Development.json` to `.gitignore` (if used)
- [ ] Created dedicated PostgreSQL application user with least privileges
- [ ] Enabled SSL/TLS for database connections
- [ ] Implemented credential rotation policy
- [ ] Configured secrets management for production (Key Vault, Secrets Manager, etc.)
- [ ] Reviewed and restricted access to environment variable configuration
- [ ] Documented credential management procedures for operations team

## Verification

After configuring credentials securely, verify the application can connect:

1. Set environment variables as documented above
2. Run the application: `dotnet run`
3. Test database connectivity through the interactive menu or CLI
4. Check logs for any connection errors

## Troubleshooting

**Connection Fails After Configuration:**
- Verify environment variables are set correctly (check casing and double underscores)
- Ensure PostgreSQL server is accessible from the application host
- Verify PostgreSQL user has necessary permissions
- Check firewall rules and network connectivity
- Review PostgreSQL logs for authentication errors

**Environment Variables Not Being Used:**
- Verify `.AddEnvironmentVariables()` is present in `Program.cs`
- Check environment variable naming convention (use `__` for nested keys)
- Restart the application after setting environment variables

## Additional Resources

- [.NET Configuration Documentation](https://docs.microsoft.com/en-us/dotnet/core/extensions/configuration)
- [PostgreSQL Security Best Practices](https://www.postgresql.org/docs/current/security.html)
- [Npgsql Connection String Parameters](https://www.npgsql.org/doc/connection-string-parameters.html)
- [Azure Key Vault Configuration Provider](https://docs.microsoft.com/en-us/aspnet/core/security/key-vault-configuration)
- [AWS Secrets Manager for .NET](https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieving-secrets.html)

## Migration-Specific Notes

### Original Security Issue
The initial migration retained hardcoded credentials (`Username=postgres;Password=postgres`) from the development environment in `appsettings.json`. This posed a significant security risk, especially if the configuration file was committed to version control or deployed to production.

### Resolution
This security remediation implements environment variable support, removes hardcoded credentials, and provides comprehensive guidance for secure credential management across different deployment scenarios (local, Docker, Azure, AWS).

### Critical Action Required Before Production Deployment
**IMPORTANT:** Before deploying to any environment (especially production), you MUST:
1. Configure appropriate environment variables or secrets management
2. Replace placeholder values in `appsettings.json` with appropriate indicators (or remove them entirely)
3. Verify the application connects successfully using the new configuration
4. Document the credential management process for your operations team
