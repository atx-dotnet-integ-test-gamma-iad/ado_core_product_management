# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

## 4. Check for Removed or Changed APIs

Review any usage of APIs that were available in .NET Framework but have changed or been removed in .NET. Key areas to check:

- `System.Web` dependencies (not available in .NET Core/.NET 5+)
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default)
- `ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)

## 5. Validate NuGet Package Compatibility

Ensure all NuGet packages referenced in `AdoCore.csproj` are compatible with your target framework. Run the following to check for outdated or incompatible packages:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update any packages that are outdated or flagged as incompatible.

## 6. Test Database Connectivity (ADO Specific)

Since this project appears to be ADO-related, verify that all database connection strings and provider configurations are correct in the new environment. Confirm that the appropriate ADO.NET provider NuGet packages are referenced, for example:

- `Microsoft.Data.SqlClient` for SQL Server
- `Npgsql` for PostgreSQL
- `MySql.Data` or `MySqlConnector` for MySQL

Run integration tests or manual connection tests against your target database to confirm connectivity.

## 7. Review Configuration Files

.NET no longer uses `App.config` or `Web.config` in the same way as .NET Framework. Confirm that configuration has been migrated to `appsettings.json` or environment variables where applicable. If `App.config` is still in use, verify the `System.Configuration.ConfigurationManager` package is referenced.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required files and dependencies are present before deploying to the target environment.