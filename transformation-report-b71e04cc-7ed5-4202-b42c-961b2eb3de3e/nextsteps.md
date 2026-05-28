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
Perform a full build to confirm there are no errors or warnings that may have been suppressed during the transformation:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings (`CA1416`).

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer to identify any APIs that are Windows-only and may fail on Linux or macOS. You can enable this by ensuring the following is present in each `csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild and review any `CA1416` warnings, which flag platform-specific API calls.

### 6. Verify Runtime Behavior on Target Platforms
Run the application on each platform you intend to support (Windows, Linux, macOS) and confirm that core functionality behaves as expected. Pay particular attention to:

- File path handling (`Path.Combine` vs hardcoded separators)
- Registry access (Windows-only)
- `System.Drawing` usage (requires additional packages on non-Windows)
- Any P/Invoke or interop code

### 7. Review NuGet Package Compatibility
Check that all referenced NuGet packages have versions compatible with your target framework. You can audit this with:

```bash
dotnet list package --outdated
```

Update packages where newer versions provide better cross-platform support.

### 8. Publish a Test Build
Produce a self-contained or framework-dependent publish output and verify it runs correctly:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Repeat for each target runtime identifier (`win-x64`, `osx-x64`, etc.) as applicable to your deployment targets.