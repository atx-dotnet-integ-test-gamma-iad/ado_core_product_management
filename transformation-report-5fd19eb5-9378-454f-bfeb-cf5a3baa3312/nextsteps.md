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

Review test output carefully, particularly for any tests that may have been skipped or that exercise platform-specific code paths.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the following CLI tool to scan for APIs that are not supported on all platforms:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to usages of `System.Windows.Forms`, `System.Drawing`, `Microsoft.Win32`, or P/Invoke calls that may not function on Linux or macOS.

### 6. Run on Each Target Platform
If cross-platform support is a goal, build and run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime issues that do not surface at compile time:

```bash
dotnet run --configuration Release
```

### 7. Verify Output Artifacts
Publish the application and inspect the output to confirm all expected files are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Check that no legacy `.config` files or Windows-specific manifests are being relied upon at runtime.

### 8. Review Removed or Changed APIs
Cross-reference the [.NET Upgrade Assistant breaking changes documentation](https://docs.microsoft.com/en-us/dotnet/core/compatibility/) for the specific version you are targeting to confirm no behavioral differences will affect the application at runtime.