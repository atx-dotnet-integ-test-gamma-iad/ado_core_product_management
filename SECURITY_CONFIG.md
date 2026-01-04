# Security Configuration Guide

## Database Connection Security

This application has been migrated from SQL Server to PostgreSQL. For security best practices, follow these guidelines:

### ⚠️ IMPORTANT: Do Not Commit Passwords

The `appsettings.json` file contains placeholder passwords (`YOUR_PASSWORD_HERE`). **Never commit actual passwords to source control.**

### Configuration Methods

#### Method 1: Environment Variables (Recommended for Production)

Set environment variables to override connection strings:

**Windows (PowerShell):**
```powershell
$env:ConnectionStrings__DevConnection="Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Pooling=true"
```

**Linux/macOS:**
```bash
export ConnectionStrings__DevConnection="Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Pooling=true"
```

#### Method 2: .env File (Development)

1. Copy `.env.example` to `.env`
2. Fill in your actual credentials in `.env`
3. The `.env` file is already in `.gitignore` and will not be committed

#### Method 3: User Secrets (Visual Studio)

For local development in Visual Studio, use the Secret Manager:

```bash
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Pooling=true"
```

### Security Best Practices

1. ✅ **Use environment variables in production**
2. ✅ **Use secrets management (AWS Secrets Manager, Azure Key Vault, etc.) in cloud environments**
3. ✅ **Rotate passwords regularly**
4. ✅ **Use least-privilege database accounts**
5. ❌ **Never commit passwords to source control**
6. ❌ **Never log connection strings with passwords**

### Configuration Priority

.NET Configuration uses the following priority (last wins):
1. `appsettings.json`
2. Environment variables
3. User secrets (in development)
4. Command-line arguments

Environment variables will override values in `appsettings.json`.

## Package Security

### Npgsql Version

The project uses Npgsql 8.0.8 (or later), which addresses known security vulnerabilities. Always keep packages up-to-date:

```bash
dotnet list package --outdated
dotnet add package Npgsql
```

Check for security advisories: https://github.com/npgsql/npgsql/security/advisories
