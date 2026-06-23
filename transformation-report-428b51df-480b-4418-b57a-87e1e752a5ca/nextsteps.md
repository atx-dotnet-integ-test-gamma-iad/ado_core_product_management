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

Review the code for any usage of APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.UpgradeAssistant` tool can assist with this:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze
```

Pay particular attention to:
- `System.Web` usages (not available in cross-platform .NET)
- Windows-only APIs (e.g., registry access, WCF server-side)
- Any P/Invoke calls targeting Windows-specific libraries

## 5. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address regressions introduced by the migration.

## 6. Validate Runtime Behavior on Target Platforms

Since the goal is cross-platform support, run the application on each intended platform (Windows, Linux, macOS) to catch any platform-specific runtime issues that do not surface at compile time:

```bash
dotnet run --configuration Release
```

Test all major code paths, particularly those involving:
- File I/O (path separator differences)
- Database connectivity
- Authentication or cryptography

## 7. Publish the Application

Once validation is complete, publish the application for the target platform. For a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the contents of the `./publish` output directory before deploying to the target environment.

## 8. Review Configuration Files

Ensure that any configuration previously stored in `app.config` or `web.config` has been migrated to `appsettings.json` or environment variables, as these are the standard configuration mechanisms in cross-platform .NET.