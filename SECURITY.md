# Security Configuration Guide

## Database Password Management

### Overview
This application has been configured to support environment variables for secure credential management. Hardcoded passwords should **never** be used in production environments.

### Configuration Methods

#### 1. Environment Variables (Recommended for Production)
Set the complete connection string via environment variable:

**Linux/macOS:**
```bash
export ConnectionStrings__ProdConnection="Host=your-host;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_SECURE_PASSWORD"
```

**Windows (PowerShell):**
```powershell
$env:ConnectionStrings__ProdConnection="Host=your-host;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_SECURE_PASSWORD"
```

**Windows (Command Prompt):**
```cmd
set ConnectionStrings__ProdConnection=Host=your-host;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_SECURE_PASSWORD
```

#### 2. Docker Environment Variables
In `docker-compose.yml`:
```yaml
services:
  app:
    environment:
      - ConnectionStrings__ProdConnection=Host=postgres;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_SECURE_PASSWORD
```

#### 3. Kubernetes Secrets
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-connection
type: Opaque
stringData:
  connection-string: "Host=postgres;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_SECURE_PASSWORD"
```

Then reference in deployment:
```yaml
env:
  - name: ConnectionStrings__ProdConnection
    valueFrom:
      secretKeyRef:
        name: db-connection
        key: connection-string
```

### Current Configuration

- **Development Connection**: Uses default password (acceptable for local development only)
- **Production Connection**: Password intentionally left empty in `appsettings.json`
- **Environment Override**: The application now reads environment variables, which override JSON settings

### Migration from SQL Server

This application has been migrated from Microsoft SQL Server to PostgreSQL. Key security changes:

1. **Connection String Format**: Now uses PostgreSQL format (`Host=`, `Port=`, etc.)
2. **Authentication**: Supports PostgreSQL authentication methods
3. **Environment Variables**: Fully integrated for secure credential management

### Best Practices

1. ✅ **DO**: Use environment variables for production credentials
2. ✅ **DO**: Use secrets management systems (AWS Secrets Manager, Azure Key Vault, HashiCorp Vault)
3. ✅ **DO**: Rotate passwords regularly
4. ✅ **DO**: Use strong, unique passwords
5. ❌ **DON'T**: Commit credentials to version control
6. ❌ **DON'T**: Use default passwords in production
7. ❌ **DON'T**: Share production credentials via insecure channels

### Verification

After configuring environment variables, verify the connection:
```bash
dotnet run
```

The application will use the environment variable if set, otherwise fall back to `appsettings.json`.

### Additional Security Considerations

1. **SSL/TLS**: For production, enable SSL in the connection string:
   ```
   Host=your-host;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;SSL Mode=Require
   ```

2. **Network Security**: Ensure PostgreSQL server is not exposed to the public internet
3. **Least Privilege**: Use database users with minimal required permissions
4. **Audit Logging**: Enable PostgreSQL audit logging for production environments

### Support

For issues or questions about security configuration, please refer to:
- [.NET Configuration Documentation](https://docs.microsoft.com/en-us/aspnet/core/fundamentals/configuration/)
- [Npgsql Connection Strings](https://www.npgsql.org/doc/connection-string-parameters.html)
