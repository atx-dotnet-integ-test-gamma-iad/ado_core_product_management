# Next Steps

The transformation appears to have completed successfully. There are no build errors reported across any of the projects in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or other legacy monikers unless a multi-targeting scenario is intentional.

## 2. Restore Dependencies

Run a full NuGet restore from the solution root to confirm all packages resolve correctly:

```bash
dotnet restore AdoCore.sln
```

Review the output for any warnings about deprecated packages or packages that could not be resolved.

## 3. Build the Solution

Perform a clean build to confirm the absence of errors is consistent across configurations:

```bash
dotnet build AdoCore.sln --configuration Release
```

Check the output for any warnings that, while non-blocking, may indicate compatibility concerns worth addressing.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test AdoCore.sln --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences introduced by the migration to cross-platform .NET rather than test logic issues.

## 5. Validate Platform-Specific Code

Search the codebase for any APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Common areas to check include:

- `System.Web` usage (not available outside of ASP.NET Core)
- `System.Drawing` (requires additional packages on Linux/macOS)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` members that are no longer supported
- `BinaryFormatter` (disabled by default in .NET 5+)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining compatibility issues.

## 6. Test on Target Platforms

If cross-platform support (Linux, macOS) is a goal, run the build and tests on each target operating system to surface any platform-specific runtime issues that would not appear on Windows.

## 7. Review Configuration Files

Check that any configuration previously handled by `App.config` or `Web.config` has been correctly migrated to `appsettings.json` or environment-based configuration, and that the application reads these values correctly at runtime.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish AdoCore.sln --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) as needed. Review the publish output directory to confirm all required files are present before deploying to the target environment.