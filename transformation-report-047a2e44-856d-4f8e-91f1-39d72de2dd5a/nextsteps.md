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
Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they are not hard errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:
```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```
Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET.

### 4. Review Removed or Replaced APIs
Check the code for any uses of APIs that were removed or have changed behavior in modern .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.UpgradeAssistant` tool can help surface these issues even when the project compiles successfully.

### 5. Check NuGet Package Compatibility
Open the `.csproj` files and review all `<PackageReference>` entries. Confirm that each package version supports the target framework. You can verify this on [nuget.org](https://www.nuget.org) or by running:
```bash
dotnet list package --outdated
```
Replace any packages that do not support the new target framework with their modern equivalents.

### 6. Validate Platform-Specific Code
Since this is a cross-platform migration, search the codebase for any platform-specific assumptions, such as:
- Windows registry access (`Microsoft.Win32.Registry`)
- Windows-only file path separators
- `System.Windows.Forms` or `System.Drawing` references
- P/Invoke calls targeting Windows-only native libraries

Use `RuntimeInformation.IsOSPlatform()` guards where platform-specific code must be retained.

### 7. Smoke Test the Application
Run the application manually and exercise its primary workflows to confirm that runtime behavior matches expectations from the legacy version.

### 8. Review Configuration and App Settings
If the project previously used `app.config` or `web.config`, confirm that configuration has been migrated appropriately to `appsettings.json` or environment-based configuration using `Microsoft.Extensions.Configuration`.

### 9. Check Output Artifacts
After a Release build, inspect the output directory to confirm the expected binaries, dependencies, and any publish profiles are producing the correct artifacts:
```bash
dotnet publish --configuration Release --output ./publish
```
Review the contents of the `./publish` folder to ensure all required files are present.