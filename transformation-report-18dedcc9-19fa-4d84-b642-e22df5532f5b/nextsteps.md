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
Review any failing tests and trace them back to behavioral differences between .NET Framework and the new .NET runtime.

### 4. Check for Removed or Changed APIs
Some APIs that existed in .NET Framework are absent or behave differently in modern .NET. Review the [.NET Upgrade Assistant compatibility analyzer output](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or run the compatibility analyzer manually:
```bash
dotnet add package Microsoft.DotNet.UpgradeAssistant.Extensions.Default.Analyzers
dotnet build
```
Address any analyzer warnings related to platform compatibility or obsolete API usage.

### 5. Review NuGet Package Versions
Open each `.csproj` and confirm that all NuGet package references are pointing to versions that support your target framework. You can check compatibility on [nuget.org](https://www.nuget.org). Replace any packages that have known cross-platform replacements (e.g., `System.Drawing.Common` has limitations on non-Windows platforms).

### 6. Validate Platform-Specific Code
Search the solution for any usage of Windows-specific APIs or P/Invoke calls that may not function correctly on Linux or macOS if cross-platform support is a goal:
```bash
grep -rn "DllImport\|Registry\|System.Drawing\|System.Windows" --include="*.cs"
```
Annotate or conditionally compile any platform-specific code using `RuntimeInformation.IsOSPlatform()` where appropriate.

### 7. Verify Configuration and App Settings
If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, and that the application reads them correctly at runtime using `Microsoft.Extensions.Configuration`.

### 8. Smoke Test the Application
Run the application manually in a development environment and exercise the primary workflows to confirm end-to-end functionality. Compare outputs and behavior against the legacy .NET Framework version where possible.

## Deployment Steps

### 1. Publish the Application
Use the `dotnet publish` command to produce deployment artifacts:
```bash
dotnet publish --configuration Release --output ./publish
```
For a self-contained deployment (no .NET runtime required on the target machine):
```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```
Replace `win-x64` with the appropriate runtime identifier for your target environment (e.g., `linux-x64`, `osx-x64`).

### 2. Verify Published Output
Inspect the `./publish` directory to confirm all expected assemblies, configuration files, and static assets are present.

### 3. Test on Target Environment
Copy the published output to the target machine and run the application there to confirm it functions correctly outside of the development environment. Pay attention to file path separators, environment variables, and permission differences across operating systems.