# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting them.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved dependencies.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that may indicate compatibility issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully, particularly for any tests that may have been skipped or that rely on Windows-specific behavior.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review the code manually for any APIs that are Windows-only or otherwise platform-restricted. These will typically be flagged with `[SupportedOSPlatform]` warnings during build. Common areas to check include:

- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side APIs
- `System.Drawing` (GDI+)
- COM interop

### 6. Validate Runtime Behavior
Run the application on each target platform (e.g., Windows, Linux, macOS) to confirm it behaves as expected. Pay particular attention to:

- File path separators (`/` vs `\`)
- Case sensitivity in file system operations
- Environment variable differences across operating systems

### 7. Review NuGet Package Compatibility
Check that all referenced NuGet packages support the target framework. You can use the following command to inspect outdated packages:

```bash
dotnet list package --outdated
```

Update packages where newer versions provide better cross-platform support or address known issues.

### 8. Publish the Application
Once validation is complete, publish the application for the desired runtime target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your deployment target. A full list of RIDs is available in the [Microsoft RID Catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).