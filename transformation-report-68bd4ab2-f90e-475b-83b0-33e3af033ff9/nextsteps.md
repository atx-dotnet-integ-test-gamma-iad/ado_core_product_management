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

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Check the build output for any warnings that, while non-blocking, may indicate compatibility concerns with the target framework.

### 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved after the transformation:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests may indicate behavioral differences introduced by the migration to cross-platform .NET.

### 4. Verify Target Framework

Open `AdoCore.csproj` and confirm that the `<TargetFramework>` element references the intended .NET version (e.g., `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the runtime version available in your deployment environment.

### 5. Check for Removed or Changed APIs

Review any usage of APIs that were available in .NET Framework but have changed behavior or been removed in cross-platform .NET. Tools that can assist with this include:

- **[.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview)** — can identify remaining compatibility issues.
- **[Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer)** — flags APIs that are not supported on all platforms.

### 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (e.g., Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

Pay particular attention to file path handling, environment variable access, and any platform-specific interop code.

### 7. Review Runtime Configuration Files

Confirm that `appsettings.json`, `runtimeconfig.json`, or any other configuration files have been updated to reflect the new runtime and any changed configuration APIs.

### 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag and `--self-contained` option to match your deployment requirements.