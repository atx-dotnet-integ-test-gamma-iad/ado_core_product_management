# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

### 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that, while non-blocking, may indicate compatibility concerns with the new target framework.

### 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test results carefully. A passing build does not guarantee correct runtime behavior, so all existing tests should pass before proceeding.

### 4. Verify Target Framework

Open `AdoCore.csproj` and confirm that the `<TargetFramework>` element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the runtime environment where the application will be deployed.

### 5. Review Removed or Changed APIs

Check for any usage of APIs that were available in .NET Framework but have changed behavior in cross-platform .NET. Pay particular attention to:

- `System.Configuration` usage (replaced by `Microsoft.Extensions.Configuration`)
- `System.Web` usage (not available in cross-platform .NET)
- Windows-specific APIs such as the registry, WCF server-side components, or `System.Drawing` (requires additional packages on non-Windows platforms)
- Any P/Invoke calls targeting Windows-only native libraries

### 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (e.g., Linux, macOS) in addition to Windows. Platform-specific issues may not surface during a Windows-only build.

### 7. Review NuGet Package Compatibility

Inspect all referenced NuGet packages and confirm they support the target framework. Packages that have not been updated for cross-platform .NET may require replacement with maintained alternatives.

```bash
dotnet list package --outdated
```

Update packages where appropriate and re-run the build and tests after each significant change.

### 8. Manual Smoke Test

Run the application manually and exercise its primary functionality to confirm end-to-end behavior is correct after the migration.

```bash
dotnet run --project AdoCore.csproj --configuration Release
```