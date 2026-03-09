# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test results carefully. A successful build does not guarantee correctness of runtime behavior after a framework migration.

### 4. Audit NuGet Package Compatibility
Check all NuGet dependencies to confirm they support the target framework. You can inspect this with:

```bash
dotnet list package --outdated
```

Replace any packages that do not have a compatible version with their recommended cross-platform alternatives.

### 5. Review Platform-Specific APIs
Search the codebase for any APIs that were available in .NET Framework but are not supported or behave differently in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` usage (not available cross-platform without specific workloads)
- Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default)
- `System.Drawing` (requires the `System.Drawing.Common` package and may have OS limitations)

The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) can assist in identifying these issues.

### 6. Test on Target Platforms
If cross-platform support (Linux, macOS) is a goal, run and test the application on each target operating system to surface any OS-specific runtime issues that would not appear during a Windows build.

### 7. Review Configuration and File Paths
Ensure that any hardcoded file paths use `Path.Combine` or `Path.DirectorySeparatorChar` rather than backslashes, which are Windows-specific. Also verify that configuration files (e.g., `app.config`) have been migrated to `appsettings.json` or the appropriate .NET configuration model if applicable.

### 8. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime, use:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Adjust the `--runtime` identifier (`win-x64`, `osx-x64`, `linux-x64`, etc.) to match your deployment target.