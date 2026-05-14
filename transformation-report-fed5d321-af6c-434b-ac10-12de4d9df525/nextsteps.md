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
Run the following commands from the root of the solution to confirm a clean restore and build:
```bash
dotnet restore
dotnet build --configuration Release
```
Review the output for any warnings that may indicate deprecated APIs or compatibility concerns even if they are not hard errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:
```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```
Review any test failures carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET.

### 4. Check for Platform-Specific API Usage
Even without build errors, some APIs may have been replaced with stubs or may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer or review the Microsoft API compatibility documentation for any APIs used in `AdoCore` that were Windows-specific, such as:
- `System.Drawing`
- `Microsoft.Win32` registry access
- WCF server-side components
- Windows-specific file path assumptions

### 5. Review NuGet Package Versions
Open the `.csproj` files and confirm all NuGet packages reference versions that are compatible with your target .NET version. Run the following to check for outdated packages:
```bash
dotnet list package --outdated
```
Update packages where appropriate, then rebuild and retest.

### 6. Validate Configuration Files
If the project previously used `App.config` or `Web.config`, confirm that any necessary settings have been migrated to `appsettings.json` or the appropriate .NET configuration model. The legacy XML-based configuration system has limited support in cross-platform .NET.

### 7. Smoke Test Core Functionality
Execute the application manually or through integration tests and exercise the primary workflows that `AdoCore` supports. Pay particular attention to:
- Database connectivity and ADO.NET operations
- Connection string configuration
- Any environment-specific behavior that may differ between Windows and Linux/macOS

### 8. Review Output Artifacts
Confirm the build output is placed in the expected directory and that all required assets, such as configuration files and native dependencies, are present alongside the compiled binaries:
```bash
dotnet publish --configuration Release --output ./publish
```
Inspect the `./publish` directory to ensure completeness before any deployment.