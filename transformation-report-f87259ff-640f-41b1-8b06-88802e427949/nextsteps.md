# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless explicitly required.

### 2. Restore Dependencies
Run a full NuGet restore from the solution root to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they indicate a regression introduced during the transformation.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review the code manually for any APIs that are Windows-specific (e.g., `System.Windows.Forms`, `Microsoft.Win32`, registry access). These will compile but will throw `PlatformNotSupportedException` at runtime on non-Windows systems.

You can enable platform compatibility warnings by adding the following to your `.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

### 6. Run the Application on Target Platforms
Execute the application on each platform you intend to support (Windows, Linux, macOS) and verify core functionality behaves as expected. Pay particular attention to:

- File path handling (use `Path.Combine` rather than hardcoded separators)
- Line ending differences
- Case-sensitive file systems on Linux/macOS

### 7. Publish a Release Build
Once validation is complete, produce a self-contained or framework-dependent publish output:

```bash
# Framework-dependent
dotnet publish --configuration Release

# Self-contained for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Review the publish output directory to confirm all required assets and dependencies are present.