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
Review the output for any warnings that may indicate compatibility concerns, even if they are not hard errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:
```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```
Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and the new .NET runtime.

### 4. Check for Removed or Changed APIs
Even without build errors, some APIs behave differently on cross-platform .NET. Pay particular attention to:
- `System.Configuration` usage (replaced by `Microsoft.Extensions.Configuration`)
- `System.Web` usage (not available on .NET Core/.NET 5+)
- Windows-specific APIs such as the registry, WCF, or `System.Drawing` (may require additional NuGet packages like `System.Drawing.Common`)
- Reflection-based code that may behave differently under the new runtime

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and check that all referenced NuGet packages have versions compatible with your target framework. You can use the following command to check for outdated packages:
```bash
dotnet list package --outdated
```
Replace any packages that do not support the new target framework with their recommended alternatives.

### 6. Verify Runtime Behavior
Run the application manually and exercise the primary workflows to confirm that the application behaves as expected. Pay attention to:
- File path handling, as .NET on Linux/macOS is case-sensitive
- Line ending differences across operating systems
- Culture and locale-sensitive formatting

### 7. Review `app.config` / `web.config` Migration
If the original project used `app.config` or `web.config`, verify that configuration values have been migrated to `appsettings.json` or another supported configuration source, and that the application reads them correctly at runtime.

### 8. Publish the Application
Once validation is complete, publish the application using:
```bash
dotnet publish --configuration Release --output ./publish
```
Review the output directory to confirm all required files, assets, and dependencies are present before deploying to the target environment.