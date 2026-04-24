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

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time but appear at runtime. Pay particular attention to:

- **Platform-specific APIs**: Any usage of Windows-only APIs (e.g., `System.Drawing`, `Microsoft.Win32`, registry access) will compile but throw `PlatformNotSupportedException` on non-Windows systems.
- **File path separators**: Ensure paths use `Path.Combine` or `Path.DirectorySeparatorChar` rather than hardcoded backslashes.
- **Configuration files**: Verify that `app.config` or `web.config` based configuration has been migrated to `appsettings.json` or environment variables where applicable.

## 5. Audit NuGet Package Compatibility

Review all NuGet dependencies to confirm they target .NET Standard 2.0+ or the specific .NET version you are using:

```bash
dotnet list package --outdated
```

Replace any packages that target only `net4x` with their cross-platform equivalents if available.

## 6. Validate Data Access (ADO.NET)

Given the project name `AdoCore`, it likely involves ADO.NET data access. Verify the following:

- The correct database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient` for SQL Server).
- Connection strings are being read from the updated configuration system.
- Any `DataSet`, `DataTable`, or `DataAdapter` usage functions correctly, as these are supported but some edge-case behaviors may differ.

## 7. Run on Target Platform

Execute the application on the intended target platform (Linux, macOS, or Windows) to catch any platform-specific runtime failures:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` folder before deploying to the target environment.