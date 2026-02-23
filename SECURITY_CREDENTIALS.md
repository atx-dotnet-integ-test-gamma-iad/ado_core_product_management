# Database Credentials Security

## Overview
This application has been updated to externalize database credentials from configuration files to environment variables for improved security.

## Configuration

### Environment Variables Required
- `DB_USER`: PostgreSQL database username
- `DB_PASSWORD`: PostgreSQL database password

### Setting Environment Variables

#### Windows (PowerShell)
```powershell
$env:DB_USER="your_username"
$env:DB_PASSWORD="your_password"
```

#### Windows (Command Prompt)
```cmd
set DB_USER=your_username
set DB_PASSWORD=your_password
```

#### Linux/macOS
```bash
export DB_USER="your_username"
export DB_PASSWORD="your_password"
```

### Using .env File (Development)
1. Copy `.env.example` to `.env`
2. Update the values in `.env` with your actual credentials
3. Use a tool like `dotenv` or configure your IDE to load environment variables from `.env`

### Production Deployment
For production environments, use secure credential storage:
- **Azure**: Azure Key Vault
- **AWS**: AWS Secrets Manager or Parameter Store
- **Container Orchestration**: Kubernetes Secrets
- **CI/CD**: Secure environment variables in your deployment pipeline

## Default Behavior
If environment variables are not set, the application will fall back to default values:
- DB_USER: postgres
- DB_PASSWORD: password

**WARNING**: Default credentials should only be used for local development. Always set proper credentials for production environments.

## Security Best Practices
1. Never commit credentials to source control
2. Add `.env` to `.gitignore`
3. Use unique, strong passwords for each environment
4. Rotate credentials regularly
5. Use principle of least privilege for database user accounts
6. Enable SSL/TLS for database connections in production
