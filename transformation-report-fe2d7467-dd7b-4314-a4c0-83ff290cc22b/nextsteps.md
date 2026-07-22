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

Perform a full build to confirm there are no errors or warnings:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

### 3. Run the Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

### 4. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the target framework used by all dependent projects in the solution.

### 5. Check for Platform-Specific API Usage

Run the .NET Compatibility Analyzer to identify any remaining usage of Windows-only or framework-specific APIs:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay attention to diagnostics prefixed with `CA1416`, which flag platform-specific API calls that may not behave correctly on non-Windows operating systems.

### 6. Review Configuration and App Settings

If the project previously used `app.config` or `web.config`, verify that settings have been migrated to `appsettings.json` or the appropriate .NET configuration model. Confirm that connection strings, environment-specific values, and any custom configuration sections are loading correctly at runtime.

### 7. Manual Smoke Testing

Run the application manually and exercise its primary workflows to catch any runtime issues that static analysis and unit tests may not surface. Pay particular attention to:

- File I/O paths, especially if the application previously assumed Windows-style path separators.
- Registry access or Windows-specific interop calls.
- Any use of `System.Web` namespaces, which are not available in cross-platform .NET.

### 8. Review NuGet Package Versions

Check that all NuGet dependencies have versions compatible with the target framework. Use the following command to list outdated packages:

```bash
dotnet list package --outdated
```

Update packages where necessary, giving priority to those flagged as incompatible or deprecated.