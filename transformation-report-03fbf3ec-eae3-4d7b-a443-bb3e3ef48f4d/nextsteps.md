# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm:

```bash
dotnet --version
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a full restore to ensure all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts that may not surface as build errors but could cause runtime issues.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings:

```bash
dotnet clean
dotnet build --configuration Release
```

Review any warnings in the output. Warnings related to nullable reference types, obsolete APIs, or platform compatibility should be addressed even if they do not block the build.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved after the migration:

```bash
dotnet test --configuration Release --verbosity normal
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Even without build errors, certain APIs that were available in .NET Framework may behave differently or have reduced functionality in cross-platform .NET. Review usage of the following areas in particular:

- `System.Data` and ADO.NET providers (relevant given the `AdoCore` project name)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific APIs (`System.Drawing`, `System.Windows.Forms`, etc.)
- `AppDomain` and remoting APIs
- Configuration APIs (`System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package)

Run the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to surface any compatibility concerns:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution-file>.sln
```

## 6. Validate ADO.NET Database Connectivity

Given the project is named `AdoCore`, validate that database connections function correctly at runtime:

- Confirm the correct database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient` for SQL Server).
- Verify connection strings in configuration files are correct and accessible in the new project structure.
- Test actual database read and write operations against a development database instance.

## 7. Review Configuration Files

.NET Framework used `App.config` and `Web.config`. Cross-platform .NET typically uses `appsettings.json`. Confirm that:

- Any remaining `.config` files are either migrated to `appsettings.json` or explicitly handled.
- The `Microsoft.Extensions.Configuration` packages are used where appropriate.

## 8. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows-only build.

```bash
dotnet run --configuration Release
```

## 9. Review Output Artifacts

Confirm the build output directory contains the expected assemblies and that no unintended dependencies on Windows-specific runtime identifiers exist in the `.csproj`:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to ensure all required files are present.