# Security Recommendations for Production Deployment

## Overview
This document outlines security considerations for deploying the migrated PostgreSQL application to production environments.

## Critical Security Issues to Address Before Production

### 1. Database Credentials Externalization

**Current State:**
- Database credentials are hardcoded in `appsettings.json`:
  ```json
  "DevConnection": "Host=localhost;Database=productmanagement;Username=postgres;Password=postgres;Port=5432;Pooling=true"
  ```

**Risk:** Hardcoded credentials expose the database to unauthorized access if the configuration file is compromised.

**Recommended Solutions:**

#### Option A: Environment Variables (Simple)
```csharp
// In Program.cs or Startup
var connectionString = $"Host={Environment.GetEnvironmentVariable("DB_HOST")};" +
                      $"Database={Environment.GetEnvironmentVariable("DB_NAME")};" +
                      $"Username={Environment.GetEnvironmentVariable("DB_USER")};" +
                      $"Password={Environment.GetEnvironmentVariable("DB_PASSWORD")};" +
                      $"Port={Environment.GetEnvironmentVariable("DB_PORT")};Pooling=true";
```

#### Option B: Azure Key Vault (Recommended for Azure)
```csharp
// Add NuGet: Azure.Identity, Azure.Security.KeyVault.Secrets
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var keyVaultUrl = new Uri($"https://{Environment.GetEnvironmentVariable("KEY_VAULT_NAME")}.vault.azure.net/");
var client = new SecretClient(keyVaultUrl, new DefaultAzureCredential());
var dbPassword = await client.GetSecretAsync("db-password");

var connectionString = $"Host=...;Password={dbPassword.Value.Value};...";
```

#### Option C: AWS Secrets Manager (Recommended for AWS)
```csharp
// Add NuGet: AWSSDK.SecretsManager
using Amazon.SecretsManager;
using Amazon.SecretsManager.Model;

var client = new AmazonSecretsManagerClient();
var request = new GetSecretValueRequest { SecretId = "prod/db/credentials" };
var response = await client.GetSecretValueAsync(request);
// Parse JSON response and build connection string
```

#### Option D: User Secrets (Development Only)
```bash
# For development environments only
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=localhost;Database=productmanagement;Username=postgres;Password=YOUR_PASSWORD;Port=5432;Pooling=true"
```

### 2. Connection String Security Best Practices

**Recommendations:**
1. **Never commit credentials to source control**
   - Add `appsettings.Production.json` to `.gitignore`
   - Use configuration transforms for environment-specific settings

2. **Use connection pooling** (already configured)
   - `Pooling=true` is set correctly

3. **Implement SSL/TLS for database connections**
   ```
   Host=localhost;Database=productmanagement;Username=postgres;Password=***;Port=5432;SSL Mode=Require;Trust Server Certificate=false
   ```

4. **Use least-privilege database accounts**
   - Create application-specific database users
   - Grant only necessary permissions (SELECT, INSERT, UPDATE, DELETE on specific tables)
   - Avoid using superuser accounts like `postgres`

5. **Rotate credentials regularly**
   - Implement automated credential rotation
   - Use managed identities where possible

### 3. Npgsql Security Configuration

**Current Status:** Npgsql 8.0.5 (security vulnerability addressed)

**Previous Issue:** Npgsql 8.0.0 had vulnerability NU1903 (GHSA-x9vc-6hfv-hg8c)
**Resolution:** Upgraded to Npgsql 8.0.5

**Recommendations:**
- Keep Npgsql updated to the latest stable version
- Monitor security advisories: https://github.com/npgsql/npgsql/security/advisories
- Consider enabling automatic security updates in your CI/CD pipeline

### 4. Configuration File Protection

**For appsettings.json:**
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=productmanagement;Username=appuser;Password=__PLACEHOLDER__;Port=5432;Pooling=true"
  }
}
```

**For appsettings.Production.json (not in source control):**
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=prod-db.example.com;Database=productmanagement;Username=prod_appuser;Password=__FROM_KEYVAULT__;Port=5432;Pooling=true;SSL Mode=Require"
  }
}
```

### 5. Database Schema Security

**Recommendations:**
1. Create application-specific schema and user:
   ```sql
   -- As postgres superuser
   CREATE USER appuser WITH PASSWORD 'secure_password';
   CREATE SCHEMA app_schema AUTHORIZATION appuser;
   
   -- Grant specific permissions
   GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app_schema TO appuser;
   GRANT USAGE ON ALL SEQUENCES IN SCHEMA app_schema TO appuser;
   ```

2. Use schema-qualified table names in queries:
   ```sql
   SELECT * FROM app_schema.products WHERE productid = @productid
   ```

3. Enable PostgreSQL audit logging:
   ```
   # In postgresql.conf
   log_connections = on
   log_disconnections = on
   log_statement = 'mod'  # Log all modification statements
   ```

### 6. Network Security

**Recommendations:**
1. **Restrict database access by IP**
   - Configure `pg_hba.conf` to allow only application servers
   - Use private networks/VPCs

2. **Use SSL/TLS for all connections**
   ```
   # In connection string
   SSL Mode=Require;Trust Server Certificate=false
   ```

3. **Implement firewall rules**
   - Allow PostgreSQL port (5432) only from application subnet
   - Block public internet access to database

### 7. Monitoring and Alerting

**Recommendations:**
1. Monitor failed connection attempts
2. Alert on unusual query patterns
3. Track connection pool exhaustion
4. Log all authentication failures

## Implementation Checklist

Before deploying to production:

- [ ] Remove hardcoded credentials from `appsettings.json`
- [ ] Implement credential management (Key Vault/Secrets Manager)
- [ ] Enable SSL/TLS for database connections
- [ ] Create application-specific database user with limited permissions
- [ ] Configure PostgreSQL `pg_hba.conf` for IP restrictions
- [ ] Enable PostgreSQL audit logging
- [ ] Set up monitoring and alerting
- [ ] Test connection with production credentials in staging environment
- [ ] Document credential rotation procedures
- [ ] Review and update `.gitignore` to exclude production configs
- [ ] Upgrade to latest stable Npgsql version (currently 8.0.5)

## Current Testing Configuration

**Note:** The current configuration in `appsettings.json` uses:
- Username: `postgres`
- Password: `postgres`
- Host: `localhost`

This is appropriate **ONLY** for:
- Local development environments
- Automated testing in isolated containers
- Proof-of-concept demonstrations

**This configuration MUST NOT be used in production.**

## Additional Resources

- [Npgsql Security Best Practices](https://www.npgsql.org/doc/security.html)
- [PostgreSQL Security Documentation](https://www.postgresql.org/docs/current/security.html)
- [OWASP Database Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Database_Security_Cheat_Sheet.html)
- [Azure Key Vault Documentation](https://docs.microsoft.com/azure/key-vault/)
- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)

## Support

For questions or concerns about security implementation, consult your organization's security team or a security specialist.
