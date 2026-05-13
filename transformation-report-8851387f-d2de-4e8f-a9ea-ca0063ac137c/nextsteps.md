# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate compatibility issues, such as platform-specific API usage warnings (`CA1416`).

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between .NET Framework and modern .NET.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been removed or behave differently in cross-platform .NET. Use the .NET Upgrade Assistant compatibility analyzer or the API compatibility tool to scan for potential issues:

```bash
dotnet tool install -g dotnet-apicompat
```

Pay particular attention to:
- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Any registry, WCF, or Windows-specific APIs
- `ConfigurationManager` usage, which requires the `System.Configuration.ConfigurationManager` NuGet package on modern .NET

## 5. Validate ADO.NET / Database Connectivity

Since this project appears to be data-access oriented, verify that:

- The correct database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient` for SQL Server)
- Connection strings are correctly configured in `appsettings.json` or the appropriate configuration source for modern .NET
- Any `DataSet`, `DataTable`, or `DataAdapter` usage functions as expected at runtime by running integration tests against a real or mocked data source

## 6. Review NuGet Package Compatibility

Check that all referenced NuGet packages support the target framework:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support. Remove any packages that were only required for .NET Framework compatibility shims.

## 7. Run on a Non-Windows Platform (if applicable)

If cross-platform support is a goal, test execution on Linux or macOS:

```bash
dotnet run --configuration Release
```

Monitor for `PlatformNotSupportedException` or similar runtime exceptions that would not have surfaced during the build.

## 8. Review Output Artifacts

Confirm the build output is producing the expected artifact type (library `.dll`, executable, etc.):

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure all required files and dependencies are present.