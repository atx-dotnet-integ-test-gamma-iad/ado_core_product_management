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
Perform a full build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility concerns even if they do not block the build.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Runtime-Only Issues
Some issues do not surface at build time. Pay attention to the following areas when running the application:

- **File paths**: Ensure no hardcoded Windows-style paths (e.g., `C:\`) exist in configuration or code.
- **Registry access**: `Microsoft.Win32.Registry` is not available on Linux/macOS. Replace any registry usage with configuration files or environment variables.
- **Windows-specific APIs**: Review any P/Invoke calls or use of `System.Windows.Forms` / `System.Drawing` that may not function on non-Windows platforms.
- **Globalization**: .NET on Linux may behave differently with culture-sensitive operations. Consider setting `<InvariantGlobalization>` explicitly in the project file if appropriate.

### 6. Review Removed or Changed APIs
Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tooling to identify any APIs used in the code that have been removed or altered in cross-platform .NET.

### 7. Publish the Application
Once validation is complete, publish the application for the target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target (e.g., `win-x64`, `osx-x64`, `linux-arm64`). Review the published output directory to confirm all required assets are present.