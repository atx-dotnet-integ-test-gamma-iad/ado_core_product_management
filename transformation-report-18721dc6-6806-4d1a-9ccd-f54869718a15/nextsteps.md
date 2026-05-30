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
Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify that existing behavior has been preserved after the transformation:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and cross-platform .NET.

### 5. Check for Windows-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are Windows-only. You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Look for `CA1416` platform compatibility warnings, which flag APIs that are not available on all platforms.

### 6. Verify Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay particular attention to:

- File path separators (`\` vs `/`)
- Environment variable access
- Registry access (Windows-only)
- Any use of `System.Drawing` or other packages with platform-specific native dependencies

### 7. Review NuGet Package Versions
Check that all NuGet packages in use have versions compatible with the target framework. Replace any packages that have known cross-platform alternatives, for example:

- Replace `Microsoft.Win32.*` usage where possible
- Replace `System.Drawing.Common` with a cross-platform alternative such as `SkiaSharp` if non-Windows support is needed

### 8. Publish a Test Build
Produce a self-contained or framework-dependent publish output and verify it runs correctly:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier to match your intended deployment target.