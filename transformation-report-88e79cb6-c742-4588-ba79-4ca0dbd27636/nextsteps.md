# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

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

### 4. Check for Removed or Changed APIs
Review any usage of APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.UpgradeAssistant` tool can help identify these at the code level.

Pay particular attention to:
- `System.Web` dependencies (not available in cross-platform .NET)
- Windows-specific APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- `AppDomain`, `BinaryFormatter`, and other APIs that are restricted or removed

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and inspect all `<PackageReference>` entries. Confirm each package has a version compatible with your target framework. You can check compatibility on [NuGet.org](https://www.nuget.org) or by running:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

### 6. Validate Configuration Files
If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or environment-based configuration as appropriate for cross-platform .NET.

### 7. Test on Target Platforms
If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear at build time.

```bash
dotnet run --configuration Release
```

### 8. Publish a Release Build
Once the above steps pass, produce a published output to verify the deployment artifact is generated correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to confirm all expected files are present and that the output matches the intended deployment model (framework-dependent vs. self-contained).

```bash
# Self-contained example
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```