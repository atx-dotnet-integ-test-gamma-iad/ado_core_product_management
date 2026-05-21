# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:
```xml
<TargetFramework>net8.0</TargetFramework>
```
Ensure this is consistent across all projects in the solution.

### 2. Restore NuGet Packages
Run the following command from the solution root to confirm all dependencies resolve correctly:
```bash
dotnet restore
```
Review the output for any warnings about deprecated or unlisted packages that may need updating.

### 3. Build the Solution
Perform a clean build to confirm there are no issues introduced by the environment:
```bash
dotnet build --configuration Release
```

### 4. Run the Test Suite
If the solution contains test projects, execute all tests to verify runtime behavior is consistent with the original project:
```bash
dotnet test --configuration Release
```
Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Review Platform-Specific API Usage
Even without build errors, some APIs that compiled successfully may behave differently or throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for such usage:
```bash
dotnet tool install -g dotnet-compatibility
```
Pay particular attention to areas such as:
- `System.Drawing` (GDI+ dependencies)
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) client/server code
- `AppDomain` usage

### 6. Verify Configuration and App Settings
If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables where appropriate, and that the application reads them correctly at runtime.

### 7. Smoke Test the Application
Run the application manually against a representative set of inputs or workflows to confirm end-to-end behavior matches the legacy version. Focus on any areas that relied heavily on Windows-specific behavior or COM interop.

### 8. Review Nullable Reference Type Warnings
If the new project files have `<Nullable>enable</Nullable>` set, review any nullable warnings that appear during the build. While these are not errors by default, addressing them improves code correctness and prevents potential null reference issues at runtime.

### 9. Check Output Artifacts
Confirm that the published output is structured as expected:
```bash
dotnet publish --configuration Release --output ./publish
```
Verify that all required files, assets, and dependencies are present in the output directory.