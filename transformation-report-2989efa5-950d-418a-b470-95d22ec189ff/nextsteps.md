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

Check the output for any warnings that, while not blocking the build, may indicate compatibility concerns with the target framework.

### 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences introduced by the framework migration rather than pre-existing failures.

### 4. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the runtime version installed on all target machines.

### 5. Check for Platform-Specific API Usage

Even without build errors, some APIs that compiled successfully may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Run the .NET Compatibility Analyzer if it is not already referenced:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any diagnostics it surfaces and replace platform-specific calls with cross-platform alternatives where necessary.

### 6. Smoke Test Core Functionality

Manually exercise the primary entry points or workflows of the application to confirm expected behavior at runtime. Pay particular attention to:

- File system path handling (ensure `Path.Combine` is used rather than hardcoded separators)
- Configuration file loading
- Any registry or Windows-specific interop that may have been carried over

### 7. Review Output Artifacts

Confirm the compiled output is placed in the expected directory and that all required assets, configuration files, and dependencies are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to verify the output is complete before deploying to a target environment.