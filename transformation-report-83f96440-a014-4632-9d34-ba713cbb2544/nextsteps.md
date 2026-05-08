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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with the target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Check for Removed or Changed APIs

Review the code for any usage of APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility tooling can assist with this.

Common areas to check:
- `System.Web` usage (not available in cross-platform .NET)
- `AppDomain` APIs with limited support
- Windows-specific registry or COM interop calls
- `BinaryFormatter` (deprecated and disabled by default)

## 5. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests to determine whether they indicate a behavioral difference introduced by the migration.

## 6. Perform Runtime Smoke Testing

Run the application locally and exercise its primary functionality manually or through integration tests. Pay particular attention to:
- Database connectivity and ADO.NET operations (given the `AdoCore` project name)
- File I/O paths, as path separators differ between Windows and Linux/macOS
- Configuration loading (e.g., confirm migration from `App.config`/`Web.config` to `appsettings.json` if applicable)

## 7. Validate Cross-Platform Behavior

If cross-platform execution is a goal, test the application on each target operating system (Windows, Linux, macOS) to surface any platform-specific issues:

```bash
dotnet run --configuration Release
```

## 8. Review `App.config` or `Web.config` Migration

If the original project used `App.config`, confirm that connection strings and application settings have been properly migrated to `appsettings.json` or environment variables, and that the application reads them correctly using `Microsoft.Extensions.Configuration`.

## 9. Check Output and Publish

Perform a publish to verify the output is complete and self-contained if needed:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present.