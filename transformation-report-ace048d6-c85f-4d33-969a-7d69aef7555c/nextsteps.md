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
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.ApiCompat` tool to identify any APIs that were available in the legacy framework but have been removed or altered in the target framework. Pay particular attention to:

- `System.Web` usages (not available in cross-platform .NET)
- Windows-specific APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- Any third-party NuGet packages that may not have cross-platform compatible versions

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and review all `<PackageReference>` entries. For each package, confirm on [nuget.org](https://www.nuget.org) that the version referenced supports the target framework. Replace or update any packages that only support `net4x`.

### 6. Validate Platform-Specific Behavior
If the application relies on file paths, line endings, or OS-specific behavior, test it on each intended target platform (Windows, Linux, macOS) to surface any runtime issues that would not appear at build time.

### 7. Review Configuration Files
Confirm that any `app.config` or `web.config` files have been migrated to `appsettings.json` or the appropriate .NET configuration model. Legacy XML-based configuration is not fully supported in cross-platform .NET.

### 8. Smoke Test the Application
Run the application in its target environment and exercise the primary workflows to confirm end-to-end functionality is intact:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Review logs and output for any runtime exceptions or unexpected behavior.

### 9. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier (`win-x64`, `osx-x64`, etc.) and `--self-contained` flag to match your deployment requirements. Review the contents of the `publish` output folder before deploying.