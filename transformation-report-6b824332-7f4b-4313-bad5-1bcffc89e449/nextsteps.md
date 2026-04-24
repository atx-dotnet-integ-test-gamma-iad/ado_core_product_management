# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:
```xml
<TargetFramework>net8.0</TargetFramework>
```
Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:
```bash
dotnet restore
dotnet build --configuration Release
```
Review the output for any warnings that may indicate deprecated APIs or compatibility concerns.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:
```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```
Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and modern .NET.

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tooling to identify any APIs that were available in .NET Framework but have been removed or altered in modern .NET. Pay particular attention to:
- `System.Web` usages (not available in modern .NET)
- `AppDomain` APIs with reduced functionality
- Reflection APIs with behavioral differences
- Binary serialization (`BinaryFormatter` is disabled by default)

### 5. Review NuGet Package Versions
Open the `.csproj` files and review all `<PackageReference>` entries. Confirm that:
- Each package supports the target framework
- No packages are pinned to versions that predate .NET compatibility
- There are no duplicate or conflicting transitive dependencies

Run the following to check for outdated packages:
```bash
dotnet list package --outdated
```

### 6. Inspect Runtime Configuration
Check for the presence of `runtimeconfig.json` or `appsettings.json` files and confirm that any environment-specific configuration has been carried over correctly from the legacy `App.config` or `Web.config` files.

### 7. Validate Platform-Specific Code
Since this is a cross-platform migration, review any code that may rely on Windows-specific behavior, including:
- File path separators (use `Path.Combine` rather than hardcoded `\`)
- Windows Registry access
- COM interop or P/Invoke calls
- Windows-only NuGet packages (check for `<PackageReference>` entries targeting `win` only)

### 8. Smoke Test the Application
Run the application manually against a representative set of inputs or workflows to confirm that the core functionality behaves as expected on the target platform.

### 9. Review Warnings as Errors Settings
Check whether any project has `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>` set. If so, address all compiler warnings before considering the build stable.

### 10. Confirm Output Artifacts
After a Release build, inspect the `bin/Release` output directory to confirm the expected assemblies, dependencies, and any publish profiles are producing the correct output structure for your deployment target.