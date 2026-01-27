# Security Configuration Guide - PostgreSQL Migration

## Overview

This document provides security best practices and configuration guidance for the AdoCore application after migration to PostgreSQL. It addresses the security concerns identified during the migration validation process.

## Critical Security Recommendations

### 1. Database Credentials Management

#### Current State (Development Only)
The application currently uses placeholder credentials in `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;..."
  }
}
```

**⚠️ WARNING:** These credentials are acceptable ONLY for local development and MUST be replaced for any other environment.

#### Recommended Approach for Production

##### Option A: Environment Variables (Simple)
1. Remove hardcoded credentials from `appsettings.json`
2. Use environment variable substitution:

```json
{
  "ConnectionStrings": {
    "ProdConnection": "Host=${DB_HOST};Port=${DB_PORT};Database=${DB_NAME};Username=${DB_USER};Password=${DB_PASSWORD};Pooling=true;Minimum Pool Size=0;Maximum Pool Size=100;SSL Mode=Require"
  }
}
```

3. Set environment variables on the host:
```bash
export DB_HOST=your-db-host.amazonaws.com
export DB_PORT=5432
export DB_NAME=ProductManagement
export DB_USER=app_user
export DB_PASSWORD=secure_random_password_here
```

##### Option B: AWS Secrets Manager (Recommended for AWS)
1. Store credentials in AWS Secrets Manager:
```bash
aws secretsmanager create-secret \
  --name prod/adocore/postgresql \
  --description "PostgreSQL credentials for AdoCore application" \
  --secret-string '{
    "host": "your-rds-instance.region.rds.amazonaws.com",
    "port": "5432",
    "database": "ProductManagement",
    "username": "app_user",
    "password": "generated_secure_password"
  }'
```

2. Add AWS SDK packages to your project:
```bash
dotnet add package AWSSDK.SecretsManager
dotnet add package AWSSDK.Extensions.NETCore.Setup
```

3. Create a secrets manager helper class:
```csharp
using Amazon.SecretsManager;
using Amazon.SecretsManager.Model;
using System.Text.Json;

public class SecretsManagerHelper
{
    private readonly IAmazonSecretsManager _secretsManager;
    
    public SecretsManagerHelper(IAmazonSecretsManager secretsManager)
    {
        _secretsManager = secretsManager;
    }
    
    public async Task<string> GetConnectionStringAsync(string secretName)
    {
        var request = new GetSecretValueRequest
        {
            SecretId = secretName
        };
        
        var response = await _secretsManager.GetSecretValueAsync(request);
        var secret = JsonSerializer.Deserialize<DbSecret>(response.SecretString);
        
        return $"Host={secret.Host};Port={secret.Port};Database={secret.Database};" +
               $"Username={secret.Username};Password={secret.Password};" +
               $"Pooling=true;Minimum Pool Size=0;Maximum Pool Size=100;SSL Mode=Require";
    }
    
    private class DbSecret
    {
        public string Host { get; set; }
        public string Port { get; set; }
        public string Database { get; set; }
        public string Username { get; set; }
        public string Password { get; set; }
    }
}
```

4. Update Program.cs to use Secrets Manager:
```csharp
var builder = WebApplication.CreateBuilder(args);

// Add AWS Secrets Manager
builder.Services.AddAWSService<IAmazonSecretsManager>();
builder.Services.AddSingleton<SecretsManagerHelper>();

// Build the app
var app = builder.Build();

// Get connection string from Secrets Manager
var secretsHelper = app.Services.GetRequiredService<SecretsManagerHelper>();
var connectionString = await secretsHelper.GetConnectionStringAsync("prod/adocore/postgresql");

// Use the connection string
// (You may need to refactor your repository to accept connection string at runtime)
```

##### Option C: Azure Key Vault (Recommended for Azure)
1. Store credentials in Azure Key Vault:
```bash
az keyvault secret set \
  --vault-name your-keyvault-name \
  --name adocore-postgresql-connection \
  --value "Host=your-server.postgres.database.azure.com;Port=5432;Database=ProductManagement;Username=app_user@your-server;Password=secure_password;SSL Mode=Require"
```

2. Add Azure Key Vault packages:
```bash
dotnet add package Azure.Extensions.AspNetCore.Configuration.Secrets
dotnet add package Azure.Identity
```

3. Update Program.cs:
```csharp
var builder = WebApplication.CreateBuilder(args);

// Add Azure Key Vault
var keyVaultEndpoint = new Uri($"https://{builder.Configuration["KeyVaultName"]}.vault.azure.net/");
builder.Configuration.AddAzureKeyVault(keyVaultEndpoint, new DefaultAzureCredential());
```

##### Option D: HashiCorp Vault (For On-Premises/Multi-Cloud)
1. Store credentials in Vault
2. Use VaultSharp package to retrieve secrets
3. Implement similar pattern to AWS Secrets Manager

### 2. Database User Permissions

Create a dedicated database user with minimal required permissions:

```sql
-- Connect as superuser (postgres)
-- Create application user
CREATE USER app_user WITH PASSWORD 'secure_generated_password';

-- Grant minimal permissions
GRANT CONNECT ON DATABASE "ProductManagement" TO app_user;

-- Switch to ProductManagement database
\c ProductManagement

-- Grant schema usage
GRANT USAGE ON SCHEMA public TO app_user;

-- Grant table permissions (adjust based on needs)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- For future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO app_user;
```

**DO NOT use the postgres superuser account for application connections.**

### 3. SSL/TLS Configuration

#### For Production Deployments
Always use encrypted connections:

```json
{
  "ConnectionStrings": {
    "ProdConnection": "Host=your-host;Port=5432;Database=ProductManagement;Username=app_user;Password=from_secrets;SSL Mode=Require;Trust Server Certificate=false"
  }
}
```

SSL Mode options:
- `Require` - Requires SSL, validates certificate
- `Prefer` - Tries SSL first, falls back to non-SSL (not recommended for production)
- `Disable` - No SSL (NEVER use in production)

#### AWS RDS PostgreSQL
RDS instances support SSL by default. Download the RDS CA certificate:

```bash
wget https://s3.amazonaws.com/rds-downloads/rds-ca-2019-root.pem
```

Add to connection string:
```
SSL Mode=Require;Root Certificate=/path/to/rds-ca-2019-root.pem
```

#### Azure Database for PostgreSQL
Azure provides SSL certificates. Configure connection:

```
SSL Mode=Require;Trust Server Certificate=false
```

### 4. Connection String Security Checklist

- [ ] No hardcoded passwords in source code
- [ ] No hardcoded passwords in appsettings.json (production)
- [ ] Credentials stored in secrets management system
- [ ] SSL/TLS enabled for production
- [ ] Using dedicated application user (not postgres/root)
- [ ] Application user has minimal required permissions
- [ ] Connection strings not logged or displayed in errors
- [ ] Secrets management system access properly secured (IAM roles, MSI, etc.)

### 5. Network Security

#### AWS RDS
1. Configure Security Groups:
   - Only allow inbound 5432 from application security group
   - No public internet access unless absolutely necessary

2. Use VPC:
   - Place RDS in private subnet
   - Use VPC peering or PrivateLink if cross-VPC access needed

#### Azure
1. Configure firewall rules in Azure Database for PostgreSQL
2. Use Virtual Network integration
3. Consider Private Endpoint for enhanced security

#### On-Premises
1. Configure pg_hba.conf to restrict access by IP/network
2. Use firewall rules to limit access to port 5432
3. Consider using connection through bastion host or VPN

### 6. Monitoring and Auditing

#### Enable PostgreSQL Logging
```sql
-- As superuser
ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_disconnections = 'on';
ALTER SYSTEM SET log_duration = 'on';
ALTER SYSTEM SET log_statement = 'all';  -- Or 'ddl' for production

-- Reload configuration
SELECT pg_reload_conf();
```

#### Application-Level Logging
Ensure your application logs:
- Connection attempts (success/failure)
- Query execution errors
- Transaction rollbacks
- Security-related events

**Do NOT log:**
- Passwords or connection strings with passwords
- Sensitive data from queries

### 7. Development Environment Setup

For local development, you can use the simple credentials in appsettings.json, but:

1. Use `appsettings.Development.json` for dev credentials:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true;Minimum Pool Size=0;Maximum Pool Size=100"
  }
}
```

2. Ensure `appsettings.Production.json` uses secrets management:
```json
{
  "ConnectionStrings": {
    "ProdConnection": "OVERRIDE_WITH_SECRETS_MANAGER"
  },
  "SecretsManagerSecretName": "prod/adocore/postgresql"
}
```

3. Add to `.gitignore`:
```
appsettings.Production.json
appsettings.*.json
!appsettings.Development.json
```

## Implementation Checklist

### Immediate Actions (Before Any Non-Dev Deployment)
- [ ] Replace placeholder credentials in appsettings.json
- [ ] Implement secrets management solution (AWS Secrets Manager, Azure Key Vault, etc.)
- [ ] Create dedicated database user with minimal permissions
- [ ] Enable SSL/TLS for database connections
- [ ] Configure network security (security groups, firewalls)
- [ ] Update .gitignore to exclude production config files

### Recommended Actions
- [ ] Implement connection string retrieval from secrets manager
- [ ] Enable PostgreSQL audit logging
- [ ] Set up application logging for security events
- [ ] Document credential rotation process
- [ ] Set up monitoring/alerts for failed connection attempts
- [ ] Review and test disaster recovery procedures
- [ ] Implement automated secrets rotation (AWS, Azure support this)

### Post-Deployment Validation
- [ ] Verify application connects using new credentials
- [ ] Confirm SSL/TLS is active (check pg_stat_ssl view)
- [ ] Test that old credentials no longer work
- [ ] Verify logging is capturing expected events
- [ ] Review security group rules
- [ ] Perform security scan of deployed application

## Additional Resources

- [Npgsql Security](https://www.npgsql.org/doc/security.html)
- [PostgreSQL Security Best Practices](https://www.postgresql.org/docs/current/security.html)
- [AWS RDS Security](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts.General.SSL)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)
- [Azure Key Vault](https://docs.microsoft.com/azure/key-vault/)
- [OWASP Database Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Database_Security_Cheat_Sheet.html)

## Support

For questions or concerns about security configuration, consult with your organization's security team before deploying to production environments.

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-27  
**Related Documents:** README.md, final_migration_report.md
