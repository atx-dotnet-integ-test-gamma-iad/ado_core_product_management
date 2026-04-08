# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally retained.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a full build to confirm the clean state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check that both `Debug` and `Release` configurations build without warnings that could indicate compatibility issues.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests that may indicate behavioral differences introduced by the migration.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to scan for any remaining Windows-specific API calls that may compile successfully but fail at runtime on Linux or macOS:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Alternatively, run the built-in platform compatibility analyzer by building with:

```bash
dotnet build -p:EnableNETAnalyzers=true
```

### 6. Validate Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay particular attention to:

- File path separators (`\` vs `/`)
- Case sensitivity in file system operations
- Registry or Windows-specific configuration access
- COM interop or P/Invoke calls

### 7. Review NuGet Package Versions
Check that all NuGet dependencies have versions compatible with the target .NET version. Use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages where newer stable versions are available and re-run the test suite after doing so.

### 8. Publish a Test Build
Produce a self-contained or framework-dependent publish output to confirm the final artifact is generated correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and run the output executable directly to confirm it starts and operates as expected.