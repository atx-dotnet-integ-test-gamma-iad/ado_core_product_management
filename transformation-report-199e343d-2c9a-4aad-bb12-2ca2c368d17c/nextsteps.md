# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally kept for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a full build to confirm the clean state holds outside of the transformation environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete API usage, as these can indicate compatibility concerns.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior, especially if the original project relied on Windows-specific APIs.

### 5. Check for Platform-Specific API Usage
Even without build errors, the code may use APIs that compile cross-platform but fail at runtime on non-Windows systems. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code for usages of namespaces such as:
- `Microsoft.Win32`
- `System.Windows.Forms`
- `System.Drawing` (without the `Common` variant)
- P/Invoke calls targeting Windows-only native libraries

### 6. Review `AdoCore.csproj` Specifically
Since `AdoCore` is the project referenced in the transformation context, open its `.csproj` and verify:
- All package references have versions compatible with the target .NET version.
- No `<HintPath>` elements point to absolute Windows paths or GAC-registered assemblies.
- Any ADO.NET-related packages (e.g., `System.Data`, database drivers) are the cross-platform compatible versions.

### 7. Run on Target Platform
If the goal is Linux or macOS compatibility, execute the built output on the target operating system to confirm there are no runtime exceptions caused by platform assumptions:

```bash
dotnet run --configuration Release
```

Or publish a self-contained executable for the target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

### 8. Review Output Warnings
Even a successful build may produce warnings that indicate future breaking changes or deprecated patterns. Run the build with detailed verbosity to capture all warnings:

```bash
dotnet build --configuration Release --verbosity detailed 2>&1 | grep -i warning
```

Address any warnings related to package deprecation, API obsolescence, or platform compatibility before considering the migration complete.