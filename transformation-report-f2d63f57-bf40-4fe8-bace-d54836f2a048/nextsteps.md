# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify functional correctness after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address regressions introduced by the migration.

## 4. Check for Removed or Changed APIs

Cross-platform .NET removes certain APIs that were available in .NET Framework. Run the .NET Upgrade Assistant compatibility analyzer or the Platform Compatibility Analyzer to identify any runtime-level API issues that do not surface as build errors:

```bash
dotnet tool install -g dotnet-upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

Pay particular attention to:
- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Any database drivers or OLE DB providers that are not supported on non-Windows platforms
- `System.Configuration` usage, which behaves differently in .NET Core and later

## 5. Validate ADO.NET / Database Connectivity

Since the project is named `AdoCore`, confirm that the database provider being used is compatible with cross-platform .NET:

- **SQL Server**: Use `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient`
- **OLE DB**: `System.Data.OleDb` is Windows-only; replace with a platform-neutral driver if cross-platform support is required
- **ODBC**: `System.Data.Odbc` has limited cross-platform support; verify your target OS is supported

Test actual database connections in your target environment to confirm connectivity works as expected.

## 6. Review Configuration Files

.NET Framework projects often rely on `App.config` or `Web.config` for connection strings and settings. In cross-platform .NET, the standard approach is `appsettings.json` with `Microsoft.Extensions.Configuration`. Verify that:

- Connection strings are accessible at runtime
- Any `ConfigurationManager` calls have been replaced or are backed by the `System.Configuration.ConfigurationManager` NuGet package if a direct replacement was not performed

## 7. Run on Target Platform

If cross-platform execution (Linux/macOS) is a goal, run the application on the target operating system to catch any platform-specific runtime issues:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Then execute the published output on the target machine and verify expected behavior.

## 8. Review NuGet Package Versions

Ensure all NuGet dependencies reference current, stable versions compatible with your target framework. Check for any packages still targeting `net45` or `netstandard1.x` that may have newer versions available:

```bash
dotnet list package --outdated
```

Update packages where appropriate and re-run tests after each significant update.