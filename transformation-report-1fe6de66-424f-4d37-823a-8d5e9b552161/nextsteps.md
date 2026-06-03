# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

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

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time. Run the application and exercise its primary code paths:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Pay particular attention to:
- Database connectivity and ADO.NET operations, as driver packages and connection string formats may differ on non-Windows platforms.
- Any use of `System.Data` APIs that may behave differently under cross-platform .NET.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with the target framework. You can use the following command to identify outdated or potentially incompatible packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions compatible with your target framework.

## 6. Audit Platform-Specific Code

Search the codebase for any APIs that are Windows-specific and may not be available on Linux or macOS. Common areas to check include:

- Registry access (`Microsoft.Win32.Registry`)
- Windows Event Log (`System.Diagnostics.EventLog`)
- COM interop
- `System.Drawing` (requires additional native dependencies on non-Windows platforms)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify these usages.

## 7. Test on Target Platform

If the goal is cross-platform support, run and test the application on each target operating system (Windows, Linux, macOS) to surface any platform-specific runtime differences.

## 8. Review Configuration and File Paths

Ensure that any hardcoded file paths use `Path.Combine` or `Path.DirectorySeparatorChar` rather than hardcoded backslashes, which are not valid path separators on Linux and macOS.

## 9. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your intended runtime identifier (e.g., `win-x64`, `osx-x64`). Review the contents of the `publish` output directory before deploying.