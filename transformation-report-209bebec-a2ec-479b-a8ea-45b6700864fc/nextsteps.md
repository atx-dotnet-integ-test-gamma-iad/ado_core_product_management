# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility issues even if they are not hard errors.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any APIs that may compile successfully but fail at runtime on non-Windows platforms. You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Pay attention to analyzer warnings prefixed with `CA1416` (platform compatibility).

### 6. Validate Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS as applicable) and exercise the primary code paths. Pay particular attention to:

- File system path separators (`\` vs `/`)
- Registry access (not available on Linux/macOS)
- Windows-specific APIs such as `System.Drawing` (requires additional packages on non-Windows)
- Culture and encoding defaults, which differ between .NET Framework and cross-platform .NET

### 7. Review `App.config` / `Web.config` Migration
If the original project used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or another supported configuration mechanism, as `ConfigurationManager` behavior differs in cross-platform .NET.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your deployment target. Review the publish output directory to confirm all required assets are present.