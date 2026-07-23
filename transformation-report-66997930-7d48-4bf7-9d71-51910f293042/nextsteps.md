# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

### 2. Build the Solution

Perform a full solution build to confirm the error-free state holds under a clean build:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that, while non-blocking, may indicate compatibility concerns worth addressing (e.g., nullable reference warnings, obsolete API usage).

### 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test results carefully. A successful build does not guarantee correct runtime behavior after a framework migration.

### 4. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

If multiple targets are needed, confirm `<TargetFrameworks>` is configured appropriately.

### 5. Check for Platform-Specific API Usage

Run the .NET Compatibility Analyzer to identify any remaining Windows-specific or platform-specific API calls that may cause issues on non-Windows systems:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Pay attention to diagnostics prefixed with `CA1416` (platform compatibility). Any flagged APIs should be either replaced with cross-platform alternatives or guarded with runtime platform checks using `OperatingSystem.IsWindows()` or similar.

### 6. Test on Target Platforms

If cross-platform support is a requirement, run and test the application on each intended operating system (e.g., Linux, macOS) to surface any runtime issues that static analysis may not catch.

### 7. Review Configuration and File Paths

Inspect any hardcoded file paths, registry access, or environment-specific configuration values in the codebase. Replace Windows-style paths or path separators with `Path.Combine` and `Path.DirectorySeparatorChar` to ensure portability.

### 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required assets, configuration files, and dependencies are present before deployment.