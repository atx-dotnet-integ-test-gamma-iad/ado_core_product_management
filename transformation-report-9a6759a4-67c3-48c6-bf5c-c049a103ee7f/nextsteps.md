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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference versions that are compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that previously targeted .NET Framework.

## 4. Check for Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tool to identify any APIs used in the code that have been removed or changed in cross-platform .NET:

```bash
dotnet tool install -g dotnet-apicompat
```

Pay particular attention to:
- `System.Web` usages (not available in cross-platform .NET)
- Windows-specific APIs such as the registry, WCF server-side, or `System.Drawing` (GDI+)
- Any P/Invoke calls targeting Windows-only native libraries

## 5. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET.

## 6. Validate Platform-Specific Behavior

If `AdoCore` involves database access (suggested by the "Ado" naming), verify the following:

- The ADO.NET provider packages (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) are the cross-platform compatible versions.
- Connection strings and configuration are being read from `appsettings.json` or environment variables rather than `app.config` or `web.config` where applicable.
- Any `ConfigurationManager` usage has been replaced with `Microsoft.Extensions.Configuration` if necessary.

## 7. Test on Target Platforms

Since the goal is cross-platform compatibility, run and validate the project on each intended operating system (Windows, Linux, macOS) if applicable:

```bash
dotnet run --configuration Release
```

Check for any `PlatformNotSupportedException` exceptions at runtime that would not have appeared during the build step.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (bundles the runtime)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory before deploying to the target environment.