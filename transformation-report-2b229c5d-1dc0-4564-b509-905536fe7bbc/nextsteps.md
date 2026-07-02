# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the absence of errors is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check both `Debug` and `Release` configurations if the project has configuration-specific code paths.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are present but throw `PlatformNotSupportedException` at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.Windows.Compatibility --version <latest>
```

Alternatively, run a static analysis pass:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Review any `CA1416` (platform compatibility) warnings in the output.

### 6. Validate Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay particular attention to:

- File system path separators (`\` vs `/`)
- Case sensitivity of file and directory names
- Registry access (not available on non-Windows)
- Windows-specific libraries (e.g., `System.Drawing.Common` has restrictions on non-Windows)

### 7. Review NuGet Package Compatibility
Open the NuGet package manager or inspect the `.csproj` files and confirm that all referenced packages have versions compatible with the target framework. Packages that have not been updated in several years may lack cross-platform support.

### 8. Inspect Output Artifacts
After a successful `Release` build, inspect the output directory:

```bash
dotnet publish --configuration Release --output ./publish
```

Confirm that all expected assemblies, configuration files, and static assets are present in the publish output.

### 9. Review Removed or Changed APIs
Consult the official .NET breaking changes documentation for the version you are targeting:

- [Breaking changes in .NET](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes)

Cross-reference any areas of the codebase that use APIs known to have breaking changes between .NET Framework and modern .NET.