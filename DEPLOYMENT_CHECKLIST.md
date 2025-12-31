# PostgreSQL Deployment Checklist

This checklist ensures proper deployment and validation of the migrated ADO.NET application with PostgreSQL.

## ✅ Pre-Deployment Checklist

### Environment Setup
- [ ] PostgreSQL 12+ installed and running
- [ ] .NET 9.0 SDK installed
- [ ] PostgreSQL client tools available (psql, pgAdmin, or DBeaver)
- [ ] Network connectivity to PostgreSQL server verified
- [ ] Firewall rules configured (port 5432)

### Database Setup
- [ ] PostgreSQL service is running
- [ ] Database `productmanagement` created
- [ ] Schema setup script executed: `Database/Scripts/01_PostgreSQL_Setup.sql`
- [ ] Sample data loaded (18 products, 20 categories, 8 suppliers)
- [ ] All tables created successfully:
  - [ ] productmanagement_dbo.categories
  - [ ] productmanagement_dbo.suppliers
  - [ ] productmanagement_dbo.products
  - [ ] productmanagement_dbo.producthistory
  - [ ] productmanagement_dbo.productstats
- [ ] All indexes created successfully
- [ ] Trigger `trg_products_history` created and functional

### Security
- [ ] Dedicated database user created (not postgres superuser)
- [ ] User permissions granted correctly:
  - [ ] CONNECT permission on database
  - [ ] USAGE permission on schema
  - [ ] ALL PRIVILEGES on tables
  - [ ] ALL PRIVILEGES on sequences
- [ ] Connection string does NOT contain hardcoded passwords
- [ ] Environment variables configured for credentials (recommended)
- [ ] SSL/TLS configured for production environments
- [ ] Password meets complexity requirements

### Application Configuration
- [ ] `appsettings.json` updated with correct PostgreSQL connection string
- [ ] Environment setting correct ("Development" or "Production")
- [ ] Connection string format verified:
  ```
  Host=<hostname>;Database=productmanagement;Username=<user>;Password=<password>;Port=5432
  ```
- [ ] Optional parameters added if needed (Pooling, SSL Mode, Timeout)

### Build Verification
- [ ] `dotnet restore` completed successfully
- [ ] `dotnet build` completed with 0 errors, 0 warnings
- [ ] All NuGet packages restored (especially Npgsql 8.0.5)
- [ ] Build artifacts generated in `bin/Debug/net9.0/`

## ✅ Runtime Validation Checklist

### Connection Testing
- [ ] Application can connect to PostgreSQL database
- [ ] Connection string validated
- [ ] No authentication errors
- [ ] No network timeout errors
- [ ] Connection pooling working (verify with `pg_stat_activity`)

### Basic Operations Testing
- [ ] **List Products** (`dotnet run -- list`):
  - [ ] Returns 18 products from sample data
  - [ ] All columns populated correctly
  - [ ] No NULL values in required fields
  - [ ] Data types correct (prices as decimal, dates as timestamp)

- [ ] **Get Product by ID** (`dotnet run -- get 1`):
  - [ ] Returns specific product
  - [ ] All fields match database
  - [ ] No data truncation or corruption

### CRUD Operations Testing
- [ ] **CREATE** (`dotnet run -- add "Test" 99.99 10 "Description"`):
  - [ ] Product inserted successfully
  - [ ] ProductId returned (SERIAL primary key)
  - [ ] CreatedDate populated automatically
  - [ ] Product appears in list
  - [ ] ProductHistory audit entry created (trigger)

- [ ] **READ**:
  - [ ] Newly created product retrievable by ID
  - [ ] Complex queries with CTEs execute correctly
  - [ ] Window functions return expected results (LAG, RANK, PERCENT_RANK)
  - [ ] JOIN queries work correctly

- [ ] **UPDATE** (`dotnet run -- update <id> "Updated" 109.99 15 "New Desc"`):
  - [ ] Product updated successfully
  - [ ] ModifiedDate updated automatically
  - [ ] Changes reflected in subsequent reads
  - [ ] ProductHistory audit entry created (UPDATE action)

- [ ] **DELETE** (`dotnet run -- delete <id>`):
  - [ ] Product deleted successfully
  - [ ] Product no longer appears in list
  - [ ] ProductHistory audit entry created (DELETE action)
  - [ ] Foreign key constraints respected

### Transaction Testing
- [ ] **Transaction Atomicity** (Insert/Update/Delete):
  - [ ] Successful operations commit properly
  - [ ] Failed operations rollback properly (simulate by invalid data)
  - [ ] No partial updates
  - [ ] Database consistency maintained
  - [ ] Concurrent transactions handled correctly

- [ ] **Stock Update** (`dotnet run -- stock <id> 100`):
  - [ ] Stock quantity updated
  - [ ] Transaction committed
  - [ ] ProductHistory entry created

### Advanced Query Testing
- [ ] **CTE Queries** (GetAllProductsAsync):
  - [ ] Common Table Expression executes
  - [ ] Subqueries return correct results
  - [ ] Performance acceptable

- [ ] **Window Functions**:
  - [ ] LAG function returns previous row values
  - [ ] RANK function assigns correct rankings
  - [ ] PERCENT_RANK calculates correct percentiles
  - [ ] AVG/MIN/MAX OVER() partitions work correctly

- [ ] **JOIN Operations** (GetProductsByCategoryAsync):
  - [ ] Category joins return correct results
  - [ ] NULL handling correct for optional foreign keys
  - [ ] Performance acceptable

### Data Integrity Testing
- [ ] **Constraints**:
  - [ ] Primary keys enforce uniqueness
  - [ ] Foreign keys prevent orphaned records
  - [ ] NOT NULL constraints enforced
  - [ ] DEFAULT values applied correctly

- [ ] **Triggers**:
  - [ ] ProductHistory trigger fires on INSERT
  - [ ] ProductHistory trigger fires on UPDATE (only when price/stock changes)
  - [ ] ProductHistory trigger fires on DELETE
  - [ ] Trigger records correct user (current_user)

- [ ] **Data Types**:
  - [ ] Decimal precision maintained (18,2)
  - [ ] Timestamps stored correctly (UTC recommended)
  - [ ] Boolean values work correctly (true/false vs 1/0)
  - [ ] VARCHAR length limits respected

### Error Handling Testing
- [ ] Invalid product ID returns appropriate error
- [ ] Duplicate key violations handled gracefully
- [ ] Foreign key violations handled gracefully
- [ ] Connection timeout handled gracefully
- [ ] Transaction rollback on errors
- [ ] Error messages don't expose sensitive information

### Performance Testing
- [ ] **Query Performance**:
  - [ ] List all products < 100ms
  - [ ] Get by ID < 10ms
  - [ ] Complex CTEs < 200ms
  - [ ] No N+1 query issues

- [ ] **Connection Pooling**:
  - [ ] Connections reused from pool
  - [ ] Pool size configurable
  - [ ] No connection leaks
  - [ ] Verify with: `SELECT count(*) FROM pg_stat_activity WHERE datname='productmanagement';`

- [ ] **Load Testing** (optional but recommended):
  - [ ] 100 concurrent users
  - [ ] Response time under load
  - [ ] Database connections don't exhaust
  - [ ] Memory usage stable

## ✅ Production Readiness Checklist

### Security Hardening
- [ ] Connection strings stored in environment variables or secrets manager
- [ ] No hardcoded passwords in appsettings.json
- [ ] SSL/TLS enabled: `SSL Mode=Require`
- [ ] Certificate validation enabled (not `Trust Server Certificate=true`)
- [ ] Database user has minimum required permissions
- [ ] PostgreSQL configured to require password authentication
- [ ] PostgreSQL listening only on required interfaces
- [ ] Firewall rules restrict database access

### Monitoring & Logging
- [ ] PostgreSQL logging enabled
- [ ] Application logging configured
- [ ] Connection pool metrics monitored
- [ ] Query performance monitored
- [ ] Error logging configured
- [ ] Audit trail (ProductHistory) working

### Backup & Recovery
- [ ] PostgreSQL backup strategy defined
- [ ] Backup schedule configured (pg_dump or continuous archiving)
- [ ] Backup restoration tested
- [ ] Point-in-time recovery tested (optional)
- [ ] Backup retention policy defined

### Documentation
- [ ] Connection string format documented
- [ ] Deployment steps documented
- [ ] Rollback procedure documented
- [ ] Troubleshooting guide available
- [ ] Migration artifacts preserved:
  - [ ] extracted_statements.sql
  - [ ] converted_statements.sql
  - [ ] dms_conversion_log.json
  - [ ] sql_equivalency_validation_report.json
  - [ ] final_migration_report.json

### High Availability (Production)
- [ ] PostgreSQL replication configured (if required)
- [ ] Failover tested (if required)
- [ ] Load balancing configured (if required)
- [ ] Connection string supports multiple hosts (if required)

## ✅ Post-Deployment Validation

### Smoke Tests
- [ ] Application starts without errors
- [ ] Health check endpoint responds (if available)
- [ ] Can connect to database
- [ ] Can execute basic query
- [ ] Can perform CRUD operations

### Integration Tests (if available)
- [ ] All integration tests pass
- [ ] Database integration tests pass
- [ ] Transaction tests pass

### User Acceptance Testing
- [ ] All critical user workflows tested
- [ ] Performance acceptable for users
- [ ] No data loss or corruption
- [ ] Audit trail complete

### Monitoring
- [ ] Application logs reviewed
- [ ] Database logs reviewed
- [ ] No errors in logs
- [ ] Performance metrics within acceptable range
- [ ] Connection pool usage normal

## ✅ Rollback Plan

In case of issues, document rollback steps:

- [ ] Rollback procedure documented
- [ ] Database backup available for restoration
- [ ] Previous application version available
- [ ] Rollback tested in non-production environment
- [ ] Rollback decision criteria defined
- [ ] Rollback authorization process defined

## Validation Results

### Current Status Summary

Based on the migration validation:

#### ✅ Completed (11/16 exit criteria PASS)
1. ✅ All SQL Server packages replaced with PostgreSQL equivalents (Npgsql 8.0.5)
2. ✅ All ADO.NET classes updated (SqlConnection → NpgsqlConnection, etc.)
3. ✅ All 7 SQL statements processed through DMS MCP tool
4. ✅ Comprehensive SQL catalog exists (extracted_statements.sql, converted_statements.sql)
5. ✅ All statement pairs validated with SQL Equivalency MCP tool
6. ✅ Comprehensive equivalency report generated (sql_equivalency_validation_report.json)
7. ✅ No agent judgment used for equivalency (tool-only)
8. ✅ DMS failures documented (1 statement required manual conversion)
9. ✅ Connection strings updated to PostgreSQL format
10. ✅ Transaction handling updated to PostgreSQL/ADO.NET patterns
11. ✅ Application compiles successfully (0 errors, 0 warnings)

#### ⚠️ Requires Runtime Environment (4/16 exit criteria PARTIAL)
12. ⚠️ Database connectivity (PARTIAL - requires PostgreSQL instance)
13. ⚠️ Database operations execution (PARTIAL - requires runtime testing)
14. ⚠️ Transaction atomicity (PARTIAL - requires runtime testing)
15. ⚠️ Test suite execution (PARTIAL - no tests found in repository)

#### ✅ Documentation Complete
16. ✅ Final report with equivalency status (final_migration_report.json)

### Required Actions for Full Validation

1. **Deploy PostgreSQL Instance**: Set up PostgreSQL 12+ with productmanagement_dbo schema
2. **Create Schema**: Run `Database/Scripts/01_PostgreSQL_Setup.sql`
3. **Configure Credentials**: Update connection strings with actual PostgreSQL credentials
4. **Runtime Testing**: Execute checklist items above to validate criteria 12-14
5. **Test Suite**: Execute unit/integration tests if they exist externally (criterion 15)

## Sign-off

### Development Team
- [ ] All code changes reviewed
- [ ] Build successful
- [ ] Migration artifacts reviewed
- [ ] Documentation complete

### QA Team
- [ ] Functional testing complete
- [ ] Performance testing complete
- [ ] Security testing complete
- [ ] User acceptance testing complete

### Operations Team
- [ ] Infrastructure ready
- [ ] Monitoring configured
- [ ] Backup configured
- [ ] Runbooks updated

### Approvals
- [ ] Technical Lead approval
- [ ] Security approval
- [ ] Operations approval
- [ ] Business approval

---

**Date**: _______________  
**Deployment Environment**: _______________  
**Deployed By**: _______________  
**Validated By**: _______________
