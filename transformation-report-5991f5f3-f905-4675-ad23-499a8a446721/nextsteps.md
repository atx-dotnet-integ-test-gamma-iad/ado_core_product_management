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
Perform a full build to confirm the absence of errors is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility concerns even if they do not block the build.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences introduced by the framework migration rather than pre-existing failures.

### 5. Check for Windows-Specific API Usage
Even without build errors, the code may reference APIs that only function correctly on Windows. Use the .NET Compatibility Analyzer to surface these at build time by adding the following property to each `.csproj` file where applicable:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild and review any new `CA1416` (platform compatibility) warnings that appear.

### 6. Verify Runtime Behavior on Target Platforms
Run the application on each platform you intend to support (Windows, Linux, macOS) and confirm that:

- File path handling uses `Path.Combine` rather than hardcoded separators.
- Any configuration files are read correctly.
- External process calls or P/Invoke signatures are valid on the target OS.

### 7. Review NuGet Package Compatibility
Check that all referenced NuGet packages have versions that support your target framework. The following command lists packages and their resolved versions:

```bash
dotnet list package
```

For any outdated packages, consider upgrading:

```bash
dotnet list package --outdated
```

### 8. Publish a Test Build
Produce a self-contained or framework-dependent publish output and verify it runs correctly in an environment that mirrors your intended deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Adjust the `--runtime` identifier to match your target platform (`win-x64`, `osx-x64`, etc.).