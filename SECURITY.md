# Security Configuration Guide

## Overview

This document provides guidance on securely configuring the AdoCore PostgreSQL application for different deployment environments.

## Development Environment

For local development, you can use `appsettings.json` with test credentials, but **never commit this file to version control**.

### Setup

1. Copy the example configuration:
   ```bash
   cp appsettings.example.json appsettings.json
   ```

2. Update with your local PostgreSQL credentials:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=dev_user;Password=dev_password;Pooling=true"
     },
     "Environment": "Development"
   }
   ```

3. Verify `.gitignore` prevents committing:
   ```bash
   git status
   # appsettings.json should NOT appear in untracked files
   ```

## Production Environment

**NEVER use hardcoded credentials in production.** Always use environment variables or secret management services.

### Option 1: Environment Variables

The application automatically reads environment variables that override `appsettings.json` values.

#### Complete Connection String Override

```bash
export ConnectionStrings__ProdConnection="Host=prod-db.example.com;Port=5432;Database=ProductManagement;Username=app_user;Password=$(cat /run/secrets/db_password);Pooling=true;SSL Mode=Require"
export Environment="Production"
```

#### Individual Component Override

```bash
export POSTGRES_HOST="prod-db.example.com"
export POSTGRES_PORT="5432"
export POSTGRES_DATABASE="ProductManagement"
export POSTGRES_USERNAME="app_user"
export POSTGRES_PASSWORD="$(cat /run/secrets/db_password)"
export Environment="Production"
```

### Option 2: AWS Secrets Manager

#### Store Secrets

```bash
aws secretsmanager create-secret \
  --name prod/adocore/postgres \
  --description "PostgreSQL credentials for AdoCore application" \
  --secret-string '{
    "host":"prod-db.example.com",
    "port":"5432",
    "database":"ProductManagement",
    "username":"app_user",
    "password":"your-secure-password"
  }'
```

#### Retrieve and Use in Application Startup

```bash
# Fetch secret and export as environment variables
SECRET=$(aws secretsmanager get-secret-value --secret-id prod/adocore/postgres --query SecretString --output text)

export POSTGRES_HOST=$(echo $SECRET | jq -r '.host')
export POSTGRES_PORT=$(echo $SECRET | jq -r '.port')
export POSTGRES_DATABASE=$(echo $SECRET | jq -r '.database')
export POSTGRES_USERNAME=$(echo $SECRET | jq -r '.username')
export POSTGRES_PASSWORD=$(echo $SECRET | jq -r '.password')

# Run application
dotnet run
```

#### Alternative: IAM Role-Based Access

For AWS environments, consider using IAM authentication instead of passwords:

```bash
export ConnectionStrings__ProdConnection="Host=prod-rds.amazonaws.com;Port=5432;Database=ProductManagement;Username=app_user;Password=$(aws rds generate-db-auth-token --hostname prod-rds.amazonaws.com --port 5432 --username app_user);SSL Mode=Require"
```

### Option 3: Azure Key Vault

#### Store Secret

```bash
az keyvault secret set \
  --vault-name "adocore-keyvault" \
  --name "postgres-connection" \
  --value "Host=prod-db.postgres.database.azure.com;Port=5432;Database=ProductManagement;Username=app_user@postgres-server;Password=your-secure-password;SSL Mode=Require"
```

#### Retrieve in Application

```bash
CONNECTION_STRING=$(az keyvault secret show \
  --vault-name "adocore-keyvault" \
  --name "postgres-connection" \
  --query value -o tsv)

export ConnectionStrings__ProdConnection="$CONNECTION_STRING"
dotnet run
```

### Option 4: Kubernetes Secrets

#### Create Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-credentials
  namespace: adocore
type: Opaque
stringData:
  POSTGRES_HOST: prod-postgres.database.svc.cluster.local
  POSTGRES_PORT: "5432"
  POSTGRES_DATABASE: ProductManagement
  POSTGRES_USERNAME: app_user
  POSTGRES_PASSWORD: your-secure-password
```

```bash
kubectl apply -f postgres-secret.yaml
```

#### Deploy Application with Secret

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: adocore-app
  namespace: adocore
spec:
  replicas: 3
  selector:
    matchLabels:
      app: adocore
  template:
    metadata:
      labels:
        app: adocore
    spec:
      containers:
      - name: adocore
        image: adocore:latest
        envFrom:
        - secretRef:
            name: postgres-credentials
        env:
        - name: Environment
          value: "Production"
```

### Option 5: Docker Secrets

#### Create Secret

```bash
echo "your-secure-password" | docker secret create postgres_password -
```

#### Use in Docker Compose

```yaml
version: '3.8'
services:
  adocore:
    image: adocore:latest
    environment:
      POSTGRES_HOST: postgres
      POSTGRES_PORT: 5432
      POSTGRES_DATABASE: ProductManagement
      POSTGRES_USERNAME: app_user
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
      Environment: Production
    secrets:
      - postgres_password
    depends_on:
      - postgres

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: ProductManagement
      POSTGRES_USER: app_user
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
    secrets:
      - postgres_password
    volumes:
      - postgres-data:/var/lib/postgresql/data

secrets:
  postgres_password:
    external: true

volumes:
  postgres-data:
```

## Connection String Security Checklist

### Required for Production

- [ ] **SSL/TLS Encryption**: Use `SSL Mode=Require` or `SSL Mode=VerifyFull`
- [ ] **No Hardcoded Passwords**: Use environment variables or secret management
- [ ] **Strong Passwords**: Minimum 16 characters, alphanumeric + special characters
- [ ] **Least Privilege**: Application user should have only required permissions
- [ ] **Connection Pooling**: Enabled for performance (`Pooling=true`)
- [ ] **Credential Rotation**: Implement automated rotation schedule
- [ ] **Audit Logging**: Enable PostgreSQL audit logging for compliance

### PostgreSQL SSL Configuration

```
# postgresql.conf
ssl = on
ssl_cert_file = '/path/to/server.crt'
ssl_key_file = '/path/to/server.key'
ssl_ca_file = '/path/to/root.crt'

# pg_hba.conf
# Require SSL for all remote connections
hostssl all all 0.0.0.0/0 scram-sha-256
```

### Connection String Examples

#### Development (Local)
```
Host=localhost;Port=5432;Database=ProductManagement;Username=dev_user;Password=dev_password;Pooling=true
```

#### Production (SSL Required)
```
Host=prod-db.example.com;Port=5432;Database=ProductManagement;Username=app_user;Password=***;Pooling=true;SSL Mode=Require;Trust Server Certificate=false;SSL Certificate=/path/to/client.crt;SSL Key=/path/to/client.key;Root Certificate=/path/to/ca.crt
```

#### AWS RDS with IAM Authentication
```
Host=prod-rds.amazonaws.com;Port=5432;Database=ProductManagement;Username=app_user;Password=$(aws rds generate-db-auth-token --hostname prod-rds.amazonaws.com --port 5432 --username app_user);SSL Mode=Require
```

## Database User Security

### Create Application User with Minimal Permissions

```sql
-- Create dedicated application user
CREATE USER app_user WITH PASSWORD 'secure-password-here';

-- Grant connection to database
GRANT CONNECT ON DATABASE "ProductManagement" TO app_user;

-- Grant schema usage
GRANT USAGE ON SCHEMA productmanagement_dbo TO app_user;

-- Grant table permissions (only what's needed)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA productmanagement_dbo TO app_user;

-- Grant sequence permissions (for SERIAL/auto-increment columns)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA productmanagement_dbo TO app_user;

-- For future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA productmanagement_dbo 
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA productmanagement_dbo 
    GRANT USAGE, SELECT ON SEQUENCES TO app_user;
```

### Verify Permissions

```sql
-- Check user permissions
\du app_user

-- Check table permissions
SELECT grantee, table_schema, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'app_user';
```

### Read-Only User (for reporting)

```sql
CREATE USER readonly_user WITH PASSWORD 'readonly-password';
GRANT CONNECT ON DATABASE "ProductManagement" TO readonly_user;
GRANT USAGE ON SCHEMA productmanagement_dbo TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA productmanagement_dbo TO readonly_user;
```

## Credential Rotation

### Automated Rotation Strategy

1. **Generate new credentials** using secure random generator
2. **Create new database user** with same permissions
3. **Update secret** in secret management service
4. **Restart application** to pick up new credentials
5. **Verify connectivity** with new credentials
6. **Revoke old user** after grace period

### Example Rotation Script

```bash
#!/bin/bash
set -e

# Generate new password
NEW_PASSWORD=$(openssl rand -base64 32)

# Create new user in PostgreSQL
psql -h prod-db.example.com -U admin -d ProductManagement <<EOF
CREATE USER app_user_new WITH PASSWORD '$NEW_PASSWORD';
GRANT CONNECT ON DATABASE "ProductManagement" TO app_user_new;
GRANT USAGE ON SCHEMA productmanagement_dbo TO app_user_new;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA productmanagement_dbo TO app_user_new;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA productmanagement_dbo TO app_user_new;
EOF

# Update AWS Secrets Manager
aws secretsmanager update-secret \
  --secret-id prod/adocore/postgres \
  --secret-string "{
    \"host\":\"prod-db.example.com\",
    \"port\":\"5432\",
    \"database\":\"ProductManagement\",
    \"username\":\"app_user_new\",
    \"password\":\"$NEW_PASSWORD\"
  }"

# Trigger application restart (K8s example)
kubectl rollout restart deployment/adocore-app -n adocore

# Wait for rollout to complete
kubectl rollout status deployment/adocore-app -n adocore

# After verification (manual step), drop old user
# psql -h prod-db.example.com -U admin -d ProductManagement -c "DROP USER app_user;"

echo "Credential rotation complete. Verify application connectivity before dropping old user."
```

## Monitoring and Alerting

### Connection Monitoring

Monitor for:
- Failed authentication attempts
- Excessive connection creation
- Connection pool exhaustion
- SSL/TLS connection failures

### PostgreSQL Logging

```
# postgresql.conf
log_connections = on
log_disconnections = on
log_hostname = off
log_line_prefix = '%t [%p]: user=%u,db=%d,app=%a,client=%h '
log_statement = 'ddl'  # Log DDL statements
log_min_duration_statement = 1000  # Log queries > 1s
```

### Application Logging

Add structured logging for security events:
- Authentication failures
- Connection errors
- Query execution errors
- Transaction rollbacks

## Compliance Considerations

### PCI DSS
- Encrypt credentials at rest and in transit
- Implement access controls and logging
- Regular security assessments

### HIPAA
- Encrypt all PHI data
- Implement audit trails
- Access controls and user authentication

### GDPR
- Data encryption
- Access controls
- Audit logging for data access

## Security Incident Response

### If Credentials are Compromised

1. **Immediately revoke** compromised credentials
2. **Generate new credentials** using secure process
3. **Update all systems** with new credentials
4. **Audit database access logs** for unauthorized activity
5. **Review application logs** for anomalous behavior
6. **Document incident** per compliance requirements

### Emergency Credential Rotation

```bash
# 1. Disable compromised user
psql -c "ALTER USER app_user WITH PASSWORD 'DISABLED' NOLOGIN;"

# 2. Create emergency user
psql -c "CREATE USER app_user_emergency WITH PASSWORD '$(openssl rand -base64 32)';"
psql -c "GRANT app_user TO app_user_emergency;"  # Copy permissions

# 3. Update connection string immediately
export ConnectionStrings__ProdConnection="Host=...;Username=app_user_emergency;Password=..."

# 4. Restart application
systemctl restart adocore.service
```

## Additional Resources

- [PostgreSQL Security Best Practices](https://www.postgresql.org/docs/current/security.html)
- [Npgsql Connection Strings](https://www.npgsql.org/doc/connection-string-parameters.html)
- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [CIS PostgreSQL Benchmark](https://www.cisecurity.org/benchmark/postgresql)
