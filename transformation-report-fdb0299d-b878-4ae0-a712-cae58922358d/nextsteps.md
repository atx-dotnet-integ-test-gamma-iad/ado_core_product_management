# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including the core project `AdoCore.csproj`.

## Validation Steps

### 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to a supported cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages.

### 3. Build the Solution

Perform a full build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

### 4. Run the Test Suite

If the solution contains test projects, execute them to validate functional correctness:

```bash
dotnet test --configuration Release
```

Review any failing tests, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been available in .NET Framework but behave differently or throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the following command to check:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to:
- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- COM interop usage
- Windows-specific file path assumptions

### 6. Run the Application

Execute the application directly to verify runtime behavior:

```bash
dotnet run --project ado_core_product_management/AdoCore.csproj --configuration Release
```

Test all major workflows that existed in the legacy application to confirm they behave as expected.

### 7. Review NuGet Package Compatibility

Check that all referenced NuGet packages support the new target framework. Visit [nuget.org](https://www.nuget.org) for each dependency and confirm the target framework is listed under the package's supported frameworks. Replace any packages that do not support the new target with their recommended alternatives.

### 8. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` or environment-based configuration, as `System.Configuration.ConfigurationManager` has limited support in cross-platform .NET.