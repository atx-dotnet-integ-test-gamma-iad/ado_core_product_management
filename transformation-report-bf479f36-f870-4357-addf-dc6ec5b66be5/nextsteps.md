# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with the target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently or have been removed in cross-platform .NET compared to .NET Framework. Review the following areas if they are used in the project:

- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Any Windows-specific APIs (e.g., `System.Drawing`, `Microsoft.Win32`, registry access)
- `ConfigurationManager` — replace with `Microsoft.Extensions.Configuration` if needed
- `AppDomain` usage that relied on .NET Framework-specific behavior

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining compatibility concerns.

## 5. Run Existing Tests

If a test project exists in the solution, execute the tests to validate runtime behavior:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET.

## 6. Perform Runtime Validation

Run the application and exercise the core ADO.NET functionality manually or through integration tests. Specifically verify:

- Database connection strings are correctly configured for the new environment
- Any database drivers (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) are the correct cross-platform versions
- Data reading, writing, and transaction behavior works as expected

## 7. Review Platform-Specific Behavior

If the project is intended to run on Linux or macOS, test explicitly on those platforms. Some ADO.NET providers or data access patterns may have platform-specific dependencies that only surface at runtime.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required assemblies and configuration files are present before deploying to the target environment.