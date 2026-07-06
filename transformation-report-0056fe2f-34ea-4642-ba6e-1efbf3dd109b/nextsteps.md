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

Perform a clean build to confirm there are no issues that only surface during a full compilation:

```bash
dotnet clean
dotnet build --configuration Release
```

Resolve any warnings that could indicate runtime issues, such as nullable reference warnings or deprecated API usage.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior.

## 5. Validate Platform-Specific Code

Search the codebase for any APIs that were Windows-specific in the original .NET Framework project. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references
- Registry access via `Microsoft.Win32`
- COM interop or P/Invoke calls
- `AppDomain` usage
- `System.Security.Permissions` attributes

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface any remaining compatibility concerns.

## 6. Check Configuration and App Settings

If the project previously used `App.config` or `Web.config`, verify that configuration has been migrated to `appsettings.json` or the appropriate .NET configuration provider. Confirm that connection strings, application settings, and environment-specific values are correctly read at runtime.

## 7. Test on Target Platforms

Since the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to identify any platform-specific runtime failures that would not appear during a Windows-only build.

```bash
dotnet run --configuration Release
```

## 8. Review Output Artifacts

Publish the project and inspect the output to confirm it produces the expected artifacts:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify that all required files, including configuration files and native dependencies, are present in the publish output.