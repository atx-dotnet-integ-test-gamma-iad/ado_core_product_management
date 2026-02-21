# Security Notes for PostgreSQL Migration

## Connection String Security

⚠️ **IMPORTANT SECURITY NOTICE** ⚠️

The `appsettings.json` file currently contains **hardcoded database credentials**. This is acceptable for local development and testing purposes only.

### For Production Deployment

**DO NOT** deploy this application to production with hardcoded credentials in `appsettings.json`.

### Recommended Solutions

#### 1. Environment Variables
Set connection strings via environment variables:
```bash
export ConnectionStrings__ProdConnection="Host=prod-server;Database=ProductManagement;Username=app_user;Password=***;Port=5432;Pooling=true"
```

#### 2. .NET User Secrets (Local Development)
Use the User Secrets feature for local development:
```bash
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=localhost;Database=ProductManagement;Username=postgres;Password=***;Port=5432;Pooling=true"
```

#### 3. Cloud Secret Management Services
- **Azure**: Azure Key Vault
- **AWS**: AWS Secrets Manager or AWS Systems Manager Parameter Store
- **Google Cloud**: Google Cloud Secret Manager

#### 4. Configuration Providers
Update `Program.cs` to use configuration providers:
```csharp
builder.Configuration
    .AddJsonFile("appsettings.json", optional: false)
    .AddEnvironmentVariables()
    .AddUserSecrets<Program>(optional: true);
```

## Package Security

✅ **Npgsql Version**: The project has been updated to use Npgsql 10.0.1, which resolves the known high-severity vulnerability (GHSA-x9vc-6hfv-hg8c) present in version 8.0.1.

### Regular Security Updates
Regularly check for package vulnerabilities:
```bash
dotnet list package --vulnerable
dotnet list package --outdated
```

## Database Security Recommendations

1. **Least Privilege**: Create application-specific database users with minimal required permissions
2. **SSL/TLS**: Enable SSL connection to PostgreSQL in production
3. **Network Security**: Restrict database access via firewall rules
4. **Password Policy**: Use strong, randomly generated passwords
5. **Rotation**: Implement regular credential rotation
6. **Audit Logging**: Enable PostgreSQL audit logging for production environments

## Runtime Testing Required

Before production deployment, ensure:
- [ ] PostgreSQL database is properly configured with lowercase schema (products, producthistory, productstats)
- [ ] Connection strings use secure credential storage
- [ ] Database user has appropriate permissions
- [ ] SSL/TLS is enabled for database connections
- [ ] All database operations have been tested
- [ ] Transaction isolation and atomicity have been verified
- [ ] Integration tests pass against the PostgreSQL database
