# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless intentionally targeting multiple frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the clean state holds outside of the transformation environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly `NU1701` (package compatibility) or `CS0618` (obsolete API usage), as these can indicate runtime risk even when the build succeeds.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior after a framework migration.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining calls to Windows-only APIs (e.g., registry access, `System.Windows.Forms`, COM interop). Run the following to enable platform compatibility analysis:

Add this to each `.csproj` if not already present:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

Then rebuild and review any `CA1416` (platform compatibility) warnings.

### 6. Validate Configuration and App Settings
If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment-based configuration using `Microsoft.Extensions.Configuration`. Legacy config files are not fully supported in cross-platform .NET.

### 7. Test on Target Platforms
If cross-platform support is a goal, run and test the application on each intended operating system (Linux, macOS, Windows) to surface any platform-specific runtime issues that static analysis would not catch.

### 8. Review Output Artifacts
After a Release build, inspect the output in the `bin/Release/net8.0/` directory (or whichever target framework was chosen) and confirm all expected assemblies, configuration files, and resources are present.

```bash
dotnet publish --configuration Release --output ./publish
```

Review the published output to ensure it is self-contained or framework-dependent as intended, and that no unintended files are missing or included.