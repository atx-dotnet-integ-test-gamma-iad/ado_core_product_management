# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no issues that may have been masked:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or obsolete API usage, as these can indicate latent issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Windows-Specific API Usage
Even if the build succeeds, some APIs that compiled successfully may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer or review the code manually for usage of APIs such as:

- `System.Windows.Forms`
- `Microsoft.Win32.Registry`
- `System.Drawing` (without the `System.Drawing.Common` package)
- P/Invoke calls targeting Windows-only native libraries

You can also run the following to surface platform compatibility warnings:

```bash
dotnet build -p:EnableNETAnalyzers=true -p:AnalysisMode=All
```

### 6. Test on Target Platforms
If cross-platform support (Linux, macOS) is a goal, run the application on each target operating system to confirm there are no runtime failures that were not caught during the build phase.

### 7. Review Configuration and File Paths
Check that any file paths, configuration file references, or environment-specific settings in the application use `Path.Combine` or equivalent cross-platform APIs rather than hardcoded Windows-style paths (e.g., `C:\` or backslash separators).

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the publish output directory to confirm all required assets are present.