# Quick Start Guide - PostgreSQL Setup

This guide will help you quickly set up and run the migrated application with PostgreSQL.

## Prerequisites Check

```bash
# Check .NET SDK
dotnet --version
# Expected: 9.0.x or later

# Check PostgreSQL installation
psql --version
# Expected: psql (PostgreSQL) 13.x or later
```

## 5-Minute Setup

### Step 1: Install PostgreSQL (if not already installed)

**Using Docker (Fastest)**:
```bash
docker run --name postgres-adocore \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=ProductManagement \
  -p 5432:5432 \
  -d postgres:15
```

**Windows**: Download from https://www.postgresql.org/download/windows/  
**macOS**: `brew install postgresql@15 && brew services start postgresql@15`  
**Linux**: `sudo apt install postgresql postgresql-contrib`

### Step 2: Create Database Schema

```bash
# Option A: Using psql
psql -U postgres -d ProductManagement -f Database/Scripts/01_PostgreSQL_InitialSetup.sql

# Option B: Using Docker
docker cp Database/Scripts/01_PostgreSQL_InitialSetup.sql postgres-adocore:/tmp/
docker exec -it postgres-adocore psql -U postgres -d ProductManagement -f /tmp/01_PostgreSQL_InitialSetup.sql
```

### Step 3: Verify Database Setup

```bash
psql -U postgres -d ProductManagement -c "SELECT COUNT(*) FROM productmanagement_dbo.products;"
# Expected output: 18
```

### Step 4: Update Connection String (if needed)

Edit `appsettings.json` - default should work for local PostgreSQL:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true;Minimum Pool Size=0;Maximum Pool Size=100"
  },
  "Environment": "Development"
}
```

### Step 5: Build and Run

```bash
# Build
dotnet build

# Run in interactive mode
dotnet run

# Or test with CLI
dotnet run -- list
```

## Verification Tests

```bash
# Test 1: List all products
dotnet run -- list
# Expected: List of 18 products

# Test 2: Get specific product
dotnet run -- get 1
# Expected: ProBook X1 details

# Test 3: Add new product (tests transaction with RETURNING)
dotnet run -- add "Test Product" 99.99 50 "Test Description"
# Expected: Product created with new ID

# Test 4: Query database directly
psql -U postgres -d ProductManagement -c "SELECT name, price, stockquantity FROM productmanagement_dbo.products LIMIT 5;"
# Expected: First 5 products displayed
```

## Common Issues

### "Connection refused"
```bash
# Check if PostgreSQL is running
docker ps  # for Docker
sudo systemctl status postgresql  # for Linux
```

### "password authentication failed"
```bash
# Update password in appsettings.json to match your PostgreSQL setup
# Or reset postgres password:
psql -U postgres -c "ALTER USER postgres PASSWORD 'newpassword';"
```

### "schema productmanagement_dbo does not exist"
```bash
# Re-run the setup script
psql -U postgres -d ProductManagement -f Database/Scripts/01_PostgreSQL_InitialSetup.sql
```

## What Was Migrated?

✅ **Code Changes**:
- `Microsoft.Data.SqlClient` → `Npgsql`
- `SqlConnection` → `NpgsqlConnection` (5 occurrences)
- `SqlCommand` → `NpgsqlCommand` (15+ occurrences)
- `SqlDataReader` → `NpgsqlDataReader`
- `SqlTransaction` → `NpgsqlTransaction` (6 occurrences)

✅ **SQL Changes**:
- `GETDATE()` → `NOW()`
- `SCOPE_IDENTITY()` → `RETURNING productid`
- `[dbo].[Products]` → `productmanagement_dbo.products`
- Window functions preserved (LAG, RANK, PERCENT_RANK, AVG OVER, etc.)
- CTEs (Common Table Expressions) converted
- Multi-statement transactions to application-level management

✅ **Configuration**:
- Connection strings updated to PostgreSQL format
- All transaction handling updated
- Application compiles successfully

## Next Steps

1. ✅ Database setup complete
2. ✅ Application running
3. 🔄 Test all CRUD operations thoroughly
4. 🔄 Run integration tests
5. 🔄 Performance tuning if needed
6. 🔄 Deploy to production

## Need More Help?

- See `README_PostgreSQL.md` for detailed documentation
- See `migration_final_report.md` for migration details
- Check PostgreSQL logs: `docker logs postgres-adocore` (for Docker)
- Check application build logs: `build.log`

## Success Criteria Checklist

- [ ] PostgreSQL server running
- [ ] Database `ProductManagement` created
- [ ] Schema `productmanagement_dbo` exists with 5 tables
- [ ] 18 sample products inserted
- [ ] Application builds without errors
- [ ] Can list all products
- [ ] Can get product by ID
- [ ] Can insert new product
- [ ] Can update product
- [ ] Can delete product
- [ ] Transactions maintain atomicity

---

**Quick Reference Commands**:
```bash
# Start PostgreSQL (Docker)
docker start postgres-adocore

# Stop PostgreSQL (Docker)
docker stop postgres-adocore

# Connect to database
psql -U postgres -d ProductManagement

# Run application
dotnet run

# List products
dotnet run -- list

# View logs
cat build.log
docker logs postgres-adocore
```
