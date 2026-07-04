# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netstandard2.0`, or other legacy monikers unless intentionally retained.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a clean build to confirm there are no hidden warnings or errors:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings (CA1416).

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests that may indicate behavioral regressions introduced during the migration.

### 5. Check for Windows-Specific API Usage
Run the .NET Compatibility Analyzer to surface any APIs that are not supported on all target platforms:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to diagnostics prefixed with `CA1416`, which flag platform-specific API calls that may fail on Linux or macOS.

### 6. Verify Runtime Behavior
Run the application directly and exercise its primary code paths:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Confirm that database connections, file I/O, and any other external integrations behave as expected on the target platform.

### 7. Review Removed or Replaced References
Check that any packages which were automatically replaced during transformation (e.g., `System.Data.SqlClient` replaced by `Microsoft.Data.SqlClient`) are the correct versions and are configured properly in `appsettings.json` or equivalent configuration files.

### 8. Publish the Application
Once validation is complete, publish a self-contained or framework-dependent build:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and confirm the output runs correctly on the target machine or operating system.