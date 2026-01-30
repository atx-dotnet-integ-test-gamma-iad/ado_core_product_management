# PostgreSQL Deployment Requirements and Guide

## Overview

This document provides comprehensive deployment requirements and guidelines for deploying the ADO.NET Core application with PostgreSQL database in various environments.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Security Requirements](#security-requirements)
3. [PostgreSQL Configuration](#postgresql-configuration)
4. [Application Configuration](#application-configuration)
5. [Deployment Environments](#deployment-environments)
6. [Testing and Validation](#testing-and-validation)
7. [Monitoring and Maintenance](#monitoring-and-maintenance)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Software Requirements

#### PostgreSQL Database
- **Version**: PostgreSQL 12 or later (PostgreSQL 15+ recommended)
- **Why**: Provides necessary features for window functions, CTEs, and JSONB support
- **Installation**: See README.md for installation instructions per platform

#### .NET Runtime
- **Version**: .NET 9.0 SDK or later
- **Installation**: https://dotnet.microsoft.com/download

#### Required NuGet Packages
- Npgsql 8.0.5 (PostgreSQL data provider)
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

### Hardware Requirements

#### Development Environment
- **RAM**: Minimum 4GB, 8GB recommended
- **CPU**: 2+ cores
- **Disk**: 10GB free space
- **PostgreSQL**: 1GB RAM minimum, 2GB+ recommended

#### Production Environment
- **RAM**: 8GB minimum, 16GB+ recommended
- **CPU**: 4+ cores recommended
- **Disk**: 50GB+ with SSD for database
- **PostgreSQL**: 4GB RAM minimum, scale based on data volume
- **Network**: Low latency between application and database servers

---

## Security Requirements

### 1. Database Credentials

**CRITICAL**: Never use default credentials in production!

#### Development (Current)
```
Username: postgres
Password: postgres
```

#### Production (Required Changes)
1. **Create dedicated application user**:
   ```sql
   -- Connect as postgres superuser
   CREATE USER app_user WITH PASSWORD 'strong_random_password_here';
   
   -- Grant necessary privileges
   GRANT CONNECT ON DATABASE "ProductManagement" TO app_user;
   GRANT USAGE ON SCHEMA public TO app_user;
   GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
   GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;
   
   -- Grant privileges on future tables
   ALTER DEFAULT PRIVILEGES IN SCHEMA public 
   GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
   ALTER DEFAULT PRIVILEGES IN SCHEMA public 
   GRANT USAGE, SELECT ON SEQUENCES TO app_user;
   ```

2. **Password Requirements**:
   - Minimum 16 characters
   - Include uppercase, lowercase, numbers, and special characters
   - Use password generator or key vault
   - Rotate passwords every 90 days

3. **Connection String Security**:
   - **Development**: Use User Secrets
     ```bash
     dotnet user-secrets init
     dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=localhost;Port=5432;Database=ProductManagement;Username=app_user;Password=your_password"
     ```
   
   - **Production**: Use environment variables or Azure Key Vault/AWS Secrets Manager
     ```bash
     export ConnectionStrings__DevConnection="Host=prod-db.example.com;Port=5432;Database=ProductManagement;Username=app_user;Password=vault_retrieved_password;SSL Mode=Require"
     ```

### 2. Network Security

#### PostgreSQL Configuration (pg_hba.conf)
```conf
# Development - localhost only
host    ProductManagement    postgres    127.0.0.1/32    scram-sha-256

# Production - specific application servers only
hostssl    ProductManagement    app_user    10.0.1.0/24    scram-sha-256
```

#### Firewall Rules
- **Development**: Accept only from localhost (127.0.0.1)
- **Production**: Accept only from application server IPs
- **Port**: PostgreSQL default 5432 (or custom port for security by obscurity)

#### SSL/TLS Requirements

**Production MUST use SSL**:

1. **Generate SSL certificates**:
   ```bash
   # Self-signed for testing (NOT for production)
   openssl req -new -x509 -days 365 -nodes -text -out server.crt \
     -keyout server.key -subj "/CN=dbhost.example.com"
   chmod 600 server.key
   ```

2. **Configure PostgreSQL** (postgresql.conf):
   ```conf
   ssl = on
   ssl_cert_file = 'server.crt'
   ssl_key_file = 'server.key'
   ssl_min_protocol_version = 'TLSv1.2'
   ```

3. **Update connection string**:
   ```
   Host=prod-db.example.com;Port=5432;Database=ProductManagement;Username=app_user;Password=your_password;SSL Mode=Require;Trust Server Certificate=false
   ```

### 3. Application Security

#### Prevent SQL Injection
✅ **Already implemented**: All queries use parameterized statements with NpgsqlParameter

#### Sensitive Data Protection
- Store connection strings in secure vaults
- Use Azure Key Vault, AWS Secrets Manager, or HashiCorp Vault
- Enable encryption at rest for database
- Enable encryption in transit (SSL/TLS)

#### Least Privilege Principle
- Application user should NOT be superuser
- Grant only necessary table/column permissions
- Revoke public schema permissions if not needed

---

## PostgreSQL Configuration

### 1. Performance Tuning

#### Basic Configuration (postgresql.conf)

```conf
# Memory Settings
shared_buffers = 4GB                    # 25% of RAM
effective_cache_size = 12GB             # 75% of RAM
work_mem = 64MB                         # Per operation
maintenance_work_mem = 1GB              # For VACUUM, CREATE INDEX

# Connection Settings
max_connections = 100                   # Adjust based on load
max_prepared_transactions = 0           # Disable if not using 2PC

# Write-Ahead Logging
wal_buffers = 16MB
checkpoint_completion_target = 0.9
max_wal_size = 2GB
min_wal_size = 1GB

# Query Planner
random_page_cost = 1.1                  # For SSD
effective_io_concurrency = 200          # For SSD

# Logging
log_min_duration_statement = 1000       # Log queries > 1s
log_connections = on
log_disconnections = on
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
```

#### Connection Pooling

**Application-side (Npgsql)**:
```
Host=localhost;Port=5432;Database=ProductManagement;Username=app_user;Password=password;Minimum Pool Size=0;Maximum Pool Size=100;Connection Lifetime=300;Connection Idle Lifetime=60
```

**PgBouncer (for high-traffic scenarios)**:
```ini
[databases]
ProductManagement = host=localhost port=5432 dbname=ProductManagement

[pgbouncer]
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 25
reserve_pool_size = 10
```

### 2. Backup Strategy

#### Daily Backups
```bash
#!/bin/bash
# backup-postgres.sh
BACKUP_DIR="/var/backups/postgresql"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="ProductManagement"

# Full backup
pg_dump -U postgres -h localhost -F c -b -v \
  -f "${BACKUP_DIR}/${DB_NAME}_${DATE}.backup" \
  "${DB_NAME}"

# Compress
gzip "${BACKUP_DIR}/${DB_NAME}_${DATE}.backup"

# Retain only last 7 days
find ${BACKUP_DIR} -name "*.backup.gz" -mtime +7 -delete
```

#### Continuous Archiving (WAL)
```conf
# postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'test ! -f /var/lib/postgresql/wal_archive/%f && cp %p /var/lib/postgresql/wal_archive/%f'
```

#### Point-in-Time Recovery Setup
```bash
# Create base backup
pg_basebackup -U postgres -h localhost -D /var/backups/basebackup -Fp -Xs -P
```

### 3. Monitoring Configuration

#### Enable pg_stat_statements
```sql
-- Add to postgresql.conf
shared_preload_libraries = 'pg_stat_statements'

-- Restart PostgreSQL, then create extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Query slow queries
SELECT 
    calls,
    total_exec_time,
    mean_exec_time,
    query
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

---

## Application Configuration

### 1. Connection String Patterns

#### Development
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres"
  },
  "Environment": "Development"
}
```

#### Staging
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=staging-db.internal;Port=5432;Database=ProductManagement;Username=app_user;Password=${DB_PASSWORD};SSL Mode=Require;Timeout=30;Command Timeout=60"
  },
  "Environment": "Staging"
}
```

#### Production
```json
{
  "ConnectionStrings": {
    "ProdConnection": "Host=prod-db.example.com;Port=5432;Database=ProductManagement;Username=app_user;Password=${DB_PASSWORD};SSL Mode=Require;Trust Server Certificate=false;Minimum Pool Size=10;Maximum Pool Size=100;Connection Lifetime=300;Timeout=30;Command Timeout=60"
  },
  "Environment": "Production"
}
```

### 2. Environment-Specific Settings

Create `appsettings.Production.json`:
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft": "Warning",
      "System": "Error"
    }
  },
  "ConnectionStrings": {
    "ProdConnection": "Host=${DB_HOST};Port=${DB_PORT};Database=ProductManagement;Username=${DB_USER};Password=${DB_PASSWORD};SSL Mode=Require;Maximum Pool Size=100"
  }
}
```

### 3. Npgsql-Specific Configuration

```csharp
// In Startup.cs or Program.cs
services.AddNpgsqlDataSource(connectionString, builder =>
{
    builder.CommandTimeout = 60;
    builder.ConnectionIdleLifetime = TimeSpan.FromMinutes(5);
    builder.MaxPoolSize = 100;
    builder.MinPoolSize = 10;
});
```

---

## Deployment Environments

### 1. AWS Deployment

#### Option A: Amazon RDS PostgreSQL

**Setup Steps**:
1. Create RDS PostgreSQL instance:
   - Engine: PostgreSQL 15.x
   - Instance class: db.t3.medium (or larger)
   - Storage: 100GB SSD (with autoscaling)
   - Multi-AZ: Yes (for production)
   - VPC: Place in private subnet

2. Security Group Configuration:
   ```
   Inbound Rules:
   - Type: PostgreSQL
   - Protocol: TCP
   - Port: 5432
   - Source: Application server security group
   ```

3. Run setup script:
   ```bash
   psql -h mydb.xxxxx.us-east-1.rds.amazonaws.com \
        -U postgres \
        -d ProductManagement \
        -f Database/Scripts/01_PostgreSQL_Setup.sql
   ```

4. Update connection string:
   ```
   Host=mydb.xxxxx.us-east-1.rds.amazonaws.com;Port=5432;Database=ProductManagement;Username=app_user;Password=${DB_PASSWORD};SSL Mode=Require
   ```

#### Option B: Amazon ECS with PostgreSQL on EC2

**docker-compose.yml**:
```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: ProductManagement
      POSTGRES_USER: app_user
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./Database/Scripts/01_PostgreSQL_Setup.sql:/docker-entrypoint-initdb.d/init.sql
    secrets:
      - db_password
    networks:
      - app_network

  app:
    build: .
    environment:
      ConnectionStrings__DevConnection: "Host=postgres;Port=5432;Database=ProductManagement;Username=app_user;Password_file=/run/secrets/db_password"
    depends_on:
      - postgres
    secrets:
      - db_password
    networks:
      - app_network

secrets:
  db_password:
    external: true

networks:
  app_network:

volumes:
  postgres_data:
```

### 2. Azure Deployment

#### Azure Database for PostgreSQL - Flexible Server

**Setup Steps**:
1. Create Flexible Server:
   ```bash
   az postgres flexible-server create \
     --resource-group myResourceGroup \
     --name myPostgresServer \
     --location eastus \
     --admin-user myadmin \
     --admin-password '<password>' \
     --sku-name Standard_D2s_v3 \
     --tier GeneralPurpose \
     --public-access 0.0.0.0 \
     --storage-size 128 \
     --version 15
   ```

2. Configure firewall:
   ```bash
   az postgres flexible-server firewall-rule create \
     --resource-group myResourceGroup \
     --name myPostgresServer \
     --rule-name AllowAppServers \
     --start-ip-address 10.0.1.0 \
     --end-ip-address 10.0.1.255
   ```

3. Connection string:
   ```
   Host=myPostgresServer.postgres.database.azure.com;Port=5432;Database=ProductManagement;Username=myadmin;Password=${DB_PASSWORD};SSL Mode=Require
   ```

4. Deploy app to Azure App Service:
   ```bash
   az webapp up \
     --resource-group myResourceGroup \
     --name myApp \
     --runtime "DOTNET|9.0" \
     --location eastus
   
   az webapp config appsettings set \
     --resource-group myResourceGroup \
     --name myApp \
     --settings ConnectionStrings__ProdConnection="<connection-string>"
   ```

### 3. On-Premises Deployment

#### Linux Server (Ubuntu/Debian)

**Setup Script**:
```bash
#!/bin/bash
# deploy-onprem.sh

# Install PostgreSQL
sudo apt update
sudo apt install postgresql-15 postgresql-contrib

# Configure PostgreSQL
sudo -u postgres psql -c "CREATE DATABASE ProductManagement;"
sudo -u postgres psql -c "CREATE USER app_user WITH PASSWORD 'your_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ProductManagement TO app_user;"

# Run setup script
sudo -u postgres psql -d ProductManagement -f Database/Scripts/01_PostgreSQL_Setup.sql

# Install .NET 9.0
wget https://dot.net/v1/dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --channel 9.0

# Build and run application
dotnet build AdoCore.csproj
dotnet run
```

#### Windows Server

**PowerShell Script**:
```powershell
# deploy-onprem.ps1

# Install PostgreSQL (manual download from postgresql.org)
# Or use Chocolatey
choco install postgresql15

# Configure PostgreSQL
& "C:\Program Files\PostgreSQL\15\bin\psql.exe" -U postgres -c "CREATE DATABASE ProductManagement;"
& "C:\Program Files\PostgreSQL\15\bin\psql.exe" -U postgres -c "CREATE USER app_user WITH PASSWORD 'your_password';"

# Run setup script
& "C:\Program Files\PostgreSQL\15\bin\psql.exe" -U postgres -d ProductManagement -f Database\Scripts\01_PostgreSQL_Setup.sql

# Build and run application
dotnet build AdoCore.csproj
dotnet run
```

---

## Testing and Validation

### 1. Pre-Deployment Testing

#### Database Connectivity Test
```bash
# Test connection
psql -h your-db-host -U app_user -d ProductManagement -c "SELECT version();"

# Test application connectivity
dotnet run -- list
```

#### Data Validation
```sql
-- Verify tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';

-- Verify sample data
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM categories;
SELECT COUNT(*) FROM suppliers;

-- Verify trigger works
SELECT * FROM product_history;
```

### 2. Load Testing

#### Simple Load Test Script
```bash
#!/bin/bash
# load-test.sh
for i in {1..100}; do
  dotnet run -- list &
done
wait
echo "Load test complete"
```

#### Using Apache Bench
```bash
# If application exposes HTTP endpoint
ab -n 1000 -c 10 http://localhost:8080/api/products
```

### 3. Validation Checklist

- [ ] PostgreSQL service is running
- [ ] Database "ProductManagement" exists
- [ ] All tables created successfully (products, categories, suppliers, product_history, product_stats)
- [ ] Sample data inserted (18 products, 20 categories, 8 suppliers)
- [ ] Triggers are working (product_history records created on insert/update/delete)
- [ ] Application connects to database successfully
- [ ] CRUD operations work (Create, Read, Update, Delete)
- [ ] Transactions work correctly (rollback on error)
- [ ] Connection pooling is configured
- [ ] SSL/TLS enabled in production
- [ ] Application logs show no errors
- [ ] Performance is acceptable (queries < 1s)

---

## Monitoring and Maintenance

### 1. Database Monitoring

#### Key Metrics to Monitor
- Active connections: `SELECT count(*) FROM pg_stat_activity;`
- Database size: `SELECT pg_size_pretty(pg_database_size('ProductManagement'));`
- Table sizes: `SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) FROM pg_tables WHERE schemaname = 'public';`
- Slow queries: Query pg_stat_statements
- Lock contention: `SELECT * FROM pg_locks;`
- Index usage: `SELECT * FROM pg_stat_user_indexes;`

#### Automated Monitoring Setup

**Using Prometheus + Grafana**:
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'postgresql'
    static_configs:
      - targets: ['postgres_exporter:9187']
```

**Install postgres_exporter**:
```bash
docker run -d \
  -p 9187:9187 \
  -e DATA_SOURCE_NAME="postgresql://app_user:password@localhost:5432/ProductManagement?sslmode=disable" \
  prometheuscommunity/postgres-exporter
```

### 2. Application Monitoring

#### Health Check Endpoint
```csharp
// Add to Program.cs
app.MapGet("/health", async (NpgsqlDataSource dataSource) =>
{
    try
    {
        await using var connection = await dataSource.OpenConnectionAsync();
        await using var cmd = new NpgsqlCommand("SELECT 1", connection);
        await cmd.ExecuteScalarAsync();
        return Results.Ok(new { status = "healthy", database = "connected" });
    }
    catch (Exception ex)
    {
        return Results.Problem(detail: ex.Message, statusCode: 503);
    }
});
```

### 3. Maintenance Tasks

#### Daily
- Monitor error logs
- Check disk space
- Review slow query log

#### Weekly
- Analyze table statistics: `ANALYZE;`
- Check for bloated tables: `SELECT * FROM pg_stat_user_tables;`
- Review backup success

#### Monthly
- Vacuum full (if needed): `VACUUM FULL;` (requires downtime)
- Reindex: `REINDEX DATABASE ProductManagement;`
- Update PostgreSQL (minor versions)
- Rotate logs
- Review and rotate credentials

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Connection Refused
**Error**: `Npgsql.NpgsqlException: Connection refused`

**Solutions**:
- Check PostgreSQL is running: `systemctl status postgresql` (Linux) or Services (Windows)
- Verify port: `netstat -an | grep 5432`
- Check firewall rules
- Verify listen_addresses in postgresql.conf

#### 2. Authentication Failed
**Error**: `password authentication failed for user "app_user"`

**Solutions**:
- Verify username and password in connection string
- Check pg_hba.conf authentication method
- Reset password: `ALTER USER app_user WITH PASSWORD 'new_password';`

#### 3. Database Does Not Exist
**Error**: `database "ProductManagement" does not exist`

**Solutions**:
- Create database: `CREATE DATABASE "ProductManagement";`
- Run setup script: `psql -U postgres -d ProductManagement -f 01_PostgreSQL_Setup.sql`

#### 4. SSL Connection Required
**Error**: `SSL connection required`

**Solutions**:
- Add to connection string: `SSL Mode=Require`
- Or disable SSL (development only): `SSL Mode=Disable`
- Configure PostgreSQL SSL: Set `ssl = on` in postgresql.conf

#### 5. Too Many Connections
**Error**: `FATAL: sorry, too many clients already`

**Solutions**:
- Increase max_connections in postgresql.conf
- Implement connection pooling (PgBouncer)
- Reduce Maximum Pool Size in connection string
- Close unused connections in application

#### 6. Slow Queries
**Symptoms**: Application timeout, slow response

**Solutions**:
- Analyze query plans: `EXPLAIN ANALYZE SELECT ...`
- Create missing indexes
- Update table statistics: `ANALYZE products;`
- Increase work_mem for complex queries
- Check for table bloat: `VACUUM ANALYZE;`

#### 7. Out of Disk Space
**Error**: `ERROR: could not extend file ... No space left on device`

**Solutions**:
- Clear old WAL files
- Run VACUUM to reclaim space
- Increase disk size
- Archive old data
- Clean up log files

---

## Deployment Checklist

### Pre-Deployment
- [ ] PostgreSQL installed and configured
- [ ] Database created with setup script
- [ ] Sample data verified
- [ ] Connection string configured (NOT using default credentials)
- [ ] SSL/TLS enabled and tested
- [ ] Firewall rules configured
- [ ] Backup strategy implemented
- [ ] Monitoring setup complete

### Deployment
- [ ] Application builds successfully (`dotnet build`)
- [ ] No compiler warnings or errors
- [ ] Connection string uses environment variables/vault
- [ ] Environment set to "Production"
- [ ] Logging configured appropriately
- [ ] Health check endpoint working

### Post-Deployment
- [ ] Application connects to database
- [ ] CRUD operations working
- [ ] Transaction rollback working
- [ ] No errors in logs
- [ ] Performance acceptable
- [ ] Monitoring dashboards showing data
- [ ] Backups running successfully
- [ ] Documentation updated

---

## Support and Escalation

### Issue Severity Levels

**Critical** (Response: Immediate)
- Database unavailable
- Data corruption
- Security breach
- Complete application failure

**High** (Response: < 4 hours)
- Slow performance affecting users
- Partial application failure
- Failed backups

**Medium** (Response: < 24 hours)
- Non-critical errors
- Minor performance issues
- Feature requests

**Low** (Response: Best effort)
- Documentation updates
- Enhancement requests

### Contact Information
- Database Administrator: dba@example.com
- Application Support: appsupport@example.com
- Infrastructure Team: infrastructure@example.com

---

## Additional Resources

- **Npgsql Documentation**: https://www.npgsql.org/doc/
- **PostgreSQL Performance**: https://wiki.postgresql.org/wiki/Performance_Optimization
- **PostgreSQL Security**: https://www.postgresql.org/docs/current/auth-pg-hba-conf.html
- **AWS RDS PostgreSQL**: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html
- **Azure Database for PostgreSQL**: https://learn.microsoft.com/en-us/azure/postgresql/

---

**Document Version**: 1.0  
**Last Updated**: 2026-01-30  
**Maintained By**: Migration Team
