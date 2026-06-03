# Next Steps

The transformation appears to have completed successfully. There are no build errors reported across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime environment you intend to deploy to.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not block the build.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Some APIs behave differently or are unavailable on cross-platform .NET even when the project compiles without errors. Pay particular attention to:

- **Windows-specific APIs**: Any usage of `System.Windows.Forms`, `System.Drawing`, `Microsoft.Win32`, or P/Invoke calls targeting Windows-only libraries will fail on non-Windows platforms.
- **AppDomain usage**: Several `AppDomain` members are not supported in .NET Core and later.
- **Reflection**: Certain reflection APIs have changed behavior.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package if used.

Run the application on the target platform (Linux, macOS, or Windows) to surface any platform-specific runtime exceptions.

## 5. Review NuGet Package Versions

Open the `.csproj` file and review all `<PackageReference>` entries. Ensure each package:

- Supports the target framework (check [nuget.org](https://www.nuget.org) for compatibility).
- Is updated to a version that does not have known vulnerabilities.

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

## 6. Validate Data Access Behavior

Given the project name `AdoCore`, it likely involves ADO.NET data access. Verify the following:

- Connection strings are correctly configured for the new environment (check `appsettings.json` or environment variables rather than `app.config` if applicable).
- Database drivers (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) are referenced as NuGet packages and are compatible with the target framework.
- Any `DataSet`, `DataTable`, or `DataAdapter` usage functions correctly, as these are supported but may behave slightly differently in edge cases.

## 7. Smoke Test Core Functionality

Manually exercise the primary workflows of the application to confirm end-to-end functionality. Focus on:

- Database connections and queries
- Any file I/O operations
- Any network or HTTP calls

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required files and dependencies are present before deploying to the target environment.