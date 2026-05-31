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
If the solution contains test projects, execute them to verify runtime behavior matches expectations:
```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```
Address any failing tests before proceeding.

### 4. Check NuGet Package Compatibility
Review all NuGet dependencies in each `.csproj` file. Confirm that every package has a version compatible with the target .NET version. You can use the following command to identify outdated packages:
```bash
dotnet list package --outdated
```
Update packages where necessary, being cautious of breaking changes between major versions.

### 5. Review Removed or Changed APIs
Cross-platform .NET removes certain APIs that were available in .NET Framework. Run the .NET Upgrade Assistant compatibility analyzer or the Platform Compatibility Analyzer to surface any API usage that may fail at runtime even if it compiles:
```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

### 6. Validate Configuration and App Settings
If the project uses `App.config` or `Web.config`, confirm those have been migrated to `appsettings.json` or the appropriate .NET configuration model. Verify connection strings, environment-specific settings, and any custom configuration sections are functioning correctly at runtime.

### 7. Test on Target Operating Systems
Since the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues such as:
- File path separator differences
- Case-sensitive file systems on Linux
- Windows-only APIs that may have been inadvertently retained

### 8. Publish a Release Build
Once the above steps pass, produce a release publish to confirm the output is complete and runnable:
```bash
dotnet publish --configuration Release --output ./publish
```
Verify the contents of the `./publish` folder and run the output directly to confirm the application starts and behaves as expected.