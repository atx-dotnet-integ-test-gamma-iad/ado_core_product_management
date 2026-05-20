# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify that behavior has not changed after the transformation:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

### 4. Check for Removed or Changed APIs
Some .NET Framework APIs are not available or behave differently in cross-platform .NET. Review the Microsoft API compatibility documentation or use the compatibility analyzer:

```bash
dotnet add package Microsoft.DotNet.ApiCompat
```

Pay particular attention to areas such as:
- `System.Web` (not available in cross-platform .NET)
- Windows Registry access
- Windows-specific security or identity APIs
- `AppDomain` usage

### 5. Review NuGet Package Versions
Open the `.csproj` files and confirm that all NuGet packages reference versions that support the target framework. You can check compatibility on [nuget.org](https://www.nuget.org). Run:

```bash
dotnet list package --outdated
```

Update packages where newer versions provide better cross-platform support.

### 6. Run on Target Platforms
If cross-platform support is a goal (e.g., Linux or macOS), run the application on each intended platform to surface any platform-specific runtime issues that would not appear during a Windows build:

```bash
dotnet run --configuration Release
```

### 7. Publish a Self-Contained or Framework-Dependent Build
Produce a release build artifact to confirm the publish process works correctly:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish-linux
```

Verify the output directory contains the expected files and that the application starts correctly from the published output.

### 8. Review Configuration Files
If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables as appropriate for cross-platform .NET. The `System.Configuration.ConfigurationManager` package can provide backward compatibility if needed:

```xml
<PackageReference Include="System.Configuration.ConfigurationManager" Version="8.0.0" />
```