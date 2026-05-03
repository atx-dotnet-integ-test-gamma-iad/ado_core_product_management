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
Perform a full build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify existing behavior has not been broken:

```bash
dotnet test --configuration Release
```

Review test output carefully, paying attention to any tests that were previously passing and are now failing.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer to identify any APIs that are Windows-only or otherwise platform-restricted. You can enable this in your `.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild after adding these properties and review any new diagnostics, particularly `CA1416` (platform compatibility).

### 6. Verify Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a goal:

```bash
dotnet run --configuration Release
```

Test all major code paths, especially those that previously relied on Windows-specific features such as the registry, COM interop, or `System.Windows.Forms`.

### 7. Review Removed or Changed APIs
Cross-reference the project against the [.NET Upgrade Assistant compatibility report](https://learn.microsoft.com/en-us/dotnet/core/porting/) or the official [.NET API differences documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) to identify any APIs that behave differently under cross-platform .NET compared to .NET Framework.

### 8. Publish a Release Build
Once validation is complete, produce a self-contained or framework-dependent publish artifact:

```bash
# Framework-dependent
dotnet publish --configuration Release

# Self-contained for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Verify the output directory contains all expected files and that the application starts correctly from the published output.