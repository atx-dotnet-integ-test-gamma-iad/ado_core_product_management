# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly under the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not fully support the target framework. Consider replacing any packages flagged with `NU1701` (package targeting a different framework) with actively maintained cross-platform equivalents.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to obsolete APIs or platform compatibility analyzers (`CA1416`).

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new .NET runtime (e.g., differences in `System.Data`, encoding defaults, or globalization behavior).

## 5. Check for Platform-Specific Code

Search the codebase for APIs that were available in .NET Framework but have limited or no support in cross-platform .NET:

- `System.Web` references
- `Microsoft.Win32.Registry` usage (Windows-only)
- `System.Drawing` (requires additional packages on Linux/macOS)
- COM interop or P/Invoke calls targeting Windows-specific libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface these issues systematically.

## 6. Validate Runtime Behavior

Run the application on each target operating system (Windows, Linux, macOS) if cross-platform support is a requirement. Pay particular attention to:

- File path separators (`\` vs `/`)
- Case sensitivity of the file system
- Culture and locale-dependent string operations
- Environment variable availability

## 7. Review Configuration Files

Ensure any configuration previously handled by `App.config` or `Web.config` has been migrated to the appropriate .NET configuration system (`appsettings.json`, environment variables, or `IConfiguration`). The legacy XML-based configuration system is not fully supported in cross-platform .NET.

## 8. Publish the Application

Once validation is complete, publish the application using the desired deployment model:

**Framework-dependent deployment:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained deployment (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application starts correctly in the target environment.