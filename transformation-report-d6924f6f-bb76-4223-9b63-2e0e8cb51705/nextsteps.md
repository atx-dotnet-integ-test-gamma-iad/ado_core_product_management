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

Perform a full solution build to confirm the error-free state holds across all configurations:

```bash
dotnet build --configuration Debug
dotnet build --configuration Release
```

Check the output for any warnings that, while not blocking the build, may indicate compatibility concerns worth addressing.

### 3. Review Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to an appropriate cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the TFM is set to a Windows-specific variant such as `net8.0-windows`, evaluate whether that restriction is necessary or if it can be broadened.

### 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test
```

Review any failing tests carefully, as they may surface runtime issues that were not caught at compile time.

### 5. Audit for Platform-Specific APIs

Even without build errors, the code may reference APIs that only function correctly on Windows. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay attention to diagnostics prefixed with `CA1416`, which flag platform-specific API usage.

### 6. Verify Runtime Behavior on Target Platforms

Run the application on each platform you intend to support (Windows, Linux, macOS) and confirm that all core functionality behaves as expected. Pay particular attention to:

- File path handling (directory separators)
- Environment variable access
- Any registry or Windows-specific configuration that may have been in use in the legacy project

### 7. Review NuGet Package Versions

Check that all NuGet dependencies are up to date and compatible with the chosen TFM:

```bash
dotnet list package --outdated
```

Update packages where appropriate, particularly any that were carried over directly from the legacy project, as older versions may have known issues on cross-platform .NET.

### 8. Publish the Application

Once validation is complete, produce a release build artifact:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and confirm the output runs correctly in an environment that mirrors your intended deployment target.