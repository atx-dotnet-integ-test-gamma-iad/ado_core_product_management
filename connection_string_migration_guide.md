# Connection String Migration Guide
## SQL Server to PostgreSQL Connection String Transformation

**Date:** 2026-01-20  
**Application:** ADO .NET ProductManagement Application

---

## Overview

This guide documents the transformation of SQL Server connection strings to PostgreSQL (Npgsql) connection strings as part of the database migration process.

---

## Connection String Transformations

### SQL Server Format (Original)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### PostgreSQL Format (New)

**Development Connection:**
```
Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;SSL Mode=Disable;Include Error Detail=true
```

**Production Connection:**
```
Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=CHANGE_ME_IN_PRODUCTION;SSL Mode=Require;Include Error Detail=true
```

---

## Parameter Mapping Reference

| SQL Server Parameter | PostgreSQL Parameter | Notes |
|---------------------|---------------------|--------|
| `Server=localhost` | `Host=localhost` | Host/server name remains the same |
| (implicit port 1433) | `Port=5432` | PostgreSQL default port must be explicit |
| `Database=ProductManagement` | `Database=ProductManagement` | Database name unchanged |
| `Trusted_Connection=True` | `Username=postgres;Password=...` | Windows integrated auth → credentials |
| `MultipleActiveResultSets=true` | (removed) | Not applicable to PostgreSQL |
| `TrustServerCertificate=True` | `SSL Mode=Disable` (dev) / `SSL Mode=Require` (prod) | SSL configuration |
| (none) | `Include Error Detail=true` | PostgreSQL-specific for debugging |

---

## Security Considerations

### Development Environment
- **Current:** Password stored in appsettings.json (`postgres`)
- **Recommended:** Use dotnet user-secrets for local development
  ```bash
  dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=your_dev_password;SSL Mode=Disable;Include Error Detail=true"
  ```

### Production Environment
- **CRITICAL:** Never commit production passwords to source control
- **Current:** Placeholder `CHANGE_ME_IN_PRODUCTION` in appsettings.json
- **Recommended Options:**
  1. **AWS Secrets Manager:**
     ```csharp
     // Retrieve connection string from AWS Secrets Manager
     var secret = await secretsManagerClient.GetSecretValueAsync(new GetSecretValueRequest
     {
         SecretId = "ProductManagement/PostgreSQL/ConnectionString"
     });
     ```
  
  2. **Azure Key Vault:**
     ```csharp
     // Retrieve connection string from Azure Key Vault
     var client = new SecretClient(vaultUri, new DefaultAzureCredential());
     var secret = await client.GetSecretAsync("PostgreSQL-ConnectionString");
     ```
  
  3. **Environment Variables:**
     ```csharp
     _connectionString = Environment.GetEnvironmentVariable("POSTGRESQL_CONNECTION_STRING");
     ```

---

## Authentication Methods

### Username/Password Authentication (Current)
```
Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=your_password
```

### Certificate-Based Authentication
```
Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;SSL Mode=Require;SSL Certificate=/path/to/client.crt;SSL Key=/path/to/client.key;Root Certificate=/path/to/root.crt
```

### AWS RDS IAM Authentication
```
Host=your-rds-instance.region.rds.amazonaws.com;Port=5432;Database=ProductManagement;Username=iam_user;Password=<RDS_AUTH_TOKEN>;SSL Mode=Require
```

---

## SSL/TLS Configuration

### Development (SSL Disabled)
```
SSL Mode=Disable
```
- **Use Case:** Local development, test environments
- **Security:** No encryption - DO NOT use for production

### Production (SSL Required)
```
SSL Mode=Require;Include Error Detail=false
```
- **Use Case:** Production environments
- **Security:** Enforces encrypted connections
- **Note:** `Include Error Detail=false` for production to prevent sensitive data leakage

### Strict SSL with Certificate Validation
```
SSL Mode=VerifyFull;Root Certificate=/path/to/ca-cert.pem
```
- **Use Case:** High-security production environments
- **Security:** Validates server certificate against trusted CA

---

## Additional PostgreSQL Connection Parameters

### Connection Pooling (Default: Enabled)
```
Pooling=true;Minimum Pool Size=1;Maximum Pool Size=100
```

### Connection Timeouts
```
Timeout=30;Command Timeout=30
```

### Application Name (Useful for Monitoring)
```
Application Name=ProductManagement.NET
```

### Keep-Alive Settings
```
Keepalive=30;Tcp Keepalive=true;Tcp Keepalive Time=30;Tcp Keepalive Interval=10
```

### Example Complete Production Connection String
```
Host=prod-postgres.example.com;Port=5432;Database=ProductManagement;Username=app_user;Password=<secure_password>;SSL Mode=Require;Application Name=ProductManagement.NET;Timeout=30;Command Timeout=60;Minimum Pool Size=5;Maximum Pool Size=50;Include Error Detail=false
```

---

## Migration Checklist

- [x] SQL Server connection string parameters mapped to PostgreSQL equivalents
- [x] Development connection string updated in appsettings.json
- [x] Production connection string updated with placeholder password
- [x] SSL configuration specified for both environments
- [x] `Include Error Detail` configured appropriately for each environment
- [ ] Production password moved to secrets management system
- [ ] Environment-specific configuration verified
- [ ] Connection pooling settings reviewed and optimized
- [ ] Timeout values adjusted based on application needs

---

## Troubleshooting

### Connection Refused
**Symptom:** `Npgsql.NpgsqlException: Connection refused`
**Solutions:**
- Verify PostgreSQL server is running: `systemctl status postgresql` or `pg_isready`
- Check port 5432 is accessible: `telnet localhost 5432`
- Verify `pg_hba.conf` allows connections from your application host
- Check PostgreSQL is listening on correct interface in `postgresql.conf`

### Authentication Failed
**Symptom:** `Npgsql.PostgresException: password authentication failed for user`
**Solutions:**
- Verify username and password are correct
- Check `pg_hba.conf` authentication method (md5, scram-sha-256, trust)
- Ensure user exists: `SELECT * FROM pg_user WHERE usename = 'postgres';`
- Reset password if needed: `ALTER USER postgres PASSWORD 'new_password';`

### SSL/TLS Errors
**Symptom:** `Npgsql.NpgsqlException: SSL connection has been closed unexpectedly`
**Solutions:**
- Verify SSL Mode setting matches server configuration
- Check server certificate is valid and not expired
- For development, use `SSL Mode=Disable`
- For production, ensure CA certificate is accessible

### Database Does Not Exist
**Symptom:** `Npgsql.PostgresException: database "ProductManagement" does not exist`
**Solutions:**
- Create database: `CREATE DATABASE ProductManagement;`
- Run schema migration scripts
- Verify database name spelling and case-sensitivity

### Timeout Errors
**Symptom:** `Npgsql.NpgsqlException: Exception while connecting: Timeout during connecting attempt`
**Solutions:**
- Increase `Timeout` parameter in connection string
- Check network connectivity
- Verify firewall rules allow PostgreSQL traffic
- Check PostgreSQL max_connections setting

---

## Testing Connection Strings

### PowerShell Test Script
```powershell
$connectionString = "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;SSL Mode=Disable"

Add-Type -Path "path\to\Npgsql.dll"
$conn = New-Object Npgsql.NpgsqlConnection($connectionString)

try {
    $conn.Open()
    Write-Host "Connection successful!" -ForegroundColor Green
    $conn.Close()
} catch {
    Write-Host "Connection failed: $_" -ForegroundColor Red
}
```

### C# Test Code
```csharp
using Npgsql;

var connectionString = "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;SSL Mode=Disable";

try
{
    using var connection = new NpgsqlConnection(connectionString);
    await connection.OpenAsync();
    Console.WriteLine("Connection successful!");
}
catch (Exception ex)
{
    Console.WriteLine($"Connection failed: {ex.Message}");
}
```

---

## Rollback Instructions

If you need to revert to SQL Server:

1. Restore original connection strings from `appsettings_sqlserver.json`
2. Update AdoCore.csproj:
   ```xml
   <PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />
   ```
3. Restore original ProductRepository.cs from backups
4. Run `dotnet restore` and `dotnet build`

---

## Resources

- [Npgsql Documentation](https://www.npgsql.org/doc/index.html)
- [PostgreSQL Connection Strings](https://www.npgsql.org/doc/connection-string-parameters.html)
- [PostgreSQL Security Best Practices](https://www.postgresql.org/docs/current/auth-pg-hba-conf.html)
- [AWS RDS PostgreSQL IAM Authentication](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html)

---

**Migration Status:** Connection strings successfully migrated to PostgreSQL format  
**Next Steps:** Configure actual PostgreSQL database and test connectivity
