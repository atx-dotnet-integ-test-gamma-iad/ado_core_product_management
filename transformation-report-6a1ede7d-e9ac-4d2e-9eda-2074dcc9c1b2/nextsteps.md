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

Check the build output for any warnings that, while non-breaking, may indicate compatibility concerns with the new target framework.

### 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --verbosity normal
```

Review test results carefully. A successful build does not guarantee correct runtime behavior, especially after a cross-platform migration.

### 4. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the runtime environment where the application will be deployed.

### 5. Check for Platform-Specific API Usage

Even without build errors, certain APIs that compiled successfully may behave differently or throw exceptions at runtime on non-Windows platforms. Review the code for usage of:

- `System.Windows.Forms` or `System.Drawing` (requires additional packages or configuration on Linux/macOS)
- Windows Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (e.g., hardcoded backslashes)
- P/Invoke calls targeting Windows-only native libraries

Use the .NET Compatibility Analyzer to assist with this review:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

### 6. Review Removed or Changed APIs

Cross-reference any APIs used in the project against the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) to identify any behavioral changes between .NET Framework and modern .NET that may not surface as build errors.

### 7. Manual Smoke Testing

Run the application manually and exercise its primary workflows to confirm end-to-end functionality. Pay particular attention to:

- File I/O operations
- Network or HTTP calls
- Configuration file loading (e.g., migration from `app.config` to `appsettings.json`)
- Any reflection-based code

### 8. Review NuGet Package Compatibility

Confirm that all referenced NuGet packages have versions compatible with the new target framework. Packages that have not been updated by their authors may have limited functionality or known issues on modern .NET.

```bash
dotnet list package --outdated
```

Update packages where appropriate and re-run the build and tests after each update.