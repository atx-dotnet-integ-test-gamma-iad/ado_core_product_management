# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the absence of errors and review any warnings:

```bash
dotnet build --configuration Release
```

Address any remaining warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings (CA1416).

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify behavioral correctness after the transformation:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests and investigate the causes.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the following CLI tool to scan for APIs that are not supported on all platforms:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to any code paths that use `System.Windows.Forms`, `Microsoft.Win32`, or P/Invoke calls, as these may not behave correctly on non-Windows operating systems.

### 6. Review `AdoCore.csproj` Specifically
Since `AdoCore` is the project referenced in the transformation output, open its `.csproj` and verify:

- All package references have versions compatible with the target framework.
- Any references to `System.Data` or ADO.NET-related packages are using the cross-platform compatible versions.
- No `<HintPath>` elements point to local or GAC-based assemblies from the legacy .NET Framework.

### 7. Smoke Test Core Functionality
Run the application manually or through integration tests and exercise the primary code paths, particularly any database connectivity or data access logic within `AdoCore`, to confirm runtime behavior is correct.

### 8. Review Output Artifacts
After a successful Release build, inspect the output directory:

```bash
dotnet publish --configuration Release --output ./publish
```

Confirm that all expected assemblies, configuration files, and assets are present in the publish output.