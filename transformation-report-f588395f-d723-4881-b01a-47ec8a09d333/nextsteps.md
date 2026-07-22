# Next Steps

## Summary

The transformation appears to have been successful. No build errors were detected across any of the projects in the solution, including `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Verify that the restore completes without warnings related to missing packages or incompatible target frameworks.

### 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Review the output for any warnings that, while non-blocking, may indicate deprecated APIs or compatibility concerns worth addressing.

### 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Review test results carefully. A passing build does not guarantee correct runtime behavior, so test coverage here is important.

### 4. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with your organization's supported runtime version.

### 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been available in .NET Framework but behave differently or throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Run the .NET Compatibility Analyzer if not already applied:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any reported diagnostics and address platform-specific code paths accordingly.

### 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (e.g., Linux, macOS) to surface any runtime issues that would not appear on Windows.

### 7. Review NuGet Package Versions

Check that all referenced NuGet packages are compatible with the target framework. Look for packages that may still reference `net45` or other legacy targets and update them to versions that support the current target framework.

```bash
dotnet list package --outdated
```

Update packages as appropriate and re-run the build and tests.

### 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required assemblies and assets are present before deploying to the target environment.