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
Perform a full build to confirm there are no issues beyond what was previously reported:

```bash
dotnet build --configuration Release
```

Review all warnings in the output, as some warnings may indicate compatibility issues that do not prevent compilation but could cause runtime problems.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

### 5. Check for Windows-Specific API Usage
Even if the build succeeds, the code may reference APIs that only function on Windows. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the build output for `CA1416` platform compatibility warnings, which flag Windows-only API calls.

### 6. Verify Runtime Behavior on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to confirm consistent behavior. Pay particular attention to:

- File path separators (`\` vs `/`)
- Registry access (Windows-only)
- `System.Drawing` usage (requires additional packages on non-Windows)
- COM interop or P/Invoke calls

### 7. Review Removed or Changed APIs
Consult the [.NET Upgrade Assistant compatibility report](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [.NET API Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/api-analyzer) to identify any APIs that were available in .NET Framework but have been removed or altered in modern .NET.

### 8. Publish a Test Build
Produce a self-contained or framework-dependent publish output and verify it runs correctly in a clean environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Adjust the `--runtime` identifier to match your deployment target (e.g., `win-x64`, `osx-x64`).