# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Review any failing tests and address the underlying logic or API differences introduced by the migration.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been available in .NET Framework but behave differently or throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Search the codebase for usages of:

- `System.Windows.Forms`
- `System.Drawing` (use `System.Drawing.Common` NuGet package if needed)
- `Microsoft.Win32` registry APIs
- COM interop or P/Invoke calls targeting Windows-specific libraries

Test the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions compatible with your target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate and re-run the build and tests after each update.

## 6. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables as appropriate for .NET. Ensure the `ConfigurationManager` NuGet package (`System.Configuration.ConfigurationManager`) is referenced if legacy config access is still required.

## 7. Validate Database Connectivity (ADO.NET)

Given the project name `AdoCore`, it likely contains ADO.NET data access code. Verify the following at runtime:

- Connection strings are correctly defined and accessible.
- The appropriate database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` for SQL Server, `Npgsql` for PostgreSQL).
- Data operations (queries, transactions, stored procedures) return expected results.

Run integration tests or manual smoke tests against a development database to confirm correctness.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present before deploying to the target environment.