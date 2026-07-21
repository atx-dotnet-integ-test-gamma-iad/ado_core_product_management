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

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that, while non-blocking, may indicate compatibility concerns with the target framework.

### 3. Run the Test Suite

If the solution contains test projects, execute all tests to verify behavioral correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review test results carefully. A passing build does not guarantee that runtime behavior is identical to the original legacy project.

### 4. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

If multiple target frameworks are required, confirm `<TargetFrameworks>` is used appropriately.

### 5. Check for Platform-Specific API Usage

Even without build errors, the project may reference APIs that behave differently or are unsupported on non-Windows platforms. Use the .NET Compatibility Analyzer to surface any such issues:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Pay attention to any `CA1416` (platform compatibility) warnings in the output.

### 6. Run on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (e.g., Windows, Linux, macOS) to catch any runtime platform-specific issues that static analysis may not surface.

### 7. Review Configuration and File Paths

Check any configuration files (e.g., `appsettings.json`) and code that constructs file paths to ensure they use `Path.Combine` or equivalent cross-platform approaches rather than hardcoded backslashes or Windows-specific paths.

### 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag to match your deployment target (e.g., `win-x64`, `osx-x64`). Review the publish output directory to confirm all required assets are present.