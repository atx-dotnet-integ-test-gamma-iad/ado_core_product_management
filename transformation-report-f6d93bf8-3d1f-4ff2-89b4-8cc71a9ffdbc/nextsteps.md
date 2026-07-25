# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated package versions that may have been carried over from the legacy project.

### 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Review any warnings in the build output. While warnings do not prevent compilation, they may indicate areas where APIs have been deprecated or behavior has changed between the legacy .NET Framework and the current .NET version.

### 3. Run Existing Tests

If the solution contains test projects, execute the test suite to verify that runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Note any failing tests, as they may indicate behavioral differences between .NET Framework and cross-platform .NET that were not caught at compile time. Pay particular attention to:

- File path handling (directory separators differ between Windows and Linux/macOS)
- Culture and localization behavior
- Reflection-based code
- Any usage of `AppDomain` or remoting APIs

### 4. Review Removed or Replaced APIs

Check the codebase for any usage of APIs that are present in .NET but behave differently from their .NET Framework counterparts. Common areas to review include:

- `System.Configuration.ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)
- `System.Drawing` (requires the `System.Drawing.Common` NuGet package and has platform limitations)
- WCF client or server usage (server-side WCF is not supported on cross-platform .NET)
- Registry access (`Microsoft.Win32.Registry`) which is Windows-only

### 5. Target Framework Verification

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the project needs to support multiple frameworks, consider using `<TargetFrameworks>` (plural) to multi-target.

### 6. Runtime Smoke Test

Run the application directly to perform a basic smoke test:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Verify that the application starts without exceptions and that core functionality behaves as expected.

### 7. Platform-Specific Testing

If cross-platform support is a goal, test the application on each target operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows-only build and test pass.

## Deployment

### Publish a Self-Contained or Framework-Dependent Executable

To produce a deployable artifact, use the `dotnet publish` command. For a framework-dependent deployment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish/win-x64
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish/linux-x64
```

### Verify Published Output

After publishing, navigate to the output directory and confirm that all expected assemblies, configuration files, and static assets are present before deploying to the target environment.