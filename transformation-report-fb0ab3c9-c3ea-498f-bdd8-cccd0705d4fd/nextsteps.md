# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and consider updating them.

### 3. Build the Solution
Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review the test results and investigate any failures, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Review Removed or Incompatible APIs
Check the code for any APIs that were available in .NET Framework but have changed or been removed in modern .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) can help identify these at the code level.

Common areas to review:
- `System.Web` usages (not available in modern .NET)
- `AppDomain` APIs with reduced functionality
- Windows-specific registry or COM interop calls
- `BinaryFormatter` usage, which is disabled by default in .NET 5+

### 6. Verify Runtime Behavior
Run the application and exercise its primary workflows manually or through integration tests. Pay attention to:
- Configuration loading (e.g., `app.config` vs `appsettings.json`)
- File path handling, which may differ across operating systems
- Any platform-specific code paths that may only execute on Windows

### 7. Check Output Artifacts
Confirm the build output in the `bin/Release/net8.0/` (or equivalent) directory contains the expected assemblies and that the application starts correctly:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 8. Review Project References and Package Versions
Open the `.csproj` files and confirm that all `<PackageReference>` entries are pointing to NuGet packages compatible with modern .NET. Use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, particularly any that were previously targeting .NET Framework only.