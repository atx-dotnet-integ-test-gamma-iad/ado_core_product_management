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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time but appear at runtime. Pay particular attention to:

- **Reflection-based code**: Behavior can differ between .NET Framework and modern .NET.
- **`AppDomain` usage**: Some `AppDomain` APIs are no longer supported or are no-ops.
- **`System.Configuration`**: If the project previously used `ConfigurationManager`, ensure the `System.Configuration.ConfigurationManager` NuGet package is referenced and that configuration files are correctly structured.
- **Windows-only APIs**: If the project uses APIs such as the Windows Registry, WMI, or COM interop, verify that the target deployment environment is Windows or add appropriate runtime guards.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions compatible with the target framework. You can inspect compatibility using the following command:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

## 6. Validate Database Connectivity (ADO-specific)

Given the project name `AdoCore`, it likely involves ADO.NET data access. Verify the following:

- The correct database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of the legacy `System.Data.SqlClient` for SQL Server).
- Connection strings are correctly configured in the new configuration system (`appsettings.json` or environment variables) rather than `app.config` or `web.config` if those were migrated away from.
- Run integration tests or manual queries against a test database to confirm data access works as expected.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files and dependencies are present before deploying to the target environment.