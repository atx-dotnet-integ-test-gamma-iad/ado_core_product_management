# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are targeting versions compatible with your chosen .NET version. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available.

## 4. Check for Removed or Changed APIs

Review any usages of APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Key areas to inspect include:

- `System.Data` and ADO.NET-related types (given the `AdoCore` naming)
- `ConfigurationManager` (replaced by `Microsoft.Extensions.Configuration`)
- `AppDomain` usage
- Any Windows-specific APIs (e.g., registry access, COM interop)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to surface any compatibility concerns.

## 5. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET.

## 6. Validate ADO.NET Connectivity

Since the project name suggests ADO.NET usage, verify that database connections function correctly at runtime:

- Confirm the correct database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of the legacy `System.Data.SqlClient` where applicable).
- Test connection strings and ensure they are being loaded correctly from the new configuration system if `ConfigurationManager` was replaced.

## 7. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag and `--self-contained` option based on your deployment target. Refer to the [.NET RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog) for available runtime identifiers.