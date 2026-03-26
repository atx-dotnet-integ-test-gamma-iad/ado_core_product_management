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

Check the output for any warnings that may indicate compatibility issues that did not surface as errors.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any APIs that may compile successfully but are not supported at runtime on non-Windows platforms. Run the following if you have the analyzer tooling installed:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Pay particular attention to:
- `System.Drawing` (requires `libgdiplus` on Linux/macOS or replacement with `SkiaSharp`/`ImageSharp`)
- Windows Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop or P/Invoke calls

### 6. Validate Runtime Behavior
Execute the application on each target platform (Windows, Linux, macOS) if cross-platform support is a goal. Test all major code paths, particularly those involving:
- File system operations (path separators, case sensitivity)
- Encoding and globalization
- Configuration file loading
- Any serialization or reflection-heavy code

### 7. Review Removed or Changed APIs
Consult the [.NET breaking changes documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes) for the specific version you are targeting to identify any APIs that were removed or changed in behavior relative to the .NET Framework version previously used.

### 8. Publish the Application
Once validation is complete, publish the application for the desired target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Adjust the `--runtime` identifier as appropriate for your deployment target. Review the publish output directory to confirm all required assets are present.