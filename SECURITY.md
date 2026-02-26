# Security Guidelines

## Credential Management

This application has been migrated from SQL Server to PostgreSQL and implements secure credential management practices.

### Environment Variable Configuration

Database credentials should NEVER be hardcoded in source code or committed to version control. Instead, use environment variables to configure database connections.

#### Setup Instructions

1. **Copy the example environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Update .env with your actual credentials:**
   Edit `.env` and replace placeholder values with your PostgreSQL credentials.

3. **The application configuration system supports:**
   - Environment variables override appsettings.json values
   - Hierarchical configuration using double underscore (__) notation
   - Example: `DatabaseSettings__Username=myuser` overrides `DatabaseSettings.Username`

#### Environment Variable Naming Convention

Use the following environment variables to override database settings:

```bash
DatabaseSettings__Host=your-postgres-host
DatabaseSettings__Port=5432
DatabaseSettings__Database=ProductManagement
DatabaseSettings__Username=your-username
DatabaseSettings__Password=your-secure-password
```

Or override entire connection strings:

```bash
ConnectionStrings__DevConnection="Host=localhost;Port=5432;Database=ProductManagement;Username=youruser;Password=yourpassword"
ConnectionStrings__ProdConnection="Host=prod-server;Port=5432;Database=ProductManagement;Username=youruser;Password=yourpassword"
```

### Production Deployment

For production environments, use secure secret management solutions:

- **Azure:** Azure Key Vault
- **AWS:** AWS Secrets Manager or Systems Manager Parameter Store
- **On-Premises:** HashiCorp Vault
- **Docker/Kubernetes:** Kubernetes Secrets or Docker Secrets

### What's Protected

The following files are excluded from version control (see .gitignore):
- `.env` - Local environment configuration
- `.env.local` - Local overrides
- `.env.production` - Production environment configuration

### Security Best Practices

1. ✅ **DO:** Use environment variables or secret management services
2. ✅ **DO:** Use strong, unique passwords for database accounts
3. ✅ **DO:** Use principle of least privilege for database user permissions
4. ✅ **DO:** Rotate credentials regularly
5. ❌ **DON'T:** Commit credentials to version control
6. ❌ **DON'T:** Share .env files via email or messaging
7. ❌ **DON'T:** Use default passwords (like 'postgres') in production

### Package Security

The application uses Npgsql 8.0.5 for PostgreSQL connectivity. Regularly check for security updates:

```bash
dotnet list package --vulnerable
```

To update Npgsql to the latest version:

```bash
dotnet add package Npgsql
```

## Reporting Security Issues

If you discover a security vulnerability, please report it immediately to your security team or project maintainer.
