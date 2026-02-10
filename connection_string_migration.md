# Connection String Migration Guide
# SQL Server to PostgreSQL Migration
# Date: 2026-02-10

## Overview
This document describes the connection string format changes required when migrating from Microsoft SQL Server to PostgreSQL.

## Connection String Transformation

### Original SQL Server Format
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### Converted PostgreSQL Format
```
Host=localhost;Port=5432;Database=productmanagement;Username=postgres;Password=postgres;Pooling=true
```

## Parameter Mappings

| SQL Server Parameter | PostgreSQL Parameter | Notes |
|---------------------|---------------------|-------|
| `Server=` | `Host=` | Server hostname or IP address |
| `Database=ProductManagement` | `Database=productmanagement` | Database name (PostgreSQL typically uses lowercase) |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` | Authentication method changed from Windows Integrated to username/password |
| `MultipleActiveResultSets=true` | *Removed* | Not applicable to PostgreSQL (MARS is SQL Server specific) |
| `TrustServerCertificate=True` | *Removed* | Replaced with SSL Mode if needed |
| *N/A* | `Port=5432` | **Added** - Default PostgreSQL port |
| *N/A* | `Pooling=true` | **Added** - Connection pooling enabled |

## Connection String Components Explained

### Required Parameters
1. **Host**: Server hostname or IP address
   - Development: `localhost`
   - Production: Replace with actual PostgreSQL server address

2. **Port**: PostgreSQL listening port
   - Default: `5432`
   - May vary based on PostgreSQL configuration

3. **Database**: Database name
   - Converted to lowercase: `productmanagement`
   - PostgreSQL is case-sensitive for identifiers
   - Unquoted identifiers are folded to lowercase

4. **Username**: PostgreSQL user account
   - Default superuser: `postgres`
   - Production: Use application-specific user with appropriate permissions

5. **Password**: PostgreSQL password
   - Current: `postgres` (default password)
   - **SECURITY NOTE**: Change this in production!

### Optional Parameters
1. **Pooling**: Connection pooling
   - Enabled: `true`
   - Improves performance by reusing connections
   - Npgsql manages the connection pool

2. **SSL Mode** (not included, but available)
   - Options: `Disable`, `Allow`, `Prefer`, `Require`
   - Example: `SSL Mode=Prefer`
   - Use for secure connections over network

## Security Considerations

### Development Environment
Current connection strings use default PostgreSQL credentials:
- Username: `postgres`
- Password: `postgres`

This is acceptable for local development but **MUST NOT** be used in production.

### Production Environment Recommendations
1. **Create Application-Specific User**
   ```sql
   CREATE USER app_user WITH PASSWORD 'strong_password_here';
   GRANT CONNECT ON DATABASE productmanagement TO app_user;
   GRANT USAGE ON SCHEMA public TO app_user;
   GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
   ```

2. **Use Environment Variables**
   - Store connection strings in environment variables or secure configuration
   - Never commit passwords to source control
   - Use Azure Key Vault, AWS Secrets Manager, or similar services

3. **Enable SSL/TLS**
   - Add `SSL Mode=Require` to connection string
   - Configure PostgreSQL to require SSL connections

4. **Connection Pooling**
   - Npgsql handles pooling automatically when `Pooling=true`
   - Default max pool size: 100 connections
   - Customize with `Maximum Pool Size=N` if needed

## Connection String Formats

### Standard Format (Used in this migration)
```
Host=localhost;Port=5432;Database=productmanagement;Username=postgres;Password=postgres;Pooling=true
```

### Alternative URI Format
```
postgresql://postgres:postgres@localhost:5432/productmanagement?Pooling=true
```

### With SSL
```
Host=localhost;Port=5432;Database=productmanagement;Username=postgres;Password=postgres;SSL Mode=Require
```

### With Connection Pool Settings
```
Host=localhost;Port=5432;Database=productmanagement;Username=postgres;Password=postgres;Pooling=true;Minimum Pool Size=0;Maximum Pool Size=50
```

## Migration Checklist

- [x] Replace `Server=` with `Host=`
- [x] Add `Port=5432` parameter
- [x] Replace `Database=ProductManagement` with `Database=productmanagement`
- [x] Replace `Trusted_Connection=True` with `Username=postgres;Password=postgres`
- [x] Remove `MultipleActiveResultSets=true` (SQL Server specific)
- [x] Remove `TrustServerCertificate=True` (SQL Server specific)
- [x] Add `Pooling=true` for connection pooling
- [x] Applied changes to both DevConnection and ProdConnection
- [ ] **Production**: Change username and password from defaults
- [ ] **Production**: Configure SSL if connecting over network
- [ ] **Production**: Store connection string in secure configuration

## Testing Connection Strings

### Test PostgreSQL Connection
```bash
# Using psql command-line tool
psql -h localhost -p 5432 -U postgres -d productmanagement

# Using .NET application
dotnet run
```

### Verify Connection in Code
The application should successfully:
1. Connect to PostgreSQL database
2. Execute queries against productmanagement database
3. Handle transactions properly
4. Close connections appropriately

## Troubleshooting

### Connection Refused
- Verify PostgreSQL service is running: `sudo systemctl status postgresql`
- Check PostgreSQL is listening on port 5432
- Verify firewall rules allow connections

### Authentication Failed
- Verify username and password are correct
- Check PostgreSQL pg_hba.conf authentication configuration
- Ensure user has appropriate permissions

### Database Does Not Exist
- Create the database: `CREATE DATABASE productmanagement;`
- Run database schema migration scripts
- Verify database name matches connection string (case-sensitive)

## References
- Npgsql Connection String Parameters: https://www.npgsql.org/doc/connection-string-parameters.html
- PostgreSQL Authentication: https://www.postgresql.org/docs/current/auth-pg-hba-conf.html
- Connection Pooling in Npgsql: https://www.npgsql.org/doc/connection-string-parameters.html#pooling
