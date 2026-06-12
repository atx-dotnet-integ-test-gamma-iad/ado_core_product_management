# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `net472`, or any other legacy .NET Framework moniker unless that is intentional.

### 2. Restore NuGet Packages
Run the following command from the solution root to confirm all dependencies resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the no-error state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check both `Debug` and `Release` configurations to rule out configuration-specific issues.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., changes in globalization, reflection, or threading behavior).

### 5. Check for Runtime-Only Issues
Some incompatibilities do not surface at build time. Pay attention to the following areas at runtime:

- **File paths**: Ensure no hardcoded Windows-style paths (e.g., `C:\`) exist in configuration files or code.
- **Registry access**: `Microsoft.Win32.Registry` is not supported on Linux/macOS. Replace any registry reads/writes with configuration file alternatives.
- **Windows-specific APIs**: Review any P/Invoke calls or uses of `System.Windows.Forms` / `System.Drawing` that may not be available cross-platform.
- **Globalization**: .NET on Linux uses ICU by default. If the application relied on Windows NLS behavior, results from string comparisons and formatting may differ.

### 6. Review Removed or Changed APIs
Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility shims if any APIs were silently replaced during transformation. Running the following can surface analyzer warnings:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisLevel=latest
```

### 7. Validate on Target Platforms
If cross-platform support is a goal, run the built application on each intended operating system (Windows, Linux, macOS) to confirm consistent behavior before proceeding to deployment.

### 8. Publish the Application
Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release

# Self-contained (bundles the runtime)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Review the contents of the `publish` output folder to confirm all required assets and configuration files are present.