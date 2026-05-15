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
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that may indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or review the code manually for APIs that are Windows-only. These will typically be annotated with `[SupportedOSPlatform("windows")]` warnings during build. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` usage
- Registry access (`Microsoft.Win32.Registry`)
- COM interop
- P/Invoke calls targeting Windows system libraries

If any are found and cross-platform support is required, these will need to be replaced or conditionally compiled.

### 6. Run on Target Platforms
If the goal is cross-platform execution, run the application on each intended operating system (Linux, macOS, Windows) to catch any platform-specific runtime issues that static analysis may not surface:

```bash
dotnet run --configuration Release
```

### 7. Publish a Release Build
Once validation is complete, publish the application for the target runtime(s):

```bash
# Framework-dependent
dotnet publish -c Release

# Self-contained for a specific runtime
dotnet publish -c Release -r linux-x64 --self-contained true
```

Review the publish output directory to confirm all expected assets are present.