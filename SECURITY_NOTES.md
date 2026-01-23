# Security Configuration Notes

## Connection String Security

### Current Configuration
The `appsettings.json` file contains development connection strings with default credentials. **These should NOT be used in production environments.**

### Recommended Production Configuration

#### Option 1: Environment Variables (Recommended)
Override connection strings using environment variables:

```bash
# Linux/Mac
export ConnectionStrings__DevConnection="Host=prod-host;Database=ProductManagement;Username=app_user;Password=secure_password;Port=5432"
export ConnectionStrings__ProdConnection="Host=prod-host;Database=ProductManagement;Username=app_user;Password=secure_password;Port=5432"

# Windows
set ConnectionStrings__DevConnection=Host=prod-host;Database=ProductManagement;Username=app_user;Password=secure_password;Port=5432
set ConnectionStrings__ProdConnection=Host=prod-host;Database=ProductManagement;Username=app_user;Password=secure_password;Port=5432
```

#### Option 2: User Secrets (Development)
For local development, use .NET User Secrets:

```bash
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=localhost;Database=ProductManagement;Username=postgres;Password=your_secure_password;Port=5432"
```

#### Option 3: Azure Key Vault / AWS Secrets Manager
For production deployments, use cloud-based secret management services.

### PostgreSQL Security Best Practices

1. **Use Strong Passwords**: Replace default 'postgres' password
2. **Create Application-Specific Users**: Don't use the postgres superuser for application connections
3. **Configure SSL/TLS**: Add `SSL Mode=Require` to connection strings for encrypted connections
4. **Network Security**: Use firewall rules and VPC/security groups to restrict database access
5. **Principle of Least Privilege**: Grant only necessary permissions to application database users

### Example Secure Connection String

```
Host=prod-db.example.com;Database=ProductManagement;Username=app_reader;Password=SecureP@ssw0rd!;Port=5432;SSL Mode=Require;Trust Server Certificate=false
```

## Vulnerability Mitigation

### Npgsql Package Update
The Npgsql package has been updated to version 8.0.5 to address known security vulnerability GHSA-x9vc-6hfv-hg8c.

**Always keep packages updated to the latest stable versions.**
