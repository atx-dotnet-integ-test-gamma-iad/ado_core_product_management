# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on all machines that will build or run this project.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not fully support the target framework. Check for `NU1701` warnings, which indicate a package was restored using a compatibility fallback.

## 3. Build the Solution

Perform a clean build to confirm there are no issues beyond what was reported:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or deprecated APIs, as these can indicate latent runtime issues.

## 4. Run the Test Suite

If the solution contains test projects, execute them now:

```bash
dotnet test --configuration Release
```

Review test results carefully. Failures that did not exist before migration may point to behavioral differences between .NET Framework and modern .NET, such as changes in globalization, threading, or reflection behavior.

## 5. Validate Platform-Specific Code

Search the codebase for any APIs that were available in .NET Framework but have changed or been removed in modern .NET. Common areas to check include:

- `System.Web` usage (not available in modern .NET)
- `AppDomain` APIs with reduced functionality
- `BinaryFormatter` (disabled by default in .NET 5+)
- Windows Registry access (`Microsoft.Win32.Registry`), which is Windows-only
- `System.Drawing` (requires the `System.Drawing.Common` package and may have OS restrictions)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface any remaining compatibility issues.

## 6. Test on All Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime failures that do not appear at compile time.

```bash
dotnet run --configuration Release
```

## 7. Review Output Artifacts

Confirm that the build output is placed in the expected location and that all required assets, configuration files, and dependencies are included:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to verify the output is complete before deploying to a target environment.

## 8. Update Documentation

Update any internal documentation or README files that reference .NET Framework-specific build steps, SDK versions, or tooling to reflect the current cross-platform .NET setup.