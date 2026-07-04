# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or other legacy monikers unless intentionally targeting multiple frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that could indicate latent issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review test output for any failures that may have been introduced during the transformation.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to scan for any remaining Windows-only API calls that may not surface as build errors but will fail at runtime on non-Windows platforms:

```bash
dotnet tool install -g dotnet-analyze
```

Pay particular attention to:
- `System.Windows.Forms` or `System.Drawing` usage
- Registry access (`Microsoft.Win32.Registry`)
- COM interop
- P/Invoke calls targeting Windows-specific native libraries

### 6. Run the Application
Execute the application on each target platform (Windows, Linux, macOS as applicable) to confirm runtime behavior:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 7. Publish a Release Build
Once runtime validation is complete, produce a published output to confirm the publish pipeline works correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to ensure all required assets and dependencies are present.

### 8. Review Removed or Changed APIs
Cross-reference the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) for any APIs that were available in the legacy framework but have changed behavior in modern .NET, even if they compile without errors.