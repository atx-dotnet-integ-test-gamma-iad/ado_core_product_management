# Connection String Migration: SQL Server to PostgreSQL

## Overview
This document describes the transformation of connection strings from Microsoft SQL Server format to PostgreSQL format compatible with Npgsql driver.

## Connection String Transformations

### SQL Server Connection Strings (Original)

**DevConnection:**
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

**ProdConnection:**
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### PostgreSQL Connection Strings (Converted)

**DevConnection:**
```
Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=yourpassword;Pooling=true
```

**ProdConnection:**
```
Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=yourpassword;Pooling=true
```

## Parameter Mapping

| SQL Server Parameter | PostgreSQL Parameter | Notes |
|---------------------|---------------------|-------|
| `Server=localhost` | `Host=localhost` | Hostname/IP address of database server |
| *(default port 1433)* | `Port=5432` | PostgreSQL default port explicitly specified |
| `Database=ProductManagement` | `Database=ProductManagement` | Database name unchanged |
| `Trusted_Connection=True` | `Username=postgres;Password=yourpassword` | Windows authentication replaced with username/password authentication |
| `MultipleActiveResultSets=true` | *(removed)* | Not applicable to PostgreSQL - each command requires its own connection or transaction |
| `TrustServerCertificate=True` | *(removed)* | SSL/TLS configuration handled differently in PostgreSQL |
| *(not present)* | `Pooling=true` | Enable connection pooling for better performance |

## SQL Server Parameters Removed

1. **MultipleActiveResultSets (MARS)**: PostgreSQL doesn't support MARS. Each command should use its own connection or be executed within the same transaction.

2. **TrustServerCertificate**: SSL/TLS configuration in PostgreSQL uses different parameters:
   - `SSL Mode=Require` - Require SSL connection
   - `SSL Mode=Prefer` - Prefer SSL but allow non-SSL
   - `SSL Mode=Disable` - Disable SSL
   - `Trust Server Certificate=true` - Can be used if needed

## PostgreSQL Parameters Added

1. **Port**: Explicitly specifies PostgreSQL port (5432). While optional, it's good practice to include it.

2. **Pooling**: Enables connection pooling in Npgsql for improved performance. This is similar to SQL Server's connection pooling.

## Authentication Changes

**SQL Server:** Used `Trusted_Connection=True` for Windows Authentication

**PostgreSQL:** Uses username/password authentication
- `Username=postgres` - Database user account
- `Password=yourpassword` - User password (should be replaced with actual credentials)

**Important:** For production environments, credentials should be:
- Stored securely (e.g., Azure Key Vault, AWS Secrets Manager, environment variables)
- Not hardcoded in appsettings.json
- Managed through secure configuration providers

## Additional PostgreSQL Connection Parameters (Optional)

These parameters can be added if needed:

- **Timeout**: Connection timeout in seconds (default: 15)
  ```
  Timeout=30
  ```

- **Command Timeout**: Command execution timeout in seconds (default: 30)
  ```
  Command Timeout=60
  ```

- **SSL Mode**: SSL/TLS configuration
  ```
  SSL Mode=Require
  ```

- **Application Name**: Helps identify connections in PostgreSQL logs
  ```
  Application Name=AdoCore
  ```

- **Maximum Pool Size**: Maximum number of connections in the pool
  ```
  Maximum Pool Size=100
  ```

- **Minimum Pool Size**: Minimum number of connections maintained in the pool
  ```
  Minimum Pool Size=0
  ```

## Migration Checklist

- [x] Replaced `Server` with `Host`
- [x] Added `Port=5432`
- [x] Maintained `Database` parameter
- [x] Replaced `Trusted_Connection` with `Username` and `Password`
- [x] Removed `MultipleActiveResultSets`
- [x] Removed `TrustServerCertificate`
- [x] Added `Pooling=true`
- [x] Updated both DevConnection and ProdConnection
- [ ] **TODO**: Replace placeholder password with actual credentials
- [ ] **TODO**: Move credentials to secure configuration provider for production

## Post-Migration Configuration

1. **Update Credentials**: Replace `Username=postgres;Password=yourpassword` with actual PostgreSQL credentials

2. **Environment-Specific Settings**: Consider using different connection strings for different environments:
   - Development: Local PostgreSQL instance
   - Staging: Staging PostgreSQL server
   - Production: Production PostgreSQL server with secure credential management

3. **Connection Pooling**: Monitor connection pool usage and adjust `Maximum Pool Size` if needed

4. **SSL/TLS**: For production environments, consider adding SSL Mode configuration:
   ```
   SSL Mode=Require;Trust Server Certificate=false
   ```

## Verification

After migration, verify connection strings work correctly:

1. Test application startup and configuration loading
2. Test database connection establishment
3. Test query execution
4. Test transaction handling
5. Monitor connection pool behavior

## References

- [Npgsql Connection String Parameters](https://www.npgsql.org/doc/connection-string-parameters.html)
- [PostgreSQL Connection URI Format](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING)
- [Npgsql Connection Pooling](https://www.npgsql.org/doc/connection-pooling.html)
