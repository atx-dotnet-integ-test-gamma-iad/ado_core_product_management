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
Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:
```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```
Review any failing tests and address them before proceeding.

### 4. Check NuGet Package Compatibility
Review all NuGet package references in each `.csproj` file. Confirm that every package supports the target framework. You can use the following command to identify outdated packages:
```bash
dotnet list package --outdated
```
Update packages that have newer versions compatible with your target framework.

### 5. Review Removed or Changed APIs
Cross-platform .NET removes certain APIs that existed in .NET Framework. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any calls to APIs that may compile but behave differently or throw at runtime, such as:
- `System.Web` types
- Windows Registry access
- `AppDomain` usage
- `BinaryFormatter`

### 6. Validate Configuration and App Settings
If the project previously used `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` or environment variables as appropriate, and that `Microsoft.Extensions.Configuration` is wired up correctly.

### 7. Smoke Test the Application
Run the application manually against a representative set of inputs or workflows to confirm end-to-end behavior is correct. Pay particular attention to:
- File I/O paths (path separators differ on Linux/macOS)
- Culture and encoding defaults, which changed between .NET Framework and .NET
- Any platform-specific code paths that may have been conditionally compiled

### 8. Publish the Application
Once validation is complete, publish the application using:
```bash
dotnet publish --configuration Release --output ./publish
```
Review the output directory to confirm all required assets, dependencies, and configuration files are present before deploying to the target environment.