# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other unintended frameworks.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.ApiCompat` tool to identify any APIs that were available in the legacy framework but have been removed or changed in the target framework. Pay particular attention to:

- `System.Web` dependencies (not available in cross-platform .NET)
- Windows-specific APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- Any third-party NuGet packages that may have platform-specific limitations

### 5. Review NuGet Package Versions
Open the `.csproj` files and verify all NuGet package references are using versions compatible with the target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where necessary, testing after each update to isolate any issues.

### 6. Validate Runtime Behavior
Run the application locally and exercise the primary workflows to confirm functional correctness. Compare outputs against the legacy version where possible.

### 7. Review Configuration Files
Confirm that any configuration files (e.g., `appsettings.json`, formerly `app.config` or `web.config`) have been correctly migrated. The `<appSettings>` and `<connectionStrings>` sections from legacy config files should be represented in the new configuration system using `Microsoft.Extensions.Configuration`.

### 8. Publish a Release Build
Once validation is complete, produce a self-contained or framework-dependent publish output to confirm the application packages correctly:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the output directory contains all expected files and that the application runs from the published output.