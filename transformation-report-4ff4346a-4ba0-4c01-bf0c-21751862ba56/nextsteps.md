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

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that may surface at runtime.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are targeting versions compatible with your chosen .NET version. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available using:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

## 4. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior matches expectations from the legacy project:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences introduced during migration even when the build succeeds.

## 5. Check for Platform-Specific Code

Search the codebase for any APIs that were Windows-specific in the original .NET Framework project. Common areas to review include:

- `System.Windows.Forms` or `System.Drawing` usage
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific P/Invoke calls
- `AppDomain` usage that behaves differently on .NET Core and later

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package where needed.

## 6. Validate Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that configuration has been migrated to the appropriate modern format:

- Console/library projects: `appsettings.json` with `Microsoft.Extensions.Configuration`
- Ensure `ConfigurationManager` references have been replaced if they were present

## 7. Test on Target Platforms

Since the goal is cross-platform support, run and validate the application on each intended platform:

```bash
# On Linux or macOS
dotnet run --configuration Release
```

Verify that file paths, line endings, and any OS-dependent behavior function correctly on non-Windows systems.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime(s):

```bash
# Framework-dependent publish
dotnet publish --configuration Release --output ./publish

# Self-contained publish for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish-linux
```

Review the output directory to confirm all required assets and dependencies are present before deployment.