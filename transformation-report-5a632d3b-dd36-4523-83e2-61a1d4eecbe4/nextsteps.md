# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Some APIs behave differently or are unavailable on cross-platform .NET even when the project compiles successfully. Pay attention to:

- **Windows-only APIs**: Features such as the registry, certain `System.Drawing` types, or COM interop may not function on Linux or macOS. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `PlatformCompatibilityAnalyzer` to identify these.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on cross-platform .NET. Confirm any `app.config` or `web.config` usage has been accounted for.
- **Reflection and serialization**: Verify any reflection-heavy or serialization code behaves as expected at runtime.

## 5. Review NuGet Package Versions

Inspect `AdoCore.csproj` for any NuGet packages that may have been carried over from the legacy project. Ensure all packages target .NET Standard 2.0+ or .NET 6/8 directly:

```bash
dotnet list package --outdated
```

Update packages where appropriate using:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 6. Validate Data Access Behavior

Since the project name suggests ADO.NET usage (`AdoCore`), perform the following checks:

- Confirm the correct database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of the legacy `System.Data.SqlClient` where applicable).
- Run integration tests or manual queries against a test database to verify connection strings, query execution, and data mapping behave correctly.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and dependencies are present.

## 8. Test on Target Platform

If the goal is cross-platform execution, run the published output on each target operating system (Windows, Linux, macOS) to confirm there are no platform-specific runtime failures before promoting to a production environment.