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
Review all NuGet dependencies in each `.csproj` file. Confirm that every package has a version that supports your target framework. You can use the following command to identify outdated packages:
```bash
dotnet list package --outdated
```
Update packages where a newer, compatible version is available.

### 5. Review Removed or Changed APIs
Cross-platform .NET removes or modifies certain APIs that existed in .NET Framework. Check the code for usage of the following common problem areas:
- `System.Web` namespace (not available in .NET Core/.NET 5+)
- `AppDomain` members with limited support
- Windows Registry access (`Microsoft.Win32.Registry`) — only functional on Windows
- `BinaryFormatter` — deprecated and disabled by default in .NET 7+

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining compatibility issues.

### 6. Validate Configuration Files
If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or equivalent .NET configuration providers where applicable.

### 7. Test on Target Platform
If cross-platform support (Linux, macOS) is a goal, run the build and tests on those operating systems to surface any platform-specific runtime issues that would not appear on Windows.

### 8. Publish the Application
Once the build and tests are passing, produce a publish output to verify the deployment artifact is correct:
```bash
dotnet publish --configuration Release --output ./publish
```
Review the contents of the `./publish` directory to confirm all expected assemblies, configuration files, and assets are present.

### 9. Smoke Test the Published Output
Run the published output directly to confirm the application starts and behaves as expected:
```bash
./publish/AdoCore
```
Or, for a framework-dependent executable:
```bash
dotnet ./publish/AdoCore.dll
```