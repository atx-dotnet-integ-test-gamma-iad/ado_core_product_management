# Security Configuration Guide

## Overview
This document provides guidance on securely configuring the AdoCore application after migration to PostgreSQL.

## Critical Security Updates Applied

### 1. Npgsql Version Upgrade
**Issue**: Npgsql 8.0.0 had a known high severity vulnerability (GHSA-x9vc-6hfv-hg8c)
**Resolution**: Upgraded to Npgsql 8.0.5 which addresses the vulnerability
**Verification**: Check AdoCore.csproj for `<PackageReference Include="Npgsql" Version="8.0.5" />`

### 2. Credential Management
**Issue**: Hardcoded database credentials in appsettings.json
**Resolution**: Replaced with environment variable placeholders

#### Connection String Configuration
The application now uses environment variables for sensitive configuration:
- `${DB_HOST}` - Database server hostname/IP
- `${DB_PORT}` - Database server port (default: 5432)
- `${DB_NAME}` - Database name
- `${DB_USERNAME}` - Database username
- `${DB_PASSWORD}` - Database password

#### Setup Instructions

**For Development:**
1. Copy `.env.example` to `.env`
2. Fill in your local database credentials
3. Ensure `.env` is in `.gitignore` (already configured)
4. Install and configure environment variable expansion for .NET configuration

**For Production:**
Use a secure secrets management solution:
- **Azure**: Azure Key Vault with Azure App Configuration
- **AWS**: AWS Secrets Manager or Systems Manager Parameter Store
- **On-Premise**: HashiCorp Vault or similar enterprise solution

**Never commit actual credentials to version control!**

### 3. PostgreSQL Security Best Practices

#### Database Setup Requirements
Before running the application, ensure:

1. **PostgreSQL Database Instance**
   - PostgreSQL 12+ recommended
   - Database 'ProductManagement' created
   - Proper user permissions configured

2. **Database User Permissions**
   Grant only necessary permissions:
   ```sql
   -- Create user with limited permissions
   CREATE USER app_user WITH PASSWORD 'secure_password';
   
   -- Grant only required permissions
   GRANT CONNECT ON DATABASE ProductManagement TO app_user;
   GRANT USAGE ON SCHEMA public TO app_user;
   GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
   GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;
   ```

3. **Connection Security**
   - Use SSL/TLS for production connections
   - Add to connection string: `SslMode=Require`
   - Configure PostgreSQL `pg_hba.conf` to require SSL

4. **Network Security**
   - Restrict database access to application servers only
   - Use firewall rules to limit PostgreSQL port (5432) access
   - Consider using VPN or private networks

## Runtime Validation Requirements

The following validation steps require a running PostgreSQL database:

### Database Connection Testing
```bash
# Test database connectivity
psql -h localhost -p 5432 -U app_user -d ProductManagement -c "SELECT version();"
```

### Application Testing
```bash
# Build the application
dotnet build

# Run the application (ensure environment variables are set)
dotnet run

# Run with specific connection string (for testing)
export DB_USERNAME=your_user
export DB_PASSWORD=your_password
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=ProductManagement
dotnet run
```

### SQL Statement Validation
All 7 SQL statements have been converted but require runtime validation against PostgreSQL:
- 5 SELECT queries
- 1 INSERT statement
- 1 UPDATE statement
- 1 DELETE statement (note: appears to be 0 based on validation report)

**Action Required**: Execute comprehensive integration tests against PostgreSQL database to validate:
- Functional equivalency of converted SQL statements
- Transaction atomicity
- Data integrity
- Performance characteristics

## Unmet Exit Criteria

The following exit criteria cannot be verified without a PostgreSQL database instance:

1. **Criterion 12**: Application successfully connects to PostgreSQL database
2. **Criterion 13**: All database operations execute successfully
3. **Criterion 14**: Transaction blocks maintain atomicity
4. **Criterion 15**: Application passes all existing tests

## Next Steps

1. **CRITICAL**: Set up PostgreSQL database environment
   - Install PostgreSQL 12+
   - Create 'ProductManagement' database
   - Configure user permissions
   - Migrate schema from SQL Server DDL to PostgreSQL DDL

2. **HIGH PRIORITY**: Configure secure credential management
   - Implement environment variable expansion in application
   - Or integrate with secrets management solution
   - Update deployment scripts/documentation

3. **HIGH PRIORITY**: Execute runtime validation
   - Run all 7 SQL statements against PostgreSQL
   - Execute comprehensive test suite
   - Validate transaction behavior
   - Verify data integrity

4. **MEDIUM PRIORITY**: Performance testing
   - Compare query performance with SQL Server baseline
   - Optimize PostgreSQL-specific query patterns
   - Configure connection pooling parameters

## Additional Resources

- [Npgsql Documentation](https://www.npgsql.org/doc/index.html)
- [PostgreSQL Security](https://www.postgresql.org/docs/current/security.html)
- [.NET Configuration](https://learn.microsoft.com/en-us/dotnet/core/extensions/configuration)
- [Azure Key Vault with .NET](https://learn.microsoft.com/en-us/azure/key-vault/general/overview)
