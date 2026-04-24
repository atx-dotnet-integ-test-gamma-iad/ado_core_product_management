# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that may have been suppressed during the transformation:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or platform compatibility (`CA1416`).

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between the old .NET Framework runtime and the new .NET runtime.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the following command to scan for APIs that are not supported on all platforms:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to any `CA1416` warnings, which indicate calls to Windows-only APIs. If cross-platform support is required, those code paths will need to be refactored or guarded with runtime checks such as `OperatingSystem.IsWindows()`.

### 6. Validate Runtime Behavior
Run the application and exercise its primary workflows manually or through integration tests. Pay attention to:

- File path handling (`Path.Combine` vs hardcoded separators)
- Configuration file loading (e.g., `app.config` vs `appsettings.json`)
- Any reflection-based code that may behave differently under the new runtime

### 7. Review Removed or Changed APIs
Cross-reference the project's dependencies against the [.NET Upgrade Assistant compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) to identify any APIs that were removed or changed in behavior between .NET Framework and modern .NET.

### 8. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the output directory contains all expected files and that the application runs correctly from the published output on the target operating system(s).