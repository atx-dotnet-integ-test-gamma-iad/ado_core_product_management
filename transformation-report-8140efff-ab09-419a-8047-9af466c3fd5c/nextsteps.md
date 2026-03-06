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

Check all NuGet dependencies in `AdoCore.csproj` to confirm they target compatible .NET versions. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any outdated packages using:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 4. Check for Removed or Changed APIs

Review the code for any usage of APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) can assist with this if not already run.

Common areas to check:
- `System.Web` references (not available in cross-platform .NET)
- `AppDomain` usage
- Windows-specific registry or file path assumptions
- `ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)

## 5. Run Existing Tests

If the solution contains a test project, execute the test suite to validate runtime behavior:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET.

## 6. Validate Platform-Specific Behavior

Since this is a cross-platform migration, run the application on each target operating system (Windows, Linux, macOS) if applicable. Pay attention to:

- File path separators (`\` vs `/`) — use `Path.Combine` and `Path.DirectorySeparatorChar`
- Case sensitivity in file system operations (Linux is case-sensitive)
- Environment variable differences across operating systems

## 7. Check Runtime Configuration

Review or create an `appsettings.json` or `runtimeconfig.json` if the project previously relied on `App.config` or `Web.config`. Ensure connection strings, logging settings, and other configuration values have been migrated appropriately.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed.

## 9. Verify Published Output

Navigate to the `./publish` directory and confirm the expected binaries and configuration files are present before deploying to the target environment.