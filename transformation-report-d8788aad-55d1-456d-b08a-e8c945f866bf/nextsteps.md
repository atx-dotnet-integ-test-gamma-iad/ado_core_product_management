# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless a multi-targeting scenario is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tooling to identify any APIs that were available in .NET Framework but behave differently or are absent in cross-platform .NET:

```bash
dotnet tool install -g dotnet-apicompat
```

Pay particular attention to:
- `System.Web` usages (not available on cross-platform .NET)
- Windows-specific APIs such as the registry, WCF server-side, or `System.Drawing` (GDI+)
- Any P/Invoke calls that may be platform-dependent

### 5. Review NuGet Package Versions
Open each `.csproj` and verify that all `<PackageReference>` entries reference versions that support the target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where newer versions provide better cross-platform support.

### 6. Validate Configuration Files
If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables as appropriate for the new hosting model.

### 7. Smoke Test on Target Platforms
Run the application on each platform you intend to support (Windows, Linux, macOS) to catch any platform-specific runtime failures that would not surface during a build:

```bash
dotnet run --configuration Release
```

### 8. Publish a Self-Contained or Framework-Dependent Build
Once the above steps pass, produce a release artifact to confirm the publish process completes without errors:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish-linux
```

Review the output directory to ensure all expected assemblies and configuration files are present.