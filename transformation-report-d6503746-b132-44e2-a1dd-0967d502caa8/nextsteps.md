# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. The solution compiled without issues after migration to cross-platform .NET.

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

Check the output for any warnings that, while non-blocking, may indicate deprecated APIs or compatibility concerns worth addressing.

### 3. Run the Test Suite
If the solution contains test projects, execute all tests to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test results carefully. A successful build does not guarantee correct runtime behavior, so passing tests are an important validation step.

### 4. Review Target Framework
Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

If multiple target frameworks are needed, ensure `<TargetFrameworks>` is used with the appropriate monikers.

### 5. Check for Platform-Specific API Usage
Even without build errors, some APIs may have been available in .NET Framework but behave differently or throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Run the build again and review any newly surfaced analyzer warnings.

### 6. Review Configuration and App Settings
If the project previously used `App.config` or `Web.config`, verify that configuration has been migrated to `appsettings.json` or environment-based configuration using `Microsoft.Extensions.Configuration` where appropriate.

### 7. Validate Runtime on Target Platforms
Run the application on each platform you intend to support (e.g., Windows, Linux, macOS) to confirm there are no platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, such as `win-x64`, `linux-x64`, or `osx-x64`. Use `--self-contained true` if you require the .NET runtime to be bundled with the output.

Review the publish output directory to confirm all expected assets are present.