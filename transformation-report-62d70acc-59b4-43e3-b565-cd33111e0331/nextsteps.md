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
Perform a full build to confirm there are no warnings that may indicate compatibility issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to platform compatibility, nullable reference types, or obsolete APIs.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test output carefully. A successful build does not guarantee correct runtime behavior after a framework migration.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or review the code manually for APIs that are Windows-only. These will typically be annotated with `[SupportedOSPlatform("windows")]` warnings during build. Common areas to check include:

- Registry access (`Microsoft.Win32.Registry`)
- Windows Forms or WPF dependencies
- COM interop
- `System.Drawing` (requires additional packages on non-Windows)

If any are found and cross-platform support is required, replace them with cross-platform alternatives.

### 6. Run on Target Platforms
If the goal is cross-platform support, test the application on each intended operating system (Linux, macOS, Windows) by publishing a platform-specific build:

```bash
dotnet publish --configuration Release --runtime linux-x64
dotnet publish --configuration Release --runtime osx-x64
dotnet publish --configuration Release --runtime win-x64
```

Run the resulting binaries on their respective platforms and verify expected behavior.

### 7. Review Configuration and File Paths
Check any hardcoded file paths, directory separators, or environment-specific configuration values in the codebase. Replace backslash-based paths with `Path.Combine` or forward-slash equivalents to ensure cross-platform compatibility.

### 8. Validate Application Output
Perform end-to-end functional testing of the application to confirm that the migrated version produces the same output and behavior as the original legacy version.