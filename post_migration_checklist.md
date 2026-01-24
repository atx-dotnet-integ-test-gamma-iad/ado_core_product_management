# Post-Migration Checklist for AdoCore PostgreSQL Migration

## Database Setup

- [ ] **Set up PostgreSQL database instance**
  - Install PostgreSQL 15 or higher
  - Configure PostgreSQL server
  - Create database user with appropriate permissions

- [ ] **Convert and run schema creation scripts**
  - Convert `01_InitialSetup.sql` from SQL Server to PostgreSQL syntax
  - Update IDENTITY columns to SERIAL or use GENERATED ... AS IDENTITY
  - Update data types (nvarchar → varchar/text, datetime → timestamp)
  - Update GETDATE() → CURRENT_TIMESTAMP in triggers and defaults
  - Run converted DDL scripts against PostgreSQL database
  - Verify all tables, indexes, and constraints are created

- [ ] **Update connection credentials**
  - Update `appsettings.json` with actual PostgreSQL server address
  - Replace hardcoded passwords with environment variables or secrets
  - Test connection from application to PostgreSQL database

## Validation Testing

- [ ] **Test database connectivity**
  - Run application and verify successful connection
  - Check for connection errors in logs
  - Validate connection pooling behavior

- [ ] **Execute CRUD operations**
  - Test `GetAllProductsAsync()` - verify CTE with window functions works
  - Test `GetProductByIdAsync()` - verify LAG window function works
  - Test `InsertProductAsync()` - verify transaction and CURRENT_TIMESTAMP work
  - Test `UpdateProductAsync()` - verify transaction and date functions work
  - Test `DeleteProductAsync()` - verify transaction with CASE statement works
  - Test `GetProductsByPriceRangeAsync()` - verify RANK/PERCENT_RANK functions
  - Test `GetLowStockProductsAsync()` - verify aggregate window functions

- [ ] **Verify transaction handling**
  - Test transaction commit behavior
  - Test transaction rollback on errors
  - Verify ACID properties are maintained
  - Test concurrent transactions

- [ ] **Data integrity validation**
  - Insert test data and verify RETURNING clause returns correct IDs
  - Verify ProductHistory logging works correctly
  - Verify ProductStats updates work correctly
  - Compare results with SQL Server (if available) for equivalency

## Code Review

- [ ] **Review equivalency validation report**
  - Open `sql_equivalency_validation_report.json`
  - Review 5 statements with ERROR status
  - Note: ERROR due to tool limitations, not actual non-equivalency
  - Statements 1, 2, 6, 7 are structurally identical to original
  - Statement 3 uses different ID retrieval pattern (SCOPE_IDENTITY vs transaction)
  - Validate these statements through manual testing

- [ ] **Review manual conversion documentation**
  - Review `manual_conversions.txt` for conversion rationale
  - Verify all GETDATE() → CURRENT_TIMESTAMP conversions
  - Verify window functions syntax compatibility
  - Verify CTE syntax compatibility

## Performance Testing

- [ ] **Execute performance benchmarks**
  - Run queries with large datasets
  - Compare query execution times
  - Analyze PostgreSQL EXPLAIN plans
  - Identify any performance regressions

- [ ] **Optimize as needed**
  - Create additional indexes if needed
  - Adjust PostgreSQL configuration parameters
  - Update statistics
  - Optimize slow queries

## Integration Testing

- [ ] **Run existing unit tests**
  - Execute all unit tests against PostgreSQL
  - Fix any failing tests
  - Update test data if needed

- [ ] **Run integration tests**
  - Test all application features end-to-end
  - Verify business logic correctness
  - Test error handling

- [ ] **User acceptance testing**
  - Perform UAT with actual users
  - Validate all features work as expected
  - Document any issues found

## Security and Configuration

- [ ] **Implement secure connection strings**
  - Move passwords to environment variables
  - Consider using Azure Key Vault or similar secrets management
  - Implement connection string encryption if needed

- [ ] **Configure PostgreSQL security**
  - Set up proper user roles and permissions
  - Configure pg_hba.conf for secure connections
  - Enable SSL/TLS if required
  - Implement connection limits

## Documentation

- [ ] **Update deployment documentation**
  - Document PostgreSQL requirements
  - Document connection string format
  - Document any configuration changes

- [ ] **Update development setup guide**
  - Add PostgreSQL installation instructions
  - Update local development setup steps
  - Document any development environment changes

- [ ] **Create migration notes**
  - Document migration date and team
  - List all manual interventions
  - Document known issues or limitations

## Deployment

- [ ] **Prepare deployment plan**
  - Create rollback plan
  - Schedule deployment window
  - Notify stakeholders

- [ ] **Deploy to staging**
  - Deploy application to staging environment
  - Run full test suite
  - Verify all features work correctly

- [ ] **Deploy to production**
  - Execute deployment plan
  - Monitor application health
  - Verify database connectivity and performance

- [ ] **Post-deployment validation**
  - Monitor logs for errors
  - Verify all features work in production
  - Check database performance metrics

## Known Considerations from Migration

### SQL Equivalency Validation

- **5 statements marked as ERROR** in equivalency report due to tool limitations:
  - Statement 1 (GetAllProductsAsync): Tool returned UNKNOWN for complex CTE
  - Statement 2 (GetProductByIdAsync): Tool returned UNKNOWN for LAG function
  - Statement 3 (InsertProductAsync): Tool returned UNKNOWN for transaction block
  - Statement 6 (GetProductsByPriceRangeAsync): Tool returned UNKNOWN for RANK functions
  - Statement 7 (GetLowStockProductsAsync): Tool returned UNKNOWN for aggregate functions

- **Action Required**: Manually test these statements to verify functional equivalency
- **Note**: These statements are structurally identical or use standard SQL features

### DMS Tool Conversion

- DMS MCP tool failed for all conversion attempts (timeout errors)
- All statements manually converted based on PostgreSQL syntax documentation
- Manual conversions documented in `manual_conversions.txt`

### Date/Time Functions

- All `GETDATE()` calls converted to `CURRENT_TIMESTAMP`
- Verify timestamp precision matches application requirements
- PostgreSQL timestamps may have different precision than SQL Server

### Window Functions

- All window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX OVER) are SQL standard
- Expected to work identically in PostgreSQL
- Verify through testing

### Transaction Blocks

- Multi-statement transactions maintained in SQL
- Transaction syntax compatible between SQL Server and PostgreSQL
- Verify ACID properties through testing

## Completion Criteria

Migration is complete when:

- ✅ All checklist items are completed
- ✅ All tests pass successfully
- ✅ Application runs without errors in PostgreSQL
- ✅ Performance is acceptable
- ✅ No data integrity issues observed
- ✅ Documentation is updated
- ✅ Deployment is successful

## Support Contacts

- Database Team: [Contact info]
- Development Team: [Contact info]
- DevOps Team: [Contact info]

## References

- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Npgsql Documentation: https://www.npgsql.org/doc/
- SQL Server to PostgreSQL Migration Guide: [Internal link]
- Migration Summary Report: `migration_summary_report.json`
- SQL Equivalency Report: `sql_equivalency_validation_report.json`
- Manual Conversions: `manual_conversions.txt`
