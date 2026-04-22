# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

### 3. Build the Solution
Perform a full solution build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new .NET runtime.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review the code manually for any APIs that were available in .NET Framework but are absent or behave differently in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references (not available cross-platform)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop or P/Invoke calls
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default)

### 6. Run the Application
Execute the application directly to observe runtime behavior:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Verify that the application behaves as expected and that no runtime exceptions surface that were not caught by the test suite.

### 7. Review NuGet Package Compatibility
Check that all third-party NuGet packages in use have versions that explicitly support the target .NET version. Visit [nuget.org](https://www.nuget.org) to confirm compatibility and update any packages that have newer, compatible releases:

```bash
dotnet list package --outdated
```

### 8. Validate Output Artifacts
Confirm that the build output is placed in the expected directory and that all required assets, configuration files, and dependencies are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to ensure completeness before any further distribution.